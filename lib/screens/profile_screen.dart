import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/pregnancy_timing.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/widgets.dart';

/// Profile page — view and edit pregnancy context used to personalize chat.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _concernController = TextEditingController();

  int _pregnancyWeek = 20;
  DateTime? _dueDate;
  bool _dueDateManuallySet = false;
  bool? _isFirstPregnancy;
  String _language = 'en';
  String? _dietPreference;
  bool _isSaving = false;
  bool _initialized = false;

  static const _dietOptions = [
    '',
    'vegetarian',
    'vegan',
    'pescatarian',
    'gluten-free',
    'halal',
    'kosher',
  ];

  static const _concernSuggestions = [
    'Morning sickness',
    'Nutrition',
    'Sleep',
    'Cramping',
    'Anxiety',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _concernController.dispose();
    super.dispose();
  }

  void _applyProfile(UserProfile profile, {bool force = false}) {
    if (_initialized && !force) return;
    _initialized = true;
    _nameController.text = profile.name;
    _language = profile.language;
    _pregnancyWeek = profile.pregnancyWeek ?? 20;
    final storedDueDate = profile.expectedDeliveryDate;
    if (storedDueDate != null &&
        !PregnancyTiming.eddMatchesWeek(storedDueDate, _pregnancyWeek)) {
      _dueDate = storedDueDate;
      _dueDateManuallySet = true;
    } else {
      _dueDate = PregnancyTiming.eddFromWeek(_pregnancyWeek);
      _dueDateManuallySet = false;
    }
    _isFirstPregnancy = profile.isFirstPregnancy;
    _concernController.text = profile.primaryConcern ?? '';
    _dietPreference = profile.dietPreference ?? profile.diet ?? '';
  }

  void _onPregnancyWeekChanged(int week) {
    setState(() {
      _pregnancyWeek = week;
      _dueDateManuallySet = false;
      _dueDate = PregnancyTiming.eddFromWeek(week);
    });
  }

  Future<void> _pickDueDate() async {
    final today = DateTime.now();
    final firstDate = PregnancyTiming.eddFromWeek(42, today);
    final lastDate = PregnancyTiming.eddFromWeek(4, today);
    var initialDate = _dueDate ?? PregnancyTiming.eddFromWeek(_pregnancyWeek, today);
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Expected due date',
    );
    if (picked != null && mounted) {
      setState(() {
        _dueDate = picked;
        _dueDateManuallySet = true;
        _pregnancyWeek = PregnancyTiming.weekFromEdd(picked);
      });
    }
  }

  void _useWeekBasedDueDate() {
    setState(() {
      _dueDateManuallySet = false;
      _dueDate = PregnancyTiming.eddFromWeek(_pregnancyWeek);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final saved = await ref.read(profileProvider.notifier).updateProfile(
            ProfileSavePayload(
              name: _nameController.text.trim(),
              language: _language,
              pregnancyWeek: _dueDateManuallySet ? null : _pregnancyWeek,
              expectedDeliveryDate:
                  _dueDateManuallySet ? _dueDate : null,
              isFirstPregnancy: _isFirstPregnancy,
              primaryConcern: _concernController.text.trim().isEmpty
                  ? null
                  : _concernController.text.trim(),
              dietPreference:
                  (_dietPreference == null || _dietPreference!.isEmpty)
                      ? null
                      : _dietPreference,
            ),
          );

      if (mounted) {
        setState(() => _applyProfile(saved, force: true));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;

    if (profile != null) {
      _applyProfile(profile);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Your profile', style: AppTypography.headingMedium),
      ),
      body: profileState.isLoading && profile == null
          ? const LoadingState(message: 'Loading profile...')
          : profileState.error != null && profile == null
              ? ErrorState(
                  title: 'Could not load profile',
                  description: profileState.error,
                  onRetry: () =>
                      ref.read(profileProvider.notifier).loadProfile(),
                )
              : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.only(
                  left: AppSpacing.spaceMD,
                  right: AppSpacing.spaceMD,
                  top: AppSpacing.spaceMD,
                  bottom: 120,
                ),
                children: [
                  _buildHeader(user?.email),
                  const SizedBox(height: AppSpacing.spaceLG),
                  _buildSectionTitle('About you'),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.spaceMD),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Display name',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.spaceMD),
                        DropdownButtonFormField<String>(
                          value: _language,
                          decoration: const InputDecoration(
                            labelText: 'Language',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'en', child: Text('English')),
                            DropdownMenuItem(value: 'es', child: Text('Spanish')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _language = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spaceLG),
                  _buildSectionTitle('Pregnancy journey'),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.spaceMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          activeColor: AppColors.primaryPink,
                          onChanged: (value) {
                            _onPregnancyWeekChanged(value.round());
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Expected due date'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dueDate == null
                                    ? 'Tap to set a custom date'
                                    : MaterialLocalizations.of(context)
                                        .formatMediumDate(_dueDate!),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _dueDateManuallySet
                                    ? 'Custom date · week adjusted to match'
                                    : 'Calculated from pregnancy week',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.calendar_today_outlined),
                          onTap: _pickDueDate,
                        ),
                        if (_dueDateManuallySet)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: _useWeekBasedDueDate,
                              child: const Text('Recalculate from week'),
                            ),
                          ),
                        const Divider(),
                        Text(
                          'First pregnancy?',
                          style: AppTypography.bodyTextMedium,
                        ),
                        const SizedBox(height: AppSpacing.spaceSM),
                        Row(
                          children: [
                            Expanded(
                              child: _ChoiceButton(
                                label: 'Yes',
                                selected: _isFirstPregnancy == true,
                                onTap: () =>
                                    setState(() => _isFirstPregnancy = true),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.spaceSM),
                            Expanded(
                              child: _ChoiceButton(
                                label: 'No',
                                selected: _isFirstPregnancy == false,
                                onTap: () =>
                                    setState(() => _isFirstPregnancy = false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spaceLG),
                  _buildSectionTitle('Preferences'),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.spaceMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _dietPreference ?? '',
                          decoration: const InputDecoration(
                            labelText: 'Diet preference',
                          ),
                          items: _dietOptions
                              .map(
                                (option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(
                                    option.isEmpty
                                        ? 'No preference'
                                        : _formatDiet(option),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _dietPreference = value);
                          },
                        ),
                        const SizedBox(height: AppSpacing.spaceMD),
                        Text(
                          'Current focus',
                          style: AppTypography.bodyTextMedium,
                        ),
                        const SizedBox(height: AppSpacing.spaceSM),
                        Wrap(
                          spacing: AppSpacing.spaceSM,
                          runSpacing: AppSpacing.spaceSM,
                          children: _concernSuggestions.map((concern) {
                            final selected =
                                _concernController.text == concern;
                            return FilterChip(
                              label: Text(concern),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _concernController.text =
                                      selected ? '' : concern;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.spaceSM),
                        TextFormField(
                          controller: _concernController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'What would you like help with?',
                            hintText: 'e.g. morning sickness, nutrition',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (profile?.learnedFacts.isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.spaceLG),
                    _buildSectionTitle('Learned from your chats'),
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.spaceMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'These details were picked up as you chatted and help personalize responses.',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.spaceSM),
                          Wrap(
                            spacing: AppSpacing.spaceSM,
                            runSpacing: AppSpacing.spaceSM,
                            children: profile!.learnedFacts.entries.map((entry) {
                              return AppBadge(
                                label: '${_formatFactKey(entry.key)}: ${entry.value}',
                                variant: AppBadgeVariant.secondary,
                                small: true,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.spaceXL),
                  GradientButton(
                    label: 'Save changes',
                    isLoading: _isSaving,
                    onPressed: _save,
                    icon: Icons.check_rounded,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(String? email) {
    return Row(
      children: [
        AppAvatar(name: _nameController.text, size: AppAvatarSize.large),
        const SizedBox(width: AppSpacing.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personalization',
                style: AppTypography.headingMedium,
              ),
              const SizedBox(height: 4),
              Text(
                email ?? '',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'MomLaunchpad uses this to tailor guidance. We keep learning more every time you chat.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
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

  String _formatDiet(String value) {
    if (value == 'gluten-free') return 'Gluten-free';
    return value[0].toUpperCase() + value.substring(1);
  }

  String _formatFactKey(String key) {
    return key.replaceAll('_', ' ');
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.spaceMD),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
          color: selected ? context.appPrimary : context.appSurface,
          border: Border.all(
            color: selected
                ? Colors.transparent
                : context.appPrimary.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyText.copyWith(
              color: selected ? context.appOnPrimary : context.appInk,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
