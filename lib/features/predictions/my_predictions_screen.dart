//lib\features\predictions\my_predictions_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../services/auth_service.dart';
import '../../services/prediction_service.dart';

class MyPredictionsScreen extends StatelessWidget {
  const MyPredictionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AuthService().isLoggedIn) {
      return Scaffold(
        body: _PredictionBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
              children: [
                const _PageHeader(),
                const SizedBox(height: 18),
                EmptyView(
                  message: 'Login to submit predictions and track your score.',
                  action: Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () {
                          context.push('/login?redirect=/my-predictions');
                        },
                        child: const Text('Login'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          context.push('/register?redirect=/my-predictions');
                        },
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: _PredictionBackground(
        child: SafeArea(
          child: FutureBuilder(
            future: PredictionService().myPredictions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView();
              }

              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                  children: [
                    const _PageHeader(),
                    const SizedBox(height: 18),
                    _StateCard(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load predictions',
                      message: '${snapshot.error}',
                    ),
                  ],
                );
              }

              final list = snapshot.data ?? [];

              if (list.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                  children: const [
                    _PageHeader(),
                    SizedBox(height: 18),
                    EmptyView(message: 'No predictions yet.'),
                  ],
                );
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                itemCount: list.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const _PageHeader();
                  }

                  final prediction = list[index - 1];

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface2.withOpacity(0.94),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.teal.withOpacity(0.055),
                          AppTheme.surface2.withOpacity(0.95),
                          AppTheme.surface.withOpacity(0.95),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.teal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: AppTheme.teal.withOpacity(0.18),
                            ),
                          ),
                          child: const Icon(
                            Icons.fact_check_rounded,
                            color: AppTheme.teal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prediction.matchTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      prediction.teamAName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.teal.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: AppTheme.teal.withOpacity(0.20),
                                      ),
                                    ),
                                    child: Text(
                                      '${prediction.teamAScore} - ${prediction.teamBScore}',
                                      style: const TextStyle(
                                        color: AppTheme.teal,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      prediction.teamBName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              Text(
                                'Scorer: ${prediction.scorerName ?? '—'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                DateTimeUtils.format(prediction.submittedAt),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: AppTheme.gold.withOpacity(0.20),
                            ),
                          ),
                          child: Text(
                            prediction.points == null
                                ? prediction.status
                                : '${prediction.points} pts',
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Predictions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Track your submitted scores and points.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionBackground extends StatelessWidget {
  final Widget child;

  const _PredictionBackground({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.background),
      child: Stack(
        children: [
          Positioned(
            top: -170,
            right: -160,
            child: _GlowBlob(
              color: AppTheme.teal,
              size: 330,
              opacity: 0.16,
            ),
          ),
          Positioned(
            bottom: -160,
            left: -160,
            child: _GlowBlob(
              color: AppTheme.blue,
              size: 290,
              opacity: 0.08,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _GlowBlob({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(opacity),
            blurRadius: 100,
            spreadRadius: 46,
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface2.withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Colors.white70),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}