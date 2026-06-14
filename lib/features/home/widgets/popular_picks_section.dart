import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/popular_pick_model.dart';
import '../../../services/popular_picks_service.dart';
import 'home_section_card.dart';

class PopularPicksSection extends StatefulWidget {
  final List<PopularPickModel>? picks;

  const PopularPicksSection({
    super.key,
    this.picks,
  });

  @override
  State<PopularPicksSection> createState() => _PopularPicksSectionState();
}

class _PopularPicksSectionState extends State<PopularPicksSection> {
  late Future<List<PopularPickModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.picks != null ? Future.value(widget.picks) : _loadPicks();
  }


  @override
  void didUpdateWidget(covariant PopularPicksSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.picks != widget.picks && widget.picks != null) {
      _future = Future.value(widget.picks);
    }
  }

  Future<List<PopularPickModel>> _loadPicks() {
    return PopularPicksService.instance.getSeasonPopularPicks(
      limit: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomeSectionCard(
      title: 'Popular Picks',
      subtitle: 'Popular score & goal difference trends this World Cup',
      icon: Icons.insights_rounded,
      accent: const Color(0xFFFF9B54),
      action: 'Season',
      gradientColors: const [
        Color(0xFF3C2412),
        Color(0xFF18243A),
        Color(0xFF08111E),
      ],
      child: FutureBuilder<List<PopularPickModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _PopularPicksSkeleton();
          }

          if (snapshot.hasError) {
            debugPrint('Popular picks error: ${snapshot.error}');
            return const _PopularPicksEmpty(
              title: 'Could not load trends',
              message: 'Pull down to refresh and try again.',
              icon: Icons.error_outline_rounded,
            );
          }

          final picks = snapshot.data ?? [];

          if (picks.isEmpty) {
            return const _PopularPicksEmpty(
              title: 'No season trends yet',
              message:
                  'Popular picks will appear after completed matches have predictions.',
              icon: Icons.bar_chart_rounded,
            );
          }

          final topPick = picks.first;
          final secondary = picks.skip(1).take(2).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FeaturedTrendCard(pick: topPick),
              if (secondary.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: List.generate(secondary.length, (index) {
                    final pick = secondary[index];
                    final color = index == 0 ? AppTheme.blue : AppTheme.gold;

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
                        child: _MiniTrendCard(
                          pick: pick,
                          color: color,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FeaturedTrendCard extends StatelessWidget {
  final PopularPickModel pick;

  const _FeaturedTrendCard({
    required this.pick,
  });

  String get _goalDifferenceLabel {
    final diff = (pick.teamAScore - pick.teamBScore).abs();
    return 'Goal difference $diff';
  }

  String get _totalGoalsLabel {
    final total = pick.teamAScore + pick.teamBScore;
    return '$total total goals';
  }

  @override
  Widget build(BuildContext context) {
    final progress = (pick.pickPercent / 100).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF9B54).withOpacity(0.18),
            AppTheme.teal.withOpacity(0.10),
            Colors.white.withOpacity(0.04),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFF9B54).withOpacity(0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9B54).withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9B54).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFFF9B54).withOpacity(0.22),
                    ),
                  ),
                  child: const Text(
                    'Most picked this World Cup',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  pick.scoreText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${pick.totalPicks} picks • ${pick.pickPercent.toStringAsFixed(0)}% of all predictions',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.64),
                    fontSize: 11.2,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Flexible(
                      child: _InfoPill(
                        label: _goalDifferenceLabel,
                        color: AppTheme.teal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _InfoPill(
                        label: _totalGoalsLabel,
                        color: const Color(0xFFFF9B54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    color: const Color(0xFFFF9B54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 86,
            height: 110,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: CustomPaint(
                      painter: _TrendChartPainter(
                        primaryColor: const Color(0xFFFF9B54),
                        secondaryColor: AppTheme.teal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9B54).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF9B54).withOpacity(0.22),
                    ),
                  ),
                  child: Text(
                    '#${pick.rankNo}',
                    style: const TextStyle(
                      color: Color(0xFFFFC182),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTrendCard extends StatelessWidget {
  final PopularPickModel pick;
  final Color color;

  const _MiniTrendCard({
    required this.pick,
    required this.color,
  });

  String get _goalDiffText {
    final diff = (pick.teamAScore - pick.teamBScore).abs();
    return 'GD $diff';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.04),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _RankDot(
                rank: pick.rankNo,
                color: color,
              ),
              const Spacer(),
              Text(
                '${pick.pickPercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Text(
            pick.scoreText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          Text(
            '$_goalDiffText • ${pick.totalPicks} picks',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 9.9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.20),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RankDot extends StatelessWidget {
  final int rank;
  final Color color;

  const _RankDot({
    required this.rank,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      width: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.22),
        ),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PopularPicksSkeleton extends StatelessWidget {
  const _PopularPicksSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SkeletonBox(
          height: 152,
          radius: BorderRadius.circular(22),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SkeletonBox(
                height: 94,
                radius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SkeletonBox(
                height: 94,
                radius: BorderRadius.circular(18),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final BorderRadius radius;

  const _SkeletonBox({
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: radius,
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
    );
  }
}

class _PopularPicksEmpty extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _PopularPicksEmpty({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppTheme.gold,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  const _TrendChartPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor,
          secondaryColor,
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withOpacity(0.20),
          secondaryColor.withOpacity(0.02),
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final points = <Offset>[
      Offset(size.width * 0.05, size.height * 0.82),
      Offset(size.width * 0.23, size.height * 0.60),
      Offset(size.width * 0.42, size.height * 0.68),
      Offset(size.width * 0.63, size.height * 0.34),
      Offset(size.width * 0.82, size.height * 0.46),
      Offset(size.width * 0.95, size.height * 0.18),
    ];

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    for (final point in points) {
      final glow = Paint()
        ..color = primaryColor.withOpacity(0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 4.8, glow);

      final dot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 2.4, dot);
    }

    final barPaint = Paint()
      ..color = secondaryColor.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    const bars = [0.28, 0.46, 0.34, 0.58];
    final barWidth = math.max(6.0, size.width * 0.06);
    final startX = size.width * 0.04;

    for (int i = 0; i < bars.length; i++) {
      final heightFactor = bars[i];
      final left = startX + (i * (barWidth + 4));
      final top = size.height * (1 - heightFactor);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, size.height - top),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}