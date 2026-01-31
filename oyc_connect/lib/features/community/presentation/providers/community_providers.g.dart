// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$communityRepositoryHash() =>
    r'98f6c6398d0351a54b2b0075ef787060790f0ae5';

/// See also [communityRepository].
@ProviderFor(communityRepository)
final communityRepositoryProvider =
    AutoDisposeProvider<CommunityRepository>.internal(
      communityRepository,
      name: r'communityRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$communityRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CommunityRepositoryRef = AutoDisposeProviderRef<CommunityRepository>;
String _$eventsHash() => r'dcd0ecd6ba9afbcbf345e8bf17d00b690e1885e7';

/// See also [events].
@ProviderFor(events)
final eventsProvider = AutoDisposeFutureProvider<List<Event>>.internal(
  events,
  name: r'eventsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$eventsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EventsRef = AutoDisposeFutureProviderRef<List<Event>>;
String _$announcementsHash() => r'394da187b3ac1ac6c8416b480340725a729af334';

/// See also [announcements].
@ProviderFor(announcements)
final announcementsProvider =
    AutoDisposeFutureProvider<List<Announcement>>.internal(
      announcements,
      name: r'announcementsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$announcementsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnnouncementsRef = AutoDisposeFutureProviderRef<List<Announcement>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
