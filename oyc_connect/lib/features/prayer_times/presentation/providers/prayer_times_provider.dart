import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/prayer_times_repository.dart';
import '../../data/models/prayer_time_model.dart';

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

  return repository.subscribeToPrayerTimes().map((list) {
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    try {
      return list.firstWhere(
        (pt) => pt.date.toIso8601String().split('T')[0] == todayStr,
      );
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
