import 'dart:convert';

// Local identity matching only; the server must still verify the JWT.
String operatorIdFromToken(String token) {
  if (token.startsWith('offline_operator:')) return token.substring(17);
  try {
    final parts = token.split('.');
    if (parts.length != 3) return '';
    final data = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    return data is Map && data['type'] == 'pos_operator'
        ? data['user_id']?.toString() ?? ''
        : '';
  } catch (_) {
    return '';
  }
}

bool operatorTokenIsCurrent(String token, {DateTime? now}) {
  try {
    final parts = token.split('.');
    if (parts.length != 3 || operatorIdFromToken(token).isEmpty) return false;
    final data =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
            as Map;
    final expiry = data['exp'];
    return expiry is num &&
        expiry * 1000 > (now ?? DateTime.now()).millisecondsSinceEpoch + 30000;
  } catch (_) {
    return false;
  }
}

String? operatorTokenForSync(String saved, String current) {
  if (saved.isEmpty) return '';
  final id = operatorIdFromToken(saved);
  if (id.isNotEmpty &&
      id == operatorIdFromToken(current) &&
      operatorTokenIsCurrent(current)) {
    return current;
  }
  return operatorTokenIsCurrent(saved) ? saved : null;
}
