//lib\services\profile_service.dart
import '../core/config/supabase_config.dart';
import '../models/app_user_profile.dart';

class ProfileService {
  final _db = SupabaseConfig.client;
  Future<void> createProfile(String id, String fullName, String mobile, String email) => _db.from('profiles').upsert({'id':id,'full_name':fullName,'mobile_number':mobile,'email':email,'updated_at':DateTime.now().toUtc().toIso8601String()});
  Future<AppUserProfile?> currentProfile() async { final id = _db.auth.currentUser?.id; if (id == null) return null; final data = await _db.from('profiles').select().eq('id', id).maybeSingle(); return data == null ? null : AppUserProfile.fromMap(data); }
  Future<void> updateProfile(String fullName, String mobile) async { final id = _db.auth.currentUser!.id; await _db.from('profiles').update({'full_name':fullName,'mobile_number':mobile,'updated_at':DateTime.now().toUtc().toIso8601String()}).eq('id', id); }
}
