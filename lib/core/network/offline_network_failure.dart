import 'package:graphql_flutter/graphql_flutter.dart';

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
