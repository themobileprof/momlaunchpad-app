import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community.dart';
import '../providers/community_provider.dart';
import '../providers/service_providers.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/country_picker_field.dart';
import '../widgets/community_interest_selector.dart';
import '../widgets/facility_search_field.dart';
import '../widgets/gradient_button.dart';

/// First-time community setup: location dropdowns + up to 5 interests.
class CommunityOnboardingScreen extends ConsumerStatefulWidget {
  const CommunityOnboardingScreen({super.key});

  @override
  ConsumerState<CommunityOnboardingScreen> createState() =>
      _CommunityOnboardingScreenState();
}

class _CommunityOnboardingScreenState
    extends ConsumerState<CommunityOnboardingScreen> {
  final _selected = <String>{};
  final _cityTextController = TextEditingController();
  String? _countryCode;
  String? _stateProvince;
  String _city = '';
  String? _selectedFacilityId;
  String _selectedFacilityName = '';
  List<CommunityStateOption> _states = const [];
  List<CommunityCityOption> _cities = const [];
  bool _loadingStates = false;
  bool _loadingCities = false;
  bool _submitting = false;

  @override
  void dispose() {
    _cityTextController.dispose();
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

  Future<void> _submit() async {
    final stateProvince = _stateProvince?.trim() ?? '';
    final city = _cities.isNotEmpty ? _city.trim() : _cityTextController.text.trim();
    final facilityName = _selectedFacilityName.trim();

    if (_countryCode == null || stateProvince.isEmpty || city.isEmpty) {
      _showSnack('Please select your country, state, and city.');
      return;
    }
    if (facilityName.isEmpty) {
      _showSnack('Please select your hospital or health center.');
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
    final facilityId =
        (_selectedFacilityId != null && _selectedFacilityId!.isNotEmpty)
            ? _selectedFacilityId
            : null;
    final ok = await ref.read(communityProvider.notifier).completeOnboarding(
          countryCode: _countryCode!,
          stateProvince: stateProvince,
          city: city,
          healthcareFacilityId: facilityId,
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

  bool get _facilityEnabled =>
      _countryCode != null && (_stateProvince?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final communityState = ref.watch(communityProvider);
    final groups = communityState.interestGroups;
    final countries = communityState.countries
        .map((c) => (code: c.code, name: c.name))
        .toList();
    final cityLabel = _countryCode == 'NG' ? 'City / LGA' : 'City';
    final useCityDropdown = _cities.isNotEmpty;

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
          Text('Where are you?',
              style: AppTypography.bodyTextMedium.copyWith(color: context.appInk)),
          const SizedBox(height: AppSpacing.spaceSM),
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
            enabled: _facilityEnabled,
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
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.spaceXS),
            child: Text(
              'Search within your state (e.g. Ikorodu). Picking a center sets the LGA when known.',
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
