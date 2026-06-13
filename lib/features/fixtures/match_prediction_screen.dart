//lib/features/fixtures/match_prediction_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/auth_required_sheet.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/match_status_badge.dart';
import '../../core/widgets/team_flag.dart';
import '../../models/fixture_model.dart';
import '../../models/participant_model.dart';
import '../../models/player_model.dart';
import '../../services/auth_service.dart';
import '../../services/fixture_service.dart';
import '../../services/prediction_service.dart';

class MatchPredictionScreen extends StatefulWidget {
  final String matchId;

  const MatchPredictionScreen({
    super.key,
    required this.matchId,
  });

  @override
  State<MatchPredictionScreen> createState() => _MatchPredictionScreenState();
}

class _MatchPredictionScreenState extends State<MatchPredictionScreen> {
  int teamAScore = 0;
  int teamBScore = 0;

  PlayerModel? selectedScorer;

  bool submitting = false;
  bool submitted = false;

  String? message;

  late Future<_MatchPredictionData> _screenFuture;

  @override
  void initState() {
    super.initState();
    _screenFuture = _loadScreenData();
  }

  Future<_MatchPredictionData> _loadScreenData() async {
    final fixture = await FixtureService().fixture(widget.matchId);
    final players = await FixtureService().players(widget.matchId);

    UserMatchPrediction? existingPrediction;

    if (AuthService().isLoggedIn) {
      existingPrediction =
          await PredictionService().myPredictionForMatch(widget.matchId);
    }

    if (existingPrediction != null) {
      teamAScore = existingPrediction.teamAScore;
      teamBScore = existingPrediction.teamBScore;
      selectedScorer = _findPlayerById(
        players,
        existingPrediction.scorerId,
      );
      submitted = true;
    } else {
      submitted = false;
    }

    return _MatchPredictionData(
      fixture: fixture,
      players: List<PlayerModel>.from(players),
      existingPrediction: existingPrediction,
    );
  }

  PlayerModel? _findPlayerById(List<PlayerModel> players, String? playerId) {
    if (playerId == null || playerId.isEmpty) return null;

    for (final player in players) {
      if (player.id == playerId) return player;
    }

    return null;
  }

  Future<void> _reload() async {
    setState(() {
      _screenFuture = _loadScreenData();
    });

    await _screenFuture;
  }

  Future<void> _submitPrediction() async {
    setState(() {
      submitting = true;
      message = null;
    });

    try {
      await PredictionService().submit(
        matchId: widget.matchId,
        teamAScore: teamAScore,
        teamBScore: teamBScore,
        scorerId: selectedScorer?.id,
      );

      if (!mounted) return;

      setState(() {
        submitted = true;
        message = 'Prediction saved: $teamAScore - $teamBScore';
        _screenFuture = _loadScreenData();
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        submitted = false;
        message = 'Could not save prediction. Details: $error';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MatchPredictionData>(
      future: _screenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: LoadingView(),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: _PredictionBackground(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  children: const [
                    _SimpleTopBar(title: 'Predict Score'),
                    SizedBox(height: 18),
                    _StateCard(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load match details',
                      message: 'Please check your connection and try again.',
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final data = snapshot.data;

        if (data == null || data.fixture == null) {
          return Scaffold(
            body: _PredictionBackground(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  children: const [
                    _SimpleTopBar(title: 'Predict Score'),
                    SizedBox(height: 18),
                    _StateCard(
                      icon: Icons.search_off_rounded,
                      title: 'Match not found',
                      message: 'No match was found for this fixture.',
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final fixture = data.fixture!;
        final players = data.players;
        final locked = fixture.isLocked == true;

        return Scaffold(
          body: _PredictionBackground(
            child: RefreshIndicator(
              color: AppTheme.teal,
              backgroundColor: AppTheme.surface2,
              onRefresh: _reload,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverAppBar(
                    title: const Text('Predict Score'),
                    pinned: true,
                    expandedHeight: 292,
                    backgroundColor: const Color(0xFF07131F),
                    flexibleSpace: FlexibleSpaceBar(
                      background: _PredictionHero(fixture: fixture),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _MatchInfoCard(fixture: fixture),
                          const SizedBox(height: 14),
                          if (!locked)
                            _predictionForm(
                              context,
                              fixture,
                              players,
                              data.existingPrediction,
                            )
                          else if (data.existingPrediction != null) ...[
                            _FinalPredictionCard(
                              prediction: data.existingPrediction!,
                              fixture: fixture,
                              scorerName: selectedScorer?.name,
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (message != null) ...[
                            const SizedBox(height: 12),
                            _MessageCard(
                              success: submitted,
                              message: message!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (locked) _participantsSliver(),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 110),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _predictionForm(
    BuildContext context,
    FixtureModel fixture,
    List<PlayerModel> players,
    UserMatchPrediction? existingPrediction,
  ) {
    final loggedIn = AuthService().isLoggedIn;
    final hasExistingPrediction = existingPrediction != null;

    if (!loggedIn) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: AppTheme.teal.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.teal.withOpacity(0.22)),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 28,
                color: AppTheme.teal,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Login or register to submit your prediction.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Predict Now',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: AppTheme.surface2,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  builder: (_) => AuthRequiredSheet(
                    redirect: '/fixtures/${widget.matchId}',
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your prediction',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    color: Colors.white,
                  ),
                ),
              ),
              if (hasExistingPrediction)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: AppTheme.teal.withOpacity(0.18),
                    ),
                  ),
                  child: const Text(
                    'EDITABLE',
                    style: TextStyle(
                      color: AppTheme.teal,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            hasExistingPrediction
                ? 'You already predicted. You can edit until lock time.'
                : 'Select expected score and goal scorer.',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ScoreDropdown(
                  label: fixture.teamAName,
                  value: teamAScore,
                  disabled: submitting,
                  onChanged: (value) {
                    setState(() {
                      teamAScore = value ?? 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScoreDropdown(
                  label: fixture.teamBName,
                  value: teamBScore,
                  disabled: submitting,
                  onChanged: (value) {
                    setState(() {
                      teamBScore = value ?? 0;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PlayerModel>(
            value: selectedScorer,
            isExpanded: true,
            dropdownColor: AppTheme.surface2,
            iconEnabledColor: Colors.white70,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
            items: players.map((player) {
              final teamText =
                  player.teamName.isEmpty ? '' : ' • ${player.teamName}';

              return DropdownMenuItem<PlayerModel>(
                value: player,
                child: Text(
                  '${player.name}$teamText',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: submitting
                ? null
                : (value) {
                    setState(() {
                      selectedScorer = value;
                    });
                  },
            decoration: const InputDecoration(
              labelText: 'Goal scorer',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: hasExistingPrediction
                  ? AppTheme.gold.withOpacity(0.08)
                  : AppTheme.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasExistingPrediction
                    ? AppTheme.gold.withOpacity(0.16)
                    : AppTheme.teal.withOpacity(0.14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasExistingPrediction
                      ? Icons.edit_note_rounded
                      : Icons.info_outline_rounded,
                  color: hasExistingPrediction ? AppTheme.gold : AppTheme.teal,
                  size: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    hasExistingPrediction
                        ? 'You can edit this prediction until lock time. Once locked, this becomes final.'
                        : 'You can submit until prediction lock time.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label:
                  hasExistingPrediction ? 'Update Prediction' : 'Submit Prediction',
              loading: submitting,
              onPressed: submitting ? null : _submitPrediction,
            ),
          ),
        ],
      ),
    );
  }

  Widget _participantsSliver() {
  return FutureBuilder<List<ParticipantModel>>(
    future: PredictionService().participants(widget.matchId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Container(
              height: 88,
              alignment: Alignment.center,
              decoration: _participantsPanelDecoration(),
              child: const CircularProgressIndicator(
                color: AppTheme.teal,
              ),
            ),
          ),
        );
      }

      if (snapshot.hasError) {
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _participantsPanelDecoration(),
              child: Text(
                'Could not load participants: ${snapshot.error}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }

      final list = snapshot.data ?? const <ParticipantModel>[];

      if (list.isEmpty) {
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _participantsPanelDecoration(),
              child: const Text(
                'No participants yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }

      return SliverMainAxisGroup(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _SimpleParticipantsHeader(count: list.length),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: SliverList.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 7),
              itemBuilder: (context, index) {
                return _SimpleParticipantRow(
                  item: list[index],
                  index: index,
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

BoxDecoration _participantsPanelDecoration() {
  return BoxDecoration(
    color: const Color(0xFF091827).withOpacity(0.94),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withOpacity(0.08),
    ),
  );
}

  BoxDecoration _participantsOuterDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.18),
          AppTheme.teal.withOpacity(0.34),
          AppTheme.gold.withOpacity(0.14),
          AppTheme.blue.withOpacity(0.10),
          Colors.white.withOpacity(0.05),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.20),
          blurRadius: 24,
          offset: const Offset(0, 13),
        ),
        BoxShadow(
          color: AppTheme.teal.withOpacity(0.10),
          blurRadius: 22,
          offset: const Offset(0, 9),
        ),
      ],
    );
  }

  BoxDecoration _participantsInnerDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF0A1B2A).withOpacity(0.96),
          const Color(0xFF081523).withOpacity(0.94),
          const Color(0xFF06111B).withOpacity(0.97),
        ],
      ),
      border: Border.all(
        color: Colors.white.withOpacity(0.08),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF091827).withOpacity(0.94),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Colors.white.withOpacity(0.09)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.18),
          blurRadius: 20,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}

class _SimpleParticipantsHeader extends StatelessWidget {
  final int count;

  const _SimpleParticipantsHeader({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
      child: Row(
        children: [
          const Icon(
            Icons.groups_rounded,
            color: AppTheme.teal,
            size: 18,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Participants',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '$count users',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleParticipantRow extends StatelessWidget {
  final ParticipantModel item;
  final int index;

  const _SimpleParticipantRow({
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final name = item.name.trim().isEmpty ? 'Participant' : item.name.trim();
    final initial = name[0].toUpperCase();

    final scoreA = item.teamAScore?.toString() ?? '-';
    final scoreB = item.teamBScore?.toString() ?? '-';

    final scorer = item.scorerName == null || item.scorerName!.trim().isEmpty
        ? 'No scorer'
        : item.scorerName!.trim();

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: index.isEven
            ? Colors.white.withOpacity(0.055)
            : Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(0.065),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: index < 3
                    ? const [
                        AppTheme.gold,
                        Color(0xFFFF7A3D),
                      ]
                    : const [
                        Color(0xFF34F5C5),
                        Color(0xFF0F766E),
                      ],
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 7,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 58,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppTheme.teal.withOpacity(0.18),
              ),
            ),
            child: Text(
              '$scoreA - $scoreB',
              style: const TextStyle(
                color: AppTheme.teal,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Row(
              children: [
                const Icon(
                  Icons.sports_soccer_rounded,
                  color: Colors.white38,
                  size: 13,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    scorer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
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

class _ParticipantsHeader extends StatelessWidget {
  final int count;

  const _ParticipantsHeader({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34F5C5),
                Color(0xFF0F766E),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.teal.withOpacity(0.22),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(
            Icons.groups_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Participants',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Predictions submitted for this match',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final ParticipantModel item;
  final int rank;

  const _ParticipantTile({
    required this.item,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final scoreA = item.teamAScore?.toString() ?? '-';
    final scoreB = item.teamBScore?.toString() ?? '-';

    final scorer = (item.scorerName == null || item.scorerName!.trim().isEmpty)
        ? 'No scorer selected'
        : item.scorerName!.trim();

    final name = item.name.trim().isEmpty ? 'Participant' : item.name.trim();
    final initial = name[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.16),
            rank <= 3
                ? AppTheme.gold.withOpacity(0.18)
                : AppTheme.teal.withOpacity(0.16),
            Colors.white.withOpacity(0.04),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          color: Colors.white.withOpacity(0.045),
          border: Border.all(
            color: Colors.white.withOpacity(0.045),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ParticipantAvatar(
              initial: initial,
              rank: rank,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RankMini(rank: rank),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      if (item.pointsTotal != null)
                        _PointsPill(points: item.pointsTotal!),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const Text(
                        'Prediction',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _PredictionScorePill(
                        left: scoreA,
                        right: scoreB,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.sports_soccer_rounded,
                        size: 14,
                        color: AppTheme.teal,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Scorer: $scorer',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (item.submittedAt != null) ...[
                    const SizedBox(height: 7),
                    Text(
                      DateTimeUtils.format(item.submittedAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  final String initial;
  final int rank;

  const _ParticipantAvatar({
    required this.initial,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final colors = rank <= 3
        ? const [
            AppTheme.gold,
            Color(0xFFFF7A3D),
          ]
        : const [
            Color(0xFF3DD6FF),
            Color(0xFF0EA5E9),
          ];

    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: (rank <= 3 ? AppTheme.gold : AppTheme.blue).withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _RankMini extends StatelessWidget {
  final int rank;

  const _RankMini({
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final color = rank <= 3 ? AppTheme.gold : AppTheme.teal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PointsPill extends StatelessWidget {
  final int points;

  const _PointsPill({
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.18),
        ),
      ),
      child: Text(
        '$points pts',
        style: const TextStyle(
          color: AppTheme.gold,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PredictionScorePill extends StatelessWidget {
  final String left;
  final String right;

  const _PredictionScorePill({
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF34F5C5),
            Color(0xFF0F766E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.teal.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        '$left  -  $right',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FinalPredictionCard extends StatelessWidget {
  final UserMatchPrediction prediction;
  final FixtureModel fixture;
  final String? scorerName;

  const _FinalPredictionCard({
    required this.prediction,
    required this.fixture,
    required this.scorerName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF091827).withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppTheme.gold,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Final Prediction',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Prediction is locked and cannot be edited.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FinalTeamBlock(
                  flagUrl: fixture.teamAFlagUrl,
                  shortName: fixture.teamAShort,
                  name: fixture.teamAName,
                ),
              ),
              Container(
                width: 86,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.gold.withOpacity(0.20),
                  ),
                ),
                child: Text(
                  '${prediction.teamAScore} - ${prediction.teamBScore}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              Expanded(
                child: _FinalTeamBlock(
                  flagUrl: fixture.teamBFlagUrl,
                  shortName: fixture.teamBShort,
                  name: fixture.teamBName,
                ),
              ),
            ],
          ),
          if (scorerName != null && scorerName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.055),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sports_soccer_rounded,
                    color: AppTheme.teal,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Goal scorer: $scorerName',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FinalTeamBlock extends StatelessWidget {
  final String? flagUrl;
  final String shortName;
  final String name;

  const _FinalTeamBlock({
    required this.flagUrl,
    required this.shortName,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamFlag(
          url: flagUrl,
          shortName: shortName,
          width: 42,
          height: 28,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 7),
        Text(
          shortName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ScoreDropdown extends StatelessWidget {
  final String label;
  final int value;
  final bool disabled;
  final ValueChanged<int?> onChanged;

  const _ScoreDropdown({
    required this.label,
    required this.value,
    required this.disabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: value,
      dropdownColor: AppTheme.surface2,
      iconEnabledColor: Colors.white70,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
      ),
      decoration: InputDecoration(
        labelText: label,
      ),
      items: [
        for (var i = 0; i <= 10; i++)
          DropdownMenuItem<int>(
            value: i,
            child: Text('$i'),
          ),
      ],
      onChanged: disabled ? null : onChanged,
    );
  }
}

class _PredictionHero extends StatelessWidget {
  final FixtureModel fixture;

  const _PredictionHero({
    required this.fixture,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 92, 18, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF144E5F),
            Color(0xFF092934),
            Color(0xFF06111D),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -46,
            child: Icon(
              Icons.sports_soccer_rounded,
              size: 150,
              color: Colors.white.withOpacity(0.045),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  MatchStatusBadge(label: fixture.predictionStatus),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: AppTheme.teal.withOpacity(0.18),
                      ),
                    ),
                    child: Text(
                      'Closes in ${DateTimeUtils.closeIn(fixture.predictionLockAt)}',
                      style: const TextStyle(
                        color: AppTheme.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: _HeroTeam(
                      flagUrl: fixture.teamAFlagUrl,
                      shortName: fixture.teamAShort,
                      name: fixture.teamAName,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 13),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _HeroTeam(
                      flagUrl: fixture.teamBFlagUrl,
                      shortName: fixture.teamBShort,
                      name: fixture.teamBName,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroTeam extends StatelessWidget {
  final String? flagUrl;
  final String shortName;
  final String name;

  const _HeroTeam({
    required this.flagUrl,
    required this.shortName,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamFlag(
          url: flagUrl,
          shortName: shortName,
          width: 82,
          height: 56,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(height: 10),
        Text(
          shortName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MatchInfoCard extends StatelessWidget {
  final FixtureModel fixture;

  const _MatchInfoCard({
    required this.fixture,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF091827).withOpacity(0.94),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fixture.matchTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fixture.stage,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.event_rounded,
            label: 'Start',
            value: DateTimeUtils.format(fixture.matchStartAt),
          ),
          const SizedBox(height: 11),
          _InfoRow(
            icon: Icons.lock_clock_rounded,
            label: 'Prediction lock',
            value: DateTimeUtils.format(fixture.predictionLockAt),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: Colors.white70),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _PredictionBackground extends StatelessWidget {
  final Widget child;

  const _PredictionBackground({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF061A18),
            Color(0xFF071523),
            Color(0xFF03070D),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -130,
            child: _GlowBlob(
              color: AppTheme.teal,
              size: 300,
              opacity: 0.18,
            ),
          ),
          Positioned(
            bottom: -150,
            left: -160,
            child: _GlowBlob(
              color: AppTheme.blue,
              size: 300,
              opacity: 0.10,
            ),
          ),
          child,
        ],
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
            spreadRadius: 38,
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final bool success;
  final String message;

  const _MessageCard({
    required this.success,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final color = success ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _SimpleTopBar extends StatelessWidget {
  final String title;

  const _SimpleTopBar({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BackButton(
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF091827).withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Colors.white70),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _MatchPredictionData {
  final FixtureModel? fixture;
  final List<PlayerModel> players;
  final UserMatchPrediction? existingPrediction;

  const _MatchPredictionData({
    required this.fixture,
    required this.players,
    required this.existingPrediction,
  });
}