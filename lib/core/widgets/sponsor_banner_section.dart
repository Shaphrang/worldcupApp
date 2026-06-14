import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/sponsor_banner_model.dart';
import '../../services/sponsor_banner_service.dart';
import '../theme/app_theme.dart';

class SponsorBannerSection extends StatefulWidget {
  final String placement;
  final String slot;
  final bool includeGlobal;
  final double height;
  final int limit;
  final bool autoPlay;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final bool showSponsoredLabel;
  final bool openLinkOnTap;
  final void Function(SponsorBannerModel banner)? onBannerTap;

  const SponsorBannerSection({
    super.key,
    required this.placement,
    this.slot = SponsorBannerSlot.top,
    this.includeGlobal = true,
    this.height = 118,
    this.limit = 5,
    this.autoPlay = true,
    this.margin,
    this.borderRadius,
    this.showSponsoredLabel = true,
    this.openLinkOnTap = true,
    this.onBannerTap,
  });

  @override
  State<SponsorBannerSection> createState() => _SponsorBannerSectionState();
}

class _SponsorBannerSectionState extends State<SponsorBannerSection> {
  final PageController _pageController = PageController();

  Timer? _timer;
  int _currentIndex = 0;

  late Future<List<SponsorBannerModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadBannersAndStartAutoPlay();
  }

  @override
  void didUpdateWidget(covariant SponsorBannerSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    final shouldReload = oldWidget.placement != widget.placement ||
        oldWidget.slot != widget.slot ||
        oldWidget.limit != widget.limit ||
        oldWidget.includeGlobal != widget.includeGlobal ||
        oldWidget.autoPlay != widget.autoPlay;

    if (!shouldReload) return;

    _timer?.cancel();
    _timer = null;
    _currentIndex = 0;

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }

    setState(() {
      _future = _loadBannersAndStartAutoPlay();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<List<SponsorBannerModel>> _loadBannersAndStartAutoPlay({
    bool forceRefresh = false,
  }) async {
    final banners = await SponsorBannerService.instance.getBanners(
      placement: widget.placement,
      slot: widget.slot,
      limit: widget.limit,
      includeGlobal: widget.includeGlobal,
      forceRefresh: forceRefresh,
    );

    if (!mounted) return banners;

    _startAutoPlay(banners.length);

    return banners;
  }

  void _startAutoPlay(int itemCount) {
    _timer?.cancel();
    _timer = null;

    if (!widget.autoPlay || itemCount <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;

      final nextIndex = (_currentIndex + 1) % itemCount;

      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _handleBannerTap(SponsorBannerModel banner) async {
    widget.onBannerTap?.call(banner);

    if (!widget.openLinkOnTap) return;

    final link = banner.linkUrl?.trim();
    if (link == null || link.isEmpty) return;

    final uri = Uri.tryParse(link);
    if (uri == null) return;

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> refresh() async {
    SponsorBannerService.instance.clearPlacementSlot(
      widget.placement,
      widget.slot,
    );

    _timer?.cancel();
    _timer = null;

    setState(() {
      _future = _loadBannersAndStartAutoPlay(forceRefresh: true);
    });

    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(22);

    return FutureBuilder<List<SponsorBannerModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _BannerSkeleton(
            height: widget.height,
            margin: widget.margin,
            radius: radius,
          );
        }

        if (snapshot.hasError) {
          debugPrint('Sponsor banner error: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        final banners = snapshot.data ?? [];

        if (banners.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: widget.margin,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 16,
                offset: const Offset(0, 9),
              ),
              BoxShadow(
                color: AppTheme.teal.withOpacity(0.07),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: banners.length,
                  physics: banners.length > 1
                      ? const PageScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    if (!mounted) return;
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final banner = banners[index];

                    return _SponsorBannerImage(
                      banner: banner,
                      onTap: () => _handleBannerTap(banner),
                    );
                  },
                ),
                if (widget.showSponsoredLabel)
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: _SponsoredLabel(),
                  ),
                if (banners.length > 1)
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: _BannerDots(
                      count: banners.length,
                      activeIndex: _currentIndex,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SponsorBannerImage extends StatelessWidget {
  final SponsorBannerModel banner;
  final VoidCallback onTap;

  const _SponsorBannerImage({
    required this.banner,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLink = banner.linkUrl != null && banner.linkUrl!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasLink ? onTap : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              banner.imageUrl,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const _ImageLoadingFallback();
              },
              errorBuilder: (context, error, stackTrace) {
                return _ImageErrorFallback(title: banner.title);
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withOpacity(0.20),
                    Colors.transparent,
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

class _SponsoredLabel extends StatelessWidget {
  const _SponsoredLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.16),
        ),
      ),
      child: const Text(
        'SPONSORED',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          height: 1,
        ),
      ),
    );
  }
}

class _BannerDots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _BannerDots({
    required this.count,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        final active = index == activeIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.only(left: 4),
          height: 5,
          width: active ? 16 : 5,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withOpacity(0.42),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _BannerSkeleton extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry? margin;
  final BorderRadius radius;

  const _BannerSkeleton({
    required this.height,
    required this.margin,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: radius,
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
    );
  }
}

class _ImageLoadingFallback extends StatelessWidget {
  const _ImageLoadingFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF071827),
      alignment: Alignment.center,
      child: SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: AppTheme.teal.withOpacity(0.85),
        ),
      ),
    );
  }
}

class _ImageErrorFallback extends StatelessWidget {
  final String title;

  const _ImageErrorFallback({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF071827),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppTheme.teal.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: AppTheme.teal,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title.trim().isEmpty ? 'Sponsored Banner' : title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}