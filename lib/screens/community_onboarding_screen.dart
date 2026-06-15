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
  final _selected = <String>{};
  String? _countryCode;
  bool _submitting = false;

  @override
  void dispose() {
    _stateController.dispose();
    _cityController.dispose();
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

    if (_countryCode == null || stateProvince.isEmpty || city.isEmpty) {
      _showSnack('Please select your country and enter state and city.');
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
    final ok = await ref.read(communityProvider.notifier).completeOnboarding(
          countryCode: _countryCode!,
          stateProvince: stateProvince,
          city: city,
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
            'Your location helps us show nearby discussions and events. '
            'Pick a few topics so we can personalize your feed.',
            style: AppTypography.bodyText.copyWith(color: context.appInkMuted),
          ),
          const SizedBox(height: AppSpacing.spaceLG),
          Text('Where are you?', style: AppTypography.bodyTextMedium.copyWith(color: context.appInk)),
          const SizedBox(height: AppSpacing.spaceSM),
          CountryPickerField(
            countryCode: _countryCode,
            countries: countries,
            onSelected: (code) => setState(() => _countryCode = code),
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
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.spaceXS),
            child: Text(
              'Start typing to see suggestions. You can always enter your own.',
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
