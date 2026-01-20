import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prayer_time_model.dart';

class PrayerTimesRepository {
  final SupabaseClient _client;

  PrayerTimesRepository(this._client);

  /// Fetches prayer times for a specific date (defaults to today)
  Future<PrayerTime?> getPrayerTimes(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _client
          .from('prayer_times')
          .select()
          .eq('date', dateStr)
          .maybeSingle();

      if (response == null) return null;
      return PrayerTime.fromJson(response);
    } catch (e) {
      // TODO: Handle error properly
      print('Error fetching prayer times: $e');
      return null;
    }
  }

  /// Subscribes to realtime updates for the prayer_times table
  Stream<List<PrayerTime>> subscribeToPrayerTimes() {
    return _client
        .from('prayer_times')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => PrayerTime.fromJson(json)).toList());
  }

  /// Upserts prayer times for a specific date
  Future<void> upsertPrayerTimes(PrayerTime prayerTime) async {
    final dateStr = prayerTime.date.toIso8601String().split('T')[0];
    final data = prayerTime.toJson();
    if (prayerTime.id == 0) {
      data.remove('id');
    }
    data['date'] = dateStr;
    await _client.from('prayer_times').upsert(data, onConflict: 'date');
  }
}
