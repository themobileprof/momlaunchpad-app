import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../providers/welcome_provider.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/widgets.dart';
import 'calendar_screen.dart';
import 'conversation_list_screen.dart';
import 'symptom_stats_screen.dart';

/// Home dashboard with a daily personalized welcome message.
class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final welcomeAsync = ref.watch(welcomeMessageProvider);
    final profile = ref.watch(profileProvider).profile;

    return Scaffold(
      backgroundColor: context.appCanvas,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(welcomeMessageProvider);
          await ref.read(welcomeMessageProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.spaceMD,
                  AppSpacing.spaceLG,
                  AppSpacing.spaceMD,
                  AppSpacing.spaceSM,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Home', style: AppTypography.headingLarge),
                    if (profile?.pregnancyWeek != null) ...[
                      const SizedBox(height: AppSpacing.spaceXS),
                      AppBadge(
                        label: 'Week ${profile!.pregnancyWeek}',
                        icon: Icons.favorite_rounded,
                        variant: AppBadgeVariant.secondary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMD),
                child: welcomeAsync.when(
                  data: (welcome) => _WelcomeCard(message: welcome.message),
                  loading: () => const _WelcomeLoadingCard(),
                  error: (error, _) => _WelcomeErrorCard(
                    onRetry: () => ref.invalidate(welcomeMessageProvider),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.spaceMD,
                  AppSpacing.spaceLG,
                  AppSpacing.spaceMD,
                  AppSpacing.spaceSM,
                ),
                child: Text('Quick links', style: AppTypography.bodyTextMedium),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spaceMD,
                0,
                AppSpacing.spaceMD,
                120,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.spaceSM,
                  crossAxisSpacing: AppSpacing.spaceSM,
                  childAspectRatio: 1.6,
                ),
                delegate: SliverChildListDelegate([
                  _QuickLinkCard(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Chat',
                    onTap: () => _open(context, const ConversationListScreen()),
                  ),
                  _QuickLinkCard(
                    icon: Icons.calendar_today_rounded,
                    label: 'Calendar',
                    onTap: () => _open(context, const CalendarScreen()),
                  ),
                  _QuickLinkCard(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Health tracker',
                    onTap: () => _open(context, const SymptomStatsScreen()),
                  ),
                  _QuickLinkCard(
                    icon: Icons.auto_awesome_rounded,
                    label: 'New chat',
                    onTap: () => _open(context, const ConversationListScreen()),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String message;

  const _WelcomeCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.92,
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.waving_hand_rounded, color: context.appPrimary, size: 22),
              const SizedBox(width: AppSpacing.spaceSM),
              Text('Today\'s note for you', style: AppTypography.bodyTextMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          Text(
            message,
            style: AppTypography.bodyText.copyWith(
              fontSize: 16,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeLoadingCard extends StatelessWidget {
  const _WelcomeLoadingCard();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.92,
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 14,
            width: 140,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          for (var i = 0; i < 4; i++) ...[
            Container(
              height: 12,
              width: double.infinity,
              margin: EdgeInsets.only(bottom: i == 3 ? 0 : 10),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.spaceSM),
          const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeErrorCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _WelcomeErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(height: AppSpacing.spaceSM),
          Text(
            'Could not load your welcome message',
            style: AppTypography.bodyTextMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          AppButton(
            label: 'Retry',
            isFullWidth: false,
            size: AppButtonSize.small,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLinkCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: context.appPrimary),
          const SizedBox(height: AppSpacing.spaceSM),
          Text(label, style: AppTypography.bodyTextMedium),
        ],
      ),
    );
  }
}
