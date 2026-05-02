class SupabaseConstants {
  // TODO: Replace with your actual Supabase URL and Anon Key
  static const String url = 'https://jbjtrppxzbgwbqzcpcib.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpianRycHB4emJnd2JxemNwY2liIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4MTA2MTgsImV4cCI6MjA4NjM4NjYxOH0.fbi0cw7UNgswt3FnNXwDPpHOs6tuPDej4kpLfmpPfL8';

  /// Default event image when none is uploaded (bucket: app_assets, file: defaultoycimage.jpg).
  static String get defaultEventImageUrl =>
      '$url/storage/v1/object/public/app_assets/defaultoycimage.jpg';

  /// Default announcement image when none is uploaded (same as event default).
  static String get defaultAnnouncementImageUrl => defaultEventImageUrl;
}
