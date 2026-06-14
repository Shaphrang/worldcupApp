import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/match_prize_pool_card.dart';
import '../../core/widgets/sponsor_banner_section.dart';
import '../../core/widgets/team_flag.dart';
import '../../models/match_prize_pool_model.dart';
import '../../models/prediction_model.dart';
import '../../models/sponsor_banner_model.dart';
import '../../services/prediction_service.dart';

class WinnersScreen extends StatefulWidget {
  const WinnersScreen({super.key});

  @override
  State<WinnersScreen> createState() => _WinnersScreenState();
}

class _WinnersScreenState extends State<WinnersScreen> {
  final _service = PredictionService();

  bool _loading = true;
  bool _loadingWinners = false;
  bool _loadingPrizePool = false;
  bool _isRefreshing = false;
  int _refreshTick = 0;

  String? _error;
  String? _selectedMatchId;

  List<PredictionMatchFilter> _matches = [];
  List<PredictionModel> _winners = [];
  MatchPrizePoolModel? _prizePool;

  PredictionMatchFilter? get _selectedMatch {
    final id = _selectedMatchId;

    if (id == null) return null;

    for (final match in _matches) {
      if (match.id == id) return match;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _winners = [];
      _prizePool = null;
    });

    try {
      final matches = await _service.completedPredictionMatches();

      if (!mounted) return;

      final firstMatchId = matches.isEmpty ? null : matches.first.id;

      setState(() {
        _matches = matches;
        _selectedMatchId = firstMatchId;
        _loading = false;
      });

      if (firstMatchId != null) {
        await _loadSelectedMatchData(firstMatchId);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  Future<void> _loadSelectedMatchData(String matchId) async {
    setState(() {
      _loadingWinners = true;
      _loadingPrizePool = true;
      _error = null;
      _selectedMatchId = matchId;
      _winners = [];
      _prizePool = null;
    });

    try {
      PredictionMatchFilter? match;

      for (final item in _matches) {
        if (item.id == matchId) {
          match = item;
          break;
        }
      }

      if (match == null) {
        if (!mounted) return;

        setState(() {
          _winners = [];
          _prizePool = null;
          _loadingWinners = false;
          _loadingPrizePool = false;
        });

        return;
      }

      final predictions = await _service.publicPredictionsForMatch(
        match: match,
        limit: 100,
        offset: 0,
      );

      final validWinners = predictions.where((item) {
        return item.isEvaluated &&
            item.exactScorePoints > 0 &&
            item.points > 0;
      }).toList();

      validWinners.sort((a, b) {
        final pointCompare = b.points.compareTo(a.points);

        if (pointCompare != 0) return pointCompare;

        final aDate = a.submittedAt;
        final bDate = b.submittedAt;

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return aDate.compareTo(bDate);
      });

      MatchPrizePoolModel? prizePool;

      try {
        prizePool = await _service.matchPrizePool(matchId);
      } catch (_) {
        prizePool = null;
      }

      if (!mounted) return;

      setState(() {
        _winners = validWinners.take(10).toList();
        _prizePool = prizePool;
        _loadingWinners = false;
        _loadingPrizePool = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingWinners = false;
        _loadingPrizePool = false;
        _error = '$error';
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    if (mounted) {
      setState(() {
        _refreshTick++;
      });
    }

    try {
      final selected = _selectedMatchId;

      if (selected == null) {
        await _loadInitial();
        return;
      }

      await _loadSelectedMatchData(selected);
    } catch (_) {
      // Error is already handled inside _loadInitial or _loadSelectedMatchData.
      // Do not crash RefreshIndicator.
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMatch = _selectedMatch;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _WinnersBackground(
        child: SafeArea(
          bottom: false,
          child: _loading
              ? const LoadingView()
              : RefreshIndicator(
                    color: AppTheme.gold,
                    backgroundColor: const Color(0xFF091827),
                    displacement: 42,
                    edgeOffset: 4,
                    triggerMode: RefreshIndicatorTriggerMode.onEdge,
                    onRefresh: _refresh,
                    child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 110),
                    children: [
                      const _PageHeader(),

                      const SizedBox(height: 14),

                      SponsorBannerSection(
                        key: ValueKey('winners-top-banner-$_refreshTick'),
                        placement: SponsorBannerPlacement.winners,
                        slot: SponsorBannerSlot.top,
                        height: 104,
                        limit: 5,
                        autoPlay: true,
                      ),

                      const SizedBox(height: 14),

                      if (_matches.isNotEmpty) ...[
                        MatchPrizePoolCard(
                          prizePool: _prizePool,
                          loading: _loadingPrizePool,
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (_error != null) ...[
                        _StateCard(
                          icon: Icons.error_outline_rounded,
                          title: 'Could not load winners',
                          message: _error!,
                          buttonLabel: 'Retry',
                          onPressed: _refresh,
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (_matches.isEmpty)
                        const _NoCompletedMatchCard()
                      else ...[
                        _MatchFilterCard(
                          matches: _matches,
                          selectedMatchId: _selectedMatchId,
                          selectedMatch: selectedMatch,
                          totalShown: _winners.length,
                          loading: _loadingWinners || _loadingPrizePool,
                          onChanged: (matchId) {
                            if (matchId == null ||
                                matchId == _selectedMatchId) {
                              return;
                            }

                            _loadSelectedMatchData(matchId);
                          },
                        ),

                        const SizedBox(height: 14),

                        SponsorBannerSection(
                          key: ValueKey('winners-middle-banner-$_refreshTick'),
                          placement: SponsorBannerPlacement.winners,
                          slot: SponsorBannerSlot.middle,
                          height: 96,
                          limit: 5,
                          autoPlay: true,
                        ),

                        const SizedBox(height: 14),

                        _TopTenHeader(
                          totalShown: _winners.length,
                          loading: _loadingWinners,
                        ),

                        const SizedBox(height: 10),

                        if (_loadingWinners)
                          const _NativeLoadingCard()
                        else if (_winners.isEmpty)
                          const _NoPredictionsCard()
                        else
                          ...List.generate(_winners.length, (index) {
                            final winner = _winners[index];

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == _winners.length - 1 ? 0 : 10,
                              ),
                              child: _WinnerRankTile(
                                rank: index + 1,
                                item: winner,
                                match: selectedMatch,
                              ),
                            );
                          }),
                      ],
                    ],
                  ),
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
                'Top 10 exact-score winners by match',
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

class _MatchFilterCard extends StatelessWidget {
  final List<PredictionMatchFilter> matches;
  final String? selectedMatchId;
  final PredictionMatchFilter? selectedMatch;
  final int totalShown;
  final bool loading;
  final ValueChanged<String?> onChanged;

  const _MatchFilterCard({
    required this.matches,
    required this.selectedMatchId,
    required this.selectedMatch,
    required this.totalShown,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final match = selectedMatch;

    final dateText = match?.matchStartAt == null
        ? 'Completed match'
        : DateTimeUtils.dateOnly(match!.matchStartAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF091827).withOpacity(0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.gold.withOpacity(0.10),
            const Color(0xFF091827).withOpacity(0.96),
            const Color(0xFF050E18).withOpacity(0.98),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SmallPill(
                icon: Icons.sports_soccer_rounded,
                label: 'SELECT MATCH',
                color: AppTheme.gold,
              ),
              const Spacer(),
              if (loading)
                const SizedBox(
                  height: 15,
                  width: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.gold,
                  ),
                )
              else
                Text(
                  dateText,
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

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.055),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.09)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedMatchId,
                isExpanded: true,
                dropdownColor: const Color(0xFF091827),
                iconEnabledColor: AppTheme.gold,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                items: matches.map((match) {
                  return DropdownMenuItem<String>(
                    value: match.id,
                    child: Text(
                      match.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: loading ? null : onChanged,
              ),
            ),
          ),

          if (match != null) ...[
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _MatchTeam(
                    name: match.teamAName,
                    shortName: match.teamAShortName ?? '',
                    flagUrl: match.teamAFlagUrl,
                    alignRight: false,
                  ),
                ),
                const SizedBox(width: 8),
                _ResultScoreBox(scoreText: match.scoreText),
                const SizedBox(width: 8),
                Expanded(
                  child: _MatchTeam(
                    name: match.teamBName,
                    shortName: match.teamBShortName ?? '',
                    flagUrl: match.teamBFlagUrl,
                    alignRight: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            Container(
              width: double.infinity,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.gold.withOpacity(0.0),
                    AppTheme.gold.withOpacity(0.24),
                    AppTheme.teal.withOpacity(0.16),
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
                _MiniInfoPill(
                  icon: Icons.emoji_events_rounded,
                  label: '$totalShown winners',
                  color: AppTheme.gold,
                ),
                const SizedBox(width: 8),
                _MiniInfoPill(
                  icon: Icons.sports_soccer_rounded,
                  label: 'Final ${match.scoreText}',
                  color: AppTheme.teal,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TopTenHeader extends StatelessWidget {
  final int totalShown;
  final bool loading;

  const _TopTenHeader({
    required this.totalShown,
    required this.loading,
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
            Icons.workspace_premium_rounded,
            color: AppTheme.gold,
            size: 18,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top 10 Winners',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                loading
                    ? 'Loading winners...'
                    : '$totalShown exact-score winners shown',
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

class _WinnerRankTile extends StatelessWidget {
  final int rank;
  final PredictionModel item;
  final PredictionMatchFilter? match;

  const _WinnerRankTile({
    required this.rank,
    required this.item,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final isTop = rank == 1;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(21),
        gradient: LinearGradient(
          colors: isTop
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
          color: isTop
              ? AppTheme.gold.withOpacity(0.22)
              : Colors.white.withOpacity(0.075),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _UserAvatar(
                name: item.displayUserName,
                avatarUrl: item.userAvatarUrl,
                size: 43,
                rankNo: rank,
                isWinner: isTop,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayUserName,
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
                      'Predicted ${match?.teamAShortName ?? match?.teamAName ?? 'A'} ${item.teamAScore} - ${item.teamBScore} ${match?.teamBShortName ?? match?.teamBName ?? 'B'}',
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
                    '${item.points}',
                    style: TextStyle(
                      color: isTop ? AppTheme.gold : AppTheme.teal,
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

          const SizedBox(height: 10),

          Row(
            children: [
              _BreakdownPill(
                label: 'Score',
                value: item.exactScorePoints,
                color: AppTheme.teal,
              ),
              const SizedBox(width: 7),
              _BreakdownPill(
                label: 'Scorer',
                value: item.playerPoints,
                color: AppTheme.blue,
              ),
              const SizedBox(width: 7),
              _BreakdownPill(
                label: 'Time',
                value: item.timePoints,
                color: AppTheme.gold,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _BreakdownPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.085),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withOpacity(0.16)),
        ),
        child: Text(
          '$label: $value',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 9.6,
            fontWeight: FontWeight.w900,
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
  final String scoreText;

  const _ResultScoreBox({
    required this.scoreText,
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
        scoreText,
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
        border: Border.all(color: color.withOpacity(0.22)),
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

class _MiniInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniInfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: color.withOpacity(0.17)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NativeLoadingCard extends StatelessWidget {
  const _NativeLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF091827).withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: const SizedBox(
        height: 28,
        width: 28,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: AppTheme.gold,
        ),
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
          'Winners will appear after a completed match has exact-score predictions.',
    );
  }
}

class _NoPredictionsCard extends StatelessWidget {
  const _NoPredictionsCard();

  @override
  Widget build(BuildContext context) {
    return const _MessageCard(
      icon: Icons.person_search_rounded,
      title: 'No winners found',
      message:
          'No exact-score winner found for this selected completed match.',
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
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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

String _scorerText(PredictionModel item) {
  final scorer = item.scorerName?.trim();

  if (scorer == null || scorer.isEmpty) {
    return 'No scorer selected';
  }

  return 'Scorer: $scorer';
}