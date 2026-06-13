import '../core/config/supabase_config.dart';
import '../models/fixture_model.dart';
import '../models/player_model.dart';

class FixtureService { final _db=SupabaseConfig.client; Future<List<FixtureModel>> fixtures() async { final d=await _db.from('fixtures_view').select().order('match_start_at'); return (d as List).map((e)=>FixtureModel.fromMap(Map<String,dynamic>.from(e))).toList(); } Future<FixtureModel?> fixture(String id) async { final d=await _db.from('fixtures_view').select().eq('id', id).maybeSingle(); return d==null?null:FixtureModel.fromMap(d); } Future<List<PlayerModel>> players(String matchId) async { final d=await _db.from('match_players_view').select().eq('match_id', matchId).order('player_name'); return (d as List).map((e)=>PlayerModel.fromMap(Map<String,dynamic>.from(e))).toList(); }}
