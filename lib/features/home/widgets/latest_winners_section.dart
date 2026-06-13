import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/team_flag.dart';
import '../../../models/fixture_model.dart';

class LatestWinnersSection extends StatelessWidget {
  final List<FixtureModel> results;
  final VoidCallback onViewAll;

  const LatestWinnersSection({
    super.key,
    required this.results,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final latestResults = results.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFE8A3),
                    Color(0xFF86EFAC),
                  ],
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF86EFAC).withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF047857),
                size: 16,
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest Results',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Last 2 completed games',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: Color(0xFF86EFAC),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        if (latestResults.isEmpty)
          const _NoResultCard()
        else
          Column(
            children: [
              for (int i = 0; i < latestResults.length; i++) ...[
                _LightResultCard(
                  match: latestResults[i],
                  index: i,
                ),
                if (i != latestResults.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
      ],
    );
  }
}

class _LightResultCard extends StatelessWidget {
  final FixtureModel match;
  final int index;

  const _LightResultCard({
    required this.match,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final aScore = match.teamAScore ?? 0;
    final bScore = match.teamBScore ?? 0;

    final isDraw = aScore == bScore;
    final teamAWon = aScore > bScore;
    final teamBWon = bScore > aScore;

    final colors = index.isEven
        ? const [
            Color(0xFFFFFBEB),
            Color(0xFFDCFCE7),
            Color(0xFFE0F2FE),
          ]
        : const [
            Color(0xFFFDF2F8),
            Color(0xFFFFEDD5),
            Color(0xFFFEF9C3),
          ];

    final glowColor = index.isEven
        ? const Color(0xFF22C55E)
        : const Color(0xFFF59E0B);

    return Container(
      width: double.infinity,
      height: 78,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -24,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 76,
              color: Colors.white.withOpacity(0.52),
            ),
          ),
          Positioned(
            left: -12,
            bottom: -20,
            child: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.32),
              ),
            ),
          ),
          const Positioned(
            left: 20,
            top: 10,
            child: _SparkleDot(size: 4, opacity: 0.60),
          ),
          const Positioned(
            right: 58,
            top: 9,
            child: _SparkleDot(size: 5, opacity: 0.50),
          ),
          const Positioned(
            right: 22,
            bottom: 13,
            child: _SparkleDot(size: 3.5, opacity: 0.46),
          ),
          Row(
            children: [
              Expanded(
                child: _TeamResultSide(
                  flagUrl: match.teamAFlagUrl,
                  shortName: match.teamAShort,
                  name: match.teamAName,
                  isWinner: teamAWon,
                ),
              ),
              SizedBox(
                width: 88,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$aScore - $bScore',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDraw
                            ? const Color(0xFFF59E0B).withOpacity(0.16)
                            : const Color(0xFF22C55E).withOpacity(0.16),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isDraw ? 'DRAW' : 'FULL TIME',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDraw
                              ? const Color(0xFFD97706)
                              : const Color(0xFF047857),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _TeamResultSide(
                  flagUrl: match.teamBFlagUrl,
                  shortName: match.teamBShort,
                  name: match.teamBName,
                  isWinner: teamBWon,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamResultSide extends StatelessWidget {
  final String? flagUrl;
  final String shortName;
  final String name;
  final bool isWinner;

  const _TeamResultSide({
    required this.flagUrl,
    required this.shortName,
    required this.name,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: Colors.white.withOpacity(0.75),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TeamFlag(
                url: flagUrl,
                shortName: shortName,
                width: 37,
                height: 25,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            if (isWinner)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  height: 16,
                  width: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF86EFAC),
                        Color(0xFF22C55E),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withOpacity(0.40),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 11,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          name.isNotEmpty ? name : shortName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isWinner
                ? const Color(0xFF0F172A)
                : const Color(0xFF64748B),
            fontSize: 9.5,
            fontWeight: isWinner ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SparkleDot extends StatelessWidget {
  final double size;
  final double opacity;

  const _SparkleDot({
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
        color: Colors.white.withOpacity(opacity),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(opacity),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _NoResultCard extends StatelessWidget {
  const _NoResultCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface2.withOpacity(0.70),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.white38,
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'No completed match results yet.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}