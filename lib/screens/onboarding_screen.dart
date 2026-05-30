import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_button.dart';

/// First-time walkthrough to capture core pregnancy context for personalization.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _concernController = TextEditingController();

  int _step = 0;
  int _pregnancyWeek = 20;
  bool? _isFirstPregnancy;
  bool _isSubmitting = false;

  static const _concernSuggestions = [
    'Morning sickness',
    'Nutrition',
    'Sleep',
    'Cramping',
    'Anxiety',
  ];

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
    _concernController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 1 && _nameController.text.trim().isEmpty) {
      _showMessage('Please enter your name');
      return;
    }
    if (_step == 3 && _isFirstPregnancy == null) {
      _showMessage('Please let us know if this is your first pregnancy');
      return;
    }

    if (_step < 4) {
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
    setState(() => _isSubmitting = true);
    try {
      await ref.read(profileProvider.notifier).completeOnboarding(
            name: _nameController.text.trim(),
            language: 'en',
            pregnancyWeek: _pregnancyWeek,
            isFirstPregnancy: _isFirstPregnancy ?? true,
            primaryConcern: _concernController.text.trim().isEmpty
                ? null
                : _concernController.text.trim(),
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
                    _buildWeekStep(),
                    _buildFirstPregnancyStep(),
                    _buildConcernStep(),
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
          style: AppTypography.headingMedium.copyWith(
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppSpacing.spaceSM),
        Row(
          children: List.generate(5, (index) {
            final active = index <= _step;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(
                  right: index == 4 ? 0 : AppSpacing.spaceXS,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: active ? AppColors.brandGradient : null,
                  color: active ? null : AppColors.primaryPurple.withValues(alpha: 0.15),
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
                  color: AppColors.primaryPurple,
                ),
              ),
            )
          else
            const SizedBox(width: 64),
          Expanded(
            child: GradientButton(
              label: _step == 4 ? 'Start chatting' : 'Continue',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _nextStep,
              icon: _step == 4 ? Icons.chat_bubble_outline_rounded : Icons.arrow_forward_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLG),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.spaceLG),
        child: child,
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
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.spaceLG),
          Text(
            'Your journey, personalized',
            style: AppTypography.headingLarge.copyWith(
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          Text(
            'MomLaunchpad remembers what matters to you — your stage of pregnancy, concerns, and preferences — so every conversation builds on what we already know.',
            style: AppTypography.bodyText.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: AppSpacing.spaceLG),
          _buildHighlight(Icons.psychology_outlined, 'Smarter answers over time'),
          const SizedBox(height: AppSpacing.spaceSM),
          _buildHighlight(Icons.health_and_safety_outlined, 'Tailored pregnancy guidance'),
          const SizedBox(height: AppSpacing.spaceSM),
          _buildHighlight(Icons.chat_outlined, 'We learn more as you chat'),
        ],
      ),
    );
  }

  Widget _buildHighlight(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryPink),
        const SizedBox(width: AppSpacing.spaceSM),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyText.copyWith(color: AppColors.textDark),
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
          Text('What should we call you?', style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.spaceSM),
          Text(
            'We\'ll use this to make conversations feel personal.',
            style: AppTypography.caption.copyWith(color: AppColors.textLight),
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

  Widget _buildWeekStep() {
    return _buildStepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How far along are you?', style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.spaceSM),
          Text(
            'This helps us give stage-appropriate advice.',
            style: AppTypography.caption.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: AppSpacing.spaceXL),
          Center(
            child: Text(
              'Week $_pregnancyWeek',
              style: AppTypography.headingLarge.copyWith(
                color: AppColors.primaryPurple,
              ),
            ),
          ),
          Slider(
            value: _pregnancyWeek.toDouble(),
            min: 4,
            max: 42,
            divisions: 38,
            activeColor: AppColors.primaryPink,
            onChanged: (value) {
              setState(() => _pregnancyWeek = value.round());
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('4 weeks', style: AppTypography.caption),
              Text('42 weeks', style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFirstPregnancyStep() {
    return _buildStepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Is this your first pregnancy?', style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.spaceSM),
          Text(
            'First-time and experienced moms often have different questions.',
            style: AppTypography.caption.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: AppSpacing.spaceLG),
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
        ],
      ),
    );
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
          gradient: selected ? AppColors.brandGradient : null,
          color: selected ? null : AppColors.white,
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.primaryPurple.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyText.copyWith(
            color: selected ? Colors.white : AppColors.textDark,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildConcernStep() {
    return _buildStepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Anything on your mind?', style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.spaceSM),
          Text(
            'Optional — we\'ll keep learning more as you chat.',
            style: AppTypography.caption.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          Wrap(
            spacing: AppSpacing.spaceSM,
            runSpacing: AppSpacing.spaceSM,
            children: _concernSuggestions.map((concern) {
              final selected = _concernController.text == concern;
              return FilterChip(
                label: Text(concern),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _concernController.text = selected ? '' : concern;
                  });
                },
                selectedColor: AppColors.primaryPink.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primaryPurple,
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          TextField(
            controller: _concernController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Or describe in your own words',
              hintText: 'e.g. worried about swelling',
            ),
          ),
        ],
      ),
    );
  }
}
