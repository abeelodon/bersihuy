import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton Supabase client helper.
/// Initialized once in main.dart via `await Supabase.initialize(...)`.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  /// Returns the currently authenticated user, or null if not logged in.
  static User? get currentUser => client.auth.currentUser;

  /// Returns true if there is an authenticated session.
  static bool get isAuthenticated => currentUser != null;

  /// Authenticates user with email & password.
  /// Returns session on success, throws on failure.
  static Future<Session> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.session!;
  }

  /// Signs out the current user and clears local session.
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Listens to auth state changes (login / logout / token refresh).
  /// Returns a stream you can subscribe to.
  static Stream<AuthState> get onAuthStateChange => client.auth.onAuthStateChange;
}