import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class HeaderBannerSection extends StatelessWidget {
  final String? name;
  final VoidCallback onProfileTap;

  const HeaderBannerSection({
    super.key,
    required this.name,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final userName = name?.trim();
    final mainTitle =
        userName == null || userName.isEmpty ? 'World Cup' : 'Hi, $userName';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TopHeader(
          title: mainTitle,
          onProfileTap: onProfileTap,
        ),
        const SizedBox(height: 14),
        const _MatchdayBanner(),
      ],
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onProfileTap;

  const _TopHeader({
    required this.title,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFD166),
                Color(0xFFFF7A3D),
                Color(0xFF00D9A3),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8A3D).withOpacity(0.34),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppTheme.teal.withOpacity(0.18),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.12),
                ),
              ),
              const Icon(
                Icons.sports_soccer_rounded,
                color: Colors.white,
                size: 27,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFFFE0A3),
                      Color(0xFF25F2C3),
                    ],
                  ).createShader(bounds);
                },
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Predict scores. Win rewards.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                ),
              ),
            ],
          ),
        ),
        _GlassIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {},
          showDot: true,
        ),
        const SizedBox(width: 8),
        _GlassIconButton(
          icon: Icons.person_rounded,
          onTap: onProfileTap,
        ),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.16),
                        Colors.white.withOpacity(0.055),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showDot)
          Positioned(
            top: 6,
            right: 7,
            child: Container(
              height: 9,
              width: 9,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD166),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF07111E),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD166).withOpacity(0.55),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MatchdayBanner extends StatelessWidget {
  const _MatchdayBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 136,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7A3D).withOpacity(0.28),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: AppTheme.teal.withOpacity(0.16),
            blurRadius: 34,
            offset: const Offset(-8, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFB84D),
                      Color(0xFFFF6B4A),
                      Color(0xFFB0267A),
                      Color(0xFF0F7B6C),
                    ],
                    stops: [0.0, 0.34, 0.68, 1.0],
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.15,
                    colors: [
                      Colors.white.withOpacity(0.24),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),

            Positioned(
              top: -42,
              left: -36,
              child: Container(
                height: 118,
                width: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.13),
                ),
              ),
            ),

            Positioned(
              right: -40,
              bottom: -60,
              child: Icon(
                Icons.sports_soccer_rounded,
                size: 168,
                color: Colors.white.withOpacity(0.11),
              ),
            ),

            Positioned(
              right: 78,
              top: 20,
              child: Transform.rotate(
                angle: -0.16,
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 44,
                  color: Colors.white.withOpacity(0.18),
                ),
              ),
            ),

            Positioned(
              right: 15,
              top: 14,
              child: Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
            ),

            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _BannerBadge(),
                          const Spacer(),
                          const Text(
                            'Matchday Challenge',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text.rich(
                            const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Predict exact score and win ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: '₹500',
                                  style: TextStyle(
                                    color: Color(0xFFFFF3B0),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                TextSpan(
                                  text: ' reward',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
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

class _BannerBadge extends StatelessWidget {
  const _BannerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 12,
            color: Color(0xFFFFF3B0),
          ),
          SizedBox(width: 5),
          Text(
            'SHILLONG MATCHDAY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.55,
            ),
          ),
        ],
      ),
    );
  }
}
