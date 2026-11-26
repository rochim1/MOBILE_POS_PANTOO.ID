import 'dart:async';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'offline_network_failure.dart';

const posBootstrapReadTimeout = Duration(seconds: 8);

/// Retry only a fast transient failure, never a healthy-but-slow connection.
/// A full attempt retains eight seconds; at most two seconds may precede the
/// retry. This remains below the lock screen's fifteen-second UI deadline.
/// Never retry a PIN verification, write, or authoritative server rejection.
Future<QueryResult<T>> queryPOSPinRoster<T>(
  GraphQLClient client,
  QueryOptions<T> options, {
  required void Function() validateSession,
}) async {
  final bounded = options.copyWithOptions(
    queryRequestTimeout: posBootstrapReadTimeout,
  );
  var mayRetry = true;
  final retryWindow = Timer(const Duration(seconds: 2), () => mayRetry = false);
  try {
    for (var attempt = 0; ; attempt++) {
      validateSession();
      try {
        final result = await client
            .query<T>(bounded)
            .timeout(posBootstrapReadTimeout);
        if (result.hasException) throw result.exception!;
        return result;
      } catch (error) {
        if (attempt == 1 || !mayRetry || !isOfflineReadFailure(error)) rethrow;
      }
    }
  } finally {
    retryWindow.cancel();
  }
}

/// In-flight sharing only. Never cache a settled permission result or share
/// between endpoint/tenant/terminal/operator/client-session identities.
class PosBootstrapReads {
  final _pending = <String, Future<Object?>>{};

  Future<T> run<T>(String scope, Future<T> Function() read) {
    final pending = _pending[scope];
    if (pending != null) return pending as Future<T>;
    late final Future<T> result;
    result = Future<T>.sync(read).whenComplete(() {
      if (identical(_pending[scope], result)) _pending.remove(scope);
    });
    _pending[scope] = result;
    return result;
  }
}

/// Close a stalled read stream after one timeout. The GraphQL client's default
/// Stream.timeout otherwise continues emitting timeout errors while its source
/// stays open. Financial mutations are deliberately outside this link.
Link posBootstrapReadDeadlineLink({
  Duration timeout = posBootstrapReadTimeout,
}) => Link.function((request, [forward]) {
  final definitions = request.operation.document.definitions
      .whereType<OperationDefinitionNode>();
  final selected = definitions
      .where(
        (definition) =>
            request.operation.operationName == null ||
            definition.name?.value == request.operation.operationName,
      )
      .toList();
  const reads = {
    'GetPOSPinUsers',
    'GetMyPOSLockStatus',
    'GetPOSRuntimeConfig',
    'GetCurrentPOSUser',
  };
  final bounded =
      selected.length == 1 &&
      selected.single.type == OperationType.query &&
      reads.contains(selected.single.name?.value);
  final response = forward!(request);
  if (!bounded) return response;
  return response.timeout(
    timeout,
    onTimeout: (sink) {
      sink.addError(TimeoutException('POS startup read timed out', timeout));
      sink.close();
    },
  );
});
