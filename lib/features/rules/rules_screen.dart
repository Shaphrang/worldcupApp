import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/sponsor_banner_section.dart';
import '../../models/sponsor_banner_model.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _RulesHero(),

                    SizedBox(height: 14),

                    SponsorBannerSection(
                      placement: SponsorBannerPlacement.rules,
                      slot: SponsorBannerSlot.top,
                      height: 104,
                      limit: 5,
                      autoPlay: true,
                    ),

                    SizedBox(height: 14),

                    _GoldenRuleCard(),

                    SizedBox(height: 14),

                    _PointsSection(),

                    SizedBox(height: 14),

                    _HowToWinSection(),

                    SizedBox(height: 14),

                    _TieBreakerSection(),

                    SizedBox(height: 14),

                    _ImportantNotesSection(),

                    SizedBox(height: 14),

                    SponsorBannerSection(
                      placement: SponsorBannerPlacement.rules,
                      slot: SponsorBannerSlot.bottom,
                      height: 96,
                      limit: 5,
                      autoPlay: true,
                    ),

                    SizedBox(height: 14),

                    _FinalDecisionCard(),
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

class _RulesHero extends StatelessWidget {
  const _RulesHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF103548),
            Color(0xFF071C2D),
            Color(0xFF04101B),
          ],
        ),
        border: Border.all(
          color: Colors.white24,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.32),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppTheme.teal.withOpacity(0.16),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -24,
            child: Icon(
              Icons.rule_rounded,
              size: 116,
              color: Colors.white.withOpacity(0.055),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppTheme.teal.withOpacity(0.32),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sports_soccer_rounded,
                      size: 14,
                      color: AppTheme.teal,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Prediction Rules',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'How to Win',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Predict the exact final score before the match locks. If your score is correct, you qualify for points and bonus rewards.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoldenRuleCard extends StatelessWidget {
  const _GoldenRuleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF7A3D),
            Color(0xFF8E2D17),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7A3D).withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 28,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Main Rule: Exact score is compulsory. If your exact score prediction is wrong, your points for that match will be 0 and you cannot win that match.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.2,
                fontWeight: FontWeight.w900,
                height: 1.42,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsSection extends StatelessWidget {
  const _PointsSection();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Points System',
      icon: Icons.workspace_premium_rounded,
      children: [
        _PointTile(
          points: '10',
          title: 'Exact Score Prediction',
          description:
              'You get 10 points only if you correctly predict the final score of the match.',
          color: Color(0xFFFFB84D),
        ),
        SizedBox(height: 10),
        _PointTile(
          points: '+5',
          title: 'Goal Scorer Bonus',
          description:
              'You can select one goal scorer. If that player scores at least one goal in the match, you get 5 bonus points.',
          color: AppTheme.teal,
        ),
        SizedBox(height: 10),
        _PointTile(
          points: '15',
          title: 'Maximum Points Per Match',
          description:
              '10 points for exact score + 5 bonus points for correct goal scorer.',
          color: Color(0xFF57A6FF),
        ),
      ],
    );
  }
}

class _HowToWinSection extends StatelessWidget {
  const _HowToWinSection();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Winning Flow',
      icon: Icons.route_rounded,
      children: [
        _StepTile(
          number: '1',
          title: 'Submit before lock time',
          description:
              'Predictions must be submitted before the prediction lock time. Late predictions will not count.',
        ),
        _StepTile(
          number: '2',
          title: 'Predict the exact score',
          description:
              'Example: Qatar 2 - 1 Switzerland. The final score must match exactly.',
        ),
        _StepTile(
          number: '3',
          title: 'Choose one goal scorer',
          description:
              'This is a bonus selection. The player must score at least one official goal in that match.',
        ),
        _StepTile(
          number: '4',
          title: 'Match result is updated',
          description:
              'After the match, the actual score and official goal scorers are entered by the admin.',
        ),
        _StepTile(
          number: '5',
          title: 'Only exact-score users qualify',
          description:
              'If the exact score is wrong, the user gets 0 points for that match.',
        ),
        _StepTile(
          number: '6',
          title: 'Highest valid points wins',
          description:
              'Among exact-score winners, goal scorer bonus is added. If there is still a tie, the earliest prediction wins.',
        ),
      ],
    );
  }
}

class _TieBreakerSection extends StatelessWidget {
  const _TieBreakerSection();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Tie Breaker',
      icon: Icons.timer_rounded,
      children: [
        _InfoTile(
          icon: Icons.bolt_rounded,
          title: 'First correct prediction wins',
          description:
              'If two or more users have the same valid winning points, the user who submitted the prediction first will be the winner.',
        ),
        SizedBox(height: 10),
        _ExampleBox(),
      ],
    );
  }
}

class _ImportantNotesSection extends StatelessWidget {
  const _ImportantNotesSection();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Important Rules',
      icon: Icons.verified_user_rounded,
      children: [
        _InfoTile(
          icon: Icons.lock_clock_rounded,
          title: 'Prediction lock',
          description:
              'Once prediction time is locked, users cannot create or change their prediction for that match.',
        ),
        _InfoTile(
          icon: Icons.person_search_rounded,
          title: 'Only one scorer bonus',
          description:
              'Each prediction can have only one goal scorer bonus player.',
        ),
        _InfoTile(
          icon: Icons.scoreboard_rounded,
          title: 'Wrong score means zero',
          description:
              'Even if your selected goal scorer scores, you will not get bonus points if your exact score prediction is wrong.',
        ),
        _InfoTile(
          icon: Icons.sports_rounded,
          title: 'Official match result only',
          description:
              'Points are calculated based on the final official score and goal scorer data entered in the app.',
        ),
      ],
    );
  }
}

class _FinalDecisionCard extends StatelessWidget {
  const _FinalDecisionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF4C2),
            Color(0xFFFFB84D),
            Color(0xFFFF7A3D),
            Color(0xFF18D6B1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withOpacity(0.26),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppTheme.teal.withOpacity(0.12),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF211604),
              Color(0xFF071827),
              Color(0xFF03121C),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -22,
              child: Icon(
                Icons.gavel_rounded,
                size: 104,
                color: Colors.white.withOpacity(0.045),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFF4C2),
                        Color(0xFFFFB84D),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.gavel_rounded,
                    color: Color(0xFF2B1908),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Final Decision',
                        style: TextStyle(
                          color: Color(0xFFFFE7A3),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.25,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'The organizer/admin decision will be final and binding for match results, goal scorers, points calculation, tie-breaks, and winner declaration.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF071827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.09),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: title,
            icon: icon,
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: AppTheme.teal.withOpacity(0.13),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.teal.withOpacity(0.24),
            ),
          ),
          child: Icon(
            icon,
            color: AppTheme.teal,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _PointTile extends StatelessWidget {
  final String points;
  final String title;
  final String description;
  final Color color;

  const _PointTile({
    required this.points,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.30),
              ),
            ),
            child: Text(
              points,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.62),
                    fontSize: 11.8,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

class _StepTile extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _StepTile({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 30,
            width: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.teal.withOpacity(0.14),
              border: Border.all(
                color: AppTheme.teal.withOpacity(0.30),
              ),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppTheme.teal,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.62),
                      fontSize: 11.8,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.teal,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.62),
                    fontSize: 11.8,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

class _ExampleBox extends StatelessWidget {
  const _ExampleBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF02070D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Text(
        'Example: User A and User B both predicted 2 - 1 correctly and both got the scorer bonus. User A submitted at 7:05 PM and User B submitted at 7:20 PM. User A wins because the prediction was submitted first.',
        style: TextStyle(
          color: Colors.white.withOpacity(0.70),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.45,
        ),
      ),
    );
  }
}