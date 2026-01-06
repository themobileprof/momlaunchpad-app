import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import 'call_screen.dart';
import 'chat_screen.dart';
import 'calendar_screen.dart';
import 'savings_screen.dart';
import 'settings_screen.dart';

/// Navigation item data
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

/// Home screen with bottom navigation - optimized with PageView for smoother transitions
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  // Define navigation items for cleaner code
  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.phone_in_talk_outlined,
      activeIcon: Icons.phone_in_talk_rounded,
      label: 'Call',
      screen: CallScreen(),
    ),
    _NavItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Chat',
      screen: ChatScreen(),
    ),
    _NavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: 'Calendar',
      screen: CalendarScreen(),
    ),
    _NavItem(
      icon: Icons.savings_outlined,
      activeIcon: Icons.savings_rounded,
      label: 'Savings',
      screen: SavingsScreen(),
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
      screen: SettingsScreen(),
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
    
    // Haptic feedback for better UX
    HapticFeedback.lightImpact();
    
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe navigation
        children: _navItems.map((item) => item.screen).toList(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spaceSM,
            vertical: AppSpacing.spaceSM,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _navItems.length,
              (index) => _NavBarItem(
                icon: _navItems[index].icon,
                activeIcon: _navItems[index].activeIcon,
                label: _navItems[index].label,
                isSelected: _currentIndex == index,
                onTap: () => _onNavTap(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom navigation bar item with animation
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spaceMD,
          vertical: AppSpacing.spaceSM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPink.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? AppColors.primaryPink : AppColors.textLight,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primaryPink : AppColors.textLight,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
