class FixtureModel {
  final String id;
  final String matchTitle;
  final String stage;

  final String teamAId;
  final String teamAName;
  final String teamAShort;
  final String? teamAFlagUrl;

  final String teamBId;
  final String teamBName;
  final String teamBShort;
  final String? teamBFlagUrl;

  final DateTime matchStartAt;
  final DateTime predictionLockAt;

  final bool isLocked;
  final int? secondsToLock;

  final int? teamAScore;
  final int? teamBScore;

  final String status;

  const FixtureModel({
    required this.id,
    required this.matchTitle,
    required this.stage,
    required this.teamAId,
    required this.teamAName,
    required this.teamAShort,
    required this.teamAFlagUrl,
    required this.teamBId,
    required this.teamBName,
    required this.teamBShort,
    required this.teamBFlagUrl,
    required this.matchStartAt,
    required this.predictionLockAt,
    required this.isLocked,
    required this.secondsToLock,
    required this.teamAScore,
    required this.teamBScore,
    required this.status,
  });

  bool get isCompleted {
    return status.toLowerCase() == 'completed' ||
        status.toLowerCase() == 'finished';
  }

  bool get hasScore {
    return teamAScore != null && teamBScore != null;
  }

  String get predictionStatus {
    if (isCompleted) {
      return 'COMPLETED';
    }

    if (isLocked) {
      return 'LOCKED';
    }

    return 'OPEN';
  }

  factory FixtureModel.fromMap(Map<String, dynamic> map) {
    return FixtureModel(
      id: '${map['id']}',
      matchTitle: '${map['match_title'] ?? ''}',
      stage: '${map['stage'] ?? ''}',
      teamAId: '${map['team_a_id'] ?? ''}',
      teamAName: '${map['team_a_name'] ?? ''}',
      teamAShort:
          '${map['team_a_short_name'] ?? map['team_a_short'] ?? ''}',
      teamAFlagUrl: map['team_a_flag_url']?.toString(),
      teamBId: '${map['team_b_id'] ?? ''}',
      teamBName: '${map['team_b_name'] ?? ''}',
      teamBShort:
          '${map['team_b_short_name'] ?? map['team_b_short'] ?? ''}',
      teamBFlagUrl: map['team_b_flag_url']?.toString(),
      matchStartAt: _readDateTime(map['match_start_at']),
      predictionLockAt: _readDateTime(map['prediction_lock_at']),
      isLocked: map['is_prediction_locked'] == true ||
          map['is_locked'] == true,
      secondsToLock: _readInt(map['seconds_to_lock']),
      teamAScore: _readInt(map['team_a_score']),
      teamBScore: _readInt(map['team_b_score']),
      status: '${map['status'] ?? 'upcoming'}',
    );
  }

  static DateTime _readDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    return DateTime.parse(value.toString()).toLocal();
  }

  static int? _readInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }
}