import '../core/utils/date_time_utils.dart';

class FixtureModel {
  final String id, matchTitle, stage, teamAName, teamBName, teamAShort, teamBShort, status;
  final DateTime? matchStartAt, predictionLockAt;
  final int? teamAScore, teamBScore;
  FixtureModel({required this.id, required this.matchTitle, required this.stage, required this.teamAName, required this.teamBName, required this.teamAShort, required this.teamBShort, required this.status, this.matchStartAt, this.predictionLockAt, this.teamAScore, this.teamBScore});
  factory FixtureModel.fromMap(Map<String, dynamic> m) => FixtureModel(
    id: (m['id'] ?? m['match_id'] ?? '').toString(), matchTitle: (m['match_title'] ?? 'Match').toString(), stage: (m['stage'] ?? '').toString(),
    teamAName: (m['team_a_name'] ?? m['team_a'] ?? 'Team A').toString(), teamBName: (m['team_b_name'] ?? m['team_b'] ?? 'Team B').toString(),
    teamAShort: (m['team_a_short_name'] ?? m['team_a_short'] ?? m['team_a_name'] ?? 'A').toString(), teamBShort: (m['team_b_short_name'] ?? m['team_b_short'] ?? m['team_b_name'] ?? 'B').toString(),
    status: (m['status'] ?? 'scheduled').toString(), matchStartAt: DateTimeUtils.parse(m['match_start_at']), predictionLockAt: DateTimeUtils.parse(m['prediction_lock_at']),
    teamAScore: int.tryParse('${m['team_a_score'] ?? ''}'), teamBScore: int.tryParse('${m['team_b_score'] ?? ''}'));
  bool get isLocked => predictionLockAt != null && DateTime.now().isAfter(predictionLockAt!);
  bool get isCompleted => status.toLowerCase().contains('complete') || (teamAScore != null && teamBScore != null);
  String get predictionStatus => isCompleted ? 'Completed' : isLocked ? 'Locked' : 'Prediction Open';
}
