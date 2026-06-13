//lib/models/participant_model.dart
class ParticipantModel {
  final String id;
  final String name;
  final String? avatarUrl;

  final int? teamAScore;
  final int? teamBScore;

  final String? scorerName;
  final int? pointsTotal;
  final DateTime? submittedAt;

  const ParticipantModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.teamAScore,
    this.teamBScore,
    this.scorerName,
    this.pointsTotal,
    this.submittedAt,
  });

  factory ParticipantModel.fromMap(Map<String, dynamic> map) {
    return ParticipantModel(
      id: _text(
        map['prediction_id'] ??
            map['id'] ??
            map['user_id'],
      ),
      name: _text(
        map['full_name'] ??
            map['name'] ??
            'Participant',
      ),
      avatarUrl: _nullableText(
        map['avatar_url'],
      ),
      teamAScore: _nullableInt(
        map['predicted_team_a_score'] ??
            map['team_a_score'],
      ),
      teamBScore: _nullableInt(
        map['predicted_team_b_score'] ??
            map['team_b_score'],
      ),
      scorerName: _nullableText(
        map['predicted_player_name'] ??
            map['scorer_name'] ??
            map['player_name'],
      ),
      pointsTotal: _nullableInt(
        map['points_total'],
      ),
      submittedAt: _toDateTime(
        map['created_at'] ??
            map['submitted_at'],
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

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = '$value'.trim();
    if (text.isEmpty) return null;

    return int.tryParse(text);
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;

    final text = '$value'.trim();
    if (text.isEmpty) return null;

    return DateTime.tryParse(text)?.toLocal();
  }
}