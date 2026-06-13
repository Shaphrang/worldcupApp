import 'dart:developer' as developer;

import '../core/config/supabase_config.dart';

class WinnerService {
  final _db = SupabaseConfig.client;

  Future<LatestMatchWinnersResult> latestMatchWinners() async {
    try {
      final data = await _db.rpc('get_latest_match_winners');

      final rows = (data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (rows.isEmpty) {
        return const LatestMatchWinnersResult(
          match: null,
          winners: [],
          participants: [],
          highestPoints: 0,
          isEvaluated: false,
        );
      }

      final latestMatch = WinnerMatchInfo.fromMap(rows.first);

      final predictionRows = rows.where((row) {
        return row['has_prediction'] == true && row['prediction_id'] != null;
      }).toList();

      if (predictionRows.isEmpty) {
        return LatestMatchWinnersResult(
          match: latestMatch,
          winners: const [],
          participants: const [],
          highestPoints: 0,
          isEvaluated: false,
        );
      }

      final participants = predictionRows.map((row) {
        return LatestMatchWinnerItem(
          predictionId: _text(row['prediction_id']),
          userId: _text(row['user_id']),
          fullName: _nullableText(row['full_name']) ?? 'Participant',
          avatarUrl: _nullableText(row['avatar_url']),
          predictedTeamAScore: _toInt(row['predicted_team_a_score']),
          predictedTeamBScore: _toInt(row['predicted_team_b_score']),
          scorerId: _nullableText(row['predicted_player_id']),
          scorerName: _nullableText(row['scorer_name']),
          scorerTeamName: _nullableText(row['scorer_team_name']),
          exactScorePoints: _toInt(row['exact_score_points']),
          totalGoalsPoints: _toInt(row['total_goals_points']),
          playerPoints: _toInt(row['player_points']),
          totalPoints: _toInt(row['points_total']),
          isEvaluated: row['is_evaluated'] == true,
          createdAt: _toDateTime(row['prediction_created_at']),
          rankNo: 0,
          isWinner: false,
        );
      }).toList();

      participants.sort((a, b) {
        final pointCompare = b.totalPoints.compareTo(a.totalPoints);

        if (pointCompare != 0) {
          return pointCompare;
        }

        return a.fullName.toLowerCase().compareTo(
              b.fullName.toLowerCase(),
            );
      });

      final highestPoints =
          participants.isEmpty ? 0 : participants.first.totalPoints;

      final isEvaluated = participants.any((item) => item.isEvaluated) ||
          participants.any((item) => item.totalPoints > 0);

      final rankedParticipants = <LatestMatchWinnerItem>[];

      int currentRank = 0;
      int? previousPoints;

      for (int i = 0; i < participants.length; i++) {
        final item = participants[i];

        if (previousPoints == null || item.totalPoints != previousPoints) {
          currentRank = i + 1;
          previousPoints = item.totalPoints;
        }

        rankedParticipants.add(
          item.copyWith(
            rankNo: currentRank,
            isWinner: isEvaluated && item.totalPoints == highestPoints,
          ),
        );
      }

      final winners =
          rankedParticipants.where((item) => item.isWinner).toList();

      developer.log(
        'Latest winners RPC loaded. Match: ${latestMatch.teamAName} vs ${latestMatch.teamBName}, participants: ${rankedParticipants.length}, winners: ${winners.length}',
      );

      return LatestMatchWinnersResult(
        match: latestMatch,
        winners: winners,
        participants: rankedParticipants,
        highestPoints: highestPoints,
        isEvaluated: isEvaluated,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load latest match winners',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  String _text(dynamic value) {
    if (value == null) return '';
    return '$value'.trim();
  }

  String? _nullableText(dynamic value) {
    final text = _text(value);
    return text.isEmpty ? null : text;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    return DateTime.tryParse('$value')?.toLocal();
  }
}

class LatestMatchWinnersResult {
  final WinnerMatchInfo? match;
  final List<LatestMatchWinnerItem> winners;
  final List<LatestMatchWinnerItem> participants;
  final int highestPoints;
  final bool isEvaluated;

  const LatestMatchWinnersResult({
    required this.match,
    required this.winners,
    required this.participants,
    required this.highestPoints,
    required this.isEvaluated,
  });
}

class WinnerMatchInfo {
  final String id;
  final String matchTitle;
  final String stage;

  final String teamAName;
  final String teamAShort;
  final String? teamAFlagUrl;

  final String teamBName;
  final String teamBShort;
  final String? teamBFlagUrl;

  final int teamAScore;
  final int teamBScore;

  final DateTime? matchStartAt;
  final String status;

  const WinnerMatchInfo({
    required this.id,
    required this.matchTitle,
    required this.stage,
    required this.teamAName,
    required this.teamAShort,
    required this.teamAFlagUrl,
    required this.teamBName,
    required this.teamBShort,
    required this.teamBFlagUrl,
    required this.teamAScore,
    required this.teamBScore,
    required this.matchStartAt,
    required this.status,
  });

  factory WinnerMatchInfo.fromMap(Map<String, dynamic> row) {
    return WinnerMatchInfo(
      id: _readText(row['match_id'] ?? row['id']),
      matchTitle: _readText(row['match_title']),
      stage: _readText(row['stage']),
      teamAName: _readText(row['team_a_name']),
      teamAShort: _readText(row['team_a_short_name']),
      teamAFlagUrl: _readNullableText(row['team_a_flag_url']),
      teamBName: _readText(row['team_b_name']),
      teamBShort: _readText(row['team_b_short_name']),
      teamBFlagUrl: _readNullableText(row['team_b_flag_url']),
      teamAScore: _readInt(row['team_a_score']),
      teamBScore: _readInt(row['team_b_score']),
      matchStartAt: _readDate(row['match_start_at']),
      status: _readText(row['match_status'] ?? row['status']),
    );
  }
}

class LatestMatchWinnerItem {
  final String predictionId;
  final String userId;
  final String fullName;
  final String? avatarUrl;

  final int predictedTeamAScore;
  final int predictedTeamBScore;

  final String? scorerId;
  final String? scorerName;
  final String? scorerTeamName;

  final int exactScorePoints;
  final int totalGoalsPoints;
  final int playerPoints;
  final int totalPoints;

  final bool isEvaluated;
  final DateTime? createdAt;

  final int rankNo;
  final bool isWinner;

  const LatestMatchWinnerItem({
    required this.predictionId,
    required this.userId,
    required this.fullName,
    required this.avatarUrl,
    required this.predictedTeamAScore,
    required this.predictedTeamBScore,
    required this.scorerId,
    required this.scorerName,
    required this.scorerTeamName,
    required this.exactScorePoints,
    required this.totalGoalsPoints,
    required this.playerPoints,
    required this.totalPoints,
    required this.isEvaluated,
    required this.createdAt,
    required this.rankNo,
    required this.isWinner,
  });

  LatestMatchWinnerItem copyWith({
    int? rankNo,
    bool? isWinner,
  }) {
    return LatestMatchWinnerItem(
      predictionId: predictionId,
      userId: userId,
      fullName: fullName,
      avatarUrl: avatarUrl,
      predictedTeamAScore: predictedTeamAScore,
      predictedTeamBScore: predictedTeamBScore,
      scorerId: scorerId,
      scorerName: scorerName,
      scorerTeamName: scorerTeamName,
      exactScorePoints: exactScorePoints,
      totalGoalsPoints: totalGoalsPoints,
      playerPoints: playerPoints,
      totalPoints: totalPoints,
      isEvaluated: isEvaluated,
      createdAt: createdAt,
      rankNo: rankNo ?? this.rankNo,
      isWinner: isWinner ?? this.isWinner,
    );
  }
}

String _readText(dynamic value) {
  if (value == null) return '';
  return '$value'.trim();
}

String? _readNullableText(dynamic value) {
  final text = _readText(value);
  return text.isEmpty ? null : text;
}

int _readInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  return DateTime.tryParse('$value')?.toLocal();
}