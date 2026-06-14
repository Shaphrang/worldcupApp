import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../fixtures/fixtures_screen.dart';
import '../home/home_screen.dart';
import '../predictions/my_predictions_screen.dart';
import '../rules/rules_screen.dart';
import '../winners/winners_screen.dart';

class MainShellScreen extends StatelessWidget {
  final Widget child;

  const MainShellScreen({
    super.key,
    required this.child,
  });

  int _selectedIndex(String location) {
    if (location.startsWith('/fixtures')) return 0;
    if (location.startsWith('/rules')) return 1;
    if (location == '/' || location.startsWith('/home')) return 2;
    if (location.startsWith('/my-predictions')) return 3;
    if (location.startsWith('/winners')) return 4;

    return 2;
  }

  String _pathForIndex(int index) {
    switch (index) {
      case 0:
        return '/fixtures';
      case 1:
        return '/rules';
      case 2:
        return '/home';
      case 3:
        return '/my-predictions';
      case 4:
        return '/winners';
      default:
        return '/home';
    }
  }

  Future<bool> _confirmExit(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF091827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Close app?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Do you want to close World Cup Predictions?',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.tealDark,
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _selectedIndex(location);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (selectedIndex != 2) {
          context.go('/home');
          return;
        }

        final shouldExit = await _confirmExit(context);

        if (!context.mounted) return;

        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        extendBody: false,
        body: child,
        bottomNavigationBar: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: _BottomRectangleNavBar(
            selectedIndex: selectedIndex,
            onTap: (index) {
              final nextPath = _pathForIndex(index);

              if (nextPath == location) return;

              context.go(nextPath);
            },
          ),
        ),
      ),
    );
  }
}

class _BottomRectangleNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomRectangleNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      _NavItem(
        label: 'Fixtures',
        icon: Icons.sports_soccer_outlined,
        activeIcon: Icons.sports_soccer_rounded,
        color: Color(0xFFFFB84D),
      ),
      _NavItem(
        label: 'Rules',
        icon: Icons.rule_outlined,
        activeIcon: Icons.rule_rounded,
        color: Color(0xFFFF7A3D),
      ),
      _NavItem(
        label: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        color: AppTheme.teal,
      ),
      _NavItem(
        label: 'Predict',
        icon: Icons.center_focus_weak_rounded,
        activeIcon: Icons.center_focus_strong_rounded,
        color: Color(0xFF57A6FF),
      ),
      _NavItem(
        label: 'Winners',
        icon: Icons.emoji_events_outlined,
        activeIcon: Icons.emoji_events_rounded,
        color: Color(0xFFE8B647),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF02070D),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.52),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
          BoxShadow(
            color: AppTheme.teal.withOpacity(0.12),
            blurRadius: 22,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: Column(
            children: [
              const _NavigationTopGlow(),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(7, 5, 7, 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF10263A),
                        Color(0xFF071827),
                        Color(0xFF050E18),
                      ],
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.10),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      for (int i = 0; i < items.length; i++)
                        Expanded(
                          child: _NavButton(
                            item: items[i],
                            selected: selectedIndex == i,
                            isHome: i == 2,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationTopGlow extends StatelessWidget {
  const _NavigationTopGlow();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 2.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.teal.withOpacity(0.0),
                AppTheme.teal.withOpacity(0.85),
                const Color(0xFFFFB84D).withOpacity(0.95),
                const Color(0xFFFF7A3D).withOpacity(0.85),
                AppTheme.teal.withOpacity(0.0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.teal.withOpacity(0.38),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        Container(
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.teal.withOpacity(0.10),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final bool isHome;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.isHome,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      item.color.withOpacity(0.30),
                      item.color.withOpacity(0.12),
                      Colors.white.withOpacity(0.03),
                    ],
                  )
                : null,
            border: Border.all(
              color: selected
                  ? item.color.withOpacity(0.42)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: item.color.withOpacity(0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              height: 46,
              width: 58,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 25,
                    width: 25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? item.color.withOpacity(0.18)
                          : Colors.transparent,
                      border: selected
                          ? Border.all(
                              color: item.color.withOpacity(0.22),
                            )
                          : null,
                    ),
                    child: Icon(
                      selected ? item.activeIcon : item.icon,
                      color: selected ? item.color : Colors.white54,
                      size: isHome ? 18.5 : 17.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white54,
                      fontSize: selected ? 9.5 : 8.8,
                      fontWeight:
                          selected ? FontWeight.w900 : FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color color;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.color,
  });
}

class HomeScreenTab extends HomeScreen {
  const HomeScreenTab({super.key});
}

class FixturesScreenTab extends FixturesScreen {
  const FixturesScreenTab({super.key});
}

class MyPredictionsScreenTab extends MyPredictionsScreen {
  const MyPredictionsScreenTab({super.key});
}

class RulesScreenTab extends RulesScreen {
  const RulesScreenTab({super.key});
}

class WinnersScreenTab extends WinnersScreen {
  const WinnersScreenTab({super.key});
}