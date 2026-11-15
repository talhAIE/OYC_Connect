import 'package:supabase_flutter/supabase_flutter.dart';
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
            ? (response.data['error'] as String? ??
                  'Could not send reset email.')
            : 'Could not send reset email.';
        throw Exception(msg);
      }
    } on FunctionException catch (e) {
      // Edge Function returned 4xx/5xx; show the message from the response body
      final msg = e.details is Map
          ? (e.details['error'] as String? ??
                e.reasonPhrase ??
                'Could not send reset email.')
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

  /// Recovery grants a temporary session, not a normal application login.
  Future<void> signOutRecoverySession() async {
    try {
      await _supabase.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // GoTrue clears local state before requesting server revocation. An
      // offline revocation failure must not trap a locally signed-out user.
      if (_supabase.auth.currentSession != null) rethrow;
    }
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
    // Sign out from Supabase
    await _supabase.auth.signOut();
  }

  // Get Current User
  User? get currentUser => _supabase.auth.currentUser;

  // Listen to Auth Changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
