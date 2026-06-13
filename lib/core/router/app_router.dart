//lib\core\router\app_router.dart
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/fixtures/match_prediction_screen.dart';
import '../../features/home/main_shell_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/splash/splash_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    ShellRoute(
      builder: (context, state, child) => MainShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreenTab(),
        ),
        GoRoute(
          path: '/fixtures',
          builder: (context, state) => const FixturesScreenTab(),
        ),
        GoRoute(
          path: '/my-predictions',
          builder: (context, state) => const MyPredictionsScreenTab(),
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => const LeaderboardScreenTab(),
        ),
        GoRoute(
          path: '/winners',
          builder: (context, state) => const WinnersScreenTab(),
        ),
      ],
    ),

    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),

    GoRoute(
      path: '/fixtures/:matchId',
      builder: (context, state) {
        final matchId = state.pathParameters['matchId']!;

        return MatchPredictionScreen(matchId: matchId);
      },
    ),

    GoRoute(
      path: '/login',
      builder: (context, state) {
        return LoginScreen(
          redirect: state.uri.queryParameters['redirect'],
        );
      },
    ),

    GoRoute(
      path: '/register',
      builder: (context, state) {
        return RegisterScreen(
          redirect: state.uri.queryParameters['redirect'],
        );
      },
    ),
  ],
);