import 'dart:developer' as developer;

import '../core/config/supabase_config.dart';
import '../models/fixture_model.dart';
import '../models/player_model.dart';

class FixtureService {
  final _db = SupabaseConfig.client;

  Future<List<FixtureModel>> allFixtures() async {
    try {
      final data = await _db
          .from('fixtures_view')
          .select()
          .order('match_start_at', ascending: true);

      return (data as List)
          .map(
            (item) => FixtureModel.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load all fixtures',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<FixtureModel>> fixtures() async {
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();

      final data = await _db
          .from('fixtures_view')
          .select()
          .neq('status', 'completed')
          .gte('match_start_at', nowUtc)
          .order('match_start_at', ascending: true);

      return (data as List)
          .map(
            (item) => FixtureModel.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .where((fixture) => !fixture.isCompleted)
          .toList();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load fixtures',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<FixtureModel>> todayFixtures() async {
    try {
      final now = DateTime.now();
      final localStart = DateTime(now.year, now.month, now.day);
      final localEnd = localStart.add(const Duration(days: 1));

      final startUtc = localStart.toUtc().toIso8601String();
      final endUtc = localEnd.toUtc().toIso8601String();

      final data = await _db
          .from('fixtures_view')
          .select()
          .neq('status', 'completed')
          .gte('match_start_at', startUtc)
          .lt('match_start_at', endUtc)
          .order('match_start_at', ascending: true);

      return (data as List)
          .map(
            (item) => FixtureModel.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .where((fixture) => !fixture.isCompleted)
          .toList();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load today fixtures',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<FixtureModel>> latestResults({int limit = 2}) async {
    try {
      final data = await _db
          .from('fixtures_view')
          .select()
          .not('team_a_score', 'is', null)
          .not('team_b_score', 'is', null)
          .order('match_start_at', ascending: false)
          .limit(limit);

      return (data as List)
          .map(
            (item) => FixtureModel.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .where((fixture) {
            final status = fixture.status.toLowerCase();
            return status == 'completed' || status == 'finalized';
          })
          .toList();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load latest results',
        error: error,
        stackTrace: stackTrace,
      );
      return <FixtureModel>[];
    }
  }

  Future<FixtureModel?> nextFixture() async {
    final list = await fixtures();

    if (list.isEmpty) {
      return null;
    }

    return list.first;
  }

  Future<FixtureModel?> fixture(String id) async {
    try {
      final data = await _db
          .from('fixtures_view')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) {
        return null;
      }

      return FixtureModel.fromMap(
        Map<String, dynamic>.from(data),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load fixture: $id',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<PlayerModel>> players(String matchId) async {
    try {
      final data = await _db
          .from('match_players_view')
          .select()
          .eq('match_id', matchId)
          .order('player_name', ascending: true);

      return (data as List)
          .map(
            (item) => PlayerModel.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load match players',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}