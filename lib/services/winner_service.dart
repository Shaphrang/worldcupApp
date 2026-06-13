import '../core/config/supabase_config.dart';
import '../models/winner_model.dart';
class WinnerService { final _db=SupabaseConfig.client; Future<List<WinnerModel>> winners() async { final d=await _db.from('winners').select().order('published_at', ascending:false); return (d as List).map((e)=>WinnerModel.fromMap(Map<String,dynamic>.from(e))).toList(); }}
