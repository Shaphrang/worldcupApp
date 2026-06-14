import 'dart:developer' as developer;

import '../core/config/supabase_config.dart';
import '../features/home/widgets/home_my_predictions_section.dart';
import '../models/fixture_model.dart';
import '../models/participant_model.dart';
import '../models/prediction_model.dart';
import '../models/match_prize_pool_model.dart';

class UserMatchPrediction {
  final String matchId;
  final int teamAScore;
  final int teamBScore;
  final String? scorerId;

  const UserMatchPrediction({
    required this.matchId,
    required this.teamAScore,
    required this.teamBScore,
    required this.scorerId,
  });
}

class PredictionService {
  final _db = SupabaseConfig.client;

  Future<void> submit({
    required String matchId,
    required int teamAScore,
    required int teamBScore,
    String? scorerId,
  }) async {
    try {
      await _db.rpc(
        'submit_prediction',
        params: {
          'p_match_id': matchId,
          'p_predicted_team_a_score': teamAScore,
          'p_predicted_team_b_score': teamBScore,
          'p_predicted_player_id': scorerId,
        },
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to submit prediction',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<ParticipantModel>> participants(String matchId) async {
    final data = await _db.rpc(
      'get_match_participants',
      params: {
        'p_match_id': matchId,
      },
    );

    return (data as List)
        .map(
          (item) => ParticipantModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<PredictionModel>> myPredictions() async {
    final userId = _db.auth.currentUser?.id;

    if (userId == null) {
      return [];
    }

    final data = await _db
        .from('predictions_view')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map(
          (item) => PredictionModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<UserMatchPrediction?> myPredictionForMatch(String matchId) async {
    final userId = _db.auth.currentUser?.id;

    if (userId == null) {
      return null;
    }

    final data = await _db
        .from('predictions_view')
        .select()
        .eq('user_id', userId)
        .eq('match_id', matchId)
        .limit(1);

    final rows = data as List;

    if (rows.isEmpty) {
      return null;
    }

    final row = Map<String, dynamic>.from(rows.first as Map);

    return UserMatchPrediction(
      matchId: matchId,
      teamAScore: _toInt(
        row['predicted_team_a_score'] ??
            row['prediction_team_a_score'] ??
            row['team_a_prediction_score'] ??
            row['team_a_score'],
      ),
      teamBScore: _toInt(
        row['predicted_team_b_score'] ??
            row['prediction_team_b_score'] ??
            row['team_b_prediction_score'] ??
            row['team_b_score'],
      ),
      scorerId: _nullableText(
        row['predicted_player_id'] ??
            row['scorer_id'] ??
            row['player_id'] ??
            row['predicted_scorer_id'],
      ),
    );
  }

  Future<List<HomePredictionPreviewItem>> homeUpcomingPredictionsFromFixtures(
    List<FixtureModel> upcomingFixtures, {
    int limit = 5,
  }) async {
    final userId = _db.auth.currentUser?.id;

    if (userId == null) {
      return [];
    }

    final data = await _db
        .from('predictions_view')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final rows = (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final fixtureById = {
      for (final fixture in upcomingFixtures) fixture.id: fixture,
    };

    final matchIds = rows
        .map(
          (row) => _text(
            row['match_id'] ?? row['fixture_id'] ?? row['matchId'],
          ),
        )
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final scorerIds = rows
        .map(
          (row) => _nullableText(
            row['predicted_player_id'] ??
                row['scorer_id'] ??
                row['player_id'] ??
                row['predicted_scorer_id'],
          ),
        )
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final scorerLookup = <String, _ScorerInfo>{};

    if (matchIds.isNotEmpty && scorerIds.isNotEmpty) {
      try {
        final scorerRows = await _db
            .from('match_players_view')
            .select('match_id, player_id, player_name, team_name')
            .inFilter('match_id', matchIds)
            .inFilter('player_id', scorerIds);

        for (final item in scorerRows as List) {
          final row = Map<String, dynamic>.from(item as Map);

          final matchId = _text(row['match_id']);
          final playerId = _text(row['player_id']);

          if (matchId.isEmpty || playerId.isEmpty) continue;

          scorerLookup['$matchId-$playerId'] = _ScorerInfo(
            name: _nullableText(row['player_name']),
            teamName: _nullableText(row['team_name']),
          );
        }
      } catch (error, stackTrace) {
        developer.log(
          'Could not load scorer names for home predictions',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    final now = DateTime.now();
    final items = <HomePredictionPreviewItem>[];

    for (final row in rows) {
      final matchId = _text(
        row['match_id'] ?? row['fixture_id'] ?? row['matchId'],
      );

      if (matchId.isEmpty) {
        continue;
      }

      final status = _text(
        row['match_status'] ?? row['status'] ?? row['fixture_status'],
      ).toLowerCase();

      final isCompleted = status == 'completed' ||
          status == 'finished' ||
          status == 'full_time' ||
          status == 'full time' ||
          status == 'ft' ||
          status == 'finalized';

      if (isCompleted) {
        continue;
      }

      final fixture = fixtureById[matchId];

      final matchStartAt = _toDateTime(
            row['match_start_at'] ??
                row['start_at'] ??
                row['match_date'] ??
                row['fixture_start_at'],
          ) ??
          fixture?.matchStartAt;

      final predictionLockAt = _toDateTime(
            row['prediction_lock_at'] ??
                row['lock_at'] ??
                row['fixture_lock_at'],
          ) ??
          fixture?.predictionLockAt;

      final scorerId = _nullableText(
        row['predicted_player_id'] ??
            row['scorer_id'] ??
            row['player_id'] ??
            row['predicted_scorer_id'],
      );

      final scorerFromLookup =
          scorerId == null ? null : scorerLookup['$matchId-$scorerId'];

      final scorerName = _nullableText(
            row['scorer_name'] ??
                row['predicted_player_name'] ??
                row['player_name'] ??
                row['predicted_scorer_name'],
          ) ??
          scorerFromLookup?.name;

      final scorerTeamName = _nullableText(
            row['scorer_team_name'] ??
                row['player_team_name'] ??
                row['team_name'],
          ) ??
          scorerFromLookup?.teamName;

      items.add(
        HomePredictionPreviewItem(
          matchId: matchId,
          teamAName: _text(
            row['team_a_name'] ??
                row['teamAName'] ??
                row['home_team_name'] ??
                fixture?.teamAName,
          ),
          teamAShort: _text(
            row['team_a_short'] ??
                row['team_a_short_name'] ??
                row['team_a_code'] ??
                row['teamAShort'] ??
                fixture?.teamAShort,
          ),
          teamAFlagUrl: _nullableText(
            row['team_a_flag_url'] ??
                row['team_a_flag'] ??
                row['teamAFlagUrl'] ??
                fixture?.teamAFlagUrl,
          ),
          teamBName: _text(
            row['team_b_name'] ??
                row['teamBName'] ??
                row['away_team_name'] ??
                fixture?.teamBName,
          ),
          teamBShort: _text(
            row['team_b_short'] ??
                row['team_b_short_name'] ??
                row['team_b_code'] ??
                row['teamBShort'] ??
                fixture?.teamBShort,
          ),
          teamBFlagUrl: _nullableText(
            row['team_b_flag_url'] ??
                row['team_b_flag'] ??
                row['teamBFlagUrl'] ??
                fixture?.teamBFlagUrl,
          ),
          teamAScore: _toInt(
            row['predicted_team_a_score'] ??
                row['prediction_team_a_score'] ??
                row['team_a_prediction_score'] ??
                row['team_a_score'],
          ),
          teamBScore: _toInt(
            row['predicted_team_b_score'] ??
                row['prediction_team_b_score'] ??
                row['team_b_prediction_score'] ??
                row['team_b_score'],
          ),
          matchStartAt: matchStartAt,
          predictionLockAt: predictionLockAt,
          isLocked: predictionLockAt != null && predictionLockAt.isBefore(now),
          scorerName: scorerName,
          scorerTeamName: scorerTeamName,
        ),
      );
    }

    items.sort((a, b) {
      final aDate = a.matchStartAt;
      final bDate = b.matchStartAt;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return aDate.compareTo(bDate);
    });

    return items.take(limit).toList();
  }

  Future<FixtureModel?> nextUpcomingPredictionMatch() async {
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();

      final data = await _db
          .from('fixtures_view')
          .select(
            'id, match_title, stage, match_start_at, prediction_lock_at, status, team_a_score, team_b_score, team_a_name, team_b_name, team_a_short_name, team_b_short_name, team_a_flag_url, team_b_flag_url',
          )
          .gt('match_start_at', nowUtc)
          .order('match_start_at', ascending: true)
          .limit(30);

      final rows = (data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      for (final row in rows) {
        final status = _text(row['status']).toLowerCase();

        final isCompleted = status == 'completed' ||
            status == 'finished' ||
            status == 'full_time' ||
            status == 'full time' ||
            status == 'ft' ||
            status == 'finalized' ||
            status == 'cancelled' ||
            status == 'canceled';

        if (isCompleted) continue;

        final fixture = FixtureModel.fromMap(row);

        if (fixture.id.trim().isNotEmpty) {
          return fixture;
        }
      }

      return null;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load next upcoming prediction match',
        error: error,
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  Future<List<PredictionMatchFilter>> completedPredictionMatches() async {
    final data = await _db
        .from('fixtures_view')
        .select(
          'id, match_title, stage, match_start_at, status, team_a_score, team_b_score, team_a_name, team_b_name, team_a_short_name, team_b_short_name, team_a_flag_url, team_b_flag_url',
        )
        .inFilter(
          'status',
          [
            'completed',
            'COMPLETED',
            'finalized',
            'FINALIZED',
            'finished',
            'FINISHED',
          ],
        )
        .order('match_start_at', ascending: false);

    return (data as List)
        .map(
          (item) => PredictionMatchFilter.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .where((match) => match.id.isNotEmpty)
        .toList();
  }

  Future<List<PredictionModel>> publicPredictionsForMatch({
    required PredictionMatchFilter match,
    int limit = 100,
    int offset = 0,
  }) async {
    final data = await _db.rpc(
      'get_public_match_predictions',
      params: {
        'p_match_id': match.id,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    return (data as List).map((item) {
      final row = Map<String, dynamic>.from(item as Map);

      return PredictionModel.fromMap({
        ...row,
        'match_title': match.matchTitle,
        'stage': match.stage,
        'team_a_name': match.teamAName,
        'team_b_name': match.teamBName,
        'team_a_short_name': match.teamAShortName,
        'team_b_short_name': match.teamBShortName,
        'team_a_flag_url': match.teamAFlagUrl,
        'team_b_flag_url': match.teamBFlagUrl,
      });
    }).toList();
  }

  Future<List<PredictionModel>> allPredictionsForMatch(String matchId) async {
    if (matchId.trim().isEmpty) {
      return [];
    }

    final data = await _db
        .from('predictions_view')
        .select()
        .eq('match_id', matchId)
        .order('submitted_at', ascending: true);

    final rows = (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final userIds = rows
        .map((row) => _text(row['user_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final profilesById = <String, Map<String, dynamic>>{};

    if (userIds.isNotEmpty) {
      try {
        final profileRows = await _db
            .from('profiles')
            .select('id, full_name, phone, email, avatar_url')
            .inFilter('id', userIds);

        for (final item in profileRows as List) {
          final row = Map<String, dynamic>.from(item as Map);
          final id = _text(row['id']);

          if (id.isNotEmpty) {
            profilesById[id] = row;
          }
        }
      } catch (error, stackTrace) {
        developer.log(
          'Could not load prediction user profiles',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    final predictions = rows.map((row) {
      final userId = _text(row['user_id']);
      final profile = profilesById[userId];

      return PredictionModel.fromMap({
        ...row,
        if (profile != null) ...profile,
      });
    }).toList();

    predictions.sort((a, b) {
      final pointCompare = (b.points ?? 0).compareTo(a.points ?? 0);

      if (pointCompare != 0) return pointCompare;

      final aDate = a.submittedAt;
      final bDate = b.submittedAt;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return aDate.compareTo(bDate);
    });

    return predictions;
  }

  Future<MatchPrizePoolModel?> matchPrizePool(String matchId) async {
    if (matchId.trim().isEmpty) {
      return null;
    }

    final response = await _db.rpc(
      'get_match_prize_pool',
      params: {
        'p_match_id': matchId,
      },
    );

    if (response == null) return null;

    if (response is List) {
      if (response.isEmpty) return null;

      final first = response.first;

      return MatchPrizePoolModel.fromMap(
        Map<String, dynamic>.from(first as Map),
      );
    }

    return MatchPrizePoolModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  String _text(dynamic value) {
    if (value == null) {
      return '';
    }

    return '$value'.trim();
  }

  String? _nullableText(dynamic value) {
    final text = _text(value);
    return text.isEmpty ? null : text;
  }

  DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse('$value')?.toLocal();
  }

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse('$value') ?? 0;
  }
}

class _ScorerInfo {
  final String? name;
  final String? teamName;

  const _ScorerInfo({
    required this.name,
    required this.teamName,
  });
}