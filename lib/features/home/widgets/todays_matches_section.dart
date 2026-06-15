import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/team_flag.dart';
import '../../../models/fixture_model.dart';
import 'home_section_card.dart';

class TodaysMatchesSection extends StatelessWidget {
  final String title;
  final List<FixtureModel> matches;
  final Object? error;
  final Future<void> Function() onRetry;
  final VoidCallback onViewAll;
  final ValueChanged<FixtureModel> onMatchTap;
  

  const TodaysMatchesSection({
    super.key,
    required this.title,
    required this.matches,
    required this.error,
    required this.onRetry,
    required this.onViewAll,
    required this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleMatches = matches.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: title,
          subtitle: 'Next 5 World Cup fixtures',
          count: visibleMatches.length,
          onViewAll: onViewAll,
        ),
        const SizedBox(height: 10),
        if (error != null)
          HomeErrorCard(
            title: 'Could not load fixtures',
            message: '$error',
            onRetry: onRetry,
          )
        else if (matches.isEmpty)
          HomeEmptyCard(
            title: 'No upcoming fixtures',
            message: 'Completed matches are hidden.',
            icon: Icons.event_busy_rounded,
            action: 'Open fixtures',
            onTap: onViewAll,
          )
        else
          _SingleGlassFixtureList(
            matches: visibleMatches,
            onMatchTap: onMatchTap,
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final VoidCallback onViewAll;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34F5C5),
                Color(0xFF14B8A6),
                Color(0xFF0F766E),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.teal.withOpacity(0.22),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(
            Icons.sports_soccer_rounded,
            color: Colors.white,
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
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
                  color: Colors.white54,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 7),
        InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onViewAll,
          child: Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppTheme.teal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppTheme.teal.withOpacity(0.16)),
            ),
            alignment: Alignment.center,
            child: const Text(
              'View all',
              style: TextStyle(
                color: AppTheme.teal,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SingleGlassFixtureList extends StatelessWidget {
  final List<FixtureModel> matches;
  final ValueChanged<FixtureModel> onMatchTap;

  const _SingleGlassFixtureList({
    required this.matches,
    required this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.22),
            const Color(0xFF34F5C5).withOpacity(0.34),
            const Color(0xFF38BDF8).withOpacity(0.16),
            const Color(0xFFFBBF24).withOpacity(0.10),
            Colors.white.withOpacity(0.06),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.teal.withOpacity(0.10),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0B1D2D).withOpacity(0.94),
                  const Color(0xFF071725).withOpacity(0.90),
                  const Color(0xFF06111D).withOpacity(0.95),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -52,
                  top: -55,
                  child: _SoftGlow(
                    color: const Color(0xFF34F5C5),
                    size: 145,
                    opacity: 0.10,
                  ),
                ),
                Positioned(
                  left: -65,
                  bottom: -65,
                  child: _SoftGlow(
                    color: const Color(0xFF38BDF8),
                    size: 145,
                    opacity: 0.07,
                  ),
                ),
                Positioned(
                  right: -28,
                  bottom: -40,
                  child: Icon(
                    Icons.sports_soccer_rounded,
                    size: 118,
                    color: Colors.white.withOpacity(0.025),
                  ),
                ),
                Column(
                  children: [
                    for (int i = 0; i < matches.length; i++) ...[
                      _FixtureListRow(
                        match: matches[i],
                        onTap: () => onMatchTap(matches[i]),
                      ),
                      if (i != matches.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _GradientDivider(),
                        ),
                    ],
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

class _FixtureListRow extends StatelessWidget {
  final FixtureModel match;
  final VoidCallback onTap;

  const _FixtureListRow({
    required this.match,
    required this.onTap,
  });

  bool get _isLocked {
    final status = match.status.trim().toLowerCase();
    final now = DateTime.now();

    return match.isLocked ||
        !now.isBefore(match.predictionLockAt) ||
        status == 'locked' ||
        status == 'live' ||
        status == 'ongoing' ||
        status == 'completed' ||
        status == 'finalized' ||
        status == 'cancelled';
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = _isLocked;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLocked ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
          child: Column(
            children: [
              Row(
                children: [
                  _TimePill(match: match),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StageText(stage: match.stage),
                  ),
                  const SizedBox(width: 8),
                  isLocked
                      ? const _LockedPill()
                      : _PredictNowPill(onTap: onTap),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TeamLine(
                      flagUrl: match.teamAFlagUrl,
                      shortName: match.teamAShort,
                      name: match.teamAName,
                      alignEnd: false,
                    ),
                  ),
                  const SizedBox(width: 9),
                  const _VsBadge(),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _TeamLine(
                      flagUrl: match.teamBFlagUrl,
                      shortName: match.teamBShort,
                      name: match.teamBName,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  final FixtureModel match;

  const _TimePill({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.075),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            color: Colors.white.withOpacity(0.62),
            size: 12,
          ),
          const SizedBox(width: 6),
          Text(
            DateTimeUtils.timeOnly(match.matchStartAt),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageText extends StatelessWidget {
  final String stage;

  const _StageText({
    required this.stage,
  });

  @override
  Widget build(BuildContext context) {
    if (stage.trim().isEmpty) return const SizedBox.shrink();

    return Text(
      stage.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withOpacity(0.36),
        fontSize: 9.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.45,
      ),
    );
  }
}

class _PredictNowPill extends StatelessWidget {
  final VoidCallback onTap;

  const _PredictNowPill({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF34F5C5),
              Color(0xFF14B8A6),
              Color(0xFF0F766E),
            ],
          ),
          border: Border.all(
            color: AppTheme.teal.withOpacity(0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.teal.withOpacity(0.20),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'Predict Now',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10.3,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _LockedPill extends StatelessWidget {
  const _LockedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: Colors.white.withOpacity(0.075),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_rounded,
            size: 12,
            color: Colors.white.withOpacity(0.62),
          ),
          const SizedBox(width: 5),
          const Text(
            'Locked',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 10.3,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamLine extends StatelessWidget {
  final String? flagUrl;
  final String shortName;
  final String name;
  final bool alignEnd;

  const _TeamLine({
    required this.flagUrl,
    required this.shortName,
    required this.name,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final teamName = name.trim().isNotEmpty ? name.trim() : shortName.trim();

    final flag = Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TeamFlag(
        url: flagUrl,
        shortName: shortName,
        width: 38,
        height: 27,
        borderRadius: BorderRadius.circular(7),
      ),
    );

    final text = Flexible(
      child: Text(
        teamName,
        maxLines: 2,
        softWrap: true,
        overflow: TextOverflow.visible,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.6,
          fontWeight: FontWeight.w900,
          height: 1.08,
          letterSpacing: 0.05,
        ),
      ),
    );

    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: alignEnd
          ? [
              text,
              const SizedBox(width: 7),
              flag,
            ]
          : [
              flag,
              const SizedBox(width: 7),
              text,
            ],
    );
  }
}

class _VsBadge extends StatelessWidget {
  const _VsBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 31,
      width: 41,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.075),
        border: Border.all(
          color: Colors.white.withOpacity(0.09),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'VS',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 10.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _GradientDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.10),
            AppTheme.teal.withOpacity(0.18),
            Colors.white.withOpacity(0.10),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _SoftGlow extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _SoftGlow({
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
            blurRadius: 80,
            spreadRadius: 25,
          ),
        ],
      ),
    );
  }
}