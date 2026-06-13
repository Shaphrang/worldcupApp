import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/loading_view.dart';
import '../../models/leaderboard_model.dart';
import '../../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<LeaderboardModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = LeaderboardService().leaderboard();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = LeaderboardService().leaderboard();
    });

    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _LeaderboardBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppTheme.gold,
            backgroundColor: const Color(0xFF091827),
            onRefresh: _refresh,
            child: FutureBuilder<List<LeaderboardModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }

                if (snapshot.hasError) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                    children: [
                      const _PageHeader(total: 0),
                      const SizedBox(height: 16),
                      _StateCard(
                        icon: Icons.error_outline_rounded,
                        title: 'Could not load leaderboard',
                        message: '${snapshot.error}',
                        buttonLabel: 'Retry',
                        onPressed: _refresh,
                      ),
                    ],
                  );
                }

                final leaders = List<LeaderboardModel>.from(
                  snapshot.data ?? <LeaderboardModel>[],
                )..sort((a, b) {
                    final pointsCompare =
                        b.totalPoints.compareTo(a.totalPoints);

                    if (pointsCompare != 0) {
                      return pointsCompare;
                    }

                    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                  });

                if (leaders.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                    children: [
                      const _PageHeader(total: 0),
                      const SizedBox(height: 16),
                      const _EmptyLeaderboardCard(),
                    ],
                  );
                }

                return ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                  children: [
                    _PageHeader(total: leaders.length),
                    const SizedBox(height: 16),
                    _TopLeaderCard(
                      leader: leaders.first,
                      rank: 1,
                    ),
                    if (leaders.length > 1) ...[
                      const SizedBox(height: 16),
                      const _SectionTitle(),
                      const SizedBox(height: 10),
                      _LeaderboardGlassList(
                        leaders: leaders.skip(1).toList(),
                        startRank: 2,
                      ),
                    ],
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

class _LeaderboardBackground extends StatelessWidget {
  final Widget child;

  const _LeaderboardBackground({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071C2D),
            Color(0xFF06251F),
            Color(0xFF06111E),
            Color(0xFF02070D),
          ],
          stops: [0.0, 0.35, 0.70, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -130,
            right: -120,
            child: _GlowBlob(
              color: AppTheme.gold,
              size: 320,
              opacity: 0.16,
            ),
          ),
          Positioned(
            top: 190,
            left: -160,
            child: _GlowBlob(
              color: AppTheme.teal,
              size: 300,
              opacity: 0.11,
            ),
          ),
          Positioned(
            bottom: 90,
            right: -180,
            child: _GlowBlob(
              color: AppTheme.blue,
              size: 320,
              opacity: 0.08,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _LeaderboardPatternPainter(),
              ),
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
            blurRadius: 110,
            spreadRadius: 46,
          ),
        ],
      ),
    );
  }
}

class _LeaderboardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final circlePaint = Paint()
      ..color = AppTheme.gold.withOpacity(0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.020)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.22),
      72,
      circlePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          22,
          size.height * 0.12,
          size.width - 44,
          118,
        ),
        const Radius.circular(30),
      ),
      linePaint,
    );

    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.024)
      ..style = PaintingStyle.fill;

    const spacing = 34.0;

    for (double y = 18; y < size.height; y += spacing) {
      for (double x = 18; x < size.width; x += spacing) {
        if (((x + y) ~/ spacing) % 3 == 0) continue;

        canvas.drawCircle(
          Offset(x, y),
          1.05,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PageHeader extends StatelessWidget {
  final int total;

  const _PageHeader({
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF4C2),
                Color(0xFFFFB84D),
                Color(0xFFFF7A3D),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gold.withOpacity(0.24),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.leaderboard_rounded,
            color: Color(0xFF301908),
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leaders',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Participants ranked by total points',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: AppTheme.gold.withOpacity(0.13),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: AppTheme.gold.withOpacity(0.22),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$total',
            style: const TextStyle(
              color: AppTheme.gold,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopLeaderCard extends StatelessWidget {
  final LeaderboardModel leader;
  final int rank;

  const _TopLeaderCard({
    required this.leader,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final name = leader.name.trim().isEmpty ? 'Participant' : leader.name;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF4C2),
            Color(0xFFFFB84D),
            Color(0xFFFF7A3D),
            Color(0xFF18D6B1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withOpacity(0.22),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(29),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF10263A).withOpacity(0.97),
                  const Color(0xFF071827).withOpacity(0.98),
                  const Color(0xFF050E18).withOpacity(0.99),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  top: -14,
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 118,
                    color: AppTheme.gold.withOpacity(0.055),
                  ),
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        _LeaderAvatar(
                          name: name,
                          avatarUrl: leader.avatarUrl,
                          rank: rank,
                          size: 62,
                          isTopThree: true,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _GoldPill(),
                              const SizedBox(height: 8),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Current top participant',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _GradientDivider(),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _PointsBox(
                            label: 'Total Points',
                            value: '${leader.totalPoints}',
                            color: AppTheme.gold,
                            large: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PointsBox(
                            label: 'Predictions',
                            value: '${leader.predictionCount}',
                            color: AppTheme.teal,
                            large: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardGlassList extends StatelessWidget {
  final List<LeaderboardModel> leaders;
  final int startRank;

  const _LeaderboardGlassList({
    required this.leaders,
    required this.startRank,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF38BDF8),
            Color(0xFF18D6B1),
            Color(0xFFFFB84D),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.teal.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF10263A).withOpacity(0.96),
                  const Color(0xFF071827).withOpacity(0.98),
                  const Color(0xFF050E18).withOpacity(0.99),
                ],
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < leaders.length; i++) ...[
                  _LeaderRow(
                    leader: leaders[i],
                    rank: startRank + i,
                  ),
                  if (i != leaders.length - 1) const _GradientDivider(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final LeaderboardModel leader;
  final int rank;

  const _LeaderRow({
    required this.leader,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final name = leader.name.trim().isEmpty ? 'Participant' : leader.name;
    final isTopThree = rank <= 3;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          _LeaderAvatar(
            name: name,
            avatarUrl: leader.avatarUrl,
            rank: rank,
            size: 44,
            isTopThree: isTopThree,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.6,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 34,
            //minWidth: 72,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: _rankColor(rank).withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: _rankColor(rank).withOpacity(0.22),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${leader.totalPoints} pts',
              style: TextStyle(
                color: _rankColor(rank),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final int rank;
  final double size;
  final bool isTopThree;

  const _LeaderAvatar({
    required this.name,
    required this.avatarUrl,
    required this.rank,
    required this.size,
    required this.isTopThree,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'P' : name.trim()[0].toUpperCase();
    final color = _rankColor(rank);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: size,
          width: size,
          padding: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isTopThree
                  ? [
                      color,
                      color.withOpacity(0.68),
                    ]
                  : [
                      AppTheme.teal.withOpacity(0.78),
                      AppTheme.blue.withOpacity(0.66),
                    ],
            ),
            boxShadow: [
              if (isTopThree)
                BoxShadow(
                  color: color.withOpacity(0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF071827),
            backgroundImage:
                avatarUrl != null && avatarUrl!.trim().isNotEmpty
                    ? NetworkImage(avatarUrl!)
                    : null,
            child: avatarUrl == null || avatarUrl!.trim().isEmpty
                ? Text(
                    initial,
                    style: TextStyle(
                      color: color,
                      fontSize: size * 0.36,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : null,
          ),
        ),
        Positioned(
          right: -3,
          bottom: -3,
          child: Container(
            height: 22,
            //minWidth: 22,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: isTopThree ? color : const Color(0xFF10263A),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: const Color(0xFF02070D),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: isTopThree ? const Color(0xFF2B1908) : Colors.white70,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PointsBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool large;

  const _PointsBox({
    required this.label,
    required this.value,
    required this.color,
    required this.large,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.14),
            Colors.white.withOpacity(0.045),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: large ? 22 : 17,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldPill extends StatelessWidget {
  const _GoldPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 27,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.13),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.22),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            color: AppTheme.gold,
            size: 14,
          ),
          SizedBox(width: 5),
          Text(
            'TOP LEADER',
            style: TextStyle(
              color: AppTheme.gold,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 33,
          width: 33,
          decoration: BoxDecoration(
            color: AppTheme.gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.format_list_numbered_rounded,
            color: AppTheme.gold,
            size: 18,
          ),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Participants',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Name and total points only',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyLeaderboardCard extends StatelessWidget {
  const _EmptyLeaderboardCard();

  @override
  Widget build(BuildContext context) {
    return const _MessageCard(
      icon: Icons.leaderboard_rounded,
      title: 'No participants yet',
      message: 'Participants will appear here once they join the leaderboard.',
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final Future<void> Function() onPressed;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _MessageCard(
      icon: icon,
      title: title,
      message: message,
      buttonLabel: buttonLabel,
      onPressed: onPressed,
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final Future<void> Function()? onPressed;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.040),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.gold, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (buttonLabel != null && onPressed != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(buttonLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _GradientDivider extends StatelessWidget {
  const _GradientDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.gold.withOpacity(0.0),
            AppTheme.gold.withOpacity(0.20),
            AppTheme.teal.withOpacity(0.18),
            AppTheme.gold.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}

Color _rankColor(int rank) {
  if (rank == 1) return AppTheme.gold;
  if (rank == 2) return const Color(0xFFD9E4EE);
  if (rank == 3) return const Color(0xFFC77A35);
  return AppTheme.teal;
}