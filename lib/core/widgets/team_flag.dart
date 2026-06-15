import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: flagUrl == null || flagUrl.isEmpty
          ? Center(
              child: Text(
                shortName,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            )
          : SvgPicture.network(
              flagUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholderBuilder: (_) {
                return Center(
                  child: Text(
                    shortName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
    );
  }
}