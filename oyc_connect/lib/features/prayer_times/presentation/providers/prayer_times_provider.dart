import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/prayer_times_repository.dart';
import '../../data/repositories/jummah_repository.dart';
import '../../data/models/prayer_time_model.dart';
import '../../data/models/jummah_config.dart';
import 'package:timezone/timezone.dart' as tz;

part 'prayer_times_provider.g.dart';

@riverpod
PrayerTimesRepository prayerTimesRepository(PrayerTimesRepositoryRef ref) {
  return PrayerTimesRepository(Supabase.instance.client);
}

@riverpod
JummahRepository jummahRepository(JummahRepositoryRef ref) {
  return JummahRepository(Supabase.instance.client);
}

@riverpod
Stream<PrayerTime?> todayPrayerTime(TodayPrayerTimeRef ref) async* {
  final repository = ref.watch(prayerTimesRepositoryProvider);

  // Determine today in Melbourne
  final melbourne = tz.getLocation('Australia/Melbourne');
  final nowMelbourne = tz.TZDateTime.now(melbourne);
  final todayStr = nowMelbourne.toIso8601String().split('T')[0];

  // 1. Attempt initial REST fetch for immediate display and fallback
  PrayerTime? fallbackData;
  try {
    fallbackData = await repository.getPrayerTimes(nowMelbourne);
    if (fallbackData != null) {
      yield fallbackData;
    }
  } catch (e) {
    print('Initial fetch failed: $e');
  }

  // 2. Subscribe to Realtime updates with error handling
  try {
    final stream = repository
        .subscribeToPrayerTimes(dateStr: todayStr)
        .map((list) {
          if (list.isNotEmpty) {
            fallbackData = list.first; // Update fallback data
            return list.first;
          }
          return null;
        })
        .handleError((error) {
          // If Realtime fails (e.g. Token Expired), we log it but do NOT crash the UI.
          // The previous yield (from REST or previous stream event) remains active.
          print(
            'Realtime subscription error (ignoring to prevent UI crash): $error',
          );
        });

    yield* stream;
  } catch (e) {
    print('Stream setup failed: $e');
  }
}

@riverpod
Future<PrayerTime?> fetchTodayPrayerTime(FetchTodayPrayerTimeRef ref) async {
  final repository = ref.watch(prayerTimesRepositoryProvider);
  return repository.getPrayerTimes(DateTime.now());
}

@riverpod
Stream<JummahConfig?> jummahConfig(JummahConfigRef ref) async* {
  final repository = ref.watch(jummahRepositoryProvider);

  // 1. Initial REST fetch
  try {
    final initial = await repository.getJummahConfig();
    if (initial != null) yield initial;
  } catch (e) {
    print('Initial Jummah fetch failed: $e');
  }

  // 2. Realtime subscription
  try {
    yield* repository.subscribeToJummahConfig();
  } catch (e) {
    print('Jummah subscription failed: $e');
  }
}
