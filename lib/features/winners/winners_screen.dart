import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/team_flag.dart';
import '../../services/winner_service.dart';

class WinnersScreen extends StatefulWidget {
  const WinnersScreen({super.key});

  @override
  State<WinnersScreen> createState() => _WinnersScreenState();
}

class _WinnersScreenState extends State<WinnersScreen> {
  late Future<LatestMatchWinnersResult> _future;

  @override
  void initState() {
    super.initState();
    _future = WinnerService().latestMatchWinners();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = WinnerService().latestMatchWinners();
    });

    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _WinnersBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppTheme.gold,
            backgroundColor: const Color(0xFF091827),
            onRefresh: _refresh,
            child: FutureBuilder<LatestMatchWinnersResult>(
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
                      const _PageHeader(),
                      const SizedBox(height: 16),
                      _StateCard(
                        icon: Icons.error_outline_rounded,
                        title: 'Could not load winners',
                        message: '${snapshot.error}',
                        buttonLabel: 'Retry',
                        onPressed: _refresh,
                      ),
                    ],
                  );
                }

                final result = snapshot.data;

                if (result == null || result.match == null) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                    children: const [
                      _PageHeader(),
                      SizedBox(height: 16),
                      _NoCompletedMatchCard(),
                    ],
                  );
                }

                final match = result.match!;

                return ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                  children: [
                    const _PageHeader(),
                    const SizedBox(height: 16),
                    _LatestMatchCard(match: match),
                    const SizedBox(height: 14),
                    if (result.participants.isEmpty)
                      const _NoPredictionsCard()
                    else ...[
                      if (result.isEvaluated) ...[
                        _WinnerSummaryCard(result: result),
                        const SizedBox(height: 16),
                      ] else ...[
                        _NotEvaluatedCard(match: match),
                        const SizedBox(height: 16),
                      ],
                      const _SectionTitle(
                        title: 'Compared Predictions',
                        subtitle: 'Sorted by points, then participant name',
                      ),
                      const SizedBox(height: 10),
                      for (int i = 0; i < result.participants.length; i++) ...[
                        _PredictionRankTile(
                          item: result.participants[i],
                          match: match,
                        ),
                        if (i != result.participants.length - 1)
                          const SizedBox(height: 10),
                      ],
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

class _WinnersBackground extends StatelessWidget {
  final Widget child;

  const _WinnersBackground({
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
            top: 210,
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
                painter: _WinnersPatternPainter(),
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

class _WinnersPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final accentPaint = Paint()
      ..color = AppTheme.gold.withOpacity(0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.24),
      72,
      accentPaint,
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
        canvas.drawCircle(Offset(x, y), 1.05, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

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
            Icons.emoji_events_rounded,
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
                'Winners',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Latest match prediction result',
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
      ],
    );
  }
}

class _LatestMatchCard extends StatelessWidget {
  final WinnerMatchInfo match;

  const _LatestMatchCard({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = match.matchStartAt == null
        ? 'Latest completed match'
        : DateTimeUtils.dateOnly(match.matchStartAt);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
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
            color: AppTheme.teal.withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27),
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
                Row(
                  children: [
                    const _SmallPill(
                      icon: Icons.sports_soccer_rounded,
                      label: 'LATEST MATCH',
                      color: AppTheme.gold,
                    ),
                    const Spacer(),
                    Text(
                      dateText,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _MatchTeam(
                        name: match.teamAName,
                        shortName: match.teamAShort,
                        flagUrl: match.teamAFlagUrl,
                        alignRight: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ResultScoreBox(
                      teamAScore: match.teamAScore,
                      teamBScore: match.teamBScore,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MatchTeam(
                        name: match.teamBName,
                        shortName: match.teamBShort,
                        flagUrl: match.teamBFlagUrl,
                        alignRight: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 1.1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.gold.withOpacity(0.0),
                        AppTheme.gold.withOpacity(0.22),
                        AppTheme.teal.withOpacity(0.18),
                        AppTheme.gold.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        match.stage.isEmpty ? 'Completed match' : match.stage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      match.matchTitle.isEmpty ? 'Result declared' : match.matchTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
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

class _MatchTeam extends StatelessWidget {
  final String name;
  final String shortName;
  final String? flagUrl;
  final bool alignRight;

  const _MatchTeam({
    required this.name,
    required this.shortName,
    required this.flagUrl,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isNotEmpty ? name.trim() : shortName;

    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        TeamFlag(
          url: flagUrl,
          shortName: shortName,
          width: 42,
          height: 30,
          borderRadius: BorderRadius.circular(9),
        ),
        const SizedBox(height: 8),
        Text(
          displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignRight ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.2,
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
        ),
      ],
    );
  }
}

class _ResultScoreBox extends StatelessWidget {
  final int teamAScore;
  final int teamBScore;

  const _ResultScoreBox({
    required this.teamAScore,
    required this.teamBScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF7D6),
            Color(0xFFFFD166),
            Color(0xFFFFB84D),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$teamAScore - $teamBScore',
        style: const TextStyle(
          color: Color(0xFF2B1908),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class _WinnerSummaryCard extends StatelessWidget {
  final LatestMatchWinnersResult result;

  const _WinnerSummaryCard({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final winners = result.winners;
    final title = winners.length == 1 ? 'Winner' : 'Winners';
    final subtitle = winners.length == 1
        ? 'Highest points for this latest match'
        : '${winners.length} users tied with highest points';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.045),
          ],
        ),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: AppTheme.gold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
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
                  '${result.highestPoints} pts',
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 13),
          for (int i = 0; i < winners.length; i++) ...[
            _WinnerPersonRow(item: winners[i]),
            if (i != winners.length - 1)
              Divider(
                height: 14,
                color: Colors.white.withOpacity(0.07),
              ),
          ],
        ],
      ),
    );
  }
}

class _WinnerPersonRow extends StatelessWidget {
  final LatestMatchWinnerItem item;

  const _WinnerPersonRow({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _UserAvatar(
          name: item.fullName,
          avatarUrl: item.avatarUrl,
          size: 46,
          rankNo: item.rankNo,
          isWinner: true,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _scorerText(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${item.predictedTeamAScore} - ${item.predictedTeamBScore}',
          style: const TextStyle(
            color: AppTheme.gold,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PredictionRankTile extends StatelessWidget {
  final LatestMatchWinnerItem item;
  final WinnerMatchInfo match;

  const _PredictionRankTile({
    required this.item,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(21),
        gradient: LinearGradient(
          colors: item.isWinner
              ? [
                  AppTheme.gold.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ]
              : [
                  Colors.white.withOpacity(0.09),
                  Colors.white.withOpacity(0.035),
                ],
        ),
        border: Border.all(
          color: item.isWinner
              ? AppTheme.gold.withOpacity(0.20)
              : Colors.white.withOpacity(0.075),
        ),
      ),
      child: Row(
        children: [
          _UserAvatar(
            name: item.fullName,
            avatarUrl: item.avatarUrl,
            size: 43,
            rankNo: item.rankNo,
            isWinner: item.isWinner,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Predicted ${match.teamAShort} ${item.predictedTeamAScore} - ${item.predictedTeamBScore} ${match.teamBShort}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _scorerText(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.totalPoints}',
                style: TextStyle(
                  color: item.isWinner ? AppTheme.gold : AppTheme.teal,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'pts',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;
  final int rankNo;
  final bool isWinner;

  const _UserAvatar({
    required this.name,
    required this.avatarUrl,
    required this.size,
    required this.rankNo,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'P' : name.trim()[0].toUpperCase();

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
              colors: isWinner
                  ? const [
                      Color(0xFFFFF4C2),
                      Color(0xFFFFB84D),
                      Color(0xFFFF7A3D),
                    ]
                  : [
                      AppTheme.teal.withOpacity(0.80),
                      AppTheme.blue.withOpacity(0.70),
                    ],
            ),
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
                      color: isWinner ? AppTheme.gold : Colors.white,
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
            height: 21,
            //minWidth: 21,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: isWinner ? AppTheme.gold : const Color(0xFF10263A),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: const Color(0xFF02070D),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rankNo',
              style: TextStyle(
                color: isWinner ? const Color(0xFF2B1908) : Colors.white70,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

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
            Icons.compare_arrows_rounded,
            color: AppTheme.gold,
            size: 18,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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

class _SmallPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SmallPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 27,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: color.withOpacity(0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoCompletedMatchCard extends StatelessWidget {
  const _NoCompletedMatchCard();

  @override
  Widget build(BuildContext context) {
    return const _MessageCard(
      icon: Icons.sports_soccer_rounded,
      title: 'No completed match yet',
      message:
          'Winners will be calculated after the latest match has a final score.',
    );
  }
}

class _NoPredictionsCard extends StatelessWidget {
  const _NoPredictionsCard();

  @override
  Widget build(BuildContext context) {
    return const _MessageCard(
      icon: Icons.person_search_rounded,
      title: 'No predictions found',
      message:
          'There are no submitted predictions for the latest completed match.',
    );
  }
}

class _NotEvaluatedCard extends StatelessWidget {
  final WinnerMatchInfo match;

  const _NotEvaluatedCard({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    return _MessageCard(
      icon: Icons.pending_actions_rounded,
      title: 'Winner not calculated yet',
      message:
          'Predictions for ${match.teamAName} vs ${match.teamBName} are available, but points are not evaluated yet.',
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
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
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF091827).withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Colors.white70),
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
          const SizedBox(height: 8),
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
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

String _scorerText(LatestMatchWinnerItem item) {
  final scorer = item.scorerName?.trim();
  final team = item.scorerTeamName?.trim();

  if (scorer == null || scorer.isEmpty) {
    return 'No goal scorer selected';
  }

  if (team == null || team.isEmpty) {
    return 'Scorer: $scorer';
  }

  return 'Scorer: $scorer • $team';
}