import '../core/config/supabase_config.dart';
import '../models/participant_model.dart';
import '../models/prediction_model.dart';

class PredictionService { final _db=SupabaseConfig.client; Future<void> submit({required String matchId,required int teamAScore,required int teamBScore,String? scorerId}) async { await _db.rpc('submit_prediction', params:{'p_match_id':matchId,'p_team_a_score':teamAScore,'p_team_b_score':teamBScore,'p_scorer_id':scorerId}); } Future<List<ParticipantModel>> participants(String matchId) async { final d=await _db.rpc('get_match_participants', params:{'p_match_id':matchId}); return (d as List).map((e)=>ParticipantModel.fromMap(Map<String,dynamic>.from(e))).toList(); } Future<List<PredictionModel>> myPredictions() async { final uid=_db.auth.currentUser?.id; if(uid==null)return []; // TODO: Align this query with the production predictions view if column names differ.
 final d=await _db.from('predictions_view').select().eq('user_id', uid).order('created_at', ascending:false); return (d as List).map((e)=>PredictionModel.fromMap(Map<String,dynamic>.from(e))).toList(); }}
