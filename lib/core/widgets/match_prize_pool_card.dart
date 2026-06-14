import 'package:flutter/material.dart';

import '../../models/match_prize_pool_model.dart';

class MatchPrizePoolCard extends StatelessWidget {
  final MatchPrizePoolModel? prizePool;
  final bool loading;

  const MatchPrizePoolCard({
    super.key,
    required this.prizePool,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _PrizePoolShell(
        child: SizedBox(
          height: 96,
          child: Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    final pool = prizePool;

    if (pool == null) {
      return const _PrizePoolShell(
        child: _NoPrizePoolContent(),
      );
    }

    return _PrizePoolShell(
      bannerImageUrl: pool.bannerImageUrl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.20),
                  ),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
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
                      pool.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    if (pool.sponsorName != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Sponsored by ${pool.sponsorName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.20),
                  ),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),

          if (pool.description != null) ...[
            const SizedBox(height: 11),
            Text(
              pool.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],

          if (pool.hasAnyPrize) ...[
            const SizedBox(height: 13),
            Column(
              children: [
                if (pool.prize1 != null)
                  _PrizeRow(
                    rank: '1',
                    label: pool.prize1!,
                    color: const Color(0xFFFFF4C2),
                  ),
                if (pool.prize2 != null) ...[
                  const SizedBox(height: 7),
                  _PrizeRow(
                    rank: '2',
                    label: pool.prize2!,
                    color: const Color(0xFFFFD1A1),
                  ),
                ],
                if (pool.prize3 != null) ...[
                  const SizedBox(height: 7),
                  _PrizeRow(
                    rank: '3',
                    label: pool.prize3!,
                    color: const Color(0xFFFFB199),
                  ),
                ],
              ],
            ),
          ],

          if (pool.terms != null) ...[
            const SizedBox(height: 11),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
              child: Text(
                pool.terms!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 10.2,
                  fontWeight: FontWeight.w700,
                  height: 1.28,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrizePoolShell extends StatelessWidget {
  final Widget child;
  final String? bannerImageUrl;

  const _PrizePoolShell({
    required this.child,
    this.bannerImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = bannerImageUrl?.trim();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D00).withOpacity(0.26),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF2D00),
                    Color(0xFFFF6A00),
                    Color(0xFFFFA000),
                  ],
                ),
              ),
            ),
          ),

          if (imageUrl != null && imageUrl.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return const SizedBox.shrink();
                },
              ),
            ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(
                      imageUrl == null || imageUrl.isEmpty ? 0.04 : 0.46,
                    ),
                    Colors.black.withOpacity(
                      imageUrl == null || imageUrl.isEmpty ? 0.10 : 0.62,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: -70,
            right: -64,
            child: _GlowCircle(
              color: Colors.white.withOpacity(0.20),
              size: 160,
            ),
          ),

          Positioned(
            bottom: -90,
            left: -70,
            child: _GlowCircle(
              color: Colors.yellow.withOpacity(0.18),
              size: 170,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(15),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _PrizeRow extends StatelessWidget {
  final String rank;
  final String label;
  final Color color;

  const _PrizeRow({
    required this.rank,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 26,
            width: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              rank,
              style: const TextStyle(
                color: Color(0xFF3A1800),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPrizePoolContent extends StatelessWidget {
  const _NoPrizePoolContent();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
            ),
          ),
          child: const Icon(
            Icons.card_giftcard_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Prize Pool',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No prize pool has been announced for this match yet.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowCircle({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}