import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journey_stage.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../utils/journey_helpers.dart';
import '../utils/pregnancy_timing.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_button.dart';
import '../widgets/journey_stage_picker.dart';

/// First-time walkthrough — pregnancy-first, with TTC support at signup.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();

  int _step = 0;
  JourneyStage? _journeyStage;
  int _pregnancyWeek = 20;
  bool? _isFirstPregnancy;
  bool _isSubmitting = false;

  static const _stepCount = 4;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null && user.name.isNotEmpty) {
      _nameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 1 && _nameController.text.trim().isEmpty) {
      _showMessage('Please enter your name');
      return;
    }
    if (_step == 2 && _journeyStage == null) {
      _showMessage('Please choose where you are on your journey');
      return;
    }
    if (_step == 3) {
      if (_journeyStage == JourneyStage.pregnant && _isFirstPregnancy == null) {
        _showMessage('Please let us know if this is your first pregnancy');
        return;
      }
    }

    if (_step < _stepCount - 1) {
      setState(() => _step++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    _submit();
  }

  void _previousStep() {
    if (_step == 0) return;
    setState(() => _step--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _submit() async {
    final stage = _journeyStage;
    if (stage == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(profileProvider.notifier).completeOnboarding(
            ProfileSavePayload(
              name: _nameController.text.trim(),
              language: AppConfig.languageCode,
              journeyStage: stage,
              pregnancyWeek:
                  JourneyHelpers.needsPregnancyWeek(stage) ? _pregnancyWeek : null,
              isFirstPregnancy: _journeyStage == JourneyStage.pregnant
                  ? (_isFirstPregnancy ?? true)
                  : null,
            ),
          );
    } catch (_) {
      if (mounted) {
        _showMessage('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.spaceLG,
                  AppSpacing.spaceMD,
                  AppSpacing.spaceLG,
                  AppSpacing.spaceSM,
                ),
                child: _buildProgressHeader(),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildWelcomeStep(),
                    _buildNameStep(),
                    _buildJourneyStep(),
                    _buildStageDetailsStep(),
                  ],
                ),
              ),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Getting to know you',
          style: AppTypography.headingMedium.copyWith(color: context.appInk),
        ),
        const SizedBox(height: AppSpacing.spaceSM),
        Row(
          children: List.generate(_stepCount, (index) {
            final active = index <= _step;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(
                  right: index == _stepCount - 1 ? 0 : AppSpacing.spaceXS,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: active
                      ? context.appPrimary
                      : context.appPrimary.withValues(alpha: 0.15),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceLG),
      child: Row(
        children: [
          if (_step > 0)
            TextButton(
              onPressed: _isSubmitting ? null : _previousStep,
              child: Text(
                'Back',
                style: AppTypography.button.copyWith(
                  color: context.appPrimary,
                ),
              ),
            )
          else
            const SizedBox(width: 64),
          Expanded(
            child: GradientButton(
              label: _step == _stepCount - 1 ? 'Start chatting' : 'Continue',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _nextStep,
              icon: _step == _stepCount - 1
                  ? Icons.chat_bubble_outline_rounded
                  : Icons.arrow_forward_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({required Widget child}) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLG),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.spaceLG),
          child: child,
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return _buildStepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.appPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.favorite_rounded, color: context.appOnPrimary),
          ),
          const SizedBox(height: AppSpacing.spaceLG),
          Text(
            'Support for your journey',
            style: AppTypography.headingLarge.copyWith(color: context.appInk),
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          Text(
            'MomLaunchPad is your pregnancy companion — personalized chat, community, and gentle tools. We also support you if you\'re trying to conceive.',
            style: AppTypography.bodyText.copyWith(color: context.appInkMuted),
          ),
          const SizedBox(height: AppSpacing.spaceLG),
          _buildHighlight(Icons.favorite_outline_rounded, 'Pregnancy support, plus trying to conceive'),
          const SizedBox(height: AppSpacing.spaceSM),
          _buildHighlight(Icons.health_and_safety_outlined, 'Support that grows with your journey'),
          const SizedBox(height: AppSpacing.spaceSM),
          _buildHighlight(Icons.chat_outlined, 'We learn more as you chat'),
        ],
      ),
    );
  }

  Widget _buildHighlight(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.appSecondary),
        const SizedBox(width: AppSpacing.spaceSM),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyText.copyWith(color: context.appInk),
          ),
        ),
      ],
    );
  }

  Widget _buildNameStep() {
    return _buildStepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What should we call you?', style: AppTypography.headingMedium.copyWith(color: context.appInk)),
          const SizedBox(height: AppSpacing.spaceSM),
          Text(
            'We\'ll use this to make conversations feel personal.',
            style: AppTypography.caption.copyWith(color: context.appInkMuted),
          ),
          const SizedBox(height: AppSpacing.spaceLG),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your name',
              hintText: 'e.g. Sarah',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStep() {
    return _buildStepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where are you today?', style: AppTypography.headingMedium.copyWith(color: context.appInk)),
          const SizedBox(height: AppSpacing.spaceSM),
          Text(
            'Most moms join while pregnant; choose trying to conceive if that\'s where you are today. You can update your journey anytime.',
            style: AppTypography.caption.copyWith(color: context.appInkMuted),
          ),
          const SizedBox(height: AppSpacing.spaceLG),
          JourneyStagePicker(
            selected: _journeyStage,
            options: JourneyStage.signupStages,
            onSelected: (stage) => setState(() => _journeyStage = stage),
          ),
        ],
      ),
    );
  }

  Widget _buildStageDetailsStep() {
    final stage = _journeyStage;

    return _buildStepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stage?.label ?? 'A few details',
            style: AppTypography.headingMedium.copyWith(color: context.appInk),
          ),
          const SizedBox(height: AppSpacing.spaceSM),
          Text(
            _stageDetailsSubtitle(stage),
            style: AppTypography.caption.copyWith(color: context.appInkMuted),
          ),
          const SizedBox(height: AppSpacing.spaceLG),
          if (stage == JourneyStage.pregnant) ...[
            Center(
              child: Text(
                'Week $_pregnancyWeek',
                style: AppTypography.headingLarge.copyWith(
                  color: context.appPrimary,
                ),
              ),
            ),
            Slider(
              value: _pregnancyWeek.toDouble(),
              min: 4,
              max: 42,
              divisions: 38,
              activeColor: context.appSecondary,
              onChanged: (value) {
                setState(() => _pregnancyWeek = value.round());
              },
            ),
            Center(
              child: Text(
                'Estimated due date: ${DateFormat.yMMMd().format(PregnancyTiming.eddFromWeek(_pregnancyWeek))}',
                style: AppTypography.bodyTextMedium.copyWith(
                  color: context.appPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spaceLG),
            Text('First pregnancy?', style: AppTypography.bodyTextMedium.copyWith(color: context.appInk)),
            const SizedBox(height: AppSpacing.spaceSM),
            _buildChoiceChip(
              label: 'Yes, my first',
              selected: _isFirstPregnancy == true,
              onTap: () => setState(() => _isFirstPregnancy = true),
            ),
            const SizedBox(height: AppSpacing.spaceSM),
            _buildChoiceChip(
              label: 'No, I\'ve been pregnant before',
              selected: _isFirstPregnancy == false,
              onTap: () => setState(() => _isFirstPregnancy = false),
            ),
          ] else ...[
            Text(
              'We\'ll tailor support to your TTC journey — cycles, fertility questions, and the emotional side of waiting.',
              style: AppTypography.bodyText.copyWith(color: context.appInk),
            ),
          ],
        ],
      ),
    );
  }

  String _stageDetailsSubtitle(JourneyStage? stage) {
    switch (stage) {
      case JourneyStage.pregnant:
        return 'This helps us give stage-appropriate guidance.';
      case JourneyStage.ttc:
      case null:
        return 'Help us personalize your experience.';
      case JourneyStage.postpartum:
      case JourneyStage.miscarriage:
        return 'Help us personalize your experience.';
    }
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spaceMD,
          vertical: AppSpacing.spaceMD,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
          color: selected ? context.appPrimary : context.appSurface,
          border: Border.all(
            color: selected
                ? Colors.transparent
                : context.appPrimary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyText.copyWith(
            color: selected ? context.appOnPrimary : context.appInk,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
