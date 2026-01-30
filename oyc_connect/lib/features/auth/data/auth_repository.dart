import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // Sign Up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );

      // Enable notifications after successful signup
      if (response.user != null) {
        OneSignal.login(response.user!.id);
      }

      return response;
    } on AuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Sign In
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Enable notifications after successful login
      if (response.user != null) {
        OneSignal.login(response.user!.id);
      }

      return response;
    } on AuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  String _handleAuthError(AuthException e) {
    if (e.message.contains('Invalid login credentials')) {
      return 'Incorrect email or password.';
    } else if (e.message.contains('User already registered')) {
      return 'Email is already in use.';
    } else {
      return e.message; // Return Supabase message for other cases
    }
  }

  // Sign Out
  Future<void> signOut() async {
    // Logout from OneSignal to stop receiving notifications
    await OneSignal.logout();

    // Sign out from Supabase
    await _supabase.auth.signOut();
  }

  // Get Current User
  User? get currentUser => _supabase.auth.currentUser;

  // Listen to Auth Changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
