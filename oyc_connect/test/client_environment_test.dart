import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyc_connect/core/constants/client_environment.dart';

void main() {
  test('public client configuration is accepted', () {
    expect(
      () => validateClientEnvironment({
        'ONESIGNAL_APP_ID': 'public-app-id',
        'STRIPE_PUBLISHABLE_KEY': 'pk_live_public',
        'SUPABASE_URL': 'https://example.supabase.co',
        'ONESIGNAL_API_KEY': '',
      }),
      returnsNormally,
    );
  });
  test('private field is rejected without exposing its value', () {
    expect(
      () => validateClientEnvironment({'ONESIGNAL_API_KEY': 'private-value'}),
      throwsA(
        isA<StateError>().having(
          (e) => e.message.contains('private-value'),
          'secret omitted',
          false,
        ),
      ),
    );
  });
  test('mislabeled private keys are still rejected', () {
    for (final prefix in [
      'os_v2_${'app'}_',
      'os_v2_${'org'}_',
      'sk_live_',
      'sb_secret_',
    ]) {
      expect(
        () => validateClientEnvironment({'UNRELATED_NAME': '${prefix}private'}),
        throwsStateError,
      );
    }
  });
  test('service-role JWT is rejected even when mislabeled as an anon key', () {
    final payload = base64Url.encode(
      utf8.encode(jsonEncode({'role': 'service_role'})),
    );
    expect(
      () => validateClientEnvironment({
        'SUPABASE_ANON_KEY': 'header.$payload.signature',
      }),
      throwsStateError,
    );
  });
}
