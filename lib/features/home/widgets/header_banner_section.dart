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

    return _TopHeader(
      title: mainTitle,
      onProfileTap: onProfileTap,
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