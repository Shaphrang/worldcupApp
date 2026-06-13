import '../core/config/supabase_config.dart';
import '../models/leaderboard_model.dart';
class LeaderboardService { final _db=SupabaseConfig.client; Future<List<LeaderboardModel>> leaderboard() async { final d=await _db.from('leaderboard_view').select().order('rank'); return (d as List).map((e)=>LeaderboardModel.fromMap(Map<String,dynamic>.from(e))).toList(); }}
