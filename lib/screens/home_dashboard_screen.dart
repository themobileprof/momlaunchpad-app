import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/community_badges.dart';
import '../utils/generic_welcome.dart';
import '../utils/journey_helpers.dart';
import '../utils/baby_theme.dart';
import '../models/journey_stage.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../providers/community_badges_provider.dart';
import '../providers/home_navigation_provider.dart';
import '../providers/symptom_provider.dart';
import '../providers/welcome_provider.dart';
import '../providers/home_community_preview_provider.dart';
import '../providers/service_providers.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/widgets.dart';
import '../widgets/ongoing_symptom_prompt.dart';
import '../widgets/home_community_highlight.dart';
import '../widgets/visit_check_in_prompt.dart';
import '../widgets/ttc_home_hero.dart';
import 'calendar_screen.dart';
import 'conversation_list_screen.dart';
import 'symptom_stats_screen.dart';
import 'hospital_bag_screen.dart';

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
      ref.read(apiServiceProvider).trackUsage('home_view');
    });
  }

  @override
  Widget build(BuildContext context) {
    final welcomeState = ref.watch(welcomeProvider);
    final profile = ref.watch(profileProvider).profile;
    final badgesAsync = ref.watch(myCommunityBadgesProvider);
    final professionalLabel = badgesAsync.maybeWhen(
      data: primaryProfessionalBadgeLabel,
      orElse: () => null,
    );
    final isProfessional = badgesAsync.maybeWhen(
      data: (data) => hasProfessionalBadge(data.badges),
      orElse: () => false,
    );
    final isTtc = JourneyHelpers.isTtc(profile) && !isProfessional;

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
                      Wrap(
                        spacing: AppSpacing.spaceXS,
                        runSpacing: AppSpacing.spaceXS,
                        children: [
                          AppBadge(
                            label: professionalLabel ??
                                JourneyHelpers.homeBadgeLabel(profile),
                            icon: professionalLabel != null
                                ? Icons.verified_rounded
                                : Icons.favorite_rounded,
                            variant: professionalLabel != null
                                ? AppBadgeVariant.primary
                                : AppBadgeVariant.secondary,
                          ),
                          if (profile.babyGender != null)
                            AppBadge(
                              label:
                                  '${babyThemeLabel(profile.babyGender)} palette',
                              icon: Icons.palette_outlined,
                              variant: AppBadgeVariant.secondary,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (isTtc)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.spaceMD,
                    AppSpacing.spaceMD,
                    AppSpacing.spaceMD,
                    0,
                  ),
                  child: TtcHomeHero(
                    onTalk: () => _open(context, const ConversationListScreen()),
                    onLogSymptoms: () =>
                        _open(context, const SymptomStatsScreen()),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMD),
                child: _buildWelcomeSection(welcomeState, profile, isProfessional),
              ),
            ),
            const SliverToBoxAdapter(child: VisitCheckInPrompt()),
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
                  120,
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
                delegate: SliverChildListDelegate(
                  _quickLinks(context, profile),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _quickLinks(BuildContext context, UserProfile? profile) {
    final isTtc = JourneyHelpers.isTtc(profile);
    final isPregnant =
        JourneyHelpers.stageOf(profile) == JourneyStage.pregnant;

    if (isTtc) {
      return [
        _QuickLinkCard(
          icon: Icons.chat_bubble_rounded,
          label: 'Talk it through',
          onTap: () => _open(context, const ConversationListScreen()),
        ),
        _QuickLinkCard(
          icon: Icons.calendar_today_rounded,
          label: 'Reminders',
          onTap: () => _open(context, const CalendarScreen()),
        ),
        _QuickLinkCard(
          icon: Icons.monitor_heart_outlined,
          label: 'Log symptoms',
          onTap: () => _open(context, const SymptomStatsScreen()),
        ),
        _QuickLinkCard(
          icon: Icons.auto_awesome_rounded,
          label: 'New topic',
          onTap: () => _open(context, const ConversationListScreen()),
        ),
      ];
    }
    return [
      _QuickLinkCard(
        icon: Icons.calendar_today_rounded,
        label: 'Calendar',
        onTap: () => ref
            .read(homeTabRequestProvider.notifier)
            .openTab(calendarTabIndex),
      ),
      _QuickLinkCard(
        icon: Icons.chat_bubble_rounded,
        label: 'Chat',
        onTap: () =>
            ref.read(homeTabRequestProvider.notifier).openTab(chatTabIndex),
      ),
      _QuickLinkCard(
        icon: Icons.monitor_heart_outlined,
        label: 'Health tracker',
        onTap: () => _open(context, const SymptomStatsScreen()),
      ),
      if (isPregnant)
        _QuickLinkCard(
          icon: Icons.luggage_outlined,
          label: 'Hospital bag',
          onTap: () => _open(context, const HospitalBagScreen()),
        )
      else
        _QuickLinkCard(
          icon: Icons.auto_awesome_rounded,
          label: 'New chat',
          onTap: () =>
              ref.read(homeTabRequestProvider.notifier).openTab(chatTabIndex),
        ),
    ];
  }

  Widget _buildWelcomeSection(
    WelcomeState welcomeState,
    UserProfile? profile,
    bool isProfessional,
  ) {
    if (welcomeState.isLoading && welcomeState.message == null) {
      return const SizedBox.shrink();
    }
    final message = welcomeState.message?.message ??
        (isProfessional
            ? 'Thank you for supporting mothers in your community — chat, community, and reminders are here when you need them.'
            : genericWelcomeMessage(profile));
    return _WelcomeCard(
      message: message,
      title: JourneyHelpers.homeWelcomeTitle(profile),
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
  final String title;

  const _WelcomeCard({required this.message, required this.title});

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
              Text(title, style: AppTypography.bodyTextMedium),
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
