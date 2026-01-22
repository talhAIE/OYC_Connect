import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/prayer_times_repository.dart';
import '../../data/models/prayer_time_model.dart';
import 'package:timezone/timezone.dart' as tz;

part 'prayer_times_provider.g.dart';

@riverpod
PrayerTimesRepository prayerTimesRepository(PrayerTimesRepositoryRef ref) {
  return PrayerTimesRepository(Supabase.instance.client);
}

@riverpod
Stream<PrayerTime?> todayPrayerTime(TodayPrayerTimeRef ref) {
  // Fetch initial data or listen to realtime?
  // For simplicity, let's just fetch for now, or stream if we want realtime updates on the day.
  // Actually, let's stream the ONE row for today.

  final repository = ref.watch(prayerTimesRepositoryProvider);
  // This is a bit tricky with standard stream/subscribe as Supabase stream usually returns a list.
  // We'll trust the repository helper or just stream the list and filter.

  // Determine today in Melbourne
  final melbourne = tz.getLocation('Australia/Melbourne');
  final nowMelbourne = tz.TZDateTime.now(melbourne);
  final todayStr = nowMelbourne.toIso8601String().split('T')[0];

  return repository.subscribeToPrayerTimes(dateStr: todayStr).map((list) {
    try {
      if (list.isEmpty) return null;
      // Since we filtered by date, the list should contain only today's record (or duplicates if any, but first is fine)
      return list.first;
    } catch (_) {
      return null;
    }
  });
}

@riverpod
Future<PrayerTime?> fetchTodayPrayerTime(FetchTodayPrayerTimeRef ref) async {
  final repository = ref.watch(prayerTimesRepositoryProvider);
  return repository.getPrayerTimes(DateTime.now());
}
