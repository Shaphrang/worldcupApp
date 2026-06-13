import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/team_flag.dart';

class HomePredictionPreviewItem {
  final String matchId;

  final String teamAName;
  final String teamAShort;
  final String? teamAFlagUrl;

  final String teamBName;
  final String teamBShort;
  final String? teamBFlagUrl;

  final int teamAScore;
  final int teamBScore;

  final DateTime? matchStartAt;
  final DateTime? predictionLockAt;
  final bool isLocked;

  final String? scorerName;
  final String? scorerTeamName;

  const HomePredictionPreviewItem({
    required this.matchId,
    required this.teamAName,
    required this.teamAShort,
    required this.teamAFlagUrl,
    required this.teamBName,
    required this.teamBShort,
    required this.teamBFlagUrl,
    required this.teamAScore,
    required this.teamBScore,
    required this.matchStartAt,
    required this.predictionLockAt,
    required this.isLocked,
    this.scorerName,
    this.scorerTeamName,
  });
}

class HomeMyPredictionsSection extends StatelessWidget {
  final bool isLoggedIn;
  final List<HomePredictionPreviewItem> predictions;
  final VoidCallback onLoginTap;
  final ValueChanged<HomePredictionPreviewItem> onPredictionTap;

  const HomeMyPredictionsSection({
    super.key,
    required this.isLoggedIn,
    required this.predictions,
    required this.onLoginTap,
    required this.onPredictionTap,
  });

  @override
  Widget build(BuildContext context) {
    final sortedPredictions = List<HomePredictionPreviewItem>.from(predictions)
      ..sort((a, b) => _compareDate(a.matchStartAt, b.matchStartAt));

    final nextFive = sortedPredictions.take(5).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF38BDF8),
            Color(0xFF18D6B1),
            Color(0xFFFFB84D),
            Color(0xFFFF7A3D),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.teal.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppTheme.blue.withOpacity(0.11),
            blurRadius: 26,
            offset: const Offset(-8, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF10263A).withOpacity(0.96),
                  const Color(0xFF071827).withOpacity(0.97),
                  const Color(0xFF050E18).withOpacity(0.99),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -42,
                  right: -42,
                  child: Container(
                    height: 110,
                    width: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.teal.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -54,
                  left: -40,
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.blue.withOpacity(0.065),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
                  child: Column(
                    children: [
                      _SectionHeader(count: isLoggedIn ? nextFive.length : 0),
                      const SizedBox(height: 10),
                      const _SoftDivider(),
                      const SizedBox(height: 10),
                      if (!isLoggedIn)
                        _StateRow(
                          icon: Icons.lock_outline_rounded,
                          title: 'Login required',
                          message: 'Login to view your submitted predictions.',
                          actionLabel: 'Login',
                          onTap: onLoginTap,
                        )
                      else if (nextFive.isEmpty)
                        const _StateRow(
                          icon: Icons.sports_soccer_rounded,
                          title: 'No upcoming predictions',
                          message: 'Submit a prediction and it will appear here.',
                          actionLabel: null,
                        )
                      else
                        Column(
                          children: [
                            for (int i = 0; i < nextFive.length; i++) ...[
                              _PredictionRow(
                                item: nextFive[i],
                                onTap: () => onPredictionTap(nextFive[i]),
                              ),
                              if (i != nextFive.length - 1) ...[
                                const SizedBox(height: 10),
                                const _GradientDivider(),
                                const SizedBox(height: 10),
                              ],
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

int _compareDate(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

class _SectionHeader extends StatelessWidget {
  final int count;

  const _SectionHeader({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF57A6FF),
                Color(0xFF18D6B1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.blue.withOpacity(0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.center_focus_strong_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Predictions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.2,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Upcoming picks and selected scorer',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.teal.withOpacity(0.12),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: AppTheme.teal.withOpacity(0.22),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppTheme.teal,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _PredictionRow extends StatelessWidget {
  final HomePredictionPreviewItem item;
  final VoidCallback onTap;

  const _PredictionRow({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final schedule = _scheduleText(item.matchStartAt);
    final lockText = item.isLocked
        ? 'Locked'
        : item.predictionLockAt == null
            ? 'Lock TBA'
            : 'Locks ${DateTimeUtils.closeIn(item.predictionLockAt)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetaText(
                      icon: Icons.calendar_month_rounded,
                      text: schedule,
                      color: AppTheme.blue,
                      alignRight: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetaText(
                      icon: item.isLocked
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                      text: lockText,
                      color: item.isLocked ? Colors.redAccent : AppTheme.teal,
                      alignRight: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _TeamSide(
                      flagUrl: item.teamAFlagUrl,
                      shortName: item.teamAShort,
                      name: item.teamAName,
                      alignRight: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ScoreBox(
                    teamAScore: item.teamAScore,
                    teamBScore: item.teamBScore,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TeamSide(
                      flagUrl: item.teamBFlagUrl,
                      shortName: item.teamBShort,
                      name: item.teamBName,
                      alignRight: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ScorerLine(
                scorerName: item.scorerName,
                scorerTeamName: item.scorerTeamName,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _scheduleText(DateTime? value) {
    if (value == null) return 'Schedule TBA';

    final date = DateTimeUtils.dateOnly(value).trim();
    final time = DateTimeUtils.timeOnly(value).trim();

    if (date.isEmpty && time.isEmpty) return 'Schedule TBA';
    if (date.isEmpty) return time;
    if (time.isEmpty) return date;

    return '$date • $time';
  }
}

class _MetaText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool alignRight;

  const _MetaText({
    required this.icon,
    required this.text,
    required this.color,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 13,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignRight ? TextAlign.end : TextAlign.start,
            style: TextStyle(
              color: color.withOpacity(0.95),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamSide extends StatelessWidget {
  final String? flagUrl;
  final String shortName;
  final String name;
  final bool alignRight;

  const _TeamSide({
    required this.flagUrl,
    required this.shortName,
    required this.name,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isNotEmpty ? name.trim() : shortName;

    final flag = TeamFlag(
      url: flagUrl,
      shortName: shortName,
      width: 31,
      height: 22,
      borderRadius: BorderRadius.circular(7),
    );

    final text = Flexible(
      child: Text(
        displayName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: alignRight ? TextAlign.end : TextAlign.start,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.8,
          fontWeight: FontWeight.w800,
          height: 1.08,
          letterSpacing: 0.03,
        ),
      ),
    );

    return Row(
      mainAxisAlignment:
          alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignRight
          ? [
              text,
              const SizedBox(width: 7),
              flag,
            ]
          : [
              flag,
              const SizedBox(width: 7),
              text,
            ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final int teamAScore;
  final int teamBScore;

  const _ScoreBox({
    required this.teamAScore,
    required this.teamBScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 61,
      height: 39,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF7D6),
            Color(0xFFFFD166),
            Color(0xFFFFB84D),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withOpacity(0.18),
            blurRadius: 13,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$teamAScore - $teamBScore',
        style: const TextStyle(
          color: Color(0xFF2B1908),
          fontSize: 16,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: -0.25,
        ),
      ),
    );
  }
}

class _ScorerLine extends StatelessWidget {
  final String? scorerName;
  final String? scorerTeamName;

  const _ScorerLine({
    required this.scorerName,
    required this.scorerTeamName,
  });

  @override
  Widget build(BuildContext context) {
    final scorer = scorerName?.trim();
    final team = scorerTeamName?.trim();

    final hasScorer = scorer != null && scorer.isNotEmpty;

    final text = hasScorer
        ? team != null && team.isNotEmpty
            ? '$scorer • $team'
            : scorer
        : 'No goal scorer selected';

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.070),
            Colors.white.withOpacity(0.030),
          ],
        ),
        border: Border.all(
          color: hasScorer
              ? AppTheme.teal.withOpacity(0.18)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_soccer_rounded,
            color: hasScorer ? AppTheme.teal : Colors.white38,
            size: 14,
          ),
          const SizedBox(width: 7),
          const Text(
            'Scorer',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 9.8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: hasScorer ? Colors.white : Colors.white38,
                fontSize: 10.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _StateRow({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final clickable = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.055),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.075),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 35,
                width: 35,
                decoration: BoxDecoration(
                  color: AppTheme.blue.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.blue,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
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
                    const SizedBox(height: 4),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (clickable && actionLabel != null) ...[
                const SizedBox(width: 8),
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: AppTheme.blue.withOpacity(0.18),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: AppTheme.blue,
                      fontSize: 10.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}

class _GradientDivider extends StatelessWidget {
  const _GradientDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.blue.withOpacity(0.0),
            AppTheme.blue.withOpacity(0.22),
            AppTheme.teal.withOpacity(0.22),
            AppTheme.gold.withOpacity(0.18),
            AppTheme.blue.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}