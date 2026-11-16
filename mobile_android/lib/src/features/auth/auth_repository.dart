import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_config.dart';

class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  Stream<AuthState> get changes => _client.auth.onAuthStateChange;
  Session? get currentSession => _client.auth.currentSession;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: ValoraAuthConfig.callbackUrl,
    );
  }

  Future<void> requestPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: ValoraAuthConfig.callbackUrl,
    );
  }

  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signOut() => _client.auth.signOut();
}
