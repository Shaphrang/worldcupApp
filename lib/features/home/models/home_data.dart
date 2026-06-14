import '../../../models/app_link_model.dart';
import '../../../models/app_user_profile.dart';
import '../../../models/fixture_model.dart';
import '../../../models/popular_pick_model.dart';
import '../../../models/prediction_model.dart';
import '../../../models/sponsor_banner_model.dart';
import '../widgets/home_my_predictions_section.dart';

class HomeData {
  final AppUserProfile? profile;
  final List<FixtureModel> matches;
  final List<FixtureModel> upcomingMatches;
  final List<FixtureModel> latestResults;
  final List<HomePredictionPreviewItem> myUpcomingPredictions;
  final List<SponsorBannerModel> topBanners;
  final List<SponsorBannerModel> midBanners;
  final List<PopularPickModel> popularPicks;
  final HomeLatestWinnersData? latestWinners;
  final AppLinkModel? whatsAppLink;
  final Object? fixtureError;
  final Object? optionalError;
  final bool isShowingTodayMatches;

  const HomeData({
    required this.profile,
    required this.matches,
    required this.upcomingMatches,
    required this.latestResults,
    required this.myUpcomingPredictions,
    required this.topBanners,
    required this.midBanners,
    required this.popularPicks,
    required this.latestWinners,
    required this.whatsAppLink,
    required this.fixtureError,
    required this.optionalError,
    required this.isShowingTodayMatches,
  });

  factory HomeData.empty({Object? fixtureError, Object? optionalError}) {
    return HomeData(
      profile: null,
      matches: const [],
      upcomingMatches: const [],
      latestResults: const [],
      myUpcomingPredictions: const [],
      topBanners: const [],
      midBanners: const [],
      popularPicks: const [],
      latestWinners: null,
      whatsAppLink: null,
      fixtureError: fixtureError,
      optionalError: optionalError,
      isShowingTodayMatches: false,
    );
  }
}

class HomeLatestWinnersData {
  final PredictionMatchFilter match;
  final List<PredictionModel> winners;

  const HomeLatestWinnersData({
    required this.match,
    required this.winners,
  });
}
