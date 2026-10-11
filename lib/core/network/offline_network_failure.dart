import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart';

class OfflineReadUnavailable implements Exception {
  const OfflineReadUnavailable();
}

bool isOfflineShiftSnapshotUsable(DateTime cachedAt, {DateTime? now}) {
  final age = (now ?? DateTime.now().toUtc()).toUtc().difference(
    cachedAt.toUtc(),
  );
  return !age.isNegative && age <= const Duration(hours: 8);
}

/// Read-only cache fallback is narrower than queueing a mutation: an API
/// response (including 5xx, invalid GraphQL, or auth errors) is not offline.
bool isOfflineReadFailure(Object error) {
  if (error is TimeoutException) return true;
  if (error is! OperationException || error.graphqlErrors.isNotEmpty) {
    return false;
  }
  final link = error.linkException;
  if (link is ServerException) {
    return link.statusCode == null &&
        (link.parsedResponse?.errors?.isEmpty ?? true);
  }
  if (link is HttpLinkServerException) return false;
  return link != null && link is! ResponseFormatException;
}

/// Only transport failures may be queued. GraphQL validation and authorization
/// errors have already reached the server and need operator intervention.
bool isRetryableOfflineNetworkFailure(OperationException? exception) {
  final link = exception?.linkException;
  if (link == null || exception!.graphqlErrors.isNotEmpty) return false;
  if (link is ServerException &&
      (link.parsedResponse?.errors?.isNotEmpty ?? false)) {
    return false;
  }
  if (link is HttpLinkServerException) {
    final code = link.response.statusCode;
    return code >= 500 || code == 408 || code == 429;
  }
  return link is ServerException || link is ResponseFormatException;
}
