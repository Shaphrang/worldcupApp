import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class HomeBackground extends StatelessWidget {
  final Widget child;

  const HomeBackground({
    super.key,
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
          stops: [0.0, 0.34, 0.68, 1.0],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: _BackgroundGradientOverlay(),
          ),

          Positioned(
            top: -130,
            right: -120,
            child: _GlowBlob(
              color: AppTheme.teal,
              size: 310,
              opacity: 0.18,
            ),
          ),

          Positioned(
            top: 110,
            left: -150,
            child: _GlowBlob(
              color: AppTheme.blue,
              size: 270,
              opacity: 0.13,
            ),
          ),

          Positioned(
            bottom: 120,
            right: -170,
            child: _GlowBlob(
              color: AppTheme.gold,
              size: 330,
              opacity: 0.09,
            ),
          ),

          Positioned(
            bottom: -160,
            left: -130,
            child: _GlowBlob(
              color: const Color(0xFFFF7A3D),
              size: 280,
              opacity: 0.06,
            ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ModernPitchPainter(),
              ),
            ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SoftDotPatternPainter(),
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 210,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.055),
                    Colors.white.withOpacity(0.012),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          child,
        ],
      ),
    );
  }
}

class _BackgroundGradientOverlay extends StatelessWidget {
  const _BackgroundGradientOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.75, -0.82),
          radius: 1.15,
          colors: [
            AppTheme.teal.withOpacity(0.16),
            Colors.transparent,
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.85, 0.05),
            radius: 1.05,
            colors: [
              AppTheme.blue.withOpacity(0.11),
              Colors.transparent,
            ],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.02),
                Colors.black.withOpacity(0.08),
                Colors.black.withOpacity(0.18),
              ],
            ),
          ),
        ),
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

class _ModernPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.030)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final accentPaint = Paint()
      ..color = AppTheme.teal.withOpacity(0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final centerY = size.height * 0.34;

    canvas.drawLine(
      Offset(24, centerY),
      Offset(size.width - 24, centerY),
      linePaint,
    );

    canvas.drawCircle(
      Offset(size.width / 2, centerY),
      86,
      linePaint,
    );

    canvas.drawCircle(
      Offset(size.width / 2, centerY),
      6,
      accentPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          24,
          size.height * 0.16,
          size.width - 48,
          134,
        ),
        const Radius.circular(28),
      ),
      linePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          58,
          size.height * 0.21,
          size.width - 116,
          74,
        ),
        const Radius.circular(20),
      ),
      accentPaint,
    );

    final diagonalPaint = Paint()
      ..color = Colors.white.withOpacity(0.018)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double x = -size.width; x < size.width * 2; x += 48) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.45, size.height * 0.45),
        diagonalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SoftDotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.026)
      ..style = PaintingStyle.fill;

    const spacing = 34.0;

    for (double y = 18; y < size.height; y += spacing) {
      for (double x = 18; x < size.width; x += spacing) {
        final shouldSkip = ((x + y) ~/ spacing) % 3 == 0;

        if (shouldSkip) continue;

        canvas.drawCircle(
          Offset(x, y),
          1.05,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}