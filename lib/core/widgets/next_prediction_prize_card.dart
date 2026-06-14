import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../models/fixture_model.dart';
import '../../../models/match_prize_pool_model.dart';
import '../../../services/prediction_service.dart';
import '../../core/widgets/match_prize_pool_card.dart';

class NextPredictionPrizeCard extends StatefulWidget {
  final void Function(FixtureModel match) onPredictNow;

  const NextPredictionPrizeCard({
    super.key,
    required this.onPredictNow,
  });

  @override
  State<NextPredictionPrizeCard> createState() =>
      _NextPredictionPrizeCardState();
}

class _NextPredictionPrizeCardState extends State<NextPredictionPrizeCard> {
  final PredictionService _predictionService = PredictionService();

  late final Future<_NextPredictionPrizeData?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_NextPredictionPrizeData?> _load() async {
    try {
      final match = await _predictionService.nextUpcomingPredictionMatch();

      if (match == null) {
        return null;
      }

      final results = await Future.wait<Object?>([
        _predictionService.matchPrizePool(match.id),
        _predictionService.myPredictionForMatch(match.id),
      ]);

      return _NextPredictionPrizeData(
        match: match,
        prizePool: results[0] as MatchPrizePoolModel?,
        userPrediction: results[1] as UserMatchPrediction?,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load next prediction prize card',
        error: error,
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_NextPredictionPrizeData?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MatchPrizePoolCard(
            prizePool: null,
            loading: true,
          );
        }

        final data = snapshot.data;

        if (data == null) {
          return const SizedBox.shrink();
        }

        return _PredictionPrizeBody(
          data: data,
          onPredictNow: widget.onPredictNow,
        );
      },
    );
  }
}

class _PredictionPrizeBody extends StatelessWidget {
  final _NextPredictionPrizeData data;
  final void Function(FixtureModel match) onPredictNow;

  const _PredictionPrizeBody({
    required this.data,
    required this.onPredictNow,
  });

  @override
  Widget build(BuildContext context) {
    final match = data.match;
    final alreadyPredicted = data.userPrediction != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MatchPrizePoolCard(
          prizePool: data.prizePool,
          loading: false,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE8ECF3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Next Prediction Match',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.52),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: _TeamBlock(
                      name: match.teamAName,
                      shortName: match.teamAShort,
                      flagUrl: match.teamAFlagUrl,
                      alignRight: false,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6FA),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _TeamBlock(
                      name: match.teamBName,
                      shortName: match.teamBShort,
                      flagUrl: match.teamBFlagUrl,
                      alignRight: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if ((match.stage ?? '').trim().isNotEmpty)
                    _InfoPill(
                      icon: Icons.emoji_events_rounded,
                      label: match.stage!.trim(),
                    ),
                  if (match.matchStartAt != null)
                    _InfoPill(
                      icon: Icons.schedule_rounded,
                      label: _formatDateTime(match.matchStartAt!),
                    ),
                ],
              ),
              const SizedBox(height: 13),
              if (alreadyPredicted)
                const _AlreadyPredictedBox()
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => onPredictNow(match),
                    icon: const Icon(
                      Icons.sports_soccer_rounded,
                      size: 19,
                    ),
                    label: const Text('Predict Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D00),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = _monthName(local.month);
    final year = local.year.toString();

    final hour12 = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;

    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$day $month $year, $hour12:$minute $period';
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }
}

class _TeamBlock extends StatelessWidget {
  final String name;
  final String shortName;
  final String? flagUrl;
  final bool alignRight;

  const _TeamBlock({
    required this.name,
    required this.shortName,
    required this.flagUrl,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = flagUrl?.trim();

    return Row(
      mainAxisAlignment:
          alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      textDirection: alignRight ? TextDirection.rtl : TextDirection.ltr,
      children: [
        _FlagBadge(imageUrl: imageUrl),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment:
                alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                shortName.trim().isNotEmpty ? shortName.trim() : name.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                name.trim().isNotEmpty ? name.trim() : 'Team',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.48),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlagBadge extends StatelessWidget {
  final String? imageUrl;

  const _FlagBadge({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    return Container(
      height: 36,
      width: 36,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: url == null || url.isEmpty
          ? const Icon(
              Icons.flag_rounded,
              size: 18,
              color: Color(0xFF6B7280),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) {
                return const Icon(
                  Icons.flag_rounded,
                  size: 18,
                  color: Color(0xFF6B7280),
                );
              },
            ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: const Color(0xFFE8ECF3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF4B5563),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlreadyPredictedBox extends StatelessWidget {
  const _AlreadyPredictedBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFED7AA),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Color(0xFFEA580C),
            size: 19,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Prediction submitted. Wait for others to predict.',
              style: TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextPredictionPrizeData {
  final FixtureModel match;
  final MatchPrizePoolModel? prizePool;
  final UserMatchPrediction? userPrediction;

  const _NextPredictionPrizeData({
    required this.match,
    required this.prizePool,
    required this.userPrediction,
  });
}