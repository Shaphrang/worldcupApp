// lib/core/widgets/team_flag.dart
import 'package:flutter/material.dart';

class TeamFlag extends StatelessWidget {
  final String? url;
  final String shortName;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const TeamFlag({
    super.key,
    required this.url,
    required this.shortName,
    this.width = 72,
    this.height = 52,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final flagUrl = url?.trim();
    final isSvg = flagUrl != null && flagUrl.toLowerCase().endsWith('.svg');

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: flagUrl == null || flagUrl.isEmpty || isSvg
          ? _FlagFallback(
              shortName: shortName,
              width: width,
              height: height,
            )
          : Image.network(
              flagUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;

                return _FlagFallback(
                  shortName: shortName,
                  width: width,
                  height: height,
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _FlagFallback(
                  shortName: shortName,
                  width: width,
                  height: height,
                );
              },
            ),
    );
  }
}

class _FlagFallback extends StatelessWidget {
  final String shortName;
  final double width;
  final double height;

  const _FlagFallback({
    required this.shortName,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final label = shortName.trim().isEmpty ? 'WC' : shortName.trim();

    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.13),
            Colors.white.withOpacity(0.04),
          ],
        ),
      ),
      child: Text(
        label.length > 4 ? label.substring(0, 4).toUpperCase() : label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withOpacity(0.92),
          fontSize: width <= 34 ? 8.5 : 11.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}