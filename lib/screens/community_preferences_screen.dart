import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/community_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/community_interest_selector.dart';
import '../widgets/gradient_button.dart';

/// Edit community feed topics (and sync location used for Nearby / onboarding).
class CommunityPreferencesScreen extends ConsumerStatefulWidget {
  const CommunityPreferencesScreen({super.key});

  @override
  ConsumerState<CommunityPreferencesScreen> createState() =>
      _CommunityPreferencesScreenState();
}

class _CommunityPreferencesScreenState
    extends ConsumerState<CommunityPreferencesScreen> {
  final _selected = <String>{};
  bool _initialized = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final communityState = ref.read(communityProvider);
    if (communityState.interestGroups.isEmpty ||
        communityState.countries.isEmpty) {
      await ref.read(communityProvider.notifier).bootstrap();
    }
    if (!mounted) return;
    _applyInitialSelection();
  }

  void _applyInitialSelection() {
    if (_initialized) return;

    final profile = ref.read(profileProvider).profile;
    final status = ref.read(communityProvider).status;
    final keys = status?.interests.isNotEmpty == true
        ? status!.interests
        : profile?.communityInterests ?? const [];

    setState(() {
      _selected
        ..clear()
        ..addAll(keys);
      _initialized = true;
    });
  }

  String? _resolveCountryCode() {
    final profile = ref.read(profileProvider).profile;
    if (profile == null) return null;

    if (profile.countryCode != null && profile.countryCode!.isNotEmpty) {
      return profile.countryCode;
    }

    final name = profile.country?.trim().toLowerCase();
    if (name == null || name.isEmpty) return null;

    for (final country in ref.read(communityProvider).countries) {
      if (country.name.toLowerCase() == name) {
        return country.code;
      }
    }
    return null;
  }

  bool _hasCompleteLocation() {
    final profile = ref.read(profileProvider).profile;
    if (profile == null) return false;

    final stateProvince = profile.stateProvince?.trim() ?? '';
    final city = profile.city?.trim() ?? '';
    return _resolveCountryCode() != null &&
        stateProvince.isNotEmpty &&
        city.isNotEmpty;
  }

  Future<void> _save() async {
    if (_selected.isEmpty) {
      _showSnack('Pick at least one feed topic.');
      return;
    }
    if (_selected.length > 5) {
      _showSnack('You can select up to 5 feed topics.');
      return;
    }
    if (!_hasCompleteLocation()) {
      _showSnack(
        'Add your community location on Profile first — it powers Nearby and your feed.',
      );
      return;
    }

    final profile = ref.read(profileProvider).profile!;
    final countryCode = _resolveCountryCode()!;

    setState(() => _submitting = true);
    final ok = await ref.read(communityProvider.notifier).completeOnboarding(
          countryCode: countryCode,
          stateProvince: profile.stateProvince!.trim(),
          city: profile.city!.trim(),
          interests: _selected.toList(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      await ref.read(profileProvider.notifier).loadProfile();
      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }

    _showSnack(ref.read(communityProvider).error ?? 'Something went wrong');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final communityState = ref.watch(communityProvider);
    final profile = ref.watch(profileProvider).profile;
    final loadingCatalog =
        communityState.interestGroups.isEmpty && communityState.isLoading;

    return Scaffold(
      backgroundColor: context.appCanvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Community feed topics', style: AppTypography.headingMedium),
      ),
      body: loadingCatalog
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spaceMD,
                AppSpacing.spaceSM,
                AppSpacing.spaceMD,
                120,
              ),
              children: [
                Text(
                  'Choose up to 5 topics for your For You feed.',
                  style: AppTypography.bodyText.copyWith(color: context.appInkMuted),
                ),
                if (profile?.stateProvince != null && profile?.city != null) ...[
                  const SizedBox(height: AppSpacing.spaceMD),
                  Text(
                    'Location: ${profile!.country ?? ''}'
                    '${profile.country != null ? ' · ' : ''}'
                    '${profile.stateProvince} · ${profile.city}',
                    style: AppTypography.caption.copyWith(
                      color: context.appInkSubtle,
                    ),
                  ),
                  Text(
                    'Update location under Community location on Profile.',
                    style: AppTypography.caption.copyWith(color: context.appInkMuted),
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.spaceMD),
                  Text(
                    'Set your community location on Profile before saving feed topics.',
                    style: AppTypography.caption.copyWith(
                      color: context.appInkSubtle,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.spaceLG),
                CommunityInterestSelector(
                  groups: communityState.interestGroups,
                  selected: _selected,
                  onToggle: (key) {
                    setState(() {
                      if (_selected.contains(key)) {
                        _selected.remove(key);
                      } else {
                        _selected.add(key);
                      }
                    });
                  },
                  onSelectionLimitReached: () {
                    _showSnack('You can select up to 5 feed topics.');
                  },
                ),
                const SizedBox(height: AppSpacing.spaceXL),
                GradientButton(
                  onPressed: _submitting ? null : _save,
                  isLoading: _submitting,
                  label: 'Save feed topics',
                ),
              ],
            ),
    );
  }
}
