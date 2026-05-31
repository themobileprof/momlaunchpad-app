import 'package:flutter/material.dart';
import '../models/journey_stage.dart';
import '../models/user_profile.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/journey_helpers.dart';
import '../utils/pregnancy_timing.dart';
import 'journey_stage_picker.dart';

/// Collects details when moving to a new journey stage from profile.
class JourneyTransitionSheet extends StatefulWidget {
  final UserProfile profile;
  final JourneyStage targetStage;

  const JourneyTransitionSheet({
    super.key,
    required this.profile,
    required this.targetStage,
  });

  static Future<ProfileSavePayload?> show(
    BuildContext context, {
    required UserProfile profile,
    required JourneyStage targetStage,
  }) {
    return showModalBottomSheet<ProfileSavePayload>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: JourneyTransitionSheet(
          profile: profile,
          targetStage: targetStage,
        ),
      ),
    );
  }

  @override
  State<JourneyTransitionSheet> createState() => _JourneyTransitionSheetState();
}

class _JourneyTransitionSheetState extends State<JourneyTransitionSheet> {
  int _pregnancyWeek = 20;
  DateTime? _babyBirthDate;
  DateTime? _lossDate;

  @override
  void initState() {
    super.initState();
    _pregnancyWeek = widget.profile.pregnancyWeek ?? 20;
    _babyBirthDate = widget.profile.babyBirthDate ?? DateTime.now();
  }

  Future<void> _pickBabyBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _babyBirthDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      helpText: 'When was your baby born?',
    );
    if (picked != null) setState(() => _babyBirthDate = picked);
  }

  Future<void> _pickLossDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lossDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Date of loss (optional)',
    );
    if (picked != null) setState(() => _lossDate = picked);
  }

  void _confirm() {
    final stage = widget.targetStage;
    if (JourneyHelpers.needsBabyBirthDate(stage) && _babyBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add your baby\'s birth date')),
      );
      return;
    }

    Navigator.pop(
      context,
      ProfileSavePayload(
        name: widget.profile.name,
        language: widget.profile.language,
        journeyStage: stage,
        pregnancyWeek:
            JourneyHelpers.needsPregnancyWeek(stage) ? _pregnancyWeek : null,
        expectedDeliveryDate: JourneyHelpers.needsPregnancyWeek(stage)
            ? null
            : null,
        babyBirthDate:
            JourneyHelpers.needsBabyBirthDate(stage) ? _babyBirthDate : null,
        lossDate: stage == JourneyStage.miscarriage ? _lossDate : null,
        isFirstPregnancy: widget.profile.isFirstPregnancy,
        primaryConcern: widget.profile.primaryConcern,
        dietPreference: widget.profile.dietPreference,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.targetStage;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Update your journey', style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.spaceSM),
            Text(
              stage == JourneyStage.miscarriage
                  ? 'We\'re so sorry for your loss. This space is still yours — we\'ll meet you with gentleness.'
                  : 'Moving to: ${stage.label}',
              style: AppTypography.bodyText.copyWith(color: AppColors.textLight),
            ),
            const SizedBox(height: AppSpacing.spaceLG),
            if (JourneyHelpers.needsPregnancyWeek(stage)) ...[
              Text('How far along are you?', style: AppTypography.bodyTextMedium),
              Center(
                child: Text(
                  'Week $_pregnancyWeek',
                  style: AppTypography.headingMedium.copyWith(
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
              Slider(
                value: _pregnancyWeek.toDouble(),
                min: 4,
                max: 42,
                divisions: 38,
                onChanged: (value) =>
                    setState(() => _pregnancyWeek = value.round()),
              ),
              Center(
                child: Text(
                  'Due ${MaterialLocalizations.of(context).formatMediumDate(PregnancyTiming.eddFromWeek(_pregnancyWeek))}',
                  style: AppTypography.caption,
                ),
              ),
            ],
            if (JourneyHelpers.needsBabyBirthDate(stage))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Baby\'s birth date'),
                subtitle: Text(
                  _babyBirthDate == null
                      ? 'Required'
                      : MaterialLocalizations.of(context)
                          .formatMediumDate(_babyBirthDate!),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickBabyBirthDate,
              ),
            if (stage == JourneyStage.miscarriage)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date of loss (optional)'),
                subtitle: Text(
                  _lossDate == null
                      ? 'Tap to add if you\'d like'
                      : MaterialLocalizations.of(context)
                          .formatMediumDate(_lossDate!),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickLossDate,
              ),
            if (stage == JourneyStage.ttc)
              Text(
                'We\'ll focus on your TTC journey and emotional wellbeing.',
                style: AppTypography.caption.copyWith(color: AppColors.textLight),
              ),
            const SizedBox(height: AppSpacing.spaceLG),
            FilledButton(
              onPressed: _confirm,
              child: const Text('Save journey update'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows allowed journey transitions for the current profile.
Future<ProfileSavePayload?> showJourneyTransitionPicker(
  BuildContext context,
  UserProfile profile,
) async {
  final current = JourneyHelpers.stageOf(profile);
  if (current == null) return null;

  final options = current.allowedTransitions;
  if (options.isEmpty) return null;

  final target = await showModalBottomSheet<JourneyStage>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update my journey', style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.spaceSM),
            Text(
              current.transitionHint,
              style: AppTypography.caption.copyWith(color: AppColors.textLight),
            ),
            const SizedBox(height: AppSpacing.spaceMD),
            JourneyStagePicker(
              selected: null,
              options: options,
              onSelected: (stage) => Navigator.pop(context, stage),
            ),
          ],
        ),
      ),
    ),
  );

  if (target == null || !context.mounted) return null;
  return JourneyTransitionSheet.show(
    context,
    profile: profile,
    targetStage: target,
  );
}
