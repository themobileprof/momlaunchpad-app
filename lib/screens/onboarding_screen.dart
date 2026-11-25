import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../models/community.dart';
import '../models/journey_stage.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/community_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/service_providers.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/journey_helpers.dart';
import '../utils/pregnancy_timing.dart';
import '../widgets/app_background.dart';
import '../widgets/country_picker_field.dart';
import '../widgets/facility_search_field.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_button.dart';
import '../widgets/journey_stage_picker.dart';

/// Combined first-run: journey + local circle. Interests deferred.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityTextController = TextEditingController();

  int _step = 0;
  JourneyStage? _journeyStage;
  int _pregnancyWeek = 20;
  bool _isSubmitting = false;
  bool _mainDone = false;

  String? _countryCode;
  String? _stateProvince;
  String _city = '';
  String? _selectedFacilityId;
  String _selectedFacilityName = '';
  List<CommunityStateOption> _states = const [];
  List<CommunityCityOption> _cities = const [];
  bool _loadingStates = false;
  bool _loadingCities = false;
  bool _hasExistingPhone = false;

  static const _stepCount = 4;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null && user.name.isNotEmpty) {
      _nameController.text = user.name;
    }
    final profile = ref.read(profileProvider).profile;
    if (profile?.phoneNumber != null && profile!.phoneNumber!.isNotEmpty) {
      _phoneController.text = profile.phoneNumber!;
      _hasExistingPhone = true;
    }
    if (profile?.onboardingCompleted == true) {
      _mainDone = true;
      if (profile!.journeyStage != null) {
        _journeyStage = profile.journeyStage;
      }
      if (profile.pregnancyWeek != null) {
        _pregnancyWeek = profile.pregnancyWeek!;
      }
      // Resume at local-circle step when journey is already saved.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (profile.onboardingCompleted && !profile.communityOnboardingCompleted) {
          setState(() => _step = 3);
          _pageController.jumpToPage(3);
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final community = ref.read(communityProvider);
      if (community.countries.isEmpty) {
        ref.read(communityProvider.notifier).bootstrap();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _cityTextController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 1 && _nameController.text.trim().isEmpty) {
      _showMessage('Please enter your name');
      return;
    }
    if (_step == 1 && !_hasExistingPhone) {
      final raw = _phoneController.text.trim();
      if (raw.isNotEmpty) {
        final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
        if (digits.length < 7 || digits.length > 15) {
          _showMessage('Enter a valid WhatsApp number');
          return;
        }
      }
    }
    if (_step == 2 && _journeyStage == null) {
      _showMessage('Please choose where you are on your journey');
      return;
    }
    if (_step == 3) {
      _submit();
      return;
    }

    setState(() => _step++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _previousStep() {
    if (_step == 0) return;
    setState(() => _step--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _loadStates(String countryCode) async {
    setState(() {
      _loadingStates = true;
      _states = const [];
      _stateProvince = null;
      _city = '';
      _cityTextController.clear();
      _cities = const [];
      _selectedFacilityId = null;
      _selectedFacilityName = '';
    });
    try {
      final states =
          await ref.read(apiServiceProvider).getCommunityStates(countryCode);
      if (!mounted) return;
      setState(() {
        _states = states;
        _loadingStates = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _states = const [];
        _loadingStates = false;
      });
    }
  }

  Future<void> _loadCities(String countryCode, String stateProvince) async {
    setState(() {
      _loadingCities = true;
      _cities = const [];
      _city = '';
      _cityTextController.clear();
      _selectedFacilityId = null;
      _selectedFacilityName = '';
    });
    try {
      final cities = await ref.read(apiServiceProvider).getCommunityCities(
            countryCode: countryCode,
            stateProvince: stateProvince,
          );
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _loadingCities = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cities = const [];
        _loadingCities = false;
      });
    }
  }

  Future<List<CommunityHealthcareFacility>> _fetchFacilities(String query) async {
    if (_countryCode == null || (_stateProvince?.trim().isEmpty ?? true)) {
      return const [];
    }
    final city =
        _cities.isNotEmpty ? _city.trim() : _cityTextController.text.trim();
    return ref.read(apiServiceProvider).getHealthcareFacilities(
          countryCode: _countryCode!,
          stateProvince: _stateProvince!.trim(),
          city: city,
          query: query,
        );
  }

  Future<void> _submit() async {
    final stage = _journeyStage;
    final stateProvince = _stateProvince?.trim() ?? '';
    final city =
        _cities.isNotEmpty ? _city.trim() : _cityTextController.text.trim();
    final facilityName = _selectedFacilityName.trim();

    if (_countryCode == null || stateProvince.isEmpty || city.isEmpty) {
      _showMessage('Please select your country, state, and city.');
      return;
    }
    if (facilityName.isEmpty) {
      _showMessage('Please select your hospital or health center.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Call APIs directly first so an intermediate profile update doesn't remount this screen.
      if (!_mainDone) {
        if (stage == null) {
          _showMessage('Please choose where you are on your journey');
          return;
        }
        await ref.read(apiServiceProvider).completeOnboarding(
              ProfileSavePayload(
                name: _nameController.text.trim(),
                language: AppConfig.languageCode,
                phoneNumber: _phoneController.text.trim().isEmpty
                    ? null
                    : _phoneController.text.trim(),
                journeyStage: stage,
                pregnancyWeek: JourneyHelpers.needsPregnancyWeek(stage)
                    ? _pregnancyWeek
                    : null,
              ),
            );
        _mainDone = true;
      }

      final facilityId =
          (_selectedFacilityId != null && _selectedFacilityId!.isNotEmpty)
              ? _selectedFacilityId
              : null;
      await ref.read(apiServiceProvider).completeCommunityOnboarding(
            countryCode: _countryCode!,
            stateProvince: stateProvince,
            city: city,
            healthcareFacilityId: facilityId,
            healthcareFacilityName: facilityName,
            interests: const [],
          );
      await ref.read(profileProvider.notifier).loadProfile();
      await ref.read(communityProvider.notifier).refreshStatus();
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
                    _buildLocalCircleStep(),
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
              label: _step == _stepCount - 1 ? 'Start your journey' : 'Continue',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _nextStep,
              icon: _step == _stepCount - 1
                  ? Icons.check_rounded
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
            'A short setup for chat and your local circle — not a long form.',
            style: AppTypography.bodyText.copyWith(color: context.appInkMuted),
          ),
          const SizedBox(height: AppSpacing.spaceLG),
          _buildHighlight(Icons.chat_outlined, 'Chat that remembers your journey'),
          const SizedBox(height: AppSpacing.spaceSM),
          _buildHighlight(
            Icons.location_on_outlined,
            'Nearby moms at your health center',
          ),
          const SizedBox(height: AppSpacing.spaceSM),
          _buildHighlight(
            Icons.health_and_safety_outlined,
            'Support that grows with you',
          ),
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
          Text(
            'What should we call you?',
            style: AppTypography.headingMedium.copyWith(color: context.appInk),
          ),
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
          if (!_hasExistingPhone) ...[
            const SizedBox(height: AppSpacing.spaceMD),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp number (optional)',
                hintText: '+234…',
                helperText: 'Optional — so we can reach you on WhatsApp later',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJourneyStep() {
    return _buildStepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where are you today?',
            style: AppTypography.headingMedium.copyWith(color: context.appInk),
          ),
          const SizedBox(height: AppSpacing.spaceSM),
          Text(
            'You can update your journey anytime in profile.',
            style: AppTypography.caption.copyWith(color: context.appInkMuted),
          ),
          const SizedBox(height: AppSpacing.spaceLG),
          JourneyStagePicker(
            selected: _journeyStage,
            options: JourneyStage.signupStages,
            onSelected: (stage) => setState(() => _journeyStage = stage),
          ),
          if (_journeyStage == JourneyStage.pregnant) ...[
            const SizedBox(height: AppSpacing.spaceLG),
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
          ] else if (_journeyStage == JourneyStage.ttc) ...[
            const SizedBox(height: AppSpacing.spaceMD),
            Text(
              'We\'ll tailor support for your fertility journey — cycles, waiting, and the questions that come with trying to conceive.',
              style: AppTypography.bodyText.copyWith(color: context.appInkMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.spaceMD),
          Text(
            'Healthcare professional at a clinic or hospital? Choose trying to conceive if you\'re not currently pregnant, then request your professional badge in Profile after signup.',
            style: AppTypography.caption.copyWith(color: context.appInkMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalCircleStep() {
    final communityState = ref.watch(communityProvider);
    final countries = communityState.countries
        .map((c) => (code: c.code, name: c.name))
        .toList();
    final cityLabel = _countryCode == 'NG' ? 'City / LGA' : 'City';
    final useCityDropdown = _cities.isNotEmpty;
    final facilityEnabled =
        _countryCode != null && (_stateProvince?.trim().isNotEmpty ?? false);

    return _buildStepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your local circle',
            style: AppTypography.headingMedium.copyWith(color: context.appInk),
          ),
          const SizedBox(height: AppSpacing.spaceSM),
          Text(
            'Share your area and health center so Nearby can show moms registered near you.',
            style: AppTypography.caption.copyWith(color: context.appInkMuted),
          ),
          const SizedBox(height: AppSpacing.spaceLG),
          CountryPickerField(
            countryCode: _countryCode,
            countries: countries,
            onSelected: (code) {
              setState(() => _countryCode = code);
              _loadStates(code);
            },
          ),
          const SizedBox(height: AppSpacing.spaceSM),
          DropdownButtonFormField<String>(
            key: ValueKey('state-$_countryCode-$_stateProvince'),
            initialValue: _stateProvince,
            decoration: InputDecoration(
              labelText: 'State / Province',
              filled: true,
              fillColor: context.appSurface,
            ),
            hint: Text(
              _countryCode == null
                  ? 'Select country first'
                  : _loadingStates
                      ? 'Loading states…'
                      : _states.isEmpty
                          ? 'No states listed'
                          : 'Select state',
            ),
            items: _states
                .map((s) => DropdownMenuItem(value: s.name, child: Text(s.name)))
                .toList(),
            onChanged: _countryCode == null || _loadingStates
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _stateProvince = value);
                    _loadCities(_countryCode!, value);
                  },
          ),
          const SizedBox(height: AppSpacing.spaceSM),
          if (useCityDropdown || _loadingCities)
            DropdownButtonFormField<String>(
              key: ValueKey('city-$_stateProvince-$_city'),
              initialValue: _city.isEmpty ? null : _city,
              decoration: InputDecoration(
                labelText: cityLabel,
                filled: true,
                fillColor: context.appSurface,
              ),
              hint: Text(_loadingCities ? 'Loading…' : 'Select $cityLabel'),
              items: _cities
                  .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                  .toList(),
              onChanged: _loadingCities
                  ? null
                  : (value) {
                      setState(() {
                        _city = value ?? '';
                        _selectedFacilityId = null;
                        _selectedFacilityName = '';
                      });
                    },
            )
          else
            TextField(
              controller: _cityTextController,
              enabled: _stateProvince != null,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: cityLabel,
                hintText: _stateProvince == null
                    ? 'Select state first'
                    : 'Enter your city',
                filled: true,
                fillColor: context.appSurface,
              ),
              onChanged: (_) => setState(() {
                _selectedFacilityId = null;
                _selectedFacilityName = '';
              }),
            ),
          const SizedBox(height: AppSpacing.spaceSM),
          FacilitySearchField(
            selectedId: _selectedFacilityId,
            selectedName: _selectedFacilityName,
            enabled: facilityEnabled,
            fetchFacilities: _fetchFacilities,
            onChanged: (facility) {
              setState(() {
                if (facility == null) {
                  _selectedFacilityId = null;
                  _selectedFacilityName = '';
                } else {
                  _selectedFacilityId =
                      facility.id.isEmpty ? null : facility.id;
                  _selectedFacilityName = facility.name;
                  if (facility.city.trim().isNotEmpty) {
                    _city = facility.city.trim();
                    _cityTextController.text = _city;
                  }
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
