import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';
import '../models/announcement_model.dart';

class CommunityRepository {
  final SupabaseClient _client;

  CommunityRepository(this._client);

  Future<List<Event>> getEvents() async {
    final response = await _client
        .from('events')
        .select()
        .order('event_date', ascending: true);

    return (response as List).map((e) => Event.fromJson(e)).toList();
  }

  Future<List<Announcement>> getAnnouncements() async {
    final response = await _client
        .from('announcements')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((e) => Announcement.fromJson(e)).toList();
  }

  Future<void> upsertAnnouncement(Announcement announcement) async {
    final data = announcement.toJson();
    if (announcement.id == 0) {
      data.remove('id');
    }
    await _client.from('announcements').upsert(data);
  }

  Future<void> deleteAnnouncement(int id) async {
    await _client.from('announcements').delete().eq('id', id);
  }

  Future<void> upsertEvent(Event event) async {
    final data = event.toJson();
    if (event.id == 0) {
      data.remove('id');
    }
    // Remove is_featured as the column might not exist in the database yet
    data.remove('is_featured');

    await _client.from('events').upsert(data);
  }

  Future<void> deleteEvent(int id) async {
    await _client.from('events').delete().eq('id', id);
  }

  Future<String?> uploadEventImage(String path, dynamic fileBytes) async {
    try {
      await _client.storage
          .from('app_assets')
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      return _client.storage.from('app_assets').getPublicUrl(path);
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
