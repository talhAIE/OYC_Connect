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
    // Manually construct map to ensure only existing DB columns are sent
    // DB Columns: id, title, description, event_date, location, image_url
    final Map<String, dynamic> data = {
      'title': event.title,
      'description': event.description,
      'event_date': event.eventDate.toIso8601String(),
      'location': event.location,
      'image_url': event.imageUrl,
    };

    if (event.id != 0) {
      data['id'] = event.id;
    }

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
