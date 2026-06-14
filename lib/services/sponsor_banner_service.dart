import '../core/config/supabase_config.dart';
import '../models/sponsor_banner_model.dart';

class SponsorBannerService {
  SponsorBannerService._();

  static final SponsorBannerService instance = SponsorBannerService._();

  final _db = SupabaseConfig.client;

  final Map<String, _BannerCacheItem> _cache = {};

  static const Duration _cacheDuration = Duration(minutes: 5);

  Future<List<SponsorBannerModel>> getBanners({
    required String placement,
    String slot = SponsorBannerSlot.top,
    int limit = 5,
    bool includeGlobal = true,
    bool forceRefresh = false,
  }) async {
    final safeLimit = limit.clamp(1, 20);
    final cacheKey = '$placement:$slot:$safeLimit:$includeGlobal';

    final cached = _cache[cacheKey];

    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.savedAt) < _cacheDuration) {
      return cached.items;
    }

    final result = await _db.rpc(
      'get_sponsor_banners',
      params: {
        'p_placement': placement,
        'p_slot': slot,
        'p_limit': safeLimit,
        'p_include_global': includeGlobal,
      },
    );

    final rows = result is List ? result : <dynamic>[];

    final banners = rows
        .map(
          (item) => SponsorBannerModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .where((banner) => banner.imageUrl.trim().isNotEmpty)
        .toList();

    _cache[cacheKey] = _BannerCacheItem(
      items: banners,
      savedAt: DateTime.now(),
    );

    return banners;
  }

  void clearCache() {
    _cache.clear();
  }

  void clearPlacement(String placement) {
    _cache.removeWhere((key, value) => key.startsWith('$placement:'));
  }

  void clearPlacementSlot(String placement, String slot) {
    _cache.removeWhere((key, value) => key.startsWith('$placement:$slot:'));
  }
}

class _BannerCacheItem {
  final List<SponsorBannerModel> items;
  final DateTime savedAt;

  const _BannerCacheItem({
    required this.items,
    required this.savedAt,
  });
}