import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';
import '../../data/password_recovery_controller.dart';

final passwordRecoveryProvider =
    ChangeNotifierProvider<PasswordRecoveryController>((ref) {
      final appLinks = AppLinks();
      final controller = PasswordRecoveryController(
        repository: ref.watch(authRepositoryProvider),
        store: PreferencesRecoverySessionStore(),
        initialLink: appLinks.getInitialLink,
        links: appLinks.uriLinkStream,
      );
      unawaited(controller.initialize());
      return controller;
    });

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
    required String phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
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
      // Notification identity is reconciled centrally from auth state.
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    // Notification identity and opt-out follow the auth-state change.
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
      final completed = await ref
          .read(passwordRecoveryProvider)
          .complete(newPassword);
      if (!completed) throw StateError('Could not finish password recovery.');
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
