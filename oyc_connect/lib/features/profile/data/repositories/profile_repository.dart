import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/profile_model.dart';
import '../../../../core/constants/supabase_constants.dart';

part 'profile_repository.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return ProfileRepository(Supabase.instance.client);
}

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  Future<ProfileModel> getProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return ProfileModel.fromJson(data);
  }

  Future<void> updateProfile({
    String? fullName,
    bool? notificationsEnabled,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (notificationsEnabled != null) {
      updates['notifications_enabled'] = notificationsEnabled;
    }

    if (updates.isEmpty) return;

    await _supabase.from('profiles').update(updates).eq('id', userId);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final email = _supabase.auth.currentUser?.email;
    if (email == null) throw Exception('User email not found');

    // 1. Re-authenticate to verify old password
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: oldPassword,
      );
    } on AuthException catch (_) {
      throw Exception('Incorrect old password');
    }

    // 2. Update password
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
