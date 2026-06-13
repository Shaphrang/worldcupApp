//lib\services\auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';

class AuthService {
  final _auth = SupabaseConfig.client.auth;

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<AuthResponse> login(String email, String password) {
    return _auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<AuthResponse> register({
    required String fullName,
    required String mobile,
    required String email,
    required String password,
  }) {
    return _auth.signUp(
      email: email.trim(),
      password: password.trim(),
      data: {
        'full_name': fullName.trim(),
        'phone': mobile.trim(),
      },
    );
  }

  Future<void> logout() {
    return _auth.signOut();
  }
}