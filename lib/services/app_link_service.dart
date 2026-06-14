import '../core/config/supabase_config.dart';
import '../models/app_link_model.dart';

class AppLinkService {
  AppLinkService._();

  static final AppLinkService instance = AppLinkService._();

  final _db = SupabaseConfig.client;

  final Map<String, _AppLinkCacheItem?> _cache = {};

  static const Duration _cacheDuration = Duration(minutes: 5);

  Future<AppLinkModel?> getLink({
    required String linkKey,
    bool forceRefresh = false,
  }) async {
    final safeKey = linkKey.trim();

    if (safeKey.isEmpty) return null;

    final cached = _cache[safeKey];

    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.savedAt) < _cacheDuration) {
      return cached.item;
    }

    final result = await _db.rpc(
      'get_app_link',
      params: {
        'p_link_key': safeKey,
      },
    );

    final rows = result is List ? result : <dynamic>[];

    if (rows.isEmpty) {
      _cache[safeKey] = _AppLinkCacheItem(
        item: null,
        savedAt: DateTime.now(),
      );
      return null;
    }

    final link = AppLinkModel.fromMap(
      Map<String, dynamic>.from(rows.first as Map),
    );

    _cache[safeKey] = _AppLinkCacheItem(
      item: link,
      savedAt: DateTime.now(),
    );

    return link;
  }

  void clearCache() {
    _cache.clear();
  }

  void clearLink(String linkKey) {
    _cache.remove(linkKey.trim());
  }
}

class _AppLinkCacheItem {
  final AppLinkModel? item;
  final DateTime savedAt;

  const _AppLinkCacheItem({
    required this.item,
    required this.savedAt,
  });
}