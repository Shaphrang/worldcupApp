//lib\models\prediction_model.dart
import '../core/utils/date_time_utils.dart';

class PredictionModel {
  final String id;
  final String matchTitle;
  final String teamAName;
  final String teamBName;
  final String status;

  final int teamAScore;
  final int teamBScore;

  final String? scorerName;
  final int? points;
  final DateTime? submittedAt;

  PredictionModel({
    required this.id,
    required this.matchTitle,
    required this.teamAName,
    required this.teamBName,
    required this.teamAScore,
    required this.teamBScore,
    required this.status,
    this.scorerName,
    this.points,
    this.submittedAt,
  });

  factory PredictionModel.fromMap(Map<String, dynamic> map) {
    return PredictionModel(
      id: '${map['id'] ?? ''}',
      matchTitle: '${map['match_title'] ?? 'Match'}',
      teamAName: '${map['team_a_name'] ?? 'Team A'}',
      teamBName: '${map['team_b_name'] ?? 'Team B'}',
      teamAScore: _readInt(map['team_a_score']) ?? 0,
      teamBScore: _readInt(map['team_b_score']) ?? 0,
      status: '${map['status'] ?? ''}',
      scorerName: map['scorer_name']?.toString(),
      points: _readInt(map['points']),
      submittedAt: DateTimeUtils.parse(
        map['submitted_at'] ?? map['created_at'],
      ),
    );
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    return int.tryParse(value.toString());
  }
}