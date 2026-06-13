import '../../../models/fixture_model.dart';

class HomeData {
  final dynamic profile;
  final List<FixtureModel> matches;
  final List<FixtureModel> upcomingMatches;
  final List<FixtureModel> latestResults;
  final Object? fixtureError;
  final bool isShowingTodayMatches;

  const HomeData({
    required this.profile,
    required this.matches,
    required this.upcomingMatches,
    required this.latestResults,
    required this.fixtureError,
    required this.isShowingTodayMatches,
  });
}