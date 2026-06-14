import '../core/config/supabase_config.dart';
import '../models/popular_pick_model.dart';

class PopularPicksService {
  PopularPicksService._();

  static final PopularPicksService instance = PopularPicksService._();

  final _db = SupabaseConfig.client;

  final Map<String, _PopularPicksCacheItem> _cache = {};

  static const Duration _cacheDuration = Duration(minutes: 2);

  Future<List<PopularPickModel>> getSeasonPopularPicks({
    int limit = 3,
    bool forceRefresh = false,
  }) async {
    final safeLimit = limit.clamp(1, 6);
    final cacheKey = 'season:$safeLimit';

    final cached = _cache[cacheKey];

    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.savedAt) < _cacheDuration) {
      return cached.items;
    }

    final result = await _db.rpc(
      'get_home_popular_score_picks',
      params: {
        'p_limit': safeLimit,
      },
    );

    final rows = result is List ? result : <dynamic>[];

    final picks = rows
        .map(
          (item) => PopularPickModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .where((item) => item.totalPicks > 0)
        .toList();

    _cache[cacheKey] = _PopularPicksCacheItem(
      items: picks,
      savedAt: DateTime.now(),
    );

    return picks;
  }

  void clearCache() {
    _cache.clear();
  }
}

class _PopularPicksCacheItem {
  final List<PopularPickModel> items;
  final DateTime savedAt;

  const _PopularPicksCacheItem({
    required this.items,
    required this.savedAt,
  });
}