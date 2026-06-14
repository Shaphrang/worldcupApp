import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/team_flag.dart';
import '../../../models/prediction_model.dart';
import '../../../services/prediction_service.dart';
import 'home_section_card.dart';

class LeadersSection extends StatefulWidget {
  final VoidCallback onViewAll;

  const LeadersSection({
    super.key,
    required this.onViewAll,
  });

  @override
  State<LeadersSection> createState() => _LeadersSectionState();
}

class _LeadersSectionState extends State<LeadersSection> {
  final _service = PredictionService();

  late Future<_LatestWinnersData?> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadLatestWinners();
  }

  Future<_LatestWinnersData?> _loadLatestWinners() async {
    try {
      final completedMatches = await _service.completedPredictionMatches();

      if (completedMatches.isEmpty) {
        return null;
      }

      final matchesToCheck = completedMatches.take(10).toList();

      for (final match in matchesToCheck) {
        final predictions = await _service.publicPredictionsForMatch(
          match: match,
          limit: 10,
          offset: 0,
        );

        if (predictions.isEmpty) {
          continue;
        }

        final winners = [...predictions];

        winners.sort((a, b) {
          final pointsCompare = b.points.compareTo(a.points);
          if (pointsCompare != 0) return pointsCompare;

          final aTime = a.submittedAt;
          final bTime = b.submittedAt;

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          return aTime.compareTo(bTime);
        });

        return _LatestWinnersData(
          match: match,
          winners: winners.take(5).toList(),
        );
      }

      return null;
    } catch (error) {
      debugPrint('Could not load latest winners on home: $error');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSectionCard(
      title: 'Winner Board',
      subtitle: 'Top 5 from latest completed match',
      icon: Icons.stadium_rounded,
      accent: const Color(0xFF22C55E),
      action: 'View all',
      onActionTap: widget.onViewAll,
      gradientColors: const [
        Color(0xFF062F2A),
        Color(0xFF0B2234),
        Color(0xFF07111E),
      ],
      child: FutureBuilder<_LatestWinnersData?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LeadersLoading();
          }

          final data = snapshot.data;

          if (data == null || data.winners.isEmpty) {
            return const _NoLatestWinners();
          }

          final topWinner = data.winners.first;
          final otherWinners = data.winners.skip(1).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResultScoreboard(match: data.match),
              const SizedBox(height: 12),
              _TopWinnerScoreboardCard(
                winner: topWinner,
                match: data.match,
              ),
              if (otherWinners.isNotEmpty) ...[
                const SizedBox(height: 10),
                _BoardListHeader(),
                const SizedBox(height: 7),
                ...List.generate(otherWinners.length, (index) {
                  final winner = otherWinners[index];
                  final rank = index + 2;

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == otherWinners.length - 1 ? 0 : 7,
                    ),
                    child: _WinnerBoardRow(
                      rank: rank,
                      winner: winner,
                      match: data.match,
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ResultScoreboard extends StatelessWidget {
  final PredictionMatchFilter match;

  const _ResultScoreboard({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF061826).withOpacity(0.72),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ScoreTeamSide(
              name: match.teamAName,
              shortName: match.teamAShortName ?? '',
              flagUrl: match.teamAFlagUrl,
              alignEnd: false,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 44,
            constraints: const BoxConstraints(minWidth: 78),
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2D3D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF22C55E).withOpacity(0.25),
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  match.scoreText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'FULL TIME',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF86EFAC),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ScoreTeamSide(
              name: match.teamBName,
              shortName: match.teamBShortName ?? '',
              flagUrl: match.teamBFlagUrl,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreTeamSide extends StatelessWidget {
  final String name;
  final String shortName;
  final String? flagUrl;
  final bool alignEnd;

  const _ScoreTeamSide({
    required this.name,
    required this.shortName,
    required this.flagUrl,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final label = shortName.trim().isNotEmpty ? shortName : name;

    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!alignEnd) ...[
          TeamFlag(
            url: flagUrl,
            shortName: shortName,
            width: 32,
            height: 23,
            borderRadius: BorderRadius.circular(7),
          ),
          const SizedBox(width: 7),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (alignEnd) ...[
          const SizedBox(width: 7),
          TeamFlag(
            url: flagUrl,
            shortName: shortName,
            width: 32,
            height: 23,
            borderRadius: BorderRadius.circular(7),
          ),
        ],
      ],
    );
  }
}

class _TopWinnerScoreboardCard extends StatelessWidget {
  final PredictionModel winner;
  final PredictionMatchFilter match;

  const _TopWinnerScoreboardCard({
    required this.winner,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final teamA = match.teamAShortName ?? match.teamAName;
    final teamB = match.teamBShortName ?? match.teamBName;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF081C2A),
        border: Border.all(
          color: const Color(0xFFFACC15).withOpacity(0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -36,
            child: Container(
              height: 118,
              width: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFACC15).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 14,
            child: _MiniScoreBars(
              color: const Color(0xFF22C55E),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFACC15).withOpacity(0.11),
                  const Color(0xFF22C55E).withOpacity(0.07),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ChampionAvatar(winner: winner),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MATCH WINNER',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFFACC15),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            winner.displayUserName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17.5,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Predicted $teamA ${winner.teamAScore} - ${winner.teamBScore} $teamB',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10.6,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ScorePointsBox(points: winner.points),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: _ScoreInfoChip(
                        icon: Icons.emoji_events_rounded,
                        label: 'Rank #1',
                        color: const Color(0xFFFACC15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ScoreInfoChip(
                        icon: Icons.timer_rounded,
                        label: 'Tie by time',
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardListHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            'RANK',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(width: 36),
          Expanded(
            child: Text(
              'PLAYER',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Text(
            'POINTS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _WinnerBoardRow extends StatelessWidget {
  final int rank;
  final PredictionModel winner;
  final PredictionMatchFilter match;

  const _WinnerBoardRow({
    required this.rank,
    required this.winner,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final color = _rankColor(rank);
    final teamA = match.teamAShortName ?? match.teamAName;
    final teamB = match.teamBShortName ?? match.teamBName;

    return Container(
      //minHeight: 62,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF071C2B).withOpacity(0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          _PositionBadge(
            rank: rank,
            color: color,
          ),
          const SizedBox(width: 10),
          _UserAvatar(winner: winner),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  winner.displayUserName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$teamA ${winner.teamAScore} - ${winner.teamBScore} $teamB',
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
          _SmallPointsBox(
            points: winner.points,
            color: color,
          ),
        ],
      ),
    );
  }

  Color _rankColor(int rank) {
    if (rank == 2) return const Color(0xFFE5E7EB);
    if (rank == 3) return const Color(0xFFF59E0B);
    if (rank == 4) return const Color(0xFF22C55E);
    return const Color(0xFF38BDF8);
  }
}

class _ChampionAvatar extends StatelessWidget {
  final PredictionModel winner;

  const _ChampionAvatar({
    required this.winner,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = winner.userAvatarUrl;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 58,
          width: 58,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFF7AD),
                Color(0xFFFACC15),
                Color(0xFF22C55E),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFACC15).withOpacity(0.22),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: Color(0xFF0B2234),
              shape: BoxShape.circle,
            ),
            child: avatar == null || avatar.trim().isEmpty
                ? Center(
                    child: Text(
                      winner.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                : Image.network(
                    avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return Center(
                        child: Text(
                          winner.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        Positioned(
          right: -4,
          top: -5,
          child: Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFFACC15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF081C2A),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFF3B2600),
              size: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final PredictionModel winner;

  const _UserAvatar({
    required this.winner,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = winner.userAvatarUrl;

    return Container(
      height: 38,
      width: 38,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withOpacity(0.11),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: avatar == null || avatar.trim().isEmpty
          ? Center(
              child: Text(
                winner.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Image.network(
              avatar,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) {
                return Center(
                  child: Text(
                    winner.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final int rank;
  final Color color;

  const _PositionBadge({
    required this.rank,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 31,
      width: 31,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: color.withOpacity(0.28),
        ),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class _ScorePointsBox extends StatelessWidget {
  final int points;

  const _ScorePointsBox({
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 62),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFACC15).withOpacity(0.13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFACC15).withOpacity(0.25),
        ),
      ),
      child: Column(
        children: [
          Text(
            '$points',
            style: const TextStyle(
              color: Color(0xFFFACC15),
              fontSize: 19,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'POINTS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallPointsBox extends StatelessWidget {
  final int points;
  final Color color;

  const _SmallPointsBox({
    required this.points,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 50),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$points pts',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 10.3,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ScoreInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ScoreInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.17),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 5),
          Flexible(
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
          ),
        ],
      ),
    );
  }
}

class _MiniScoreBars extends StatelessWidget {
  final Color color;

  const _MiniScoreBars({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      width: 58,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _ScoreBar(height: 16, color: color.withOpacity(0.10)),
          const SizedBox(width: 5),
          _ScoreBar(height: 28, color: color.withOpacity(0.14)),
          const SizedBox(width: 5),
          _ScoreBar(height: 22, color: color.withOpacity(0.11)),
          const SizedBox(width: 5),
          _ScoreBar(height: 36, color: color.withOpacity(0.18)),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final double height;
  final Color color;

  const _ScoreBar({
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _LeadersLoading extends StatelessWidget {
  const _LeadersLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 214,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          color: Color(0xFF22C55E),
        ),
      ),
    );
  }
}

class _NoLatestWinners extends StatelessWidget {
  const _NoLatestWinners();

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
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.white38,
            size: 18,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No winner board yet. Winners will show after a completed match has predictions.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestWinnersData {
  final PredictionMatchFilter match;
  final List<PredictionModel> winners;

  const _LatestWinnersData({
    required this.match,
    required this.winners,
  });
}