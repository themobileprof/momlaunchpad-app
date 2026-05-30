import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/user.dart';
import '../widgets/widgets.dart';

/// Settings screen - User preferences and account management
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themePreference = ref.watch(themePreferenceProvider);

    return Scaffold(
      appBar: const MomAppBar(pageTitle: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.spaceMD,
          left: AppSpacing.spaceMD,
          right: AppSpacing.spaceMD,
          bottom: 120, // Space for floating navbar
        ),
        children: [
          _buildAccountCard(user),

          const SizedBox(height: AppSpacing.spaceLG),

          _buildSectionHeader('Premium'),
          AppListTileCard(
            leadingIcon: Icons.phone_in_talk_rounded,
            iconColor: AppColors.primaryPurple,
            title: 'Live calls',
            subtitle: 'Coming soon for Premium members',
            trailing: const AppBadge(
              label: 'Soon',
              variant: AppBadgeVariant.secondary,
              small: true,
            ),
            onTap: () => _showComingSoon(context, 'Live calls'),
          ),

          const SizedBox(height: AppSpacing.spaceLG),

          _buildSectionHeader('Preferences'),
          AppListTileCard(
            leadingIcon: Icons.language_rounded,
            title: 'Language',
            subtitle: user?.language.toUpperCase() ?? 'EN',
            onTap: () => _showComingSoon(context, 'Language settings'),
          ),
          AppListTileCard(
            leadingIcon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: 'Manage reminders & alerts',
            onTap: () => _showComingSoon(context, 'Notification settings'),
          ),
          AppListTileCard(
            leadingIcon: Icons.dark_mode_rounded,
            title: 'Appearance',
            subtitle: themePreference.label,
            onTap: () => _showAppearancePicker(context, ref),
          ),

          const SizedBox(height: AppSpacing.spaceLG),

          _buildSectionHeader('Support'),
          AppListTileCard(
            leadingIcon: Icons.help_outline_rounded,
            iconColor: AppColors.info,
            title: 'Help & FAQ',
            subtitle: 'Get answers to common questions',
            onTap: () => _showComingSoon(context, 'Help center'),
          ),
          AppListTileCard(
            leadingIcon: Icons.feedback_rounded,
            iconColor: AppColors.info,
            title: 'Send Feedback',
            subtitle: 'Help us improve the app',
            onTap: () => _showComingSoon(context, 'Feedback'),
          ),
          AppListTileCard(
            leadingIcon: Icons.star_rounded,
            iconColor: AppColors.warning,
            title: 'Rate the App',
            subtitle: 'Share your experience',
            onTap: () => _showComingSoon(context, 'Rating'),
          ),

          const SizedBox(height: AppSpacing.spaceLG),

          _buildSectionHeader('Legal'),
          AppListTileCard(
            leadingIcon: Icons.privacy_tip_rounded,
            iconColor: AppColors.textLight,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            onTap: () => _showComingSoon(context, 'Privacy policy'),
            margin: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
          ),
          AppListTileCard(
            leadingIcon: Icons.description_rounded,
            iconColor: AppColors.textLight,
            title: 'Terms of Service',
            subtitle: 'App usage guidelines',
            onTap: () => _showComingSoon(context, 'Terms of service'),
          ),

          const SizedBox(height: AppSpacing.spaceXL),

          // Logout button
          AppButton(
            label: 'Logout',
            icon: Icons.logout_rounded,
            variant: AppButtonVariant.danger,
            onPressed: () => _handleLogout(context, ref),
          ),

          const SizedBox(height: AppSpacing.spaceMD),

          // App version
          Center(
            child: Text(
              'Version 1.0.0',
              style: AppTypography.caption.copyWith(
                color: AppColors.textLight.withOpacity(0.5),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.spaceLG),
        ],
      ),
    );
  }

  Widget _buildAccountCard(User? user) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.spaceLG),
      child: Row(
        children: [
          AppAvatar(
            name: user?.name,
            size: AppAvatarSize.large,
          ),
          const SizedBox(width: AppSpacing.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'User',
                  style: AppTypography.headingMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'No email',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 8),
                AppBadge(
                  label: 'Free Plan',
                  variant: AppBadgeVariant.secondary,
                  small: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.spaceSM,
        bottom: AppSpacing.spaceSM,
      ),
      child: Text(
        title,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showAppearancePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final current = ref.watch(themePreferenceProvider);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.spaceLG),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appearance', style: AppTypography.headingMedium),
                    const SizedBox(height: AppSpacing.spaceMD),
                    ...AppThemePreference.values.map((option) {
                      final selected = current == option;
                      return ListTile(
                        title: Text(option.label),
                        trailing: selected
                            ? Icon(Icons.check_rounded, color: context.appPrimary)
                            : null,
                        onTap: () async {
                          await ref
                              .read(themePreferenceProvider.notifier)
                              .setPreference(option);
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: AppColors.primaryPurple,
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusLarge),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Logout',
            variant: AppButtonVariant.danger,
            isFullWidth: false,
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}
