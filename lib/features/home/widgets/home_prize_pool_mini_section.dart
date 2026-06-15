import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/team_flag.dart';
import '../../../models/fixture_model.dart';

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
  late Future<_HomePrizePoolItem?> _future;
  Timer? _refreshTimer;

  static const Duration _currentMatchWindow = Duration(
    hours: 2,
    minutes: 30,
  );

  @override
  void initState() {
    super.initState();

    _future = _loadPrizePoolSection();

    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (!mounted) return;

        setState(() {
          _future = _loadPrizePoolSection();
        });
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<_HomePrizePoolItem?> _loadPrizePoolSection() async {
    try {
      final client = Supabase.instance.client;
      final now = DateTime.now();

      final fromTime = now
          .subtract(const Duration(hours: 4))
          .toUtc()
          .toIso8601String();

      final rows = await client
          .from('fixtures_view')
          .select()
          .gte('match_start_at', fromTime)
          .order('match_start_at', ascending: true)
          .limit(80);

      final matches = (rows as List)
          .map(
            (row) => FixtureModel.fromMap(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .where((match) => !_isFinished(match))
          .toList();

      if (matches.isEmpty) return null;

      final currentMatches = matches.where(_isCurrentlyPlaying).toList()
        ..sort((a, b) => b.matchStartAt.compareTo(a.matchStartAt));

      final upcomingMatches = matches.where(_isUpcoming).toList()
        ..sort((a, b) => a.matchStartAt.compareTo(b.matchStartAt));

      final selectedMatch = currentMatches.isNotEmpty
          ? currentMatches.first
          : upcomingMatches.isNotEmpty
              ? upcomingMatches.first
              : null;

      if (selectedMatch == null) return null;

      final prizePool = await _readPrizePool(selectedMatch.id);

      return _HomePrizePoolItem(
        match: selectedMatch,
        isCurrentMatch: _isCurrentlyPlaying(selectedMatch),
        prizePool: prizePool,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _readPrizePool(String matchId) async {
    try {
      final client = Supabase.instance.client;

      final response = await client
          .from('match_prize_pools')
          .select()
          .eq('match_id', matchId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final map = Map<String, dynamic>.from(response as Map);

      if (!_isPrizePoolActiveNow(map)) {
        return null;
      }

      return map;
    } catch (_) {
      return null;
    }
  }

  bool _isCurrentlyPlaying(FixtureModel match) {
    final status = match.status.trim().toLowerCase();
    final now = DateTime.now();

    if (status == 'live' || status == 'ongoing') {
      return true;
    }

    if (_isFinished(match)) {
      return false;
    }

    final estimatedEnd = match.matchStartAt.add(_currentMatchWindow);

    return !now.isBefore(match.matchStartAt) && now.isBefore(estimatedEnd);
  }

  bool _isUpcoming(FixtureModel match) {
    final status = match.status.trim().toLowerCase();
    final now = DateTime.now();

    return now.isBefore(match.matchStartAt) &&
        (status == 'upcoming' || status == 'locked');
  }

  bool _isFinished(FixtureModel match) {
    final status = match.status.trim().toLowerCase();

    return status == 'completed' ||
        status == 'finalized' ||
        status == 'finished' ||
        status == 'cancelled' ||
        status == 'canceled';
  }

  bool _isPrizePoolActiveNow(Map<String, dynamic> map) {
    final now = DateTime.now();

    final startsAt = _readDateTime(map['starts_at']);
    final endsAt = _readDateTime(map['ends_at']);

    if (startsAt != null && now.isBefore(startsAt)) return false;
    if (endsAt != null && now.isAfter(endsAt)) return false;

    return true;
  }

  DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    return DateTime.tryParse(text)?.toLocal();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomePrizePoolItem?>(
      future: _future,
      builder: (context, snapshot) {
        final item = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _PrizePoolLoadingCard();
        }

        if (item == null) {
          return const SizedBox.shrink();
        }

        return _PrizePoolCard(
          item: item,
          onPredictTap: widget.onPredictTap,
        );
      },
    );
  }
}

class _HomePrizePoolItem {
  final FixtureModel match;
  final bool isCurrentMatch;
  final Map<String, dynamic>? prizePool;

  const _HomePrizePoolItem({
    required this.match,
    required this.isCurrentMatch,
    required this.prizePool,
  });

  bool get hasPrizePool => prizePool != null;

  bool get isLocked {
    final status = match.status.trim().toLowerCase();
    final now = DateTime.now();

    return match.isLocked ||
        !now.isBefore(match.predictionLockAt) ||
        status == 'locked' ||
        status == 'live' ||
        status == 'ongoing' ||
        status == 'completed' ||
        status == 'finalized' ||
        status == 'cancelled' ||
        status == 'canceled';
  }

  bool get canPredict {
    final status = match.status.trim().toLowerCase();
    final now = DateTime.now();

    return !isLocked &&
        now.isBefore(match.predictionLockAt) &&
        status == 'upcoming';
  }

  String? get title => prizePool?['title']?.toString();
  String? get description => prizePool?['description']?.toString();
  String? get prize1 => prizePool?['prize_1']?.toString();
  String? get prize2 => prizePool?['prize_2']?.toString();
  String? get prize3 => prizePool?['prize_3']?.toString();
  String? get sponsorName => prizePool?['sponsor_name']?.toString();
  String? get bannerImageUrl => prizePool?['banner_image_url']?.toString();

  List<String> get prizes {
    return [
      if (_hasText(prize1)) prize1!.trim(),
      if (_hasText(prize2)) prize2!.trim(),
      if (_hasText(prize3)) prize3!.trim(),
    ];
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}

class _PrizePoolCard extends StatelessWidget {
  final _HomePrizePoolItem item;
  final void Function(String matchId)? onPredictTap;

  const _PrizePoolCard({
    required this.item,
    required this.onPredictTap,
  });

  @override
  Widget build(BuildContext context) {
    final match = item.match;
    final time = TimeOfDay.fromDateTime(match.matchStartAt).format(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF7D6),
            Color(0xFFE9FFF8),
            Color(0xFFFFEAF1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x2EFFC857),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -28,
            top: -28,
            child: _SoftCircle(
              size: 110,
              color: Color(0xFFFFD166),
            ),
          ),
          const Positioned(
            left: -30,
            bottom: -32,
            child: _SoftCircle(
              size: 120,
              color: Color(0xFF9AF5DD),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 18,
            child: Icon(
              Icons.card_giftcard_rounded,
              size: 78,
              color: const Color(0xFFFFB703).withOpacity(0.10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(item: item),
                const SizedBox(height: 13),
                _FixtureCard(match: match),
                const SizedBox(height: 12),
                item.hasPrizePool
                    ? _PrizeInfo(item: item)
                    : _NoPrizePool(item: item),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$time • ${match.stage}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF52616B),
                          fontSize: 10.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ActionButton(
                      item: item,
                      onPredictTap: onPredictTap,
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

class _Header extends StatelessWidget {
  final _HomePrizePoolItem item;

  const _Header({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.hasPrizePool ? 'Match Rewards' : 'Match Update';

    final subtitle = item.isCurrentMatch
        ? 'Current match playing now'
        : 'Next match prediction';

    final statusLabel = item.isCurrentMatch
        ? 'LIVE'
        : item.isLocked
            ? 'LOCKED'
            : 'OPEN';

    final statusColor = item.isCurrentMatch
        ? const Color(0xFFE87900)
        : item.isLocked
            ? const Color(0xFF64748B)
            : const Color(0xFF0F9F84);

    final statusBg = item.isCurrentMatch
        ? const Color(0xFFFFE5B4)
        : item.isLocked
            ? const Color(0xFFEFF3F7)
            : const Color(0xFFDDFBF1);

    return Row(
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: item.hasPrizePool
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD166),
                      Color(0xFFFFB703),
                      Color(0xFFFF7A00),
                    ],
                  )
                : const LinearGradient(
                    colors: [
                      Color(0xFFEFF3F7),
                      Color(0xFFDDE7EF),
                    ],
                  ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB703).withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            item.hasPrizePool
                ? Icons.card_giftcard_rounded
                : Icons.sports_soccer_rounded,
            color: Colors.white,
            size: 20,
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
                  color: Color(0xFF102A43),
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
                  color: Color(0xFF627D98),
                  fontSize: 10.7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(100),
          ),
          alignment: Alignment.center,
          child: Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _FixtureCard extends StatelessWidget {
  final FixtureModel match;

  const _FixtureCard({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _TeamBlock(
              flagUrl: match.teamAFlagUrl,
              shortName: match.teamAShort,
              name: match.teamAName,
            ),
          ),
          const SizedBox(width: 10),
          const _VsBadge(),
          const SizedBox(width: 10),
          Expanded(
            child: _TeamBlock(
              flagUrl: match.teamBFlagUrl,
              shortName: match.teamBShort,
              name: match.teamBName,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  final String? flagUrl;
  final String shortName;
  final String name;

  const _TeamBlock({
    required this.flagUrl,
    required this.shortName,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final label = name.trim().isNotEmpty ? name.trim() : shortName.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TeamFlag(
          url: flagUrl,
          shortName: shortName,
          width: 50,
          height: 35,
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF102A43),
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
        ),
      ],
    );
  }
}

class _VsBadge extends StatelessWidget {
  const _VsBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 39,
      width: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD166),
            Color(0xFFFF8A00),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA000).withOpacity(0.20),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'VS',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.2,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _PrizeInfo extends StatelessWidget {
  final _HomePrizePoolItem item;

  const _PrizeInfo({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final customTitle = item.title?.trim();

    final title = customTitle != null &&
            customTitle.isNotEmpty &&
            !customTitle.toLowerCase().contains('prize pool')
        ? customTitle
        : 'Rewards up for grabs';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE8A3),
            Color(0xFFFFC857),
            Color(0xFFFFD6E6),
          ],
        ),
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC857).withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.bannerImageUrl != null &&
              item.bannerImageUrl!.trim().isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                item.bannerImageUrl!,
                height: 78,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFF8A00),
                  size: 17,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF5C3900),
                    fontSize: 13.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (item.description != null &&
              item.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              item.description!.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6B4E16),
                fontSize: 10.9,
                fontWeight: FontWeight.w700,
                height: 1.28,
              ),
            ),
          ],
          if (item.prizes.isNotEmpty) ...[
            const SizedBox(height: 11),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (int i = 0; i < item.prizes.length; i++)
                  _PrizeChip(
                    text: item.prizes[i],
                    index: i,
                  ),
              ],
            ),
          ],
          if (item.sponsorName != null &&
              item.sponsorName!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: Color(0xFF7C5A12),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Sponsored by ${item.sponsorName!.trim()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7C5A12),
                      fontSize: 10.4,
                      fontWeight: FontWeight.w800,
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

class _PrizeChip extends StatelessWidget {
  final String text;
  final int index;

  const _PrizeChip({
    required this.text,
    required this.index,
  });

  List<Color> get _colors {
    const palettes = [
      [Color(0xFFFF8A00), Color(0xFFFFB703)],
      [Color(0xFFFF4D8D), Color(0xFFFF85A1)],
      [Color(0xFF00B4D8), Color(0xFF48CAE4)],
      [Color(0xFF10B981), Color(0xFF34D399)],
    ];

    return palettes[index % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: LinearGradient(colors: _colors),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.4,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NoPrizePool extends StatelessWidget {
  final _HomePrizePoolItem item;

  const _NoPrizePool({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = item.isLocked;

    final title = isLocked
        ? 'Rewards not announced'
        : 'Rewards not announced yet';

    final message = isLocked
        ? 'Prediction is closed for this match.'
        : 'Prediction is open, but rewards are not announced yet.';

    final icon = isLocked
        ? Icons.lock_rounded
        : Icons.notifications_none_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Container(
            height: 31,
            width: 31,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF8A00),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF5C3900),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF7C5A12),
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

class _ActionButton extends StatelessWidget {
  final _HomePrizePoolItem item;
  final void Function(String matchId)? onPredictTap;

  const _ActionButton({
    required this.item,
    required this.onPredictTap,
  });

  @override
  Widget build(BuildContext context) {
    final canPredict = item.canPredict && onPredictTap != null;

    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: canPredict ? () => onPredictTap!(item.match.id) : null,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: canPredict
              ? const LinearGradient(
                  colors: [
                    Color(0xFF14B8A6),
                    Color(0xFF0F9F84),
                  ],
                )
              : null,
          color: canPredict ? null : const Color(0xFFEFF3F7),
          boxShadow: canPredict
              ? [
                  BoxShadow(
                    color: AppTheme.teal.withOpacity(0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          canPredict ? 'Predict Now' : 'Locked',
          style: TextStyle(
            color: canPredict ? Colors.white : const Color(0xFF64748B),
            fontSize: 10.7,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PrizePoolLoadingCard extends StatelessWidget {
  const _PrizePoolLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D6),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF14B8A6),
        ),
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.22),
      ),
    );
  }
}