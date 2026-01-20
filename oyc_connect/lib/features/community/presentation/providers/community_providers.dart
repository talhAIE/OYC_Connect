import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/models/event_model.dart';
import '../../data/models/announcement_model.dart';

part 'community_providers.g.dart';

@riverpod
CommunityRepository communityRepository(CommunityRepositoryRef ref) {
  return CommunityRepository(Supabase.instance.client);
}

@riverpod
Future<List<Event>> events(EventsRef ref) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.getEvents();
}

@riverpod
Future<List<Announcement>> announcements(AnnouncementsRef ref) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.getAnnouncements();
}
