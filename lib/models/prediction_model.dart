import '../core/utils/date_time_utils.dart';

class PredictionMatchFilter {
  final String id;
  final String matchTitle;
  final String stage;
  final String status;

  final String teamAName;
  final String teamBName;
  final String? teamAShortName;
  final String? teamBShortName;
  final String? teamAFlagUrl;
  final String? teamBFlagUrl;

  final int? teamAScore;
  final int? teamBScore;

  final DateTime? matchStartAt;

  const PredictionMatchFilter({
    required this.id,
    required this.matchTitle,
    required this.stage,
    required this.status,
    required this.teamAName,
    required this.teamBName,
    this.teamAShortName,
    this.teamBShortName,
    this.teamAFlagUrl,
    this.teamBFlagUrl,
    this.teamAScore,
    this.teamBScore,
    this.matchStartAt,
  });

  factory PredictionMatchFilter.fromMap(Map<String, dynamic> map) {
    return PredictionMatchFilter(
      id: '${map['id'] ?? ''}',
      matchTitle: '${map['match_title'] ?? 'Match'}',
      stage: '${map['stage'] ?? ''}',
      status: '${map['status'] ?? ''}',
      teamAName: '${map['team_a_name'] ?? 'Team A'}',
      teamBName: '${map['team_b_name'] ?? 'Team B'}',
      teamAShortName: _nullableText(
        map['team_a_short_name'] ?? map['team_a_short'],
      ),
      teamBShortName: _nullableText(
        map['team_b_short_name'] ?? map['team_b_short'],
      ),
      teamAFlagUrl: _nullableText(map['team_a_flag_url']),
      teamBFlagUrl: _nullableText(map['team_b_flag_url']),
      teamAScore: _readInt(map['team_a_score']),
      teamBScore: _readInt(map['team_b_score']),
      matchStartAt: DateTimeUtils.parse(map['match_start_at']),
    );
  }

  String get scoreText {
    if (teamAScore == null || teamBScore == null) return '—';
    return '$teamAScore - $teamBScore';
  }

  String get label {
    final stageText = stage.trim().isEmpty ? '' : ' · $stage';
    return '$matchTitle$stageText';
  }
}

class PredictionModel {
  final String id;
  final String matchId;
  final String userId;

  final int rankNo;
  final int totalCount;

  final String matchTitle;
  final String stage;

  final String teamAName;
  final String teamBName;
  final String? teamAShortName;
  final String? teamBShortName;
  final String? teamAFlagUrl;
  final String? teamBFlagUrl;

  final String status;

  final int teamAScore;
  final int teamBScore;

  final String? scorerName;

  final int exactScorePoints;
  final int totalGoalsPoints;
  final int playerPoints;
  final int timePoints;
  final int points;

  final bool isEvaluated;

  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? userAvatarUrl;

  final DateTime? submittedAt;

  PredictionModel({
    required this.id,
    required this.matchId,
    required this.userId,
    required this.rankNo,
    required this.totalCount,
    required this.matchTitle,
    required this.stage,
    required this.teamAName,
    required this.teamBName,
    required this.teamAScore,
    required this.teamBScore,
    required this.status,
    required this.isEvaluated,
    required this.exactScorePoints,
    required this.totalGoalsPoints,
    required this.playerPoints,
    required this.timePoints,
    required this.points,
    this.teamAShortName,
    this.teamBShortName,
    this.teamAFlagUrl,
    this.teamBFlagUrl,
    this.scorerName,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.userAvatarUrl,
    this.submittedAt,
  });

  factory PredictionModel.fromMap(Map<String, dynamic> map) {
    return PredictionModel(
      id: '${map['id'] ?? map['prediction_id'] ?? ''}',
      matchId: '${map['match_id'] ?? ''}',
      userId: '${map['user_id'] ?? ''}',
      rankNo: _readInt(map['rank_no']) ?? 0,
      totalCount: _readInt(map['total_count']) ?? 0,
      matchTitle: '${map['match_title'] ?? 'Match'}',
      stage: '${map['stage'] ?? ''}',
      teamAName: '${map['team_a_name'] ?? 'Team A'}',
      teamBName: '${map['team_b_name'] ?? 'Team B'}',
      teamAShortName: _nullableText(
        map['team_a_short_name'] ?? map['team_a_short'],
      ),
      teamBShortName: _nullableText(
        map['team_b_short_name'] ?? map['team_b_short'],
      ),
      teamAFlagUrl: _nullableText(map['team_a_flag_url']),
      teamBFlagUrl: _nullableText(map['team_b_flag_url']),
      teamAScore: _readInt(
            map['predicted_team_a_score'] ??
                map['prediction_team_a_score'] ??
                map['team_a_prediction_score'] ??
                map['team_a_score'],
          ) ??
          0,
      teamBScore: _readInt(
            map['predicted_team_b_score'] ??
                map['prediction_team_b_score'] ??
                map['team_b_prediction_score'] ??
                map['team_b_score'],
          ) ??
          0,
      status: '${map['status'] ?? ''}',
      isEvaluated: _readBool(map['is_evaluated']),
      scorerName: _nullableText(
        map['scorer_name'] ??
            map['predicted_player_name'] ??
            map['player_name'] ??
            map['predicted_scorer_name'],
      ),
      exactScorePoints: _readInt(map['exact_score_points']) ?? 0,
      totalGoalsPoints: 0,
      playerPoints: _readInt(map['player_points']) ?? 0,
      timePoints: _readInt(map['time_points']) ?? 0,
      points: _readInt(map['points'] ?? map['points_total']) ?? 0,
      userName: _nullableText(
        map['full_name'] ?? map['user_name'] ?? map['name'],
      ),
      userEmail: _nullableText(map['email'] ?? map['user_email']),
      userPhone: _nullableText(map['phone'] ?? map['mobile']),
      userAvatarUrl: _nullableText(map['avatar_url']),
      submittedAt: DateTimeUtils.parse(
        map['submitted_at'] ?? map['created_at'],
      ),
    );
  }

  String get displayUserName {
    final name = userName?.trim();
    if (name != null && name.isNotEmpty) return name;

    final email = userEmail?.trim();
    if (email != null && email.isNotEmpty) return email;

    return 'Participant';
  }

  String get initials {
    final parts = displayUserName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'P';

    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  String get scoreText => '$teamAScore - $teamBScore';
}

int? _readInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _readBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;

  final text = value.toString().toLowerCase().trim();
  return text == 'true' || text == '1' || text == 'yes';
}

String? _nullableText(dynamic value) {
  if (value == null) return null;

  final text = '$value'.trim();
  return text.isEmpty ? null : text;
}