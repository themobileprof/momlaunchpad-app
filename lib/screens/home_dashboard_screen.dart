import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/journey_helpers.dart';
import '../providers/profile_provider.dart';
import '../providers/symptom_provider.dart';
import '../providers/welcome_provider.dart';
import '../providers/home_community_preview_provider.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/widgets.dart';
import '../widgets/log_vitals_sheet.dart';
import '../widgets/ongoing_symptom_prompt.dart';
import '../widgets/home_community_highlight.dart';
import 'calendar_screen.dart';
import 'conversation_list_screen.dart';
import 'doctor_visit_form_screen.dart';
import 'symptom_stats_screen.dart';

/// Home dashboard with a weekly personalized welcome message.
class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(welcomeProvider.notifier).ensureFreshForHome();
      ref.read(homeCommunityPreviewProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final welcomeState = ref.watch(welcomeProvider);
    final profile = ref.watch(profileProvider).profile;

    return Scaffold(
      backgroundColor: context.appCanvas,
      appBar: const MomAppBar(pageTitle: 'Home'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentSymptomsProvider);
          ref.invalidate(symptomStatsProvider);
          await ref.read(homeCommunityPreviewProvider.notifier).load();
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
                    if (profile != null) ...[
                      AppBadge(
                        label: JourneyHelpers.homeBadgeLabel(profile),
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
                child: _buildWelcomeSection(welcomeState),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.spaceLG),
                child: HomeCommunityHighlight(),
              ),
            ),
            const SliverToBoxAdapter(child: OngoingSymptomPrompt()),
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
                0,
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.spaceMD,
                  AppSpacing.spaceLG,
                  AppSpacing.spaceMD,
                  AppSpacing.spaceSM,
                ),
                child: Text('Health logging', style: AppTypography.bodyTextMedium),
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
                    icon: Icons.add_circle_outline,
                    label: 'Log vitals',
                    onTap: () => _openLogVitals(context),
                  ),
                  _QuickLinkCard(
                    icon: Icons.local_hospital_outlined,
                    label: 'Doctor visit',
                    onTap: () => _openDoctorVisitForm(context),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLogVitals(BuildContext context) async {
    await LogVitalsSheet.show(context);
  }

  void _openDoctorVisitForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DoctorVisitFormScreen(),
      ),
    );
  }

  Widget _buildWelcomeSection(WelcomeState welcomeState) {
    if (welcomeState.isLoading && welcomeState.message == null) {
      return const SizedBox.shrink();
    }
    if (welcomeState.error != null && welcomeState.message == null) {
      return _WelcomeErrorCard(
        onRetry: () => ref.read(welcomeProvider.notifier).refreshWelcome(),
      );
    }
    if (welcomeState.message != null) {
      return _WelcomeCard(message: welcomeState.message!.message);
    }
    return const SizedBox.shrink();
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
              Text('This week\'s note for you', style: AppTypography.bodyTextMedium),
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
