import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/match_prize_pool_card.dart';
import '../../core/widgets/sponsor_banner_section.dart';
import '../../core/widgets/team_flag.dart';
import '../../models/fixture_model.dart';
import '../../models/match_prize_pool_model.dart';
import '../../models/sponsor_banner_model.dart';
import '../../services/fixture_service.dart';
import '../../services/prediction_service.dart';
import '../../services/sponsor_banner_service.dart';


class FixturesScreen extends StatefulWidget {
  const FixturesScreen({super.key});

  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> {
  late Future<List<FixtureModel>> future;
  bool _isRefreshing = false;
  int _refreshTick = 0;

  @override
  void initState() {
    super.initState();
    future = loadFixtures();
  }

  Future<List<FixtureModel>> loadFixtures() async {
    final fixtures = await FixtureService().allFixtures();

    fixtures.sort(
      (a, b) => a.matchStartAt.compareTo(b.matchStartAt),
    );

    return fixtures;
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    SponsorBannerService.instance.clearCache();

    final refreshed = loadFixtures();

    if (mounted) {
      setState(() {
        _refreshTick++;
        future = refreshed;
      });
    }

    try {
      await refreshed;
    } catch (_) {
      // FutureBuilder will show the error.
      // Do not crash RefreshIndicator.
    } finally {
      _isRefreshing = false;
    }
  }

  bool canPredict(FixtureModel fixture) {
    final now = DateTime.now();
    final start = fixture.matchStartAt.toLocal();
    final diff = start.difference(now);
    final status = fixture.status.toLowerCase();

    final isWithinNext24Hours =
        !diff.isNegative && diff <= const Duration(hours: 24);

    return status == 'upcoming' &&
        isWithinNext24Hours &&
        !fixture.isLocked;
  }

  List<Object> buildListItems(List<FixtureModel> fixtures) {
    final items = <Object>[];
    DateTime? lastDate;
    int matchCount = 0;
    bool middleBannerInserted = false;

    for (final fixture in fixtures) {
      final currentDate = fixture.matchStartAt.toLocal();

      if (!_sameLocalDate(lastDate, currentDate)) {
        items.add(_DateHeaderItem(DateTimeUtils.dateOnly(currentDate)));
        lastDate = currentDate;
      }

      items.add(_FixtureItem(fixture));
      matchCount++;

      if (!middleBannerInserted && matchCount == 10) {
        items.add(
          const _BannerItem(
            placement: SponsorBannerPlacement.fixtures,
            slot: SponsorBannerSlot.middle,
            height: 96,
          ),
        );
        middleBannerInserted = true;
      }
    }

    return items;
  }

  bool _sameLocalDate(DateTime? a, DateTime b) {
    if (a == null) return false;

    final x = a.toLocal();
    final y = b.toLocal();

    return x.year == y.year && x.month == y.month && x.day == y.day;
  }

  List<Widget> _headerAndTopBanner() {
    return [
      const _PageHeader(),
      const SizedBox(height: 16),
      SponsorBannerSection(
        key: ValueKey('fixtures-top-banner-$_refreshTick'),
        placement: SponsorBannerPlacement.fixtures,
        slot: SponsorBannerSlot.top,
        height: 104,
        limit: 5,
        autoPlay: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _FixturesBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
              color: AppTheme.teal,
              backgroundColor: AppTheme.surface2,
              displacement: 42,
              edgeOffset: 4,
              triggerMode: RefreshIndicatorTriggerMode.onEdge,
              onRefresh: refresh,
              child: FutureBuilder<List<FixtureModel>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }

                if (snapshot.hasError) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                    children: [
                      ..._headerAndTopBanner(),
                      const SizedBox(height: 18),
                      _StateCard(
                        icon: Icons.error_outline_rounded,
                        title: 'Could not load fixtures',
                        message: '${snapshot.error}',
                        buttonLabel: 'Retry',
                        onPressed: refresh,
                      ),
                    ],
                  );
                }

                final fixtures = snapshot.data ?? <FixtureModel>[];

                if (fixtures.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                    children: [
                      ..._headerAndTopBanner(),
                      const SizedBox(height: 18),
                      _StateCard(
                        icon: Icons.event_busy_rounded,
                        title: 'No fixtures found',
                        message: 'Fixtures will appear here once added.',
                        buttonLabel: 'Refresh',
                        onPressed: refresh,
                      ),
                    ],
                  );
                }

                final items = buildListItems(fixtures);

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 110),
                  itemCount: items.length + 3,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const _PageHeader();
                    }

                    if (index == 1) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 2),
                        child: SponsorBannerSection(
                          placement: SponsorBannerPlacement.fixtures,
                          slot: SponsorBannerSlot.top,
                          height: 104,
                          limit: 5,
                          autoPlay: true,
                        ),
                      );
                    }

                    final item = items[index - 2];

                    if (item is _DateHeaderItem) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 18, bottom: 9),
                        child: _DateHeader(label: item.label),
                      );
                    }

                    if (item is _BannerItem) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 16),
                        child: SponsorBannerSection(
                          key: ValueKey('fixtures-${item.slot}-banner-$_refreshTick'),
                          placement: item.placement,
                          slot: item.slot,
                          height: item.height,
                          limit: 5,
                          autoPlay: true,
                        ),
                      );
                    }

                    if (item is _FixtureItem) {
                      final fixture = item.fixture;
                      final enabled = canPredict(fixture);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FixtureTile(
                          fixture: fixture,
                          canPredict: enabled,
                          refreshTick: _refreshTick,
                          onTap: enabled
                              ? () => context.push('/fixtures/${fixture.id}')
                              : null,
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FixturesBackground extends StatelessWidget {
  final Widget child;

  const _FixturesBackground({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF071A22),
            Color(0xFF06111E),
            Color(0xFF02070D),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -150,
            child: _GlowBlob(
              color: AppTheme.teal,
              size: 320,
              opacity: 0.15,
            ),
          ),
          Positioned(
            bottom: 120,
            left: -180,
            child: _GlowBlob(
              color: AppTheme.blue,
              size: 300,
              opacity: 0.09,
            ),
          ),
          Positioned(
            bottom: -160,
            right: -170,
            child: _GlowBlob(
              color: AppTheme.gold,
              size: 300,
              opacity: 0.06,
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
            spreadRadius: 44,
          ),
        ],
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
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(
              colors: [
                AppTheme.teal,
                AppTheme.tealDark,
              ],
            ),
          ),
          child: const Icon(
            Icons.sports_soccer_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fixtures',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'All matches sorted by date',
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
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String label;

  const _DateHeader({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 7,
          width: 7,
          decoration: const BoxDecoration(
            color: AppTheme.teal,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ],
    );
  }
}

class _FixtureTile extends StatelessWidget {
  final FixtureModel fixture;
  final bool canPredict;
  final int refreshTick;
  final VoidCallback? onTap;

  const _FixtureTile({
    required this.fixture,
    required this.canPredict,
    required this.refreshTick,
    required this.onTap,
  });

  bool get hasScore {
    return fixture.teamAScore != null && fixture.teamBScore != null;
  }

  bool get isCompleted {
    final status = fixture.status.toLowerCase();
    return status == 'completed' || status == 'finalized';
  }

  @override
  Widget build(BuildContext context) {
    final scoreText = hasScore
        ? '${fixture.teamAScore} - ${fixture.teamBScore}'
        : 'VS';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: canPredict ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: canPredict || isCompleted ? 1 : 0.70,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF091827).withOpacity(0.96),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: canPredict
                    ? AppTheme.teal.withOpacity(0.26)
                    : Colors.white.withOpacity(0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _TimeStatusBlock(
                      fixture: fixture,
                      canPredict: canPredict,
                      isCompleted: isCompleted,
                    ),
                    const Spacer(),
                    Text(
                      fixture.stage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _TeamMini(
                        flagUrl: fixture.teamAFlagUrl,
                        shortName: fixture.teamAShort,
                        name: fixture.teamAName,
                        alignEnd: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ScoreBox(
                      scoreText: scoreText,
                      hasScore: hasScore,
                      isCompleted: isCompleted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TeamMini(
                        flagUrl: fixture.teamBFlagUrl,
                        shortName: fixture.teamBShort,
                        name: fixture.teamBName,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),

                if (canPredict) ...[
                  const SizedBox(height: 12),
                  _FixturePrizePool(
                    matchId: fixture.id,
                    refreshTick: refreshTick,
                  ),
                ],

                const SizedBox(height: 12),
                if (isCompleted)
                  _ResultFooter(hasScore: hasScore)
                else
                  _PredictFooter(
                    canPredict: canPredict,
                    onTap: onTap,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FixturePrizePool extends StatefulWidget {
  final String matchId;
  final int refreshTick;

  const _FixturePrizePool({
    required this.matchId,
    required this.refreshTick,
  });

  @override
  State<_FixturePrizePool> createState() => _FixturePrizePoolState();
}

class _FixturePrizePoolState extends State<_FixturePrizePool> {
  final _service = PredictionService();

  late Future<MatchPrizePoolModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.matchPrizePool(widget.matchId);
  }

  @override
  void didUpdateWidget(covariant _FixturePrizePool oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.matchId != widget.matchId ||
        oldWidget.refreshTick != widget.refreshTick) {
      _future = _service.matchPrizePool(widget.matchId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MatchPrizePoolModel?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MatchPrizePoolCard(
            prizePool: null,
            loading: true,
          );
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final prizePool = snapshot.data;

        if (prizePool == null) {
          return const SizedBox.shrink();
        }

        return MatchPrizePoolCard(
          prizePool: prizePool,
          loading: false,
        );
      },
    );
  }
}

class _TimeStatusBlock extends StatelessWidget {
  final FixtureModel fixture;
  final bool canPredict;
  final bool isCompleted;

  const _TimeStatusBlock({
    required this.fixture,
    required this.canPredict,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final color = canPredict
        ? AppTheme.teal
        : isCompleted
            ? AppTheme.gold
            : Colors.white38;

    final label = canPredict
        ? 'OPEN'
        : isCompleted
            ? 'DONE'
            : 'WAIT';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateTimeUtils.timeOnly(fixture.matchStartAt),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 20,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(100),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 5,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TeamMini extends StatelessWidget {
  final String? flagUrl;
  final String shortName;
  final String name;
  final bool alignEnd;

  const _TeamMini({
    required this.flagUrl,
    required this.shortName,
    required this.name,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isNotEmpty ? name.trim() : shortName;

    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!alignEnd) ...[
          TeamFlag(
            url: flagUrl,
            shortName: shortName,
            width: 34,
            height: 24,
            borderRadius: BorderRadius.circular(7),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.2,
              fontWeight: FontWeight.w900,
              height: 1.08,
              letterSpacing: 0.1,
            ),
          ),
        ),
        if (alignEnd) ...[
          const SizedBox(width: 8),
          TeamFlag(
            url: flagUrl,
            shortName: shortName,
            width: 34,
            height: 24,
            borderRadius: BorderRadius.circular(7),
          ),
        ],
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String scoreText;
  final bool hasScore;
  final bool isCompleted;

  const _ScoreBox({
    required this.scoreText,
    required this.hasScore,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isCompleted ? AppTheme.gold : AppTheme.teal;

    return Container(
      width: 72,
      height: 44,
      decoration: BoxDecoration(
        color: hasScore
            ? activeColor.withOpacity(0.12)
            : Colors.white.withOpacity(0.065),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasScore
              ? activeColor.withOpacity(0.24)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        scoreText,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: hasScore ? activeColor : Colors.white70,
          fontSize: hasScore ? 18 : 13,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: hasScore ? -0.2 : 0.6,
        ),
      ),
    );
  }
}

class _PredictFooter extends StatelessWidget {
  final bool canPredict;
  final VoidCallback? onTap;

  const _PredictFooter({
    required this.canPredict,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Center(
        child: SizedBox(
          height: 32,
          width: 118,
          child: FilledButton(
            onPressed: canPredict ? onTap : null,
            style: FilledButton.styleFrom(
              disabledBackgroundColor: Colors.white.withOpacity(0.07),
              disabledForegroundColor: Colors.white38,
              backgroundColor: AppTheme.tealDark,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text(
              'Predict Now',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultFooter extends StatelessWidget {
  final bool hasScore;

  const _ResultFooter({
    required this.hasScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.11),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.20),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        hasScore ? 'Final Result' : 'Completed',
        style: const TextStyle(
          color: AppTheme.gold,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF091827).withOpacity(0.94),
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
            style: const TextStyle(
              color: Colors.white60,
              height: 1.4,
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

class _DateHeaderItem {
  final String label;

  const _DateHeaderItem(this.label);
}

class _FixtureItem {
  final FixtureModel fixture;

  const _FixtureItem(this.fixture);
}

class _BannerItem {
  final String placement;
  final String slot;
  final double height;

  const _BannerItem({
    required this.placement,
    required this.slot,
    required this.height,
  });
}