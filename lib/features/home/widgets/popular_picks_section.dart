import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'home_section_card.dart';

class PopularPicksSection extends StatelessWidget {
  const PopularPicksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeSectionCard(
      title: 'Popular Picks',
      subtitle: 'Most selected prediction scores',
      icon: Icons.trending_up_rounded,
      accent: const Color(0xFFFF7A3D),
      action: 'Soon',
      gradientColors: const [
        Color(0xFF44200E),
        Color(0xFF172038),
        Color(0xFF08111E),
      ],
      child: Row(
        children: const [
          Expanded(
            child: _PredictionChipCard(
              score: '2 - 1',
              title: 'Popular',
              color: AppTheme.teal,
            ),
          ),
          SizedBox(width: 9),
          Expanded(
            child: _PredictionChipCard(
              score: '1 - 0',
              title: 'Top score',
              color: AppTheme.blue,
            ),
          ),
          SizedBox(width: 9),
          Expanded(
            child: _PredictionChipCard(
              score: '1 - 1',
              title: 'Safe pick',
              color: AppTheme.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionChipCard extends StatelessWidget {
  final String score;
  final String title;
  final Color color;

  const _PredictionChipCard({
    required this.score,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.065),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            score,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Coming soon',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}