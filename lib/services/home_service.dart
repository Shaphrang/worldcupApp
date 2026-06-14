import 'dart:developer' as developer;

import '../features/home/models/home_data.dart';
import '../features/home/widgets/home_my_predictions_section.dart';
import '../models/app_link_model.dart';
import '../models/app_user_profile.dart';
import '../models/fixture_model.dart';
import '../models/popular_pick_model.dart';
import '../models/sponsor_banner_model.dart';
import 'app_link_service.dart';
import 'auth_service.dart';
import 'fixture_service.dart';
import 'popular_picks_service.dart';
import 'prediction_service.dart';
import 'profile_service.dart';
import 'sponsor_banner_service.dart';

class HomeService {
  HomeService._();

  static final HomeService instance = HomeService._();

  final _auth = AuthService();
  final _fixtureService = FixtureService();
  final _predictionService = PredictionService();
  final _profileService = ProfileService();

  HomeData? _cachedHomeData;
  DateTime? _cachedAt;
  Future<HomeData>? _inFlight;

  static const Duration _homeTtl = Duration(seconds: 45);

  HomeData? takePreparedData() => _cachedHomeData;

  Future<HomeData> prepareHome({bool forceRefresh = false}) {
    final cached = _cachedHomeData;
    final cachedAt = _cachedAt;
    if (!forceRefresh && cached != null && cachedAt != null &&
        DateTime.now().difference(cachedAt) < _homeTtl) {
      return Future.value(cached);
    }

    if (!forceRefresh && _inFlight != null) return _inFlight!;

    if (forceRefresh) {
      SponsorBannerService.instance.clearCache();
      AppLinkService.instance.clearCache();
      PopularPicksService.instance.clearCache();
    }

    _inFlight = _loadHome(forceRefresh: forceRefresh).then((data) {
      _cachedHomeData = data;
      _cachedAt = DateTime.now();
      return data;
    }).whenComplete(() => _inFlight = null);

    return _inFlight!;
  }

  Future<HomeData> _loadHome({required bool forceRefresh}) async {
    Object? fixtureError;
    Object? optionalError;

    var todayMatches = <FixtureModel>[];
    var upcomingMatches = <FixtureModel>[];
    var latestResults = <FixtureModel>[];
    var predictions = <HomePredictionPreviewItem>[];

    final profileFuture = _auth.isLoggedIn
        ? _safe(() => _profileService.currentProfile(), 'profile')
        : Future.value(null);

    try {
      final fixtureResults = await Future.wait<List<FixtureModel>>([
        _fixtureService.todayFixtures(),
        _fixtureService.fixtures(),
        _fixtureService.latestResults(limit: 2),
      ]);
      todayMatches = fixtureResults[0];
      upcomingMatches = fixtureResults[1];
      latestResults = fixtureResults[2];
    } catch (error, stackTrace) {
      fixtureError = error;
      developer.log('Home fixture load failed', error: error, stackTrace: stackTrace);
    }

    if (_auth.isLoggedIn && upcomingMatches.isNotEmpty) {
      predictions = await _safe(
            () => _predictionService.homeUpcomingPredictionsFromFixtures(upcomingMatches, limit: 5),
            'home predictions',
          ) ?? <HomePredictionPreviewItem>[];
    }

    final optional = await Future.wait<dynamic>([
      profileFuture,
      _safe(() => SponsorBannerService.instance.getBanners(
            placement: SponsorBannerPlacement.home,
            slot: SponsorBannerSlot.top,
            limit: 5,
            forceRefresh: forceRefresh,
          ), 'top banners'),
      _safe(() => SponsorBannerService.instance.getBanners(
            placement: SponsorBannerPlacement.fixtures,
            slot: SponsorBannerSlot.top,
            limit: 5,
            forceRefresh: forceRefresh,
          ), 'mid banners'),
      _safe(() => PopularPicksService.instance.getSeasonPopularPicks(limit: 3, forceRefresh: forceRefresh), 'popular picks'),
      _safe(_latestWinners, 'latest winners'),
      _safe(() => AppLinkService.instance.getLink(linkKey: 'home_whatsapp_group', forceRefresh: forceRefresh), 'whatsapp link'),
    ]);

    final shownMatches = todayMatches.isNotEmpty ? todayMatches : upcomingMatches.take(6).toList();

    return HomeData(
      profile: optional[0] as AppUserProfile?,
      matches: shownMatches,
      upcomingMatches: upcomingMatches,
      latestResults: latestResults,
      myUpcomingPredictions: predictions,
      topBanners: (optional[1] as List?)?.cast<SponsorBannerModel>() ?? const [],
      midBanners: (optional[2] as List?)?.cast<SponsorBannerModel>() ?? const [],
      popularPicks: (optional[3] as List?)?.cast<PopularPickModel>() ?? const [],
      latestWinners: optional[4] as HomeLatestWinnersData?,
      whatsAppLink: optional[5] as AppLinkModel?,
      fixtureError: fixtureError,
      optionalError: optionalError,
      isShowingTodayMatches: todayMatches.isNotEmpty,
    );
  }

  Future<HomeLatestWinnersData?> _latestWinners() async {
    final completed = await _predictionService.completedPredictionMatches();
    for (final match in completed.take(10)) {
      final predictions = await _predictionService.publicPredictionsForMatch(match: match, limit: 5);
      if (predictions.isNotEmpty) {
        return HomeLatestWinnersData(match: match, winners: predictions);
      }
    }
    return null;
  }

  Future<T?> _safe<T>(Future<T> Function() load, String label) async {
    try {
      return await load();
    } catch (error, stackTrace) {
      developer.log('Optional home load failed: $label', error: error, stackTrace: stackTrace);
      return null;
    }
  }
}
