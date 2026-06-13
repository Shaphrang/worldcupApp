import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import 'profile_service.dart';

class AuthService {
  final _auth = SupabaseConfig.client.auth;
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;
  Future<AuthResponse> login(String email, String password) => _auth.signInWithPassword(email: email.trim(), password: password);
  Future<AuthResponse> register({required String fullName, required String mobile, required String email, required String password}) async {
    final res = await _auth.signUp(email: email.trim(), password: password, data: {'full_name': fullName.trim(), 'mobile_number': mobile.trim()});
    final user = res.user;
    if (user != null) await ProfileService().createProfile(user.id, fullName.trim(), mobile.trim(), email.trim());
    return res;
  }
  Future<void> logout() => _auth.signOut();
}
