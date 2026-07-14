import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notifications_provider.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/glass_container.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/symptom_stats_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/hospital_bag_screen.dart';

/// Bottom sheet listing secondary destinations (profile, settings, etc.).
class MoreMenuSheet extends ConsumerWidget {
  const MoreMenuSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MoreMenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsProvider).unread;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spaceMD,
        0,
        AppSpacing.spaceMD,
        AppSpacing.spaceMD,
      ),
      child: GlassContainer(
        opacity: 0.95,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spaceMD,
          AppSpacing.spaceSM,
          AppSpacing.spaceMD,
          AppSpacing.spaceMD,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.spaceMD),
                  decoration: BoxDecoration(
                    color: context.appPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('More', style: AppTypography.headingMedium),
              const SizedBox(height: AppSpacing.spaceSM),
              _MoreMenuItem(
                icon: Icons.card_giftcard_outlined,
                title: 'Rewards & updates',
                subtitle: 'Top-up codes, discounts, and news',
                badgeCount: unread,
                onTap: () => _open(context, const NotificationsScreen()),
              ),
              _MoreMenuItem(
                icon: Icons.health_and_safety_outlined,
                title: 'Health tracker',
                subtitle: 'Symptoms, vitals, and stats',
                onTap: () => _open(context, const SymptomStatsScreen()),
              ),
              _MoreMenuItem(
                icon: Icons.luggage_outlined,
                title: 'Hospital bag',
                subtitle: 'Pack, price, and share your checklist',
                onTap: () => _open(context, const HospitalBagScreen()),
              ),
              _MoreMenuItem(
                icon: Icons.person_outline_rounded,
                title: 'Your profile',
                subtitle: 'Journey, location, and personalization',
                onTap: () => _open(context, const ProfileScreen()),
              ),
              _MoreMenuItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Account and app preferences',
                onTap: () => _open(context, const SettingsScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badgeCount;

  const _MoreMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.appPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: context.appPrimary),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: context.appSurface, width: 1.5),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(title, style: AppTypography.bodyTextMedium),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(color: context.appInkSubtle),
      ),
      trailing: Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
