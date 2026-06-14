import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/match_prize_pool_card.dart';
import '../../core/widgets/sponsor_banner_section.dart';
import '../../models/fixture_model.dart';
import '../../models/match_prize_pool_model.dart';
import '../../models/prediction_model.dart';
import '../../models/sponsor_banner_model.dart';
import '../../services/prediction_service.dart';

class MyPredictionsScreen extends StatefulWidget {
  const MyPredictionsScreen({super.key});

  @override
  State<MyPredictionsScreen> createState() => _MyPredictionsScreenState();
}

class _MyPredictionsScreenState extends State<MyPredictionsScreen> {
  final _service = PredictionService();

  bool _loading = true;
  bool _loadingPredictions = false;
  bool _loadingNextPrize = false;
  bool _isRefreshing = false;
  int _refreshTick = 0;

  String? _error;
  String? _selectedMatchId;

  List<PredictionMatchFilter> _matches = [];
  List<PredictionModel> _predictions = [];
  _NextPredictionPrizeData? _nextPrizeData;

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

  Future<_NextPredictionPrizeData?> _loadNextPredictionPrizeData() async {
    try {
      final match = await _service.nextUpcomingPredictionMatch();

      if (match == null) {
        return null;
      }

      final results = await Future.wait<Object?>([
        _service.matchPrizePool(match.id),
        _service.myPredictionForMatch(match.id),
      ]);

      return _NextPredictionPrizeData(
        match: match,
        prizePool: results[0] as MatchPrizePoolModel?,
        userPrediction: results[1] as UserMatchPrediction?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _loadingNextPrize = true;
      _error = null;
      _predictions = [];
      _nextPrizeData = null;
    });

    try {
      final results = await Future.wait<Object?>([
        _service.completedPredictionMatches(),
        _loadNextPredictionPrizeData(),
      ]);

      if (!mounted) return;

      final matches = results[0] as List<PredictionMatchFilter>;
      final nextPrizeData = results[1] as _NextPredictionPrizeData?;

      final firstMatchId = matches.isEmpty ? null : matches.first.id;

      setState(() {
        _matches = matches;
        _selectedMatchId = firstMatchId;
        _nextPrizeData = nextPrizeData;
        _loading = false;
        _loadingNextPrize = false;
      });

      if (firstMatchId != null) {
        await _loadSelectedMatchData(firstMatchId);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadingNextPrize = false;
        _error = '$error';
      });
    }
  }

  Future<void> _loadSelectedMatchData(String matchId) async {
    setState(() {
      _loadingPredictions = true;
      _error = null;
      _selectedMatchId = matchId;
      _predictions = [];
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
          _predictions = [];
          _loadingPredictions = false;
        });

        return;
      }

      final predictions = await _service.publicPredictionsForMatch(
        match: match,
        limit: 100,
        offset: 0,
      );

      if (!mounted) return;

      setState(() {
        _predictions = predictions;
        _loadingPredictions = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingPredictions = false;
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
        _loadingNextPrize = true;
      });
    }

    try {
      final selected = _selectedMatchId;

      if (selected == null) {
        await _loadInitial();
        return;
      }

      final nextPrizeFuture = _loadNextPredictionPrizeData();
      final selectedFuture = _loadSelectedMatchData(selected);

      final nextPrizeData = await nextPrizeFuture;
      await selectedFuture;

      if (!mounted) return;

      setState(() {
        _nextPrizeData = nextPrizeData;
        _loadingNextPrize = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingNextPrize = false;
        });
      }
    } finally {
      _isRefreshing = false;
    }
  }

  void _openPredictNow(FixtureModel match) {
    context.push('/fixtures/${match.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _PredictionBackground(
        child: SafeArea(
          child: _loading
              ? const LoadingView()
              : RefreshIndicator(
                  color: AppTheme.teal,
                  backgroundColor: AppTheme.surface2,
                  displacement: 42,
                  edgeOffset: 4,
                  triggerMode: RefreshIndicatorTriggerMode.onEdge,
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                    children: [
                      const _PageHeader(),
                      const SizedBox(height: 14),
                      SponsorBannerSection(
                        key: ValueKey(
                          'my-predictions-top-banner-$_refreshTick',
                        ),
                        placement: SponsorBannerPlacement.myPredictions,
                        slot: SponsorBannerSlot.top,
                        height: 104,
                        limit: 5,
                        autoPlay: true,
                      ),
                      const SizedBox(height: 14),

                      if (_loadingNextPrize) ...[
                        const MatchPrizePoolCard(
                          prizePool: null,
                          loading: true,
                        ),
                        const SizedBox(height: 14),
                      ] else if (_nextPrizeData != null) ...[
                        _NextPredictionPrizeCard(
                          data: _nextPrizeData!,
                          onPredictNow: _openPredictNow,
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (_error != null) ...[
                        _StateCard(
                          icon: Icons.error_outline_rounded,
                          title: 'Could not load predictions',
                          message: _error!,
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (_matches.isEmpty)
                        const EmptyView(
                          message:
                              'No completed matches yet. Predictions will appear after a match is completed.',
                        )
                      else ...[
                        _MatchFilterCard(
                          matches: _matches,
                          selectedMatchId: _selectedMatchId,
                          selectedMatch: _selectedMatch,
                          totalPredictions: _predictions.length,
                          loading: _loadingPredictions,
                          onChanged: (matchId) {
                            if (matchId == null ||
                                matchId == _selectedMatchId) {
                              return;
                            }

                            _loadSelectedMatchData(matchId);
                          },
                        ),
                        const SizedBox(height: 14),
                        _SummaryStrip(
                          match: _selectedMatch,
                          predictions: _predictions,
                        ),
                        const SizedBox(height: 14),
                        SponsorBannerSection(
                          key: ValueKey(
                            'my-predictions-middle-banner-$_refreshTick',
                          ),
                          placement: SponsorBannerPlacement.myPredictions,
                          slot: SponsorBannerSlot.middle,
                          height: 96,
                          limit: 5,
                          autoPlay: true,
                        ),
                        const SizedBox(height: 14),
                        if (_loadingPredictions)
                          const _NativeLoadingCard()
                        else if (_predictions.isEmpty)
                          const EmptyView(
                            message: 'No predictions found for this match.',
                          )
                        else
                          ...List.generate(_predictions.length, (index) {
                            final prediction = _predictions[index];

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    index == _predictions.length - 1 ? 0 : 12,
                              ),
                              child: _PredictionCard(
                                rank: index + 1,
                                prediction: prediction,
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

class _NextPredictionPrizeCard extends StatelessWidget {
  final _NextPredictionPrizeData data;
  final ValueChanged<FixtureModel> onPredictNow;

  const _NextPredictionPrizeCard({
    required this.data,
    required this.onPredictNow,
  });

  @override
  Widget build(BuildContext context) {
    final match = data.match;
    final alreadyPredicted = data.userPrediction != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MatchPrizePoolCard(
          prizePool: data.prizePool,
          loading: false,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface2.withOpacity(0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.gold.withOpacity(0.10),
                AppTheme.surface2.withOpacity(0.96),
                AppTheme.surface.withOpacity(0.96),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Next prediction match',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _UpcomingTeamMini(
                      name: match.teamAName,
                      shortName: match.teamAShort,
                      flagUrl: match.teamAFlagUrl,
                      alignEnd: false,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: AppTheme.gold.withOpacity(0.24),
                      ),
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _UpcomingTeamMini(
                      name: match.teamBName,
                      shortName: match.teamBShort,
                      flagUrl: match.teamBFlagUrl,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (match.stage.trim().isNotEmpty)
                    _MiniInfoPill(
                      icon: Icons.emoji_events_rounded,
                      label: match.stage.trim(),
                      color: AppTheme.gold,
                    ),
                  _MiniInfoPill(
                    icon: Icons.schedule_rounded,
                    label: DateTimeUtils.format(match.matchStartAt),
                    color: AppTheme.teal,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              if (alreadyPredicted)
                const _AlreadyPredictedBox()
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => onPredictNow(match),
                    icon: const Icon(
                      Icons.sports_soccer_rounded,
                      size: 19,
                    ),
                    label: const Text('Predict Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D00),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UpcomingTeamMini extends StatelessWidget {
  final String name;
  final String? shortName;
  final String? flagUrl;
  final bool alignEnd;

  const _UpcomingTeamMini({
    required this.name,
    required this.shortName,
    required this.flagUrl,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final label = shortName?.trim().isNotEmpty == true ? shortName! : name;

    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!alignEnd) _FlagBubble(flagUrl: flagUrl),
        if (!alignEnd) const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment:
                alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: alignEnd ? TextAlign.end : TextAlign.start,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: alignEnd ? TextAlign.end : TextAlign.start,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (alignEnd) const SizedBox(width: 8),
        if (alignEnd) _FlagBubble(flagUrl: flagUrl),
      ],
    );
  }
}

class _AlreadyPredictedBox extends StatelessWidget {
  const _AlreadyPredictedBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.22),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppTheme.gold,
            size: 19,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Prediction submitted. Wait for others to predict.',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextPredictionPrizeData {
  final FixtureModel match;
  final MatchPrizePoolModel? prizePool;
  final UserMatchPrediction? userPrediction;

  const _NextPredictionPrizeData({
    required this.match,
    required this.prizePool,
    required this.userPrediction,
  });
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.teal.withOpacity(0.95),
                  AppTheme.blue.withOpacity(0.95),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.teal.withOpacity(0.24),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.leaderboard_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Predictions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Check the prize and predict the next match.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _MatchFilterCard extends StatelessWidget {
  final List<PredictionMatchFilter> matches;
  final String? selectedMatchId;
  final PredictionMatchFilter? selectedMatch;
  final int totalPredictions;
  final bool loading;
  final ValueChanged<String?> onChanged;

  const _MatchFilterCard({
    required this.matches,
    required this.selectedMatchId,
    required this.selectedMatch,
    required this.totalPredictions,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final match = selectedMatch;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface2.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.teal.withOpacity(0.075),
            AppTheme.surface2.withOpacity(0.96),
            AppTheme.surface.withOpacity(0.96),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by completed match',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 9),
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
                iconEnabledColor: AppTheme.teal,
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
            const SizedBox(height: 13),
            _SelectedFixtureMini(match: match),
            const SizedBox(height: 12),
            Row(
              children: [
                Flexible(
                  child: _MiniInfoPill(
                    icon: Icons.groups_rounded,
                    label: '$totalPredictions predictions',
                    color: AppTheme.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: _MiniInfoPill(
                    icon: Icons.emoji_events_rounded,
                    label: 'Final ${match.scoreText}',
                    color: AppTheme.gold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectedFixtureMini extends StatelessWidget {
  final PredictionMatchFilter match;

  const _SelectedFixtureMini({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TeamMini(
            name: match.teamAName,
            shortName: match.teamAShortName,
            flagUrl: match.teamAFlagUrl,
            alignEnd: false,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppTheme.gold.withOpacity(0.20)),
          ),
          child: Text(
            match.scoreText,
            style: const TextStyle(
              color: AppTheme.gold,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: _TeamMini(
            name: match.teamBName,
            shortName: match.teamBShortName,
            flagUrl: match.teamBFlagUrl,
            alignEnd: true,
          ),
        ),
      ],
    );
  }
}

class _TeamMini extends StatelessWidget {
  final String name;
  final String? shortName;
  final String? flagUrl;
  final bool alignEnd;

  const _TeamMini({
    required this.name,
    required this.shortName,
    required this.flagUrl,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final label = shortName?.trim().isNotEmpty == true ? shortName! : name;

    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!alignEnd) _FlagBubble(flagUrl: flagUrl),
        if (!alignEnd) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (alignEnd) const SizedBox(width: 8),
        if (alignEnd) _FlagBubble(flagUrl: flagUrl),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final PredictionMatchFilter? match;
  final List<PredictionModel> predictions;

  const _SummaryStrip({
    required this.match,
    required this.predictions,
  });

  @override
  Widget build(BuildContext context) {
    final topPoints = predictions.isEmpty
        ? 0
        : predictions.map((item) => item.points).reduce((a, b) => a > b ? a : b);

    final exactScores =
        predictions.where((item) => item.exactScorePoints > 0).length;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Players',
            value: '${predictions.length}',
            icon: Icons.groups_rounded,
            color: AppTheme.blue,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _StatTile(
            label: 'Top Points',
            value: '$topPoints',
            icon: Icons.workspace_premium_rounded,
            color: AppTheme.gold,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _StatTile(
            label: 'Exact',
            value: '$exactScores',
            icon: Icons.check_circle_rounded,
            color: AppTheme.teal,
          ),
        ),
      ],
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final int rank;
  final PredictionModel prediction;

  const _PredictionCard({
    required this.rank,
    required this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    final hasPoints = prediction.isEvaluated;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.surface2.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.075)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rank == 1
                ? AppTheme.gold.withOpacity(0.075)
                : AppTheme.teal.withOpacity(0.045),
            AppTheme.surface2.withOpacity(0.96),
            AppTheme.surface.withOpacity(0.96),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _RankBadge(rank: rank),
              const SizedBox(width: 10),
              _UserAvatar(prediction: prediction),
              const SizedBox(width: 10),
              Expanded(
                child: _UserInfo(prediction: prediction),
              ),
              const SizedBox(width: 8),
              _PointsBadge(
                text: hasPoints ? '${prediction.points} pts' : 'Pending',
                color: !hasPoints
                    ? AppTheme.blue
                    : prediction.points > 0
                        ? AppTheme.gold
                        : Colors.white38,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.045),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.065)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PredictionTeamText(
                        name: prediction.teamAName,
                        shortName: prediction.teamAShortName,
                        flagUrl: prediction.teamAFlagUrl,
                        alignEnd: false,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.teal.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: AppTheme.teal.withOpacity(0.20),
                        ),
                      ),
                      child: Text(
                        prediction.scoreText,
                        style: const TextStyle(
                          color: AppTheme.teal,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _PredictionTeamText(
                        name: prediction.teamBName,
                        shortName: prediction.teamBShortName,
                        flagUrl: prediction.teamBFlagUrl,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SmallDetail(
                        icon: Icons.sports_soccer_rounded,
                        label: 'Scorer',
                        value: prediction.scorerName ?? '—',
                        color: AppTheme.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SmallDetail(
                        icon: Icons.schedule_rounded,
                        label: 'Submitted',
                        value: DateTimeUtils.format(prediction.submittedAt),
                        color: AppTheme.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (prediction.isEvaluated) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _BreakdownPill(
                  label: 'Score',
                  value: prediction.exactScorePoints,
                  color: AppTheme.teal,
                ),
                const SizedBox(width: 7),
                _BreakdownPill(
                  label: 'Scorer',
                  value: prediction.playerPoints,
                  color: AppTheme.blue,
                ),
                const SizedBox(width: 7),
                _BreakdownPill(
                  label: 'Time',
                  value: prediction.timePoints,
                  color: AppTheme.gold,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UserInfo extends StatelessWidget {
  final PredictionModel prediction;

  const _UserInfo({
    required this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          prediction.displayUserName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          prediction.userPhone ?? prediction.userEmail ?? 'Prediction player',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final isTop = rank == 1;

    return Container(
      height: 34,
      width: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTop
            ? AppTheme.gold.withOpacity(0.16)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isTop
              ? AppTheme.gold.withOpacity(0.30)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          color: isTop ? AppTheme.gold : Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final PredictionModel prediction;

  const _UserAvatar({
    required this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = prediction.userAvatarUrl;

    return Container(
      height: 42,
      width: 42,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.teal.withOpacity(0.95),
            AppTheme.blue.withOpacity(0.95),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: avatar == null
          ? Center(
              child: Text(
                prediction.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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
                    prediction.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _PredictionTeamText extends StatelessWidget {
  final String name;
  final String? shortName;
  final String? flagUrl;
  final bool alignEnd;

  const _PredictionTeamText({
    required this.name,
    required this.shortName,
    required this.flagUrl,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final label = shortName?.trim().isNotEmpty == true ? shortName! : name;

    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!alignEnd) _FlagBubble(flagUrl: flagUrl),
        if (!alignEnd) const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (alignEnd) const SizedBox(width: 7),
        if (alignEnd) _FlagBubble(flagUrl: flagUrl),
      ],
    );
  }
}

class _FlagBubble extends StatelessWidget {
  final String? flagUrl;

  const _FlagBubble({
    required this.flagUrl,
  });

  @override
  Widget build(BuildContext context) {
    final url = flagUrl?.trim();
    final isSvg = url != null && url.toLowerCase().endsWith('.svg');

    return Container(
      height: 24,
      width: 24,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: url == null || url.isEmpty || isSvg
          ? const Icon(
              Icons.flag_rounded,
              size: 13,
              color: Colors.white38,
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) {
                return const Icon(
                  Icons.flag_rounded,
                  size: 13,
                  color: Colors.white38,
                );
              },
            ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _PointsBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 64),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SmallDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SmallDetail({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.075),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color.withOpacity(0.92),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.085),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.16)),
        ),
        child: Text(
          '$label: $value',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.surface2.withOpacity(0.94),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white.withOpacity(0.075)),
      ),
      child: Row(
        children: [
          Container(
            height: 31,
            width: 31,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
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
    return Container(
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
        color: AppTheme.surface2.withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: const SizedBox(
        height: 28,
        width: 28,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: AppTheme.teal,
        ),
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