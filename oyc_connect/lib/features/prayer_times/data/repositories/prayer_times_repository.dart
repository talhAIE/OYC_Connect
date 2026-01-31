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

  /// Fetches prayer times for a specific month
  Future<List<PrayerTime>> getMonthlyPrayerTimes(int year, int month) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // Last day of month

      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      print('Fetching monthly prayer times from $startDateStr to $endDateStr');

      final response = await _client
          .from('prayer_times')
          .select()
          .gte('date', startDateStr)
          .lte('date', endDateStr)
          .order('date', ascending: true);

      return (response as List)
          .map((json) => PrayerTime.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching monthly prayer times: $e');
      return [];
    }
  }

  /// Subscribes to realtime updates for the prayer_times table
  Stream<List<PrayerTime>> subscribeToPrayerTimes({String? dateStr}) {
    if (dateStr != null) {
      return _client
          .from('prayer_times')
          .stream(primaryKey: ['id'])
          .eq('date', dateStr)
          .map(
            (data) => data.map((json) => PrayerTime.fromJson(json)).toList(),
          );
    }
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
