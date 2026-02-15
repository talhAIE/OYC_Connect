class SupabaseConstants {
  // TODO: Replace with your actual Supabase URL and Anon Key
  static const String url = 'https://jbjtrppxzbgwbqzcpcib.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpianRycHB4emJnd2JxemNwY2liIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4MTA2MTgsImV4cCI6MjA4NjM4NjYxOH0.fbi0cw7UNgswt3FnNXwDPpHOs6tuPDej4kpLfmpPfL8';

  /// Default event image when none is uploaded (bucket: app_assets, file: defaultoycimage.jpg).
  static String get defaultEventImageUrl =>
      '$url/storage/v1/object/public/app_assets/defaultoycimage.jpg';

  /// Default announcement image when none is uploaded (same as event default).
  static String get defaultAnnouncementImageUrl => defaultEventImageUrl;

  /// Redirect URL for password-reset email. User clicks link → this URL (with token in hash) → page redirects to app.
  /// Use a hosted copy of web/reset-password.html so the link opens in browser first, then opens the app.
  /// Example: 'https://yoursite.com/reset-password.html'. If null or empty, uses app deep link (may show blank in browser).
  static const String? passwordResetRedirectUrl = 'https://talhaie.github.io/oyc_reset/reset-password.html';

  /// URL used when calling resetPasswordForEmail. Prefer web page so email link doesn't open a blank browser tab.
  static String get effectivePasswordResetRedirect =>
      (passwordResetRedirectUrl != null && passwordResetRedirectUrl!.isNotEmpty)
          ? passwordResetRedirectUrl!
          : 'oycconnect://reset-password';
}
