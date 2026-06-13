import 'dart:developer' as developer;

import '../core/config/supabase_config.dart';
import '../models/leaderboard_model.dart';

class LeaderboardService {
  final _db = SupabaseConfig.client;

  Future<List<LeaderboardModel>> leaderboard() async {
    try {
      final data = await _db.rpc('get_leaderboard');

      final rows = data as List;

      final list = rows
          .map(
            (item) => LeaderboardModel.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      list.sort((a, b) {
        final pointsCompare = b.totalPoints.compareTo(a.totalPoints);

        if (pointsCompare != 0) {
          return pointsCompare;
        }

        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      developer.log('Leaderboard rows loaded: ${list.length}');

      return list;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load leaderboard',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}