import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'home_section_card.dart';

class LeadersSection extends StatelessWidget {
  final VoidCallback onViewAll;

  const LeadersSection({
    super.key,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return HomeSectionCard(
      title: 'Leaders',
      subtitle: 'Top predictors this week',
      icon: Icons.leaderboard_rounded,
      accent: AppTheme.teal,
      action: 'Full table',
      onActionTap: onViewAll,
      gradientColors: const [
        Color(0xFF06372F),
        Color(0xFF101D36),
        Color(0xFF07111E),
      ],
      child: Column(
        children: const [
          _LeaderRow(
            rank: '1',
            name: 'Top Player',
            points: '0 pts',
            color: AppTheme.gold,
          ),
          SizedBox(height: 8),
          _LeaderRow(
            rank: '2',
            name: 'Next Player',
            points: '0 pts',
            color: Color(0xFFB8C2CC),
          ),
          SizedBox(height: 8),
          _LeaderRow(
            rank: '3',
            name: 'Third Player',
            points: '0 pts',
            color: Color(0xFFB87333),
          ),
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final String rank;
  final String name;
  final String points;
  final Color color;

  const _LeaderRow({
    required this.rank,
    required this.name,
    required this.points,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: color,
            child: Text(
              rank,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            points,
            style: const TextStyle(
              color: AppTheme.teal,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}