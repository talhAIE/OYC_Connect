// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_times_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$prayerTimesRepositoryHash() =>
    r'176524cf445a91d5a358fc2c320864fea4248af3';

/// See also [prayerTimesRepository].
@ProviderFor(prayerTimesRepository)
final prayerTimesRepositoryProvider =
    AutoDisposeProvider<PrayerTimesRepository>.internal(
      prayerTimesRepository,
      name: r'prayerTimesRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$prayerTimesRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PrayerTimesRepositoryRef =
    AutoDisposeProviderRef<PrayerTimesRepository>;
String _$todayPrayerTimeHash() => r'b9b4fa9a74458a5f194c447f55040bcef57aceb3';

/// See also [todayPrayerTime].
@ProviderFor(todayPrayerTime)
final todayPrayerTimeProvider = AutoDisposeStreamProvider<PrayerTime?>.internal(
  todayPrayerTime,
  name: r'todayPrayerTimeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$todayPrayerTimeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TodayPrayerTimeRef = AutoDisposeStreamProviderRef<PrayerTime?>;
String _$fetchTodayPrayerTimeHash() =>
    r'dc830b586fb4bdff7ea8244df894bc81620cc46d';

/// See also [fetchTodayPrayerTime].
@ProviderFor(fetchTodayPrayerTime)
final fetchTodayPrayerTimeProvider =
    AutoDisposeFutureProvider<PrayerTime?>.internal(
      fetchTodayPrayerTime,
      name: r'fetchTodayPrayerTimeProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$fetchTodayPrayerTimeHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FetchTodayPrayerTimeRef = AutoDisposeFutureProviderRef<PrayerTime?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
