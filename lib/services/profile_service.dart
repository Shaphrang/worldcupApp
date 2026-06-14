//lib\services\profile_service.dart
import '../core/config/supabase_config.dart';
import '../models/app_user_profile.dart';

class ProfilePageStats {
  final int totalPredictions;
  final int pendingPredictions;
  final int exactScoreHits;
  final int scorerHits;
  final int totalPoints;
  final int timePoints;

  const ProfilePageStats({
    required this.totalPredictions,
    required this.pendingPredictions,
    required this.exactScoreHits,
    required this.scorerHits,
    required this.totalPoints,
    required this.timePoints,
  });

  factory ProfilePageStats.fromMap(Map<String, dynamic> map) {
    return ProfilePageStats(
      totalPredictions: _readInt(map['total_predictions']),
      pendingPredictions: _readInt(map['pending_predictions']),
      exactScoreHits: _readInt(map['exact_score_hits']),
      scorerHits: _readInt(map['scorer_hits']),
      totalPoints: _readInt(map['total_points']),
      timePoints: _readInt(map['time_points']),
    );
  }
}

class ProfilePredictionItem {
  final String id;
  final String matchId;
  final String matchTitle;
  final String? stage;

  final String teamAName;
  final String teamBName;
  final String? teamAFlagUrl;
  final String? teamBFlagUrl;

  final int predictedTeamAScore;
  final int predictedTeamBScore;

  final int? actualTeamAScore;
  final int? actualTeamBScore;

  final String? scorerName;

  final int exactScorePoints;
  final int playerPoints;
  final int timePoints;
  final int pointsTotal;

  final bool isEvaluated;
  final String predictionStatus;
  final String? matchStatus;

  final DateTime? matchStartAt;
  final DateTime? submittedAt;

  const ProfilePredictionItem({
    required this.id,
    required this.matchId,
    required this.matchTitle,
    required this.stage,
    required this.teamAName,
    required this.teamBName,
    required this.teamAFlagUrl,
    required this.teamBFlagUrl,
    required this.predictedTeamAScore,
    required this.predictedTeamBScore,
    required this.actualTeamAScore,
    required this.actualTeamBScore,
    required this.scorerName,
    required this.exactScorePoints,
    required this.playerPoints,
    required this.timePoints,
    required this.pointsTotal,
    required this.isEvaluated,
    required this.predictionStatus,
    required this.matchStatus,
    required this.matchStartAt,
    required this.submittedAt,
  });

  bool get hasActualScore =>
      actualTeamAScore != null && actualTeamBScore != null;

  bool get isPending => !isEvaluated;

  bool get isExactScoreCorrect => exactScorePoints > 0;

  factory ProfilePredictionItem.fromMap(Map<String, dynamic> map) {
    return ProfilePredictionItem(
      id: '${map['id'] ?? ''}',
      matchId: '${map['match_id'] ?? ''}',
      matchTitle: '${map['match_title'] ?? 'Match'}',
      stage: _readNullableString(map['stage']),
      teamAName: _teamName(map['team_a_short_name'], map['team_a_name'], 'Team A'),
      teamBName: _teamName(map['team_b_short_name'], map['team_b_name'], 'Team B'),
      teamAFlagUrl: _readNullableString(map['team_a_flag_url']),
      teamBFlagUrl: _readNullableString(map['team_b_flag_url']),
      predictedTeamAScore: _readInt(map['predicted_team_a_score']),
      predictedTeamBScore: _readInt(map['predicted_team_b_score']),
      actualTeamAScore: _readNullableInt(map['actual_team_a_score']),
      actualTeamBScore: _readNullableInt(map['actual_team_b_score']),
      scorerName: _readNullableString(map['scorer_name']),
      exactScorePoints: _readInt(map['exact_score_points']),
      playerPoints: _readInt(map['player_points']),
      timePoints: _readInt(map['time_points']),
      pointsTotal: _readInt(map['points_total']),
      isEvaluated: map['is_evaluated'] == true,
      predictionStatus: '${map['prediction_status'] ?? 'submitted'}',
      matchStatus: _readNullableString(map['match_status']),
      matchStartAt: _readDate(map['match_start_at']),
      submittedAt: _readDate(map['submitted_at']),
    );
  }
}

class ProfilePageData {
  final AppUserProfile? profile;
  final ProfilePageStats stats;
  final List<ProfilePredictionItem> predictions;

  const ProfilePageData({
    required this.profile,
    required this.stats,
    required this.predictions,
  });

  factory ProfilePageData.empty() {
    return const ProfilePageData(
      profile: null,
      stats: ProfilePageStats(
        totalPredictions: 0,
        pendingPredictions: 0,
        exactScoreHits: 0,
        scorerHits: 0,
        totalPoints: 0,
        timePoints: 0,
      ),
      predictions: [],
    );
  }
}

class ProfileService {
  final _db = SupabaseConfig.client;

  Future<void> createProfile(
    String id,
    String fullName,
    String mobile,
    String email,
  ) {
    return _db.from('profiles').upsert({
      'id': id,
      'full_name': fullName.trim(),
      'phone': mobile.trim(),
      'email': email.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<AppUserProfile?> currentProfile() async {
    final data = await profilePageData(limit: 1);
    return data.profile;
  }

  Future<ProfilePageData> profilePageData({
    int limit = 50,
    int offset = 0,
  }) async {
    final result = await _db.rpc(
      'get_my_profile_page',
      params: {
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    if (result == null) return ProfilePageData.empty();

    final map = Map<String, dynamic>.from(result as Map);

    final profileRaw = map['profile'];
    final statsRaw = map['stats'];
    final predictionsRaw = map['predictions'];

    final profile = profileRaw == null
        ? null
        : AppUserProfile.fromMap(Map<String, dynamic>.from(profileRaw as Map));

    final stats = statsRaw == null
        ? ProfilePageData.empty().stats
        : ProfilePageStats.fromMap(Map<String, dynamic>.from(statsRaw as Map));

    final predictions = predictionsRaw is List
        ? predictionsRaw
            .map(
              (item) => ProfilePredictionItem.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList()
        : <ProfilePredictionItem>[];

    return ProfilePageData(
      profile: profile,
      stats: stats,
      predictions: predictions,
    );
  }

  Future<void> updateProfile(String fullName, String mobile) async {
    final id = _db.auth.currentUser!.id;

    await _db.from('profiles').update({
      'full_name': fullName.trim(),
      'phone': mobile.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }
}

int _readInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

int? _readNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String? _readNullableString(dynamic value) {
  if (value == null) return null;

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;

  final parsed = DateTime.tryParse(value.toString());
  return parsed?.toLocal();
}

String _teamName(dynamic shortName, dynamic fullName, String fallback) {
  final short = shortName?.toString().trim() ?? '';
  if (short.isNotEmpty) return short;

  final full = fullName?.toString().trim() ?? '';
  if (full.isNotEmpty) return full;

  return fallback;
}