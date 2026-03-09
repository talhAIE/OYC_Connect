import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConstants {
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Default images for events and announcements (public URLs, not secrets)

  static const String defaultEventImageUrl =
      'https://jbjtrppxzbgwbqzcpcib.supabase.co/storage/v1/object/public/app_assets/defaultoycimage.jpg';
  static const String defaultAnnouncementImageUrl =
      'https://jbjtrppxzbgwbqzcpcib.supabase.co/storage/v1/object/public/app_assets/defaultoycimage.jpg';

  /// Redirect URL for password‐reset emails (deep‐link into the app).
  static const String passwordResetRedirect = 'oycconnect://reset-password';

  /// Falls back to [passwordResetRedirect] if nothing else is configured.
  static String get effectivePasswordResetRedirect => passwordResetRedirect;
}
