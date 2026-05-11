import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';

/// Set to true when user opens app via password-reset deep link so redirect sends them to set-new-password.
final recoveryPendingProvider = StateProvider<bool>((ref) => false);

// Dependency Injection for Supabase Client
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Dependency Injection for Auth Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthRepository(supabase);
});

// Auth Controller State
final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  late final AuthRepository _authRepository;

  @override
  AsyncValue<void> build() {
    _authRepository = ref.watch(authRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      // Force sign out so user has to log in manually
      await signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signIn(email: email, password: password);
      // OneSignal login is handled in auth_repository
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    // OneSignal logout is handled in auth_repository
    await _authRepository.signOut();
  }

  Future<void> requestPasswordReset(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.resetPasswordForEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setNewPassword(String newPassword) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.updatePassword(newPassword);
      await signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Simple provider to listen to auth state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
