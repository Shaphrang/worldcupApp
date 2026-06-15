import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/sponsor_banner_section.dart';
import '../../models/sponsor_banner_model.dart';
import '../../services/auth_service.dart';
import '../../services/home_service.dart';
import 'models/home_data.dart';
import 'widgets/header_banner_section.dart';
import 'widgets/home_background.dart';
import 'widgets/home_my_predictions_section.dart';
import 'widgets/join_whatsapp_group_section.dart';
import 'widgets/latest_winners_section.dart';
import 'widgets/leaders_section.dart';
import 'widgets/popular_picks_section.dart';
import 'widgets/todays_matches_section.dart';
import 'widgets/home_prize_pool_mini_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final auth = AuthService();
  final _homeService = HomeService.instance;

  late Future<HomeData> _future;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _future = _homeService.prepareHome();
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    final refreshed = _homeService.prepareHome(forceRefresh: true);

    if (mounted) {
      setState(() {
        _future = refreshed;
      });
    }

    try {
      await refreshed;
    } catch (_) {
      // FutureBuilder will show the error state.
      // Do not crash RefreshIndicator.
    } finally {
      _isRefreshing = false;
    }
  }

  void _openFixtures() => context.go('/fixtures');
  void _openWinners() => context.go('/winners');

  void _openProfile() {
    if (auth.isLoggedIn) {
      context.push('/profile');
    } else {
      context.push('/login?redirect=/profile');
    }
  }

  void _openLogin() => context.push('/login?redirect=/');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
              color: AppTheme.teal,
              backgroundColor: AppTheme.surface2,
              displacement: 42,
              edgeOffset: 4,
              triggerMode: RefreshIndicatorTriggerMode.onEdge,
              onRefresh: _refresh,
              child: FutureBuilder<HomeData>(
              future: _future,
              initialData: _homeService.takePreparedData(),
              builder: (context, snapshot) {
                final data = snapshot.data ?? HomeData.empty(
                  fixtureError: snapshot.error,
                );

                final homeMatches = data.matches;
                final userName = auth.isLoggedIn
                    ? data.profile?.fullName ??
                        auth.currentUser?.email?.split('@').first ??
                        'Player'
                    : null;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
                  children: [
                    HeaderBannerSection(
                      name: userName,
                      onProfileTap: _openProfile,
                    ),
                    const SizedBox(height: 14),
                    SponsorBannerSection.fromBanners(
                      banners: data.topBanners,
                      placement: SponsorBannerPlacement.home,
                      slot: SponsorBannerSlot.top,
                      height: 118,
                      autoPlay: true,
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),

                    HomePrizePoolMiniSection(
                      onPredictTap: (matchId) {
                        context.push('/fixtures/$matchId');
                      },
                    ),

                    const SizedBox(height: 16),
                    TodaysMatchesSection(
                      title: data.isShowingTodayMatches
                          ? 'Today’s Matches'
                          : 'Upcoming Matches',
                      matches: homeMatches,
                      error: data.fixtureError,
                      onRetry: _refresh,
                      onViewAll: _openFixtures,
                      onMatchTap: (match) => context.push('/fixtures/${match.id}'),
                    ),
                    const SizedBox(height: 16),
                    LatestWinnersSection(
                      results: data.latestResults,
                      onViewAll: _openFixtures,
                    ),
                    const SizedBox(height: 16),
                    SponsorBannerSection.fromBanners(
                      banners: data.midBanners,
                      placement: SponsorBannerPlacement.fixtures,
                      slot: SponsorBannerSlot.top,
                      height: 96,
                      autoPlay: true,
                    ),
                    const SizedBox(height: 16),
                    HomeMyPredictionsSection(
                      isLoggedIn: auth.isLoggedIn,
                      predictions: data.myUpcomingPredictions,
                      onLoginTap: _openLogin,
                      onPredictionTap: (prediction) =>
                          context.push('/fixtures/${prediction.matchId}'),
                    ),
                    const SizedBox(height: 16),
                    PopularPicksSection(picks: data.popularPicks),
                    const SizedBox(height: 16),
                    LeadersSection(
                      data: data.latestWinners,
                      onViewAll: _openWinners,
                    ),
                    const SizedBox(height: 16),
                    JoinWhatsAppGroupSection(link: data.whatsAppLink),
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
