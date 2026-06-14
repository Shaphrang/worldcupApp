import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../models/app_user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _profileService = ProfileService();

  late Future<ProfilePageData> _future;

  bool _pageSaving = false;

  @override
  void initState() {
    super.initState();
    _future = _profileService.profilePageData();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _profileService.profilePageData();
    });

    await _future;
  }

  void _goHome() {
    context.go('/home');
  }

  Future<void> _logout() async {
    await _auth.logout();

    if (!mounted) return;

    context.go('/home');
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF071827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Future<void> _openEditProfileSheet(AppUserProfile? profile) async {
    final nameController = TextEditingController(
      text: profile?.fullName ?? '',
    );

    final mobileController = TextEditingController(
      text: profile?.mobileNumber ?? '',
    );

    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> save() async {
              final name = nameController.text.trim();
              final mobile = mobileController.text.trim();

              if (name.isEmpty) {
                _showMessage('Please enter your full name.');
                return;
              }

              if (mobile.isEmpty) {
                _showMessage('Please enter your mobile number.');
                return;
              }

              if (mobile.length < 8) {
                _showMessage('Please enter a valid mobile number.');
                return;
              }

              setSheetState(() => saving = true);
              setState(() => _pageSaving = true);

              try {
                await _profileService.updateProfile(name, mobile);

                if (!mounted) return;

                Navigator.of(sheetContext).pop();

                _showMessage('Profile updated successfully.');

                setState(() {
                  _future = _profileService.profilePageData();
                });
              } catch (_) {
                _showMessage('Could not update profile. Please try again.');
              } finally {
                if (mounted) {
                  setState(() => _pageSaving = false);
                }

                if (sheetContext.mounted) {
                  setSheetState(() => saving = false);
                }
              }
            }

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: _EditProfileSheet(
                nameController: nameController,
                mobileController: mobileController,
                saving: saving,
                onSave: save,
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    mobileController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _goHome();
      },
      child: !_auth.isLoggedIn
          ? _LoggedOutProfileView(
              onBackHome: _goHome,
            )
          : Scaffold(
              backgroundColor: AppTheme.background,
              body: _ProfileBackground(
                child: SafeArea(
                  bottom: false,
                  child: RefreshIndicator(
                    color: AppTheme.teal,
                    backgroundColor: const Color(0xFF071827),
                    onRefresh: _refresh,
                    child: FutureBuilder<ProfilePageData>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const _ProfileLoadingView();
                        }

                        if (snapshot.hasError) {
                          return _ProfileErrorView(
                            onBackHome: _goHome,
                            onRetry: _refresh,
                          );
                        }

                        final data = snapshot.data ?? ProfilePageData.empty();
                        final profile = data.profile;
                        final predictions = data.predictions;

                        return CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  14,
                                  14,
                                  110,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _TopBar(
                                      onBackHome: _goHome,
                                      saving: _pageSaving,
                                    ),

                                    const SizedBox(height: 14),

                                    _ProfileHeroCard(
                                      profile: profile,
                                      email: profile?.email ??
                                          _auth.currentUser?.email ??
                                          '',
                                      onEdit: () =>
                                          _openEditProfileSheet(profile),
                                      onLogout: _logout,
                                    ),

                                    const SizedBox(height: 14),

                                    _ProfileStats(stats: data.stats),

                                    const SizedBox(height: 14),

                                    _CompactPrivacyCard(
                                      email: profile?.email ??
                                          _auth.currentUser?.email ??
                                          '',
                                      mobile: profile?.mobileNumber ?? '',
                                    ),

                                    const SizedBox(height: 18),

                                    _SectionHeader(
                                      title: 'My Predictions',
                                      subtitle:
                                          '${predictions.length} latest prediction${predictions.length == 1 ? '' : 's'}',
                                    ),

                                    const SizedBox(height: 10),

                                    if (predictions.isEmpty)
                                      const _EmptyPredictionsCard()
                                    else
                                      ...predictions.map(
                                        (item) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: _PredictionCard(item: item),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBackHome;
  final bool saving;

  const _TopBar({
    required this.onBackHome,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: onBackHome,
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        if (saving)
          const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.3,
              color: AppTheme.teal,
            ),
          ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.07),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 42,
          width: 42,
          child: Icon(
            icon,
            color: Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _LoggedOutProfileView extends StatelessWidget {
  final VoidCallback onBackHome;

  const _LoggedOutProfileView({
    required this.onBackHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _ProfileBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: onBackHome,
                    ),
                    const Spacer(),
                  ],
                ),
                const Spacer(),
                Container(
                  height: 92,
                  width: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.teal.withOpacity(0.95),
                        const Color(0xFF57A6FF).withOpacity(0.85),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.teal.withOpacity(0.30),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Your Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Login to submit predictions, view your history, and track your winning chances.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.66),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => context.go('/login?redirect=/profile'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => context.go('/register?redirect=/profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.20),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  final AppUserProfile? profile;
  final String email;
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  const _ProfileHeroCard({
    required this.profile,
    required this.email,
    required this.onEdit,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = profile?.fullName.trim() ?? '';
    final name = fullName.isEmpty ? 'Football Fan' : fullName;
    final mobile = profile?.mobileNumber.trim() ?? '';
    final initial = name.trim().isEmpty ? 'F' : name.trim()[0].toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
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
          color: Colors.white.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppTheme.teal.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -34,
            child: Icon(
              Icons.sports_soccer_rounded,
              size: 140,
              color: Colors.white.withOpacity(0.045),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(
                    initial: initial,
                    avatarUrl: profile?.avatarUrl,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MY PROFILE',
                          style: TextStyle(
                            color: AppTheme.teal,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email.isEmpty ? 'No email available' : email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.58),
                            fontSize: 11.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.065),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_iphone_rounded,
                      color: AppTheme.teal,
                      size: 18,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        mobile.isEmpty
                            ? 'Mobile number not added'
                            : Validators.maskMobile(mobile),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      'Public display',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.48),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(
                          Icons.edit_rounded,
                          size: 18,
                        ),
                        label: const Text('Edit Profile'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 44,
                    width: 48,
                    child: OutlinedButton(
                      onPressed: onLogout,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.14),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        size: 20,
                      ),
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

class _Avatar extends StatelessWidget {
  final String initial;
  final String? avatarUrl;

  const _Avatar({
    required this.initial,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return Container(
      height: 62,
      width: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasImage
            ? null
            : const LinearGradient(
                colors: [
                  AppTheme.teal,
                  Color(0xFF57A6FF),
                ],
              ),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.teal.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasImage
          ? Image.network(
              avatarUrl!,
              height: 62,
              width: 62,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  final ProfilePageStats stats;

  const _ProfileStats({
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Points',
                value: '${stats.totalPoints}',
                icon: Icons.workspace_premium_rounded,
                color: AppTheme.teal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Predictions',
                value: '${stats.totalPredictions}',
                icon: Icons.fact_check_rounded,
                color: const Color(0xFF57A6FF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Exact',
                value: '${stats.exactScoreHits}',
                icon: Icons.verified_rounded,
                color: const Color(0xFFFFB84D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniStatPill(
                label: 'Scorer hits',
                value: '${stats.scorerHits}',
                icon: Icons.sports_soccer_rounded,
                color: AppTheme.teal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStatPill(
                label: 'Time bonus',
                value: '${stats.timePoints}',
                icon: Icons.schedule_rounded,
                color: const Color(0xFFFFB84D),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStatPill(
                label: 'Pending',
                value: '${stats.pendingPredictions}',
                icon: Icons.timelapse_rounded,
                color: const Color(0xFF57A6FF),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF071827),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.54),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.075),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.13),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
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

class _CompactPrivacyCard extends StatelessWidget {
  final String email;
  final String mobile;

  const _CompactPrivacyCard({
    required this.email,
    required this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MiniTitle(
            icon: Icons.shield_rounded,
            title: 'Privacy',
          ),
          const SizedBox(height: 10),
          _PrivacyMiniRow(
            label: 'Email',
            value: email.isEmpty ? 'Not available' : email,
            icon: Icons.email_rounded,
          ),
          const SizedBox(height: 8),
          _PrivacyMiniRow(
            label: 'Mobile',
            value: mobile.isEmpty ? 'Not added' : Validators.maskMobile(mobile),
            icon: Icons.visibility_rounded,
          ),
        ],
      ),
    );
  }
}

class _PrivacyMiniRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _PrivacyMiniRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.teal,
          size: 16,
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.50),
              fontSize: 11.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditProfileSheet extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController mobileController;
  final bool saving;
  final Future<void> Function() onSave;

  const _EditProfileSheet({
    required this.nameController,
    required this.mobileController,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF06111E),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: AppTheme.teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: saving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileTextField(
              controller: nameController,
              label: 'Full Name',
              icon: Icons.person_rounded,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _ProfileTextField(
              controller: mobileController,
              label: 'Mobile Number',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: saving ? null : onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  disabledBackgroundColor: Colors.white.withOpacity(0.10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      cursorColor: AppTheme.teal,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.52),
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: Icon(
          icon,
          color: AppTheme.teal,
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.055),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: AppTheme.teal,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.history_rounded,
          color: AppTheme.teal,
          size: 21,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.48),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final ProfilePredictionItem item;

  const _PredictionCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final status = item.isPending
        ? const _PredictionUiStatus(
            label: 'Submitted',
            color: Color(0xFFFFB84D),
            icon: Icons.timelapse_rounded,
          )
        : item.isExactScoreCorrect
            ? const _PredictionUiStatus(
                label: 'Exact Hit',
                color: AppTheme.teal,
                icon: Icons.verified_rounded,
              )
            : const _PredictionUiStatus(
                label: 'Missed',
                color: Color(0xFFFF6B6B),
                icon: Icons.close_rounded,
              );

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF071827),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusBadge(status: status),
              const SizedBox(width: 8),
              if (item.isEvaluated)
                _PointsBadge(points: item.pointsTotal)
              else
                const _UpcomingBadge(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.stage ?? 'Match Prediction',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.44),
                    fontSize: 10.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            item.matchTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(item.matchStartAt),
            style: TextStyle(
              color: Colors.white.withOpacity(0.48),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.045),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [
                _ScoreLine(
                  label: 'Your pick',
                  teamA: item.teamAName,
                  teamB: item.teamBName,
                  teamAFlagUrl: item.teamAFlagUrl,
                  teamBFlagUrl: item.teamBFlagUrl,
                  scoreA: item.predictedTeamAScore.toString(),
                  scoreB: item.predictedTeamBScore.toString(),
                  highlight: true,
                ),
                if (item.hasActualScore) ...[
                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color: Colors.white.withOpacity(0.08),
                  ),
                  const SizedBox(height: 10),
                  _ScoreLine(
                    label: 'Final',
                    teamA: item.teamAName,
                    teamB: item.teamBName,
                    teamAFlagUrl: item.teamAFlagUrl,
                    teamBFlagUrl: item.teamBFlagUrl,
                    scoreA: item.actualTeamAScore.toString(),
                    scoreB: item.actualTeamBScore.toString(),
                    highlight: false,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Icon(
                Icons.person_pin_circle_rounded,
                color: AppTheme.teal.withOpacity(0.95),
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  item.scorerName == null || item.scorerName!.trim().isEmpty
                      ? 'No goal scorer selected'
                      : 'Scorer: ${item.scorerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.66),
                    fontSize: 11.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _submittedText(item.submittedAt),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.38),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (item.isEvaluated) ...[
            const SizedBox(height: 10),
            _PointsBreakdown(item: item),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return 'Date not available';

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();

    final hour = value.hour > 12
        ? value.hour - 12
        : value.hour == 0
            ? 12
            : value.hour;

    final minute = value.minute.toString().padLeft(2, '0');
    final ampm = value.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year • $hour:$minute $ampm';
  }

  static String _submittedText(DateTime? value) {
    if (value == null) return '';

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');

    return '$day/$month';
  }
}

class _PredictionUiStatus {
  final String label;
  final Color color;
  final IconData icon;

  const _PredictionUiStatus({
    required this.label,
    required this.color,
    required this.icon,
  });
}

class _StatusBadge extends StatelessWidget {
  final _PredictionUiStatus status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: status.color.withOpacity(0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            color: status.color,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  final int points;

  const _PointsBadge({
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = points > 0;
    final color = isPositive ? AppTheme.teal : Colors.white38;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isPositive ? 0.13 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(isPositive ? 0.28 : 0.12),
        ),
      ),
      child: Text(
        '$points pts',
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _UpcomingBadge extends StatelessWidget {
  const _UpcomingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      child: Text(
        'Waiting',
        style: TextStyle(
          color: Colors.white.withOpacity(0.60),
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ScoreLine extends StatelessWidget {
  final String label;
  final String teamA;
  final String teamB;
  final String? teamAFlagUrl;
  final String? teamBFlagUrl;
  final String scoreA;
  final String scoreB;
  final bool highlight;

  const _ScoreLine({
    required this.label,
    required this.teamA,
    required this.teamB,
    required this.teamAFlagUrl,
    required this.teamBFlagUrl,
    required this.scoreA,
    required this.scoreB,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = highlight ? AppTheme.teal : Colors.white;

    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: _TeamMiniName(
            name: teamA,
            flagUrl: teamAFlagUrl,
            reverse: true,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 9),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: scoreColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scoreColor.withOpacity(0.22),
            ),
          ),
          child: Text(
            '$scoreA - $scoreB',
            style: TextStyle(
              color: scoreColor,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: _TeamMiniName(
            name: teamB,
            flagUrl: teamBFlagUrl,
            reverse: false,
          ),
        ),
      ],
    );
  }
}

class _TeamMiniName extends StatelessWidget {
  final String name;
  final String? flagUrl;
  final bool reverse;

  const _TeamMiniName({
    required this.name,
    required this.flagUrl,
    required this.reverse,
  });

  @override
  Widget build(BuildContext context) {
    final flag = flagUrl == null || flagUrl!.trim().isEmpty
        ? const SizedBox.shrink()
        : ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              flagUrl!,
              height: 14,
              width: 20,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          );

    final text = Expanded(
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: reverse ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Row(
      mainAxisAlignment:
          reverse ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: reverse
          ? [
              text,
              const SizedBox(width: 6),
              flag,
            ]
          : [
              flag,
              const SizedBox(width: 6),
              text,
            ],
    );
  }
}

class _PointsBreakdown extends StatelessWidget {
  final ProfilePredictionItem item;

  const _PointsBreakdown({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF02070D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          _BreakdownItem(
            label: 'Exact',
            value: item.exactScorePoints,
          ),
          const _BreakdownDivider(),
          _BreakdownItem(
            label: 'Scorer',
            value: item.playerPoints,
          ),
          const _BreakdownDivider(),
          _BreakdownItem(
            label: 'Time',
            value: item.timePoints,
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  final String label;
  final int value;

  const _BreakdownItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.42),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownDivider extends StatelessWidget {
  const _BreakdownDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      width: 1,
      color: Colors.white.withOpacity(0.08),
    );
  }
}

class _EmptyPredictionsCard extends StatelessWidget {
  const _EmptyPredictionsCard();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: AppTheme.teal.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_soccer_rounded,
              color: AppTheme.teal,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No predictions yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your submitted match predictions will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.54),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () => context.go('/fixtures'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'View Fixtures',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _CardShell({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF071827),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MiniTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _MiniTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.teal,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
      children: const [
        Row(
          children: [
            _SkeletonCircle(size: 42),
            SizedBox(width: 10),
            Expanded(child: _SkeletonBox(height: 32)),
          ],
        ),
        SizedBox(height: 14),
        _SkeletonBox(height: 205),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _SkeletonBox(height: 86)),
            SizedBox(width: 10),
            Expanded(child: _SkeletonBox(height: 86)),
            SizedBox(width: 10),
            Expanded(child: _SkeletonBox(height: 86)),
          ],
        ),
        SizedBox(height: 14),
        _SkeletonBox(height: 76),
        SizedBox(height: 18),
        _SkeletonBox(height: 210),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;

  const _SkeletonBox({
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  final double size;

  const _SkeletonCircle({
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  final VoidCallback onBackHome;
  final Future<void> Function() onRetry;

  const _ProfileErrorView({
    required this.onBackHome,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
      children: [
        Row(
          children: [
            _CircleIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBackHome,
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 90),
        Icon(
          Icons.error_outline_rounded,
          color: Colors.white.withOpacity(0.75),
          size: 54,
        ),
        const SizedBox(height: 14),
        const Text(
          'Could not load profile',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please check your connection and try again.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileBackground extends StatelessWidget {
  final Widget child;

  const _ProfileBackground({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.background),
      child: Stack(
        children: [
          Positioned(
            top: -160,
            right: -140,
            child: _GlowBlob(
              color: AppTheme.teal,
              size: 310,
              opacity: 0.15,
            ),
          ),
          Positioned(
            bottom: -180,
            left: -160,
            child: _GlowBlob(
              color: Color(0xFF57A6FF),
              size: 300,
              opacity: 0.08,
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
            blurRadius: 100,
            spreadRadius: 46,
          ),
        ],
      ),
    );
  }
}