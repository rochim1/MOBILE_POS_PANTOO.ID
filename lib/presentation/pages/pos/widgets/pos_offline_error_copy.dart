import '../../../../core/error/failures.dart';

/// Presentation only: keep the original diagnostic and retry state in storage.
String posOfflineErrorCopy(Object? error) {
  final message = error?.toString().trim() ?? '';
  final detail = message.toLowerCase();
  if (const [
    'socketexception',
    'connection refused',
    'connection reset',
    'failed host lookup',
    'network is unreachable',
    'timeoutexception',
    'xmlhttprequest error',
  ].any(detail.contains)) {
    return const NetworkFailure().message;
  }
  if (const [
    'operationexception(',
    'serverexception(',
    'formatexception:',
    'originalstacktrace:',
    '#0 ',
    'e11000',
  ].any(detail.contains)) {
    return 'Terjadi kesalahan tidak terduga';
  }
  return message;
}
