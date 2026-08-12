import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/journey_stage.dart';
import '../models/baby_gender.dart';
import '../providers/baby_theme_provider.dart';
import '../models/community.dart';
import '../models/user_profile.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/community_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/service_providers.dart';
import '../utils/community_interest_labels.dart';
import '../utils/journey_helpers.dart';
import '../utils/pregnancy_timing.dart';
import '../services/api_service.dart';
import '../widgets/journey_transition_sheet.dart';
import '../widgets/country_picker_field.dart';
import '../widgets/location_suggest_field.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/community_badge_profile_section.dart';
import '../widgets/referral_profile_section.dart';
import '../widgets/widgets.dart';
import '../widgets/gender_picker.dart';
import 'community_preferences_screen.dart';

/// Profile page — view and edit pregnancy context used to personalize chat.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _facilityController = TextEditingController();
  String? _selectedFacilityId;

  String? _countryCode;

  int _pregnancyWeek = 20;
  DateTime? _dueDate;
  DateTime? _babyBirthDate;
  DateTime? _lossDate;
  bool _dueDateManuallySet = false;
  bool? _isFirstPregnancy;
  BabyGender? _babyGender;
  JourneyStage? _journeyStage;
  String? _dietPreference;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(communityProvider);
      if (state.countries.isEmpty || state.interestGroups.isEmpty) {
        ref.read(communityProvider.notifier).bootstrap();
      }
    });
  }

  @override
  void dispose() {
    ref.read(previewBabyGenderProvider.notifier).clear();
    _nameController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _facilityController.dispose();
    super.dispose();
  }

  void _resolveCountryCode(UserProfile profile, List<CommunityCountryOption> countries) {
    if (_countryCode != null || countries.isEmpty) return;
    if (profile.countryCode != null && profile.countryCode!.isNotEmpty) {
      _countryCode = profile.countryCode;
      return;
    }
    final name = profile.country?.trim().toLowerCase();
    if (name == null || name.isEmpty) return;
    for (final country in countries) {
      if (country.name.toLowerCase() == name) {
        _countryCode = country.code;
        break;
      }
    }
  }

  String? _selectedCountryName(List<CommunityCountryOption> countries) {
    if (_countryCode == null) return null;
    for (final country in countries) {
      if (country.code == _countryCode) return country.name;
    }
    return null;
  }

  Future<List<String>> _fetchStateSuggestions(String query) async {
    if (_countryCode == null) return const [];
    return ref.read(apiServiceProvider).getCommunityLocationSuggestions(
          countryCode: _countryCode!,
          field: 'state_province',
          query: query,
        );
  }

  Future<List<String>> _fetchCitySuggestions(String query) async {
    if (_countryCode == null) return const [];
    return ref.read(apiServiceProvider).getCommunityLocationSuggestions(
          countryCode: _countryCode!,
          field: 'city',
          query: query,
          stateProvince: _stateController.text.trim(),
        );
  }

  Future<List<String>> _fetchFacilitySuggestions(String query) async {
    if (_countryCode == null) return const [];
    final stateProvince = _stateController.text.trim();
    final city = _cityController.text.trim();
    if (stateProvince.isEmpty || city.isEmpty) return const [];
    final facilities = await ref.read(apiServiceProvider).getHealthcareFacilities(
          countryCode: _countryCode!,
          stateProvince: stateProvince,
          city: city,
          query: query,
        );
    return facilities.map((f) => f.name).toList();
  }

  void _onCountrySelected(String code, List<CommunityCountryOption> countries) {
    setState(() {
      if (_countryCode != code) {
        _stateController.clear();
        _cityController.clear();
        _facilityController.clear();
        _selectedFacilityId = null;
      }
      _countryCode = code;
    });
  }

  void _applyProfile(UserProfile profile, {bool force = false}) {
    if (_initialized && !force) return;
    _initialized = true;
    _nameController.text = profile.name;
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
    _babyGender = profile.babyGender;
    _journeyStage = JourneyHelpers.stageOf(profile);
    _babyBirthDate = profile.babyBirthDate;
    _lossDate = profile.lossDate;
    _dietPreference = profile.dietPreference ?? profile.diet ?? '';
    _countryCode = profile.countryCode;
    _stateController.text = profile.stateProvince ?? '';
    _cityController.text = profile.city ?? '';
    _facilityController.text = profile.healthcareFacilityName ?? '';
    _selectedFacilityId = profile.healthcareFacilityId;
  }

  Future<void> _openCommunityFeedTopics() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CommunityPreferencesScreen()),
    );
    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Community feed topics updated')),
      );
    }
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      await ref.read(profileProvider.notifier).uploadProfilePhoto(file.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _removeProfilePhoto() async {
    setState(() => _isUploadingPhoto = true);
    try {
      await ref.read(profileProvider.notifier).deleteProfilePhoto();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo removed')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
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
              language: AppConfig.languageCode,
              journeyStage: _journeyStage,
              pregnancyWeek: _journeyStage == JourneyStage.pregnant &&
                      !_dueDateManuallySet
                  ? _pregnancyWeek
                  : null,
              expectedDeliveryDate: _journeyStage == JourneyStage.pregnant &&
                      _dueDateManuallySet
                  ? _dueDate
                  : null,
              babyBirthDate: _journeyStage == JourneyStage.postpartum
                  ? _babyBirthDate
                  : null,
              lossDate: _journeyStage == JourneyStage.miscarriage ? _lossDate : null,
              isFirstPregnancy: _isFirstPregnancy,
              babyGender: _journeyStage == JourneyStage.pregnant
                  ? _babyGender
                  : null,
              clearBabyGender: _journeyStage == JourneyStage.pregnant &&
                  _babyGender == null,
              dietPreference:
                  (_dietPreference == null || _dietPreference!.isEmpty)
                      ? null
                      : _dietPreference,
              country: _selectedCountryName(
                ref.read(communityProvider).countries,
              ),
              countryCode: _countryCode,
              stateProvince: _stateController.text.trim().isEmpty
                  ? null
                  : _stateController.text.trim(),
              city: _cityController.text.trim().isEmpty
                  ? null
                  : _cityController.text.trim(),
            ),
          );

      final facilityName = _facilityController.text.trim();
      final stateProvince = _stateController.text.trim();
      final city = _cityController.text.trim();
      if (_countryCode != null &&
          stateProvince.isNotEmpty &&
          city.isNotEmpty &&
          facilityName.isNotEmpty &&
          (saved.communityOnboardingCompleted ||
              saved.communityInterests.isNotEmpty)) {
        await ref.read(communityProvider.notifier).completeOnboarding(
              countryCode: _countryCode!,
              stateProvince: stateProvince,
              city: city,
              healthcareFacilityId: _selectedFacilityId,
              healthcareFacilityName: facilityName,
              interests: saved.communityInterests,
            );
        await ref.read(profileProvider.notifier).loadProfile();
      }

      if (mounted) {
        final refreshed = ref.read(profileProvider).profile ?? saved;
        setState(() => _applyProfile(refreshed, force: true));
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

  Future<void> _updateJourney() async {
    final profile = ref.read(profileProvider).profile;
    if (profile == null) return;

    final payload = await showJourneyTransitionPicker(context, profile);
    if (payload == null || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final saved = await ref.read(profileProvider.notifier).updateProfile(payload);
      if (mounted) {
        setState(() => _applyProfile(saved, force: true));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journey updated')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickBabyBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _babyBirthDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      helpText: 'Baby\'s birth date',
    );
    if (picked != null && mounted) {
      setState(() => _babyBirthDate = picked);
    }
  }

  Future<void> _pickLossDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lossDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Date of loss (optional)',
    );
    if (picked != null && mounted) {
      setState(() => _lossDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profileState = ref.watch(profileProvider);
    final communityState = ref.watch(communityProvider);
    final profile = profileState.profile;
    final countries = communityState.countries
        .map((c) => (code: c.code, name: c.name))
        .toList();

    if (profile != null) {
      _applyProfile(profile);
      _resolveCountryCode(profile, communityState.countries);
    }

    return Scaffold(
      appBar: const MomAppBar(pageTitle: 'Your profile'),
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
                  if (profile != null) ...[
                    ReferralProfileSection(profile: profile),
                    const SizedBox(height: AppSpacing.spaceLG),
                    if (_journeyStage == JourneyStage.ttc) ...[
                      Text(
                        'Healthcare professional supporting mothers at your clinic? Request your professional badge below — workplace, role, and credentials help us verify faster.',
                        style: AppTypography.caption.copyWith(
                          color: context.appInkMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spaceSM),
                    ],
                    const CommunityBadgeProfileSection(),
                    const SizedBox(height: AppSpacing.spaceLG),
                  ],
                  _buildSectionTitle('Profile photo'),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.spaceMD),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            AppAvatar(
                              name: _nameController.text,
                              imageUrl: profile?.profilePhotoUrl,
                              size: AppAvatarSize.xlarge,
                            ),
                            if (_isUploadingPhoto)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.spaceMD),
                        Text(
                          'Your photo appears on community posts when you are not anonymous.',
                          style: AppTypography.caption.copyWith(
                            color: context.appInkSubtle,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.spaceMD),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isUploadingPhoto || _isSaving
                                    ? null
                                    : _pickProfilePhoto,
                                icon: Icon(Icons.photo_library_outlined),
                                label: const Text('Upload photo'),
                              ),
                            ),
                            if ((profile?.profilePhotoUrl ?? '').isNotEmpty) ...[
                              const SizedBox(width: AppSpacing.spaceSM),
                              IconButton(
                                tooltip: 'Remove photo',
                                onPressed: _isUploadingPhoto || _isSaving
                                    ? null
                                    : _removeProfilePhoto,
                                icon: Icon(Icons.delete_outline_rounded),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spaceLG),
                  _buildSectionTitle('Community location'),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.spaceMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CountryPickerField(
                          countryCode: _countryCode,
                          countries: countries,
                          onSelected: (code) => _onCountrySelected(
                            code,
                            communityState.countries,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spaceMD),
                        LocationSuggestField(
                          controller: _stateController,
                          label: 'State / Province',
                          enabled: _countryCode != null,
                          fetchSuggestions: _fetchStateSuggestions,
                        ),
                        const SizedBox(height: AppSpacing.spaceMD),
                        LocationSuggestField(
                          controller: _cityController,
                          label: 'City',
                          enabled: _countryCode != null,
                          fetchSuggestions: _fetchCitySuggestions,
                        ),
                        const SizedBox(height: AppSpacing.spaceMD),
                        LocationSuggestField(
                          controller: _facilityController,
                          label: 'Hospital / health center',
                          enabled: _countryCode != null,
                          fetchSuggestions: _fetchFacilitySuggestions,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.spaceXS),
                          child: Text(
                            'Start typing to search. Missing centers are added when you save.',
                            style: AppTypography.caption.copyWith(
                              color: context.appInkSubtle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spaceLG),
                  _buildSectionTitle('Community feed'),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.spaceMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feed topics personalize your For You tab in Community.',
                          style: AppTypography.caption.copyWith(
                            color: context.appInkSubtle,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spaceSM),
                        if (profile != null &&
                            profile.communityInterests.isNotEmpty) ...[
                          Wrap(
                            spacing: AppSpacing.spaceSM,
                            runSpacing: AppSpacing.spaceSM,
                            children: communityInterestLabels(
                              profile.communityInterests,
                              communityState.interestGroups,
                            ).map((label) {
                              return AppBadge(
                                label: label,
                                variant: AppBadgeVariant.secondary,
                                small: true,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.spaceMD),
                        ] else ...[
                          Text(
                            'No feed topics selected yet.',
                            style: AppTypography.bodyText.copyWith(
                              color: context.appInkMuted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.spaceMD),
                        ],
                        OutlinedButton.icon(
                          onPressed: _openCommunityFeedTopics,
                          icon: Icon(Icons.tune_rounded),
                          label: Text(
                            profile != null &&
                                    profile.communityInterests.isNotEmpty
                                ? 'Edit feed topics'
                                : 'Choose feed topics',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spaceLG),
                  _buildSectionTitle('Your journey'),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.spaceMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _journeyStage?.label ?? 'Not set',
                          style: AppTypography.headingMedium.copyWith(
                            color: context.appPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile == null
                              ? ''
                              : JourneyHelpers.profileSummary(profile),
                          style: AppTypography.caption.copyWith(
                            color: context.appInkSubtle,
                          ),
                        ),
                        if (_journeyStage != null) ...[
                          const SizedBox(height: AppSpacing.spaceSM),
                          Text(
                            _journeyStage!.transitionHint,
                            style: AppTypography.caption.copyWith(
                              color: context.appInkSubtle,
                            ),
                          ),
                        ],
                        if (_journeyStage == JourneyStage.ttc) ...[
                          const SizedBox(height: AppSpacing.spaceMD),
                          Text(
                            'MomLaunchpad is pregnancy-first. While you\'re trying to conceive, '
                            'chat focuses on fertility and the wait — update your journey when you\'re pregnant.',
                            style: AppTypography.caption.copyWith(
                              color: context.appInkSubtle,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.spaceMD),
                        OutlinedButton.icon(
                          onPressed: _isSaving ? null : _updateJourney,
                          icon: Icon(Icons.swap_horiz_rounded),
                          label: const Text('Update my journey'),
                        ),
                      ],
                    ),
                  ),
                  if (_journeyStage == JourneyStage.pregnant) ...[
                    const SizedBox(height: AppSpacing.spaceLG),
                    _buildSectionTitle('Pregnancy details'),
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.spaceMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Week $_pregnancyWeek',
                              style: AppTypography.headingMedium.copyWith(
                                color: context.appPrimary,
                              ),
                            ),
                          ),
                          Slider(
                            value: _pregnancyWeek.toDouble(),
                            min: 4,
                            max: 42,
                            divisions: 38,
                            activeColor: context.appAccent,
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
                                    color: context.appInkSubtle,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(Icons.calendar_today_outlined),
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
                          const Divider(),
                          Text(
                            'Baby gender & app colors',
                            style: AppTypography.bodyTextMedium,
                          ),
                          const SizedBox(height: AppSpacing.spaceXS),
                          Text(
                            'Optional — personalizes accent colors across the app.',
                            style: AppTypography.caption.copyWith(
                              color: context.appInkSubtle,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.spaceMD),
                          GenderPicker(
                            value: _babyGender,
                            onChanged: (gender) {
                              setState(() => _babyGender = gender);
                              ref
                                  .read(previewBabyGenderProvider.notifier)
                                  .set(gender);
                            },
                          ),
                          if (_babyGender != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {
                                  setState(() => _babyGender = null);
                                  ref
                                      .read(previewBabyGenderProvider.notifier)
                                      .clear();
                                },
                                child: const Text('Clear gender theme'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (_journeyStage == JourneyStage.postpartum) ...[
                    const SizedBox(height: AppSpacing.spaceLG),
                    _buildSectionTitle('Postpartum'),
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.spaceMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Baby\'s birth date'),
                            subtitle: Text(
                              _babyBirthDate == null
                                  ? 'Tap to set'
                                  : MaterialLocalizations.of(context)
                                      .formatMediumDate(_babyBirthDate!),
                            ),
                            trailing: Icon(Icons.calendar_today_outlined),
                            onTap: _pickBabyBirthDate,
                          ),
                          Text(
                            'We focus on your recovery and wellbeing in this stage.',
                            style: AppTypography.caption.copyWith(
                              color: context.appInkSubtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_journeyStage == JourneyStage.miscarriage) ...[
                    const SizedBox(height: AppSpacing.spaceLG),
                    _buildSectionTitle('Support after loss'),
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.spaceMD),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Date of loss (optional)'),
                        subtitle: Text(
                          _lossDate == null
                              ? 'Tap to add if you\'d like'
                              : MaterialLocalizations.of(context)
                                  .formatMediumDate(_lossDate!),
                        ),
                        trailing: Icon(Icons.calendar_today_outlined),
                        onTap: _pickLossDate,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.spaceLG),
                  _buildSectionTitle('Preferences'),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.spaceMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _dietPreference ?? '',
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
                              color: context.appInkSubtle,
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
        AppAvatar(
          name: _nameController.text,
          imageUrl: ref.watch(profileProvider).profile?.profilePhotoUrl,
          size: AppAvatarSize.large,
        ),
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
                  color: context.appInkSubtle,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'MomLaunchPad is built for pregnancy. We also support trying to conceive, postpartum, and loss — update your journey in profile when life changes.',
                style: AppTypography.caption.copyWith(
                  color: context.appInkSubtle,
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
          color: context.appInkSubtle,
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
