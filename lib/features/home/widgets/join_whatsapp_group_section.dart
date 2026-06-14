import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/app_link_model.dart';
import '../../../services/app_link_service.dart';

class JoinWhatsAppGroupSection extends StatefulWidget {
  final AppLinkModel? link;

  const JoinWhatsAppGroupSection({
    super.key,
    this.link,
  });

  @override
  State<JoinWhatsAppGroupSection> createState() =>
      _JoinWhatsAppGroupSectionState();
}

class _JoinWhatsAppGroupSectionState extends State<JoinWhatsAppGroupSection> {
  late Future<AppLinkModel?> _future;

  static const String _linkKey = 'home_whatsapp_group';

  @override
  void initState() {
    super.initState();
    _future = widget.link != null ? Future.value(widget.link) : _loadLink();
  }


  @override
  void didUpdateWidget(covariant JoinWhatsAppGroupSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.link != widget.link && widget.link != null) {
      _future = Future.value(widget.link);
    }
  }

  Future<AppLinkModel?> _loadLink() {
    return AppLinkService.instance.getLink(
      linkKey: _linkKey,
    );
  }

  Future<void> _openLink(AppLinkModel link) async {
    final uri = Uri.tryParse(link.url.trim());

    if (uri == null) return;

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppLinkModel?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _JoinGroupSkeleton();
        }

        if (snapshot.hasError) {
          debugPrint('Join WhatsApp group error: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        final link = snapshot.data;

        if (link == null || link.url.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return _JoinGroupCard(
          link: link,
          onTap: () => _openLink(link),
        );
      },
    );
  }
}

class _JoinGroupCard extends StatelessWidget {
  final AppLinkModel link;
  final VoidCallback onTap;

  const _JoinGroupCard({
    required this.link,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = link.subtitle ??
        'Join the group for match updates, prize information, reminders, and participation details.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF86EFAC),
            Color(0xFF18D6B1),
            Color(0xFFFFD166),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF18D6B1).withOpacity(0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF073B33),
              Color(0xFF071827),
              Color(0xFF03121C),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -22,
              top: -24,
              child: Icon(
                Icons.groups_rounded,
                size: 118,
                color: Colors.white.withOpacity(0.045),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF25D366).withOpacity(0.16),
                        border: Border.all(
                          color: const Color(0xFF25D366).withOpacity(0.30),
                        ),
                      ),
                      child: const Icon(
                        Icons.forum_rounded,
                        color: Color(0xFF86EFAC),
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            link.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Stay connected with the prediction community',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF86EFAC),
                              fontSize: 10.8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 12.1,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _BenefitPill(
                        icon: Icons.notifications_active_rounded,
                        label: 'Match updates',
                        color: AppTheme.teal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BenefitPill(
                        icon: Icons.card_giftcard_rounded,
                        label: 'Prize info',
                        color: AppTheme.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: onTap,
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                    ),
                    label: Text(
                      link.buttonText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: const Color(0xFF052E24),
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
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

class _BenefitPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BenefitPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinGroupSkeleton extends StatelessWidget {
  const _JoinGroupSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 194,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
    );
  }
}