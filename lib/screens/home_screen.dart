import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/widgets.dart';
import '../widgets/more_menu_sheet.dart';
import '../widgets/community_compose_fab.dart';
import '../providers/home_navigation_provider.dart';
import '../providers/community_provider.dart';
import '../utils/community_compose.dart';
import 'conversation_list_screen.dart';
import 'community_screen.dart';
import 'home_dashboard_screen.dart';
import 'calendar_screen.dart';

/// Primary shell: Home, Chat, Community, Calendar tabs + More menu.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  static const List<_NavItem> _primaryTabs = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      screen: HomeDashboardScreen(),
    ),
    _NavItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Chat',
      screen: ConversationListScreen(),
    ),
    _NavItem(
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
      label: 'Community',
      screen: CommunityScreen(),
    ),
    _NavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: 'Calendar',
      screen: CalendarScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onMoreTap() {
    HapticFeedback.lightImpact();
    MoreMenuSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(homeNavigationProvider, (previous, next) {
      if (next == null) return;
      if (_currentIndex != calendarTabIndex) {
        _onNavTap(calendarTabIndex);
      }
    });

    ref.listen(homeTabRequestProvider, (previous, next) {
      if (next == null) return;
      if (_currentIndex != next) {
        _onNavTap(next);
      }
      ref.read(homeTabRequestProvider.notifier).clear();
    });

    return Scaffold(
      backgroundColor: context.appCanvas,
      extendBody: true,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              if (_currentIndex != index) {
                setState(() => _currentIndex = index);
              }
            },
            physics: const NeverScrollableScrollPhysics(),
            children: _primaryTabs.map((item) => item.screen).toList(),
          ),
          _buildCommunityComposeFab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCommunityComposeFab() {
    if (_currentIndex != communityTabIndex) {
      return const SizedBox.shrink();
    }

    final communityState = ref.watch(communityProvider);
    if (communityState.needsOnboarding) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: AppSpacing.spaceLG,
      bottom: communityComposeFabBottomOffset(context),
      child: CommunityComposeFab(
        filter: communityState.filter,
        onPressed: () => openCommunityCompose(context, ref),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      child: GlassContainer(
        blur: 15,
        opacity: 0.8,
        borderRadius: BorderRadius.circular(32),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spaceXS,
          vertical: AppSpacing.spaceSM,
        ),
        child: Row(
          children: [
            for (var i = 0; i < _primaryTabs.length; i++)
              Expanded(
                child: _NavBarItem(
                  icon: _primaryTabs[i].icon,
                  activeIcon: _primaryTabs[i].activeIcon,
                  label: _primaryTabs[i].label,
                  isSelected: _currentIndex == i,
                  onTap: () => _onNavTap(i),
                ),
              ),
            Expanded(
              child: _NavBarItem(
                icon: Icons.apps_rounded,
                activeIcon: Icons.apps_rounded,
                label: 'More',
                isSelected: false,
                onTap: _onMoreTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
  });
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = context.appPrimary;
    final onPrimary = context.appOnPrimary;
    final muted = context.appInkSubtle;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spaceXS,
          vertical: AppSpacing.spaceSM,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? onPrimary : muted,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? onPrimary : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
