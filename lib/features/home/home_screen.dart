import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/fixture_model.dart';
import '../../services/auth_service.dart';
import '../../services/fixture_service.dart';
import '../../services/prediction_service.dart';
import '../../services/profile_service.dart';
import 'models/home_data.dart';
import 'widgets/header_banner_section.dart';
import 'widgets/home_background.dart';
import 'widgets/home_my_predictions_section.dart';
import 'widgets/latest_winners_section.dart';
import 'widgets/leaders_section.dart';
import 'widgets/popular_picks_section.dart';
import 'widgets/todays_matches_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final auth = AuthService();

  late Future<_HomeScreenData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadHome();
  }

  Future<_HomeScreenData> _loadHome() async {
    dynamic profile;
    Object? fixtureError;

    List<FixtureModel> todayMatches = [];
    List<FixtureModel> upcomingMatches = [];
    List<FixtureModel> latestResults = [];
    List<HomePredictionPreviewItem> myUpcomingPredictions = [];

    if (auth.isLoggedIn) {
      try {
        profile = await ProfileService().currentProfile();
      } catch (_) {
        profile = null;
      }
    }

    try {
      todayMatches = await FixtureService().todayFixtures();
      upcomingMatches = await FixtureService().fixtures();
      latestResults = await FixtureService().latestResults(limit: 2);
    } catch (error) {
      fixtureError = error;
    }

    if (auth.isLoggedIn && upcomingMatches.isNotEmpty) {
      try {
            myUpcomingPredictions =
                await PredictionService().homeUpcomingPredictionsFromFixtures(
              upcomingMatches,
              limit: 5,
            );
      } catch (error) {
        debugPrint('Could not load home predictions: $error');
        myUpcomingPredictions = [];
      }
    }

    final shownMatches = todayMatches.isNotEmpty
        ? todayMatches
        : upcomingMatches.take(6).toList();

    final homeData = HomeData(
      profile: profile,
      matches: shownMatches,
      upcomingMatches: upcomingMatches,
      latestResults: latestResults,
      fixtureError: fixtureError,
      isShowingTodayMatches: todayMatches.isNotEmpty,
    );

    return _HomeScreenData(
      homeData: homeData,
      myUpcomingPredictions: myUpcomingPredictions,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadHome();
    });

    await _future;
  }

  void _openFixtures() {
    context.go('/fixtures');
  }

  void _openProfile() {
    if (auth.isLoggedIn) {
      context.push('/profile');
    } else {
      context.push('/login?redirect=/profile');
    }
  }

  void _openLogin() {
    context.push('/login?redirect=/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppTheme.teal,
            backgroundColor: AppTheme.surface2,
            onRefresh: _refresh,
            child: FutureBuilder<_HomeScreenData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.teal,
                    ),
                  );
                }

                final screenData = snapshot.data;
                final data = screenData?.homeData;

                final userName = auth.isLoggedIn
                    ? data?.profile?.fullName ??
                        auth.currentUser?.email?.split('@').first ??
                        'Player'
                    : null;

                return ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                  children: [
                    HeaderBannerSection(
                      name: userName,
                      onProfileTap: _openProfile,
                    ),
                    const SizedBox(height: 16),
                    TodaysMatchesSection(
                      title: data?.isShowingTodayMatches == true
                          ? 'Today’s Matches'
                          : 'Upcoming Matches',
                      matches: data?.matches ?? [],
                      error: data?.fixtureError,
                      onRetry: _refresh,
                      onViewAll: _openFixtures,
                      onMatchTap: (match) {
                        context.push('/fixtures/${match.id}');
                      },
                    ),
                    const SizedBox(height: 16),
                    LatestWinnersSection(
                      results: data?.latestResults ?? [],
                      onViewAll: _openFixtures,
                    ),
                    const SizedBox(height: 16),
                    HomeMyPredictionsSection(
                      isLoggedIn: auth.isLoggedIn,
                      predictions: screenData?.myUpcomingPredictions ?? [],
                      onLoginTap: _openLogin,
                      onPredictionTap: (prediction) {
                        context.push('/fixtures/${prediction.matchId}');
                      },
                    ),
                    const SizedBox(height: 16),
                    const PopularPicksSection(),
                    const SizedBox(height: 16),
                    LeadersSection(
                      onViewAll: () => context.go('/leaderboard'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeScreenData {
  final HomeData homeData;
  final List<HomePredictionPreviewItem> myUpcomingPredictions;

  const _HomeScreenData({
    required this.homeData,
    required this.myUpcomingPredictions,
  });
}