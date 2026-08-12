import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/community_provider.dart';
import '../providers/service_providers.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/country_picker_field.dart';
import '../widgets/community_interest_selector.dart';
import '../widgets/gradient_button.dart';
import '../widgets/location_suggest_field.dart';

/// First-time community setup: location + up to 5 interests.
class CommunityOnboardingScreen extends ConsumerStatefulWidget {
  const CommunityOnboardingScreen({super.key});

  @override
  ConsumerState<CommunityOnboardingScreen> createState() =>
      _CommunityOnboardingScreenState();
}

class _CommunityOnboardingScreenState
    extends ConsumerState<CommunityOnboardingScreen> {
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _facilityController = TextEditingController();
  final _selected = <String>{};
  String? _countryCode;
  String? _selectedFacilityId;
  bool _submitting = false;

  @override
  void dispose() {
    _stateController.dispose();
    _cityController.dispose();
    _facilityController.dispose();
    super.dispose();
  }

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

  Future<void> _submit() async {
    final stateProvince = _stateController.text.trim();
    final city = _cityController.text.trim();
    final facilityName = _facilityController.text.trim();

    if (_countryCode == null || stateProvince.isEmpty || city.isEmpty) {
      _showSnack('Please select your country and enter state and city.');
      return;
    }
    if (facilityName.isEmpty) {
      _showSnack('Please enter your hospital or health center.');
      return;
    }
    if (_selected.isEmpty) {
      _showSnack('Pick at least one interest.');
      return;
    }
    if (_selected.length > 5) {
      _showSnack('You can select up to 5 interests.');
      return;
    }

    setState(() => _submitting = true);
    await _syncSelectedFacilityId(facilityName);
    final ok = await ref.read(communityProvider.notifier).completeOnboarding(
          countryCode: _countryCode!,
          stateProvince: stateProvince,
          city: city,
          healthcareFacilityId: _selectedFacilityId,
          healthcareFacilityName: facilityName,
          interests: _selected.toList(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      _showSnack(ref.read(communityProvider).error ?? 'Something went wrong');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleInterest(String key) {
    setState(() {
      if (_selected.contains(key)) {
        _selected.remove(key);
      } else {
        _selected.add(key);
      }
    });
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

  Future<void> _syncSelectedFacilityId(String name) async {
    final trimmed = name.trim();
    if (_countryCode == null || trimmed.isEmpty) {
      _selectedFacilityId = null;
      return;
    }
    final stateProvince = _stateController.text.trim();
    final city = _cityController.text.trim();
    if (stateProvince.isEmpty || city.isEmpty) {
      _selectedFacilityId = null;
      return;
    }
    try {
      final facilities =
          await ref.read(apiServiceProvider).getHealthcareFacilities(
                countryCode: _countryCode!,
                stateProvince: stateProvince,
                city: city,
                query: trimmed,
              );
      for (final f in facilities) {
        if (f.name.toLowerCase() == trimmed.toLowerCase()) {
          _selectedFacilityId = f.id;
          return;
        }
      }
    } catch (_) {}
    _selectedFacilityId = null;
  }

  @override
  Widget build(BuildContext context) {
    final communityState = ref.watch(communityProvider);
    final groups = communityState.interestGroups;
    final countries = communityState.countries
        .map((c) => (code: c.code, name: c.name))
        .toList();

    return Scaffold(
      backgroundColor: context.appCanvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Join the community', style: AppTypography.headingMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spaceMD,
          AppSpacing.spaceSM,
          AppSpacing.spaceMD,
          120,
        ),
        children: [
          Text(
            'Your location and health center help us show Nearby posts from '
            'moms registered where you are. Pick a few topics to personalize your feed.',
            style: AppTypography.bodyText.copyWith(color: context.appInkMuted),
          ),
          const SizedBox(height: AppSpacing.spaceLG),
          Text('Where are you?', style: AppTypography.bodyTextMedium.copyWith(color: context.appInk)),
          const SizedBox(height: AppSpacing.spaceSM),
          CountryPickerField(
            countryCode: _countryCode,
            countries: countries,
            onSelected: (code) => setState(() {
              _countryCode = code;
              _selectedFacilityId = null;
            }),
          ),
          const SizedBox(height: AppSpacing.spaceSM),
          LocationSuggestField(
            controller: _stateController,
            label: 'State / Province',
            enabled: _countryCode != null,
            fetchSuggestions: _fetchStateSuggestions,
          ),
          const SizedBox(height: AppSpacing.spaceSM),
          LocationSuggestField(
            controller: _cityController,
            label: 'City',
            enabled: _countryCode != null,
            fetchSuggestions: _fetchCitySuggestions,
          ),
          const SizedBox(height: AppSpacing.spaceSM),
          LocationSuggestField(
            controller: _facilityController,
            label: 'Hospital / health center',
            enabled: _countryCode != null,
            fetchSuggestions: _fetchFacilitySuggestions,
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.spaceXS),
            child: Text(
              'Start typing to search. If yours is missing, type the full name and we\'ll add it.',
              style: AppTypography.caption.copyWith(color: context.appInkMuted),
            ),
          ),
          const SizedBox(height: AppSpacing.spaceLG),
          CommunityInterestSelector(
            groups: groups,
            selected: _selected,
            onToggle: _toggleInterest,
            onSelectionLimitReached: () {
              _showSnack('You can select up to 5 interests.');
            },
          ),
          const SizedBox(height: AppSpacing.spaceXL),
          GradientButton(
            onPressed: _submitting ? null : _submit,
            isLoading: _submitting,
            label: 'Continue to Community',
          ),
        ],
      ),
    );
  }
}
