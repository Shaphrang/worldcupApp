import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/team_flag.dart';

class HomePrizePoolMiniSection extends StatefulWidget {
  final void Function(String matchId)? onPredictTap;

  const HomePrizePoolMiniSection({
    super.key,
    required this.onPredictTap,
  });

  @override
  State<HomePrizePoolMiniSection> createState() =>
      _HomePrizePoolMiniSectionState();
}

class _HomePrizePoolMiniSectionState extends State<HomePrizePoolMiniSection> {
  static const Duration _refreshEvery = Duration(minutes: 5);

  Timer? _refreshTimer;
  _HomePrizePoolItem? _item;
  bool _initialLoading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _refresh(initial: true);

    _refreshTimer = Timer.periodic(
      _refreshEvery,
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool initial = false}) async {
    if (_refreshing) return;

    _refreshing = true;

    if (initial && mounted) {
      setState(() => _initialLoading = true);
    }

    try {
      final nextItem = await _loadPrizePoolSection();

      if (!mounted) return;

      setState(() {
        _item = nextItem;
        _initialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _item = null;
        _initialLoading = false;
      });
    } finally {
      _refreshing = false;
    }
  }

  Future<_HomePrizePoolItem?> _loadPrizePoolSection() async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_home_current_prize_pool',
      );

      Map<String, dynamic>? map;

      if (response is List && response.isNotEmpty) {
        map = Map<String, dynamic>.from(response.first as Map);
      } else if (response is Map) {
        map = Map<String, dynamic>.from(response);
      }

      if (map == null) return null;

      final item = _HomePrizePoolItem.fromMap(map);

      if (item.matchId.isEmpty) return null;
      if (!item.hasPrizePool) return null;

      return item;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const _PrizePoolLoadingCard();
    }

    final item = _item;

    if (item == null) {
      return const SizedBox.shrink();
    }

    return _SponsoredPrizePoolCard(
      item: item,
      onPredictTap: widget.onPredictTap,
    );
  }
}

class _HomePrizePoolItem {
  final String matchId;
  final String matchTitle;
  final String stage;

  final String teamAName;
  final String teamAShortName;
  final String? teamAFlagUrl;

  final String teamBName;
  final String teamBShortName;
  final String? teamBFlagUrl;

  final DateTime? matchStartAt;
  final DateTime? predictionLockAt;

  final String matchStatus;
  final bool isPredictionLocked;
  final int secondsToLock;
  final bool isCurrentMatch;
  final String displayMode;
  final int fansCount;

  final bool hasPrizePool;
  final String? prizePoolId;

  final String cardVariant;
  final String sponsorBadgeText;
  final String sponsorLabel;

  final String sponsorName;
  final String sponsorBusinessName;
  final String sponsorLocation;
  final String? sponsorLogoUrl;
  final String? sponsorHeroImageUrl;
  final String? sponsorLinkUrl;
  final String sponsorCtaText;

  final String prizeTitle;
  final String? description;
  final String rewardTitle;
  final String highlightText;

  final _RewardItem prize1;
  final _RewardItem prize2;
  final _RewardItem prize3;

  final String? terms;

  const _HomePrizePoolItem({
    required this.matchId,
    required this.matchTitle,
    required this.stage,
    required this.teamAName,
    required this.teamAShortName,
    required this.teamAFlagUrl,
    required this.teamBName,
    required this.teamBShortName,
    required this.teamBFlagUrl,
    required this.matchStartAt,
    required this.predictionLockAt,
    required this.matchStatus,
    required this.isPredictionLocked,
    required this.secondsToLock,
    required this.isCurrentMatch,
    required this.displayMode,
    required this.fansCount,
    required this.hasPrizePool,
    required this.prizePoolId,
    required this.cardVariant,
    required this.sponsorBadgeText,
    required this.sponsorLabel,
    required this.sponsorName,
    required this.sponsorBusinessName,
    required this.sponsorLocation,
    required this.sponsorLogoUrl,
    required this.sponsorHeroImageUrl,
    required this.sponsorLinkUrl,
    required this.sponsorCtaText,
    required this.prizeTitle,
    required this.description,
    required this.rewardTitle,
    required this.highlightText,
    required this.prize1,
    required this.prize2,
    required this.prize3,
    required this.terms,
  });

  factory _HomePrizePoolItem.fromMap(Map<String, dynamic> map) {
    final status = _readString(map['match_status'], fallback: 'upcoming');
    final predictionLockAt = _readDateTime(map['prediction_lock_at']);
    final now = DateTime.now();

    final lockedByStatus = _isLockedStatus(status);
    final lockedByTime =
        predictionLockAt != null && !now.isBefore(predictionLockAt);

    final businessName = _readString(
      map['sponsor_business_name'],
      fallback: _readString(map['sponsor_name']),
    );

    return _HomePrizePoolItem(
      matchId: _readString(map['match_id']),
      matchTitle: _readString(map['match_title']),
      stage: _readString(map['stage']),

      teamAName: _readString(map['team_a_name']),
      teamAShortName: _readString(map['team_a_short_name']),
      teamAFlagUrl: _readNullableString(map['team_a_flag_url']),

      teamBName: _readString(map['team_b_name']),
      teamBShortName: _readString(map['team_b_short_name']),
      teamBFlagUrl: _readNullableString(map['team_b_flag_url']),

      matchStartAt: _readDateTime(map['match_start_at']),
      predictionLockAt: predictionLockAt,

      matchStatus: status,
      isPredictionLocked:
          _readBool(map['is_prediction_locked']) || lockedByStatus || lockedByTime,
      secondsToLock: _readInt(map['seconds_to_lock']),
      isCurrentMatch: _readBool(map['is_current_match']),
      displayMode: _readString(map['display_mode']),
      fansCount: _readInt(map['fans_count']),

      hasPrizePool: _readBool(map['has_prize_pool']),
      prizePoolId: _readNullableString(map['prize_pool_id']),

      cardVariant: _readString(
        map['card_variant'],
        fallback: 'compact_offer',
      ),
      sponsorBadgeText: _readString(
        map['sponsor_badge_text'],
        fallback: 'SPONSORED',
      ),
      sponsorLabel: _readString(
        map['sponsor_label'],
        fallback: 'OFFICIAL MATCH SPONSOR',
      ),

      sponsorName: _readString(map['sponsor_name'], fallback: businessName),
      sponsorBusinessName: businessName,
      sponsorLocation: _readString(map['sponsor_location']),
      sponsorLogoUrl: _readNullableString(map['sponsor_logo_url']),
      sponsorHeroImageUrl: _readNullableString(
        map['sponsor_hero_image_url'],
        fallback: _readNullableString(map['banner_image_url']),
      ),
      sponsorLinkUrl: _readNullableString(map['sponsor_link_url']),
      sponsorCtaText: _readString(
        map['sponsor_cta_text'],
        fallback: 'Visit Sponsor',
      ),

      prizeTitle: _readString(map['prize_title']),
      description: _readNullableString(map['description']),
      rewardTitle: _readString(
        map['reward_title'],
        fallback: 'Prizes & Rewards',
      ),
      highlightText: _readString(
        map['highlight_text'],
        fallback: 'Predict and win exclusive gifts from our match partner.',
      ),

      prize1: _RewardItem(
        title: _readString(map['prize_1']),
        subtitle: _readString(map['prize_1_subtitle']),
      ),
      prize2: _RewardItem(
        title: _readString(map['prize_2']),
        subtitle: _readString(map['prize_2_subtitle']),
      ),
      prize3: _RewardItem(
        title: _readString(map['prize_3']),
        subtitle: _readString(map['prize_3_subtitle']),
      ),

      terms: _readNullableString(map['terms']),
    );
  }

  bool get canPredict {
    final status = matchStatus.trim().toLowerCase();
    return !isPredictionLocked && status == 'upcoming';
  }

  String get statusLabel {
    final status = matchStatus.trim().toLowerCase();

    if (isCurrentMatch || status == 'live' || status == 'ongoing') {
      return 'LIVE';
    }

    if (isPredictionLocked) {
      return 'LOCKED';
    }

    return 'OPEN';
  }

  String get shortStage {
    final value = stage.trim();
    if (value.isEmpty) return 'WORLD CUP';
    return value.toUpperCase();
  }

  String get fanText {
    if (fansCount >= 1000000) {
      final value = fansCount / 1000000;
      return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}M';
    }

    if (fansCount >= 1000) {
      final value = fansCount / 1000;
      return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}K';
    }

    return fansCount.toString();
  }

  List<_RewardItem> get rewards {
    return [
      if (prize1.hasText) prize1,
      if (prize2.hasText) prize2,
      if (prize3.hasText) prize3,
    ];
  }

  static bool _isLockedStatus(String value) {
    final status = value.trim().toLowerCase();

    return status == 'locked' ||
        status == 'live' ||
        status == 'ongoing' ||
        status == 'completed' ||
        status == 'finalized' ||
        status == 'finished' ||
        status == 'cancelled' ||
        status == 'canceled';
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _readNullableString(dynamic value, {String? fallback}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static bool _readBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;

    final text = value.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  static int _readInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    return DateTime.tryParse(text)?.toLocal();
  }
}

class _RewardItem {
  final String title;
  final String subtitle;

  const _RewardItem({
    required this.title,
    required this.subtitle,
  });

  bool get hasText => title.trim().isNotEmpty || subtitle.trim().isNotEmpty;
}

class _SponsoredPrizePoolCard extends StatelessWidget {
  final _HomePrizePoolItem item;
  final void Function(String matchId)? onPredictTap;

  const _SponsoredPrizePoolCard({
    required this.item,
    required this.onPredictTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF1B8),
            Color(0xFFE5FFF4),
            Color(0xFFFFF9DE),
            Color(0xFFDFFFF0),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFDCEFD7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF16A34A).withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -46,
            right: -38,
            child: _SoftBlob(
              size: 170,
              color: Color(0xFFFFD84D),
              opacity: 0.38,
            ),
          ),
          const Positioned(
            bottom: -52,
            left: -36,
            child: _SoftBlob(
              size: 160,
              color: Color(0xFF16C784),
              opacity: 0.22,
            ),
          ),
          const Positioned(
            top: 156,
            right: 18,
            child: _TinyDecorIcon(
              icon: Icons.sports_soccer_rounded,
              color: Color(0xFF16A34A),
            ),
          ),
          const Positioned(
            bottom: 96,
            left: 18,
            child: _TinyDecorIcon(
              icon: Icons.emoji_events_rounded,
              color: Color(0xFFEAB308),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 9, 9, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopSponsorBar(item: item),
                const SizedBox(height: 7),
                _SponsorHeroImage(item: item),
                const SizedBox(height: 8),
                _SponsorInfoNoLogo(item: item),
                const SizedBox(height: 10),
                _PrizeHeading(title: item.rewardTitle),
                const SizedBox(height: 8),
                _PrizeCards(item: item),
                const SizedBox(height: 9),
                _WorldCupMatchBanner(item: item),
                const SizedBox(height: 9),
                _BottomActions(
                  item: item,
                  onPredictTap: onPredictTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _SoftBlob({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }
}

class _TinyDecorIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _TinyDecorIcon({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: 44,
      color: color.withOpacity(0.07),
    );
  }
}

class _TopSponsorBar extends StatelessWidget {
  final _HomePrizePoolItem item;

  const _TopSponsorBar({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final badge = item.sponsorBadgeText.trim().isEmpty
        ? 'SPONSORED'
        : item.sponsorBadgeText.trim();

    return SizedBox(
      height: 25,
      child: Row(
        children: [
          Container(
            height: 25,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF07224A),
                  Color(0xFF021128),
                ],
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF021128).withOpacity(0.16),
                  blurRadius: 9,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFCF40),
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  badge.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => _openSponsorLink(context, item),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.sponsorCtaText.trim().isEmpty
                        ? 'VISIT SPONSOR'
                        : item.sponsorCtaText.trim().toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF007C68),
                      fontSize: 9.3,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.45,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.open_in_new_rounded,
                    color: Color(0xFF007C68),
                    size: 12,
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

class _SponsorHeroImage extends StatelessWidget {
  final _HomePrizePoolItem item;

  const _SponsorHeroImage({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.sponsorHeroImageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        height: 108,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.trim().isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _SponsorHeroFallback(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const _SponsorHeroFallback();
                },
              )
            else
              const _SponsorHeroFallback(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.00),
                    Colors.black.withOpacity(0.13),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsorHeroFallback extends StatelessWidget {
  const _SponsorHeroFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF0B5),
            Color(0xFFE1FFF1),
            Color(0xFFFFFBDE),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.storefront_rounded,
          color: Color(0xFF0F8F78),
          size: 31,
        ),
      ),
    );
  }
}

class _SponsorInfoNoLogo extends StatelessWidget {
  final _HomePrizePoolItem item;

  const _SponsorInfoNoLogo({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final businessName = item.sponsorBusinessName.trim().isNotEmpty
        ? item.sponsorBusinessName.trim()
        : item.sponsorName.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.sponsorLabel.trim().isNotEmpty) ...[
            Text(
              item.sponsorLabel.trim().toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF9A6B0B),
                fontSize: 7.4,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.48,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
          ],
          Text(
            businessName.isEmpty ? 'Match Sponsor' : businessName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF07152F),
              fontSize: 17.8,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.38,
              height: 1,
            ),
          ),
          if (item.sponsorLocation.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF008C73),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.sponsorLocation.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
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

class _PrizeHeading extends StatelessWidget {
  final String title;

  const _PrizeHeading({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final text = title.trim().isEmpty ? 'Prizes & Rewards' : title.trim();

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF008C73).withOpacity(0.42),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
        const Icon(
          Icons.card_giftcard_rounded,
          color: Color(0xFF008C73),
          size: 14,
        ),
        const SizedBox(width: 5),
        Flexible(
          flex: 0,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF07152F),
              fontSize: 10.8,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.06,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF008C73).withOpacity(0.42),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrizeCards extends StatelessWidget {
  final _HomePrizePoolItem item;

  const _PrizeCards({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final rewards = item.rewards;

    if (rewards.isEmpty) {
      return const SizedBox.shrink();
    }

    final safeRewards = [
      rewards.isNotEmpty
          ? rewards[0]
          : const _RewardItem(title: '', subtitle: ''),
      rewards.length > 1
          ? rewards[1]
          : const _RewardItem(title: '', subtitle: ''),
      rewards.length > 2
          ? rewards[2]
          : const _RewardItem(title: '', subtitle: ''),
    ];

    return Row(
      children: [
        Expanded(child: _PrizeCard(reward: safeRewards[0], index: 0)),
        const SizedBox(width: 6),
        Expanded(child: _PrizeCard(reward: safeRewards[1], index: 1)),
        const SizedBox(width: 6),
        Expanded(child: _PrizeCard(reward: safeRewards[2], index: 2)),
      ],
    );
  }
}

class _PrizeCard extends StatelessWidget {
  final _RewardItem reward;
  final int index;

  const _PrizeCard({
    required this.reward,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _PrizePalette.fromIndex(index);

    final rank = index == 0
        ? '1ST PRIZE'
        : index == 1
            ? '2ND PRIZE'
            : '3RD PRIZE';

    final title =
        reward.title.trim().isEmpty ? 'Reward Text' : reward.title.trim();

    final subtitle =
        reward.subtitle.trim().isEmpty ? 'Placeholder' : reward.subtitle.trim();

    return Container(
      height: 88,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.gradient,
        ),
        border: Border.all(
          color: palette.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withOpacity(0.13),
            blurRadius: 11,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -26,
            child: Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.glow.withOpacity(0.24),
              ),
            ),
          ),
          Positioned(
            left: -28,
            bottom: -30,
            child: Container(
              height: 74,
              width: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.42),
              ),
            ),
          ),
          Positioned(
            right: 9,
            bottom: 8,
            child: Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.accent.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    palette.accent.withOpacity(0.10),
                    palette.accent.withOpacity(0.88),
                    palette.accent.withOpacity(0.10),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
            child: Column(
              children: [
                Text(
                  rank,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.dark,
                    fontSize: 9.9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.35,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  width: double.infinity,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        palette.accent.withOpacity(0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF07152F),
                    fontSize: 11.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.18,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Center(
                    child: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 8.7,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                      ),
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

class _PrizePalette {
  final List<Color> gradient;
  final Color border;
  final Color soft;
  final Color dark;
  final Color shadow;
  final Color accent;
  final Color glow;
  final Color icon;

  const _PrizePalette({
    required this.gradient,
    required this.border,
    required this.soft,
    required this.dark,
    required this.shadow,
    required this.accent,
    required this.glow,
    required this.icon,
  });

  factory _PrizePalette.fromIndex(int index) {
    const palettes = [
      // 1ST PRIZE - Yellow / Gold
      _PrizePalette(
        gradient: [
          Color(0xFFFFFEF6),
          Color(0xFFFFF0B6),
          Color(0xFFFFF9DE),
        ],
        border: Color(0xFFE6BD43),
        soft: Color(0xFFD6A21F),
        dark: Color(0xFF875A05),
        shadow: Color(0xFFD6A21F),
        accent: Color(0xFFD6A21F),
        glow: Color(0xFFFFD84D),
        icon: Color(0xFFD6A21F),
      ),

      // 2ND PRIZE - Green
      _PrizePalette(
        gradient: [
          Color(0xFFF2FFF7),
          Color(0xFFD7F8E3),
          Color(0xFFEEFFF5),
        ],
        border: Color(0xFF90D9AA),
        soft: Color(0xFF16A34A),
        dark: Color(0xFF14532D),
        shadow: Color(0xFF16A34A),
        accent: Color(0xFF16A34A),
        glow: Color(0xFF86EFAC),
        icon: Color(0xFF15803D),
      ),

      // 3RD PRIZE - Red
      _PrizePalette(
        gradient: [
          Color(0xFFFFF6F6),
          Color(0xFFFFDCDC),
          Color(0xFFFFF0F0),
        ],
        border: Color(0xFFF09A9A),
        soft: Color(0xFFDC2626),
        dark: Color(0xFF991B1B),
        shadow: Color(0xFFDC2626),
        accent: Color(0xFFDC2626),
        glow: Color(0xFFFCA5A5),
        icon: Color(0xFFB91C1C),
      ),
    ];

    return palettes[index % palettes.length];
  }
}

class _WorldCupMatchBanner extends StatelessWidget {
  final _HomePrizePoolItem item;

  const _WorldCupMatchBanner({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF08D9C4),
            Color(0xFFEFFFFF),
            Color(0xFFFFF9FB),
            Color(0xFFFF4F8B),
          ],
          stops: [0.0, 0.42, 0.64, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFFF4F8B).withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: _BrightWorldCupFixtureBackground(),
          ),

          Positioned(
            top: 7,
            left: 0,
            right: 0,
            child: Center(
              child: _StagePill(label: item.shortStage),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 29, 12, 9),
            child: Row(
              children: [
                Expanded(
                  child: _MatchTeamPremium(
                    flagUrl: item.teamAFlagUrl,
                    shortName: item.teamAShortName,
                    name: item.teamAName,
                  ),
                ),

                SizedBox(
                  width: 88,
                  child: _CenterVs(item: item),
                ),

                Expanded(
                  child: _MatchTeamPremium(
                    flagUrl: item.teamBFlagUrl,
                    shortName: item.teamBShortName,
                    name: item.teamBName,
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

class _BrightWorldCupFixtureBackground extends StatelessWidget {
  const _BrightWorldCupFixtureBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _FixtureArcPainter(),
          ),
        ),

        Positioned(
          left: -38,
          bottom: -28,
          child: Container(
            width: 146,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.56),
                  Colors.white.withOpacity(0.00),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          right: -36,
          bottom: -30,
          child: Container(
            width: 150,
            height: 74,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFD54A).withOpacity(0.70),
                  const Color(0xFFFF9800).withOpacity(0.00),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          left: -20,
          top: -18,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.13),
            ),
          ),
        ),

        Positioned(
          right: -20,
          top: -14,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.13),
            ),
          ),
        ),

        Positioned(
          left: 12,
          top: 15,
          child: Icon(
            Icons.stadium_rounded,
            color: Colors.white.withOpacity(0.24),
            size: 58,
          ),
        ),

        Positioned(
          right: 13,
          top: 13,
          child: Icon(
            Icons.stadium_rounded,
            color: Colors.white.withOpacity(0.20),
            size: 58,
          ),
        ),

        Positioned(
          right: 20,
          bottom: 8,
          child: Icon(
            Icons.emoji_events_rounded,
            color: Colors.white.withOpacity(0.18),
            size: 42,
          ),
        ),

        const Positioned(
          left: 15,
          top: 23,
          child: _TinySpark(color: Colors.white),
        ),

        const Positioned(
          left: 55,
          top: 17,
          child: _TinySpark(color: Color(0xFFFFD54A)),
        ),

        const Positioned(
          left: 86,
          bottom: 24,
          child: _TinySpark(color: Color(0xFF00B4D8)),
        ),

        const Positioned(
          right: 64,
          top: 20,
          child: _TinySpark(color: Color(0xFFE11D48)),
        ),

        const Positioned(
          right: 24,
          bottom: 24,
          child: _TinySpark(color: Colors.white),
        ),

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.white.withOpacity(0.18),
                  Colors.white.withOpacity(0.00),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FixtureArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()
      ..color = Colors.white.withOpacity(0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final thinPaint = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final leftArc = Path()
      ..moveTo(-20, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 1.05,
        size.width * 0.43,
        size.height * 0.76,
      );

    final rightArc = Path()
      ..moveTo(size.width * 0.56, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 1.06,
        size.width + 22,
        size.height * 0.72,
      );

    final topSweep = Path()
      ..moveTo(size.width * 0.04, size.height * 0.06)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.18,
        size.width * 0.50,
        size.height * 0.02,
      );

    final rightSweep = Path()
      ..moveTo(size.width * 0.58, size.height * 0.06)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.15,
        size.width * 0.97,
        size.height * 0.08,
      );

    canvas.drawPath(leftArc, whitePaint);
    canvas.drawPath(rightArc, whitePaint);
    canvas.drawPath(topSweep, thinPaint);
    canvas.drawPath(rightSweep, thinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StagePill extends StatelessWidget {
  final String label;

  const _StagePill({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF061B3D),
            Color(0xFF082A5C),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF061B3D).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFFFFD54A),
            size: 13,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8.8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchTeamPremium extends StatelessWidget {
  final String? flagUrl;
  final String shortName;
  final String name;

  const _MatchTeamPremium({
    required this.flagUrl,
    required this.shortName,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final label = name.trim().isNotEmpty ? name.trim() : shortName.trim();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.78),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TeamFlag(
            url: flagUrl,
            shortName: shortName,
            width: 58,
            height: 37,
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        const SizedBox(height: 7),

        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF07152F),
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.18,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _CenterVs extends StatelessWidget {
  final _HomePrizePoolItem item;

  const _CenterVs({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = item.statusLabel == 'LIVE';

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          'VS',
          style: TextStyle(
            color: Color(0xFF061B3D),
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
            height: 1,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: isLive
                    ? const Color(0xFFE11D48)
                    : const Color(0xFF009B77),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isLive
                            ? const Color(0xFFE11D48)
                            : const Color(0xFF009B77))
                        .withOpacity(0.35),
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                isLive ? 'Live now' : 'Live from World Cup',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF008C73),
                  fontSize: 8.8,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TinySpark extends StatelessWidget {
  final Color color;

  const _TinySpark({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.65,
      child: Container(
        width: 4,
        height: 9,
        decoration: BoxDecoration(
          color: color.withOpacity(0.85),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}


class _BottomActions extends StatelessWidget {
  final _HomePrizePoolItem item;
  final void Function(String matchId)? onPredictTap;

  const _BottomActions({
    required this.item,
    required this.onPredictTap,
  });

  @override
  Widget build(BuildContext context) {
    final canPredict = item.canPredict && onPredictTap != null;

    return Row(
      children: [
        Expanded(
          flex: 7,
          child: _PredictorsCount(item: item),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 13,
          child: _PredictNowButton(
            item: item,
            canPredict: canPredict,
            onPredictTap: onPredictTap,
          ),
        ),
      ],
    );
  }
}

class _PredictorsCount extends StatelessWidget {
  final _HomePrizePoolItem item;

  const _PredictorsCount({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final label = item.fansCount == 1 ? 'Predictor' : 'Predictors';

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFCDEDDD)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.groups_rounded,
            color: Color(0xFF008C73),
            size: 18,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fanText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF008C73),
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 7.4,
                    fontWeight: FontWeight.w800,
                    height: 1,
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

class _PredictNowButton extends StatelessWidget {
  final _HomePrizePoolItem item;
  final bool canPredict;
  final void Function(String matchId)? onPredictTap;

  const _PredictNowButton({
    required this.item,
    required this.canPredict,
    required this.onPredictTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: canPredict ? () => onPredictTap!(item.matchId) : null,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          gradient: canPredict
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFFF006E),
                    Color(0xFFFF5C61),
                    Color(0xFFFF9800),
                  ],
                )
              : null,
          color: canPredict ? null : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
          boxShadow: canPredict
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF006E).withOpacity(0.17),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              canPredict ? Icons.sports_soccer_rounded : Icons.lock_rounded,
              color: canPredict ? Colors.white : const Color(0xFF94A3B8),
              size: 16,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                canPredict ? 'PREDICT NOW' : 'PREDICTION LOCKED',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: canPredict ? Colors.white : const Color(0xFF94A3B8),
                  fontSize: 11.1,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.62,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openSponsorLink(
  BuildContext context,
  _HomePrizePoolItem item,
) async {
  final rawLink = item.sponsorLinkUrl?.trim();

  if (rawLink == null || rawLink.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sponsor link is not available.'),
      ),
    );
    return;
  }

  final uri = Uri.tryParse(rawLink);

  if (uri == null || !uri.hasScheme) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid sponsor link.'),
      ),
    );
    return;
  }

  final launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open sponsor link.'),
      ),
    );
  }
}

class _PrizePoolLoadingCard extends StatelessWidget {
  const _PrizePoolLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 136,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFFCFEFF),
        border: Border.all(color: const Color(0xFFE6EEF5)),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        height: 19,
        width: 19,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF009B77),
        ),
      ),
    );
  }
}