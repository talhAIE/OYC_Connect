import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

part 'profile_provider.g.dart';

@Riverpod(keepAlive: true)
class Profile extends _$Profile {
  @override
  FutureOr<ProfileModel?> build() async {
    // Watch auth state changes so this provider rebuilds when user logs in/out
    final _ = ref.watch(authStateChangesProvider);
    return _fetchProfile();
  }

  Future<ProfileModel?> _fetchProfile() async {
    try {
      return await ref.read(profileRepositoryProvider).getProfile();
    } catch (e) {
      // If user is not logged in or profile doesn't exist yet
      return null;
    }
  }

  Future<void> updateName(String fullName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(fullName: fullName);
      return _fetchProfile();
    });
  }

  Future<void> toggleNotifications(bool enabled) async {
    // Optimistic update
    final previousState = state;
    if (previousState.value != null) {
      state = AsyncValue.data(
        previousState.value!.copyWith(notificationsEnabled: enabled),
      );
    }

    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(notificationsEnabled: enabled);
    } catch (e) {
      state = previousState; // Revert on failure
      rethrow;
    }
  }
}
