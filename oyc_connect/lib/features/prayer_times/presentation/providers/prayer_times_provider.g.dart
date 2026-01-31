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
String _$jummahRepositoryHash() => r'75b5362d0e2aa23095f441ca3f3606b2a0182334';

/// See also [jummahRepository].
@ProviderFor(jummahRepository)
final jummahRepositoryProvider = AutoDisposeProvider<JummahRepository>.internal(
  jummahRepository,
  name: r'jummahRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$jummahRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef JummahRepositoryRef = AutoDisposeProviderRef<JummahRepository>;
String _$todayPrayerTimeHash() => r'e1ea9cdea22e5d0d27e2cf8551f970466d370111';

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
String _$jummahConfigHash() => r'96b240baa098decf3f6a7bc9516142d9980c9130';

/// See also [jummahConfig].
@ProviderFor(jummahConfig)
final jummahConfigProvider = AutoDisposeStreamProvider<JummahConfig?>.internal(
  jummahConfig,
  name: r'jummahConfigProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$jummahConfigHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef JummahConfigRef = AutoDisposeStreamProviderRef<JummahConfig?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
