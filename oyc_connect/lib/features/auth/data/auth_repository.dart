import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../../core/constants/supabase_constants.dart';

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

  /// Sends a password-reset email only if the email is registered. Uses Edge Function to check first.
  Future<void> resetPasswordForEmail(String email) async {
    try {
      final response = await _supabase.functions.invoke(
        'request-password-reset',
        body: {
          'email': email.trim(),
          'redirectTo': SupabaseConstants.effectivePasswordResetRedirect,
        },
      );

      if (response.status != 200) {
        final msg = response.data is Map
            ? (response.data['error'] as String? ?? 'Could not send reset email.')
            : 'Could not send reset email.';
        throw Exception(msg);
      }
    } on FunctionException catch (e) {
      // Edge Function returned 4xx/5xx; show the message from the response body
      final msg = e.details is Map
          ? (e.details['error'] as String? ?? e.reasonPhrase ?? 'Could not send reset email.')
          : (e.reasonPhrase ?? 'Could not send reset email.');
      throw Exception(msg);
    } on AuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Could not send reset email. Please try again.');
    }
  }

  /// Call after user opens the app via the reset link. Establishes session so updateUser can be used.
  Future<void> recoverSessionFromUrl(Uri uri) async {
    await _supabase.auth.getSessionFromUrl(uri);
  }

  /// Updates the current user's password (e.g. after recovery). Call recoverSessionFromUrl first.
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  String _handleAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    // Supabase can return different phrases for duplicate email
    if (msg.contains('user already registered') ||
        msg.contains('already been registered') ||
        msg.contains('email already in use') ||
        msg.contains('already exists')) {
      return 'An account with this email already exists. Please log in or use Forgot password.';
    }
    return e.message;
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
