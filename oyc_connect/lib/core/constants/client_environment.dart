import 'dart:convert';

/// Flutter assets are public. Private service credentials must never load here.
void validateClientEnvironment(Map<String, String> environment) {
  const serverFields = {
    'ONESIGNAL_API_KEY',
    'ONESIGNAL_REST_API_KEY',
    'ONESIGNAL_ORG_API_KEY',
    'SUPABASE_SERVICE_ROLE_KEY',
    'STRIPE_SECRET_KEY',
  };
  for (final entry in environment.entries) {
    final value = entry.value.trim();
    if (value.isEmpty) continue;
    var isPrivate =
        serverFields.contains(entry.key.toUpperCase()) ||
        RegExp(
          r'^(os_v2_(app|org)_|sk_(live|test)_|sb_secret_)',
        ).hasMatch(value);
    final parts = value.split('.');
    if (parts.length == 3) {
      try {
        final claims = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );
        if (claims is Map && claims['role'] == 'service_role') isPrivate = true;
      } on FormatException {
        // Ordinary non-JWT values are handled by name/prefix checks above.
      }
    }
    if (isPrivate) {
      throw StateError(
        'Server credentials must not be bundled in Flutter assets. '
        'Remove the private value from ${entry.key} and use server secrets.',
      );
    }
  }
}
