//lib/models/leaderboard_model.dart

class LeaderboardModel {
  final int rank;
  final String userId;
  final String name;
  final String? avatarUrl;

  final int predictionCount;
  final int totalPoints;

  final int exactScorePoints;
  final int totalGoalsPoints;
  final int scorerPoints;

  final int correctScoreCount;
  final int correctResultCount;
  final int playerHits;

  const LeaderboardModel({
    required this.rank,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.predictionCount,
    required this.totalPoints,
    required this.exactScorePoints,
    required this.totalGoalsPoints,
    required this.scorerPoints,
    required this.correctScoreCount,
    required this.correctResultCount,
    required this.playerHits,
  });

  factory LeaderboardModel.fromMap(Map<String, dynamic> map) {
    return LeaderboardModel(
      rank: _toInt(map['rank_no'] ?? map['rank']),

      userId: _text(map['user_id']),
      name: _text(map['full_name'] ?? map['name']),
      avatarUrl: _nullableText(map['avatar_url']),

      predictionCount: _toInt(
        map['total_predictions'] ??
            map['prediction_count'] ??
            map['predictions'],
      ),

      totalPoints: _toInt(
        map['total_points'] ??
            map['points_total'] ??
            map['points'],
      ),

      exactScorePoints: _toInt(
        map['exact_score_points'],
      ),

      totalGoalsPoints: _toInt(
        map['total_goals_points'],
      ),

      scorerPoints: _toInt(
        map['player_points'] ??
            map['scorer_points'],
      ),

      correctScoreCount: _toInt(
        map['exact_score_hits'] ??
            map['correct_score_count'] ??
            map['scores'],
      ),

      correctResultCount: _toInt(
        map['total_goals_hits'] ??
            map['correct_result_count'] ??
            map['results'],
      ),

      playerHits: _toInt(
        map['player_hits'],
      ),
    );
  }

  static String _text(dynamic value) {
    if (value == null) return '';
    return '$value'.trim();
  }

  static String? _nullableText(dynamic value) {
    final text = _text(value);
    return text.isEmpty ? null : text;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}