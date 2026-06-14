class PopularPickModel {
  final int rankNo;
  final int teamAScore;
  final int teamBScore;
  final String scoreText;
  final int totalPicks;
  final int totalPredictions;
  final double pickPercent;

  const PopularPickModel({
    required this.rankNo,
    required this.teamAScore,
    required this.teamBScore,
    required this.scoreText,
    required this.totalPicks,
    required this.totalPredictions,
    required this.pickPercent,
  });

  factory PopularPickModel.fromMap(Map<String, dynamic> map) {
    return PopularPickModel(
      rankNo: _readInt(map['rank_no']),
      teamAScore: _readInt(map['predicted_team_a_score']),
      teamBScore: _readInt(map['predicted_team_b_score']),
      scoreText: '${map['score_text'] ?? ''}',
      totalPicks: _readInt(map['total_picks']),
      totalPredictions: _readInt(map['total_predictions']),
      pickPercent: _readDouble(map['pick_percent']),
    );
  }

  static int _readInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0;
  }
}