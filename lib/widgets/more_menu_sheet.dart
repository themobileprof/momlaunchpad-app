import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/glass_container.dart';
import '../screens/savings_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/symptom_stats_screen.dart';
import '../screens/doctor_visits_screen.dart';

/// Bottom sheet listing secondary destinations (Savings, Settings, etc.).
class MoreMenuSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                    color: AppColors.primaryPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('More', style: AppTypography.headingMedium),
              const SizedBox(height: AppSpacing.spaceSM),
              _MoreMenuItem(
                icon: Icons.savings_outlined,
                title: 'Savings',
                subtitle: 'Track your baby fund',
                onTap: () => _open(context, const SavingsScreen()),
              ),
              _MoreMenuItem(
                icon: Icons.health_and_safety_outlined,
                title: 'Health tracker',
                subtitle: 'Symptoms, vitals, and stats',
                onTap: () => _open(context, const SymptomStatsScreen()),
              ),
              _MoreMenuItem(
                icon: Icons.medical_information_outlined,
                title: 'Visit records',
                subtitle: 'Doctor visits, vitals, and medications',
                onTap: () => _open(context, const DoctorVisitsScreen()),
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

  const _MoreMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primaryPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryPurple),
      ),
      title: Text(title, style: AppTypography.bodyTextMedium),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(color: AppColors.textLight),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
