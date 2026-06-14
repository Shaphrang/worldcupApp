//lib\features\splash\splash_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _imagePath =
      'assets/images/splash_worldcup_meghalaya.png';

  late final AnimationController _controller;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _boot();
    });
  }

  Future<void> _boot() async {
    try {
      await Future.wait([
        _preloadSplashImage(),
        Future.delayed(const Duration(milliseconds: 2800)),
      ]);
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 2200));
    }

    if (!mounted || _navigated) return;
    _navigated = true;
    context.go('/home');
  }

  Future<void> _preloadSplashImage() async {
    try {
      await precacheImage(const AssetImage(_imagePath), context);
    } catch (_) {
      // Do not block splash if asset preload fails.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF031019),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _imagePath,
            fit: BoxFit.cover,
          ),

          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66020B12),
                  Color(0xA0031019),
                  Color(0xE6031019),
                  Color(0xFF031019),
                ],
                stops: [0.0, 0.35, 0.70, 1.0],
              ),
            ),
          ),

          Positioned(
            top: -80,
            right: -70,
            child: _GlowBlob(
              color: const Color(0xFF13D3B4),
              size: 220,
              opacity: 0.14,
            ),
          ),

          Positioned(
            bottom: 110,
            left: -80,
            child: _GlowBlob(
              color: const Color(0xFFFFC75A),
              size: 190,
              opacity: 0.10,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
              child: Column(
                children: [
                  const Spacer(),
                  _AnimatedBadge(controller: _controller),
                  const SizedBox(height: 20),
                  const Text(
                    'World Cup Predictions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Shillong, Meghalaya',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.82),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Predict. Play. Win.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFFFD27A).withOpacity(0.98),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  _BottomLoadingCard(controller: _controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBadge extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedBadge({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        final pulse = 1 + (0.06 * (0.5 - (t - 0.5).abs()) * 2);

        return Transform.scale(
          scale: pulse,
          child: Container(
            height: 86,
            width: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFE7A8),
                  Color(0xFFFFC75A),
                  Color(0xFFFF9E42),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFC75A).withOpacity(0.30),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF062231),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFFFC75A),
                size: 42,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BottomLoadingCard extends StatelessWidget {
  final AnimationController controller;

  const _BottomLoadingCard({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.14),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF13D3B4).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.sports_soccer_rounded,
                      color: Color(0xFF13D3B4),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loading your match experience',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Preparing fixtures, predictions and winners...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.3,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _LoadingDots(controller: controller),
                ],
              ),
              const SizedBox(height: 14),
              _AnimatedProgressBar(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedProgressBar({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 7,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final widthFactor = 0.25 + (controller.value * 0.55);

          return Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: widthFactor,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF13D3B4),
                      Color(0xFF57A6FF),
                      Color(0xFFFFC75A),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF13D3B4).withOpacity(0.30),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;

  const _LoadingDots({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final phase = (controller.value + (index * 0.18)) % 1;
              final active = phase < 0.55;
              final scale = active ? 1.0 + ((0.55 - phase) * 0.7) : 0.84;

              return Transform.scale(
                scale: scale,
                child: Container(
                  height: 7,
                  width: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? const Color(0xFFFFC75A)
                        : Colors.white.withOpacity(0.30),
                  ),
                ),
              );
            }),
          );
        },
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
            blurRadius: 90,
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }
}