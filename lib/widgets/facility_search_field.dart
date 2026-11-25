import 'dart:async';

import 'package:flutter/material.dart';
import '../models/community.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

typedef FacilityCatalogFetcher = Future<List<CommunityHealthcareFacility>> Function(
  String query,
);

/// Searchable dropdown for hospitals / health centers in a city.
class FacilitySearchField extends StatefulWidget {
  final String? selectedId;
  final String selectedName;
  final bool enabled;
  final FacilityCatalogFetcher fetchFacilities;
  final ValueChanged<CommunityHealthcareFacility?> onChanged;

  const FacilitySearchField({
    super.key,
    required this.selectedId,
    required this.selectedName,
    required this.fetchFacilities,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<FacilitySearchField> createState() => _FacilitySearchFieldState();
}

class _FacilitySearchFieldState extends State<FacilitySearchField> {
  Future<void> _openPicker() async {
    if (!widget.enabled) return;
    final result = await showModalBottomSheet<_FacilityPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _FacilitySearchSheet(
          initialName: widget.selectedName,
          fetchFacilities: widget.fetchFacilities,
        );
      },
    );
    if (!mounted || result == null) return;
    if (result.clear) {
      widget.onChanged(null);
      return;
    }
    if (result.facility != null) {
      widget.onChanged(result.facility);
      return;
    }
    if (result.customName != null && result.customName!.trim().isNotEmpty) {
      widget.onChanged(
        CommunityHealthcareFacility(
          id: '',
          name: result.customName!.trim(),
          countryCode: '',
          stateProvince: '',
          city: '',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.selectedName.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Hospital / health center',
            filled: true,
            fillColor: context.appSurface,
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: InkWell(
            onTap: widget.enabled ? _openPicker : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                !widget.enabled
                    ? 'Select country and state first'
                    : hasValue
                        ? widget.selectedName
                        : 'Search and select a health center',
                style: AppTypography.bodyText.copyWith(
                  color: hasValue && widget.enabled
                      ? context.appInk
                      : context.appInkMuted,
                ),
              ),
            ),
          ),
        ),
        if (hasValue && widget.enabled)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => widget.onChanged(null),
              child: const Text('Clear'),
            ),
          ),
      ],
    );
  }
}

class _FacilityPick {
  final CommunityHealthcareFacility? facility;
  final String? customName;
  final bool clear;

  const _FacilityPick.facility(this.facility)
      : customName = null,
        clear = false;

  const _FacilityPick.custom(this.customName)
      : facility = null,
        clear = false;

  const _FacilityPick.clear()
      : facility = null,
        customName = null,
        clear = true;
}

class _FacilitySearchSheet extends StatefulWidget {
  final String initialName;
  final FacilityCatalogFetcher fetchFacilities;

  const _FacilitySearchSheet({
    required this.initialName,
    required this.fetchFacilities,
  });

  @override
  State<_FacilitySearchSheet> createState() => _FacilitySearchSheetState();
}

class _FacilitySearchSheetState extends State<_FacilitySearchSheet> {
  final _queryController = TextEditingController();
  Timer? _debounce;
  List<CommunityHealthcareFacility> _options = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      _load(value.trim());
    });
  }

  Future<void> _load(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.fetchFacilities(query);
      if (!mounted) return;
      setState(() {
        _options = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _options = const [];
        _loading = false;
        _error = 'Could not load health centers';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _queryController.text.trim();
    final exact = _options.any((f) => f.name.toLowerCase() == q.toLowerCase());
    final canAdd = q.length >= 2 && !exact;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.spaceSM),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appInkMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.spaceMD,
                  AppSpacing.spaceMD,
                  AppSpacing.spaceMD,
                  AppSpacing.spaceSM,
                ),
                child: Text(
                  'Select health center',
                  style: AppTypography.headingSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMD),
                child: TextField(
                  controller: _queryController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Type to filter…',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: _onQueryChanged,
                ),
              ),
              const SizedBox(height: AppSpacing.spaceSM),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              style: AppTypography.bodyText
                                  .copyWith(color: context.appInkMuted),
                            ),
                          )
                        : ListView(
                            children: [
                              if (_options.isEmpty && !canAdd)
                                Padding(
                                  padding: const EdgeInsets.all(AppSpacing.spaceMD),
                                  child: Text(
                                    'No centers listed for this area yet. Type a name to add yours.',
                                    style: AppTypography.bodyText
                                        .copyWith(color: context.appInkMuted),
                                  ),
                                ),
                              ..._options.map(
                                (f) => ListTile(
                                  title: Text(f.name),
                                  subtitle: f.city.trim().isEmpty
                                      ? null
                                      : Text(f.city),
                                  onTap: () => Navigator.pop(
                                    context,
                                    _FacilityPick.facility(f),
                                  ),
                                ),
                              ),
                              if (canAdd)
                                ListTile(
                                  title: Text(
                                    'Add “$q”',
                                    style: TextStyle(
                                      color: context.appPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onTap: () => Navigator.pop(
                                    context,
                                    _FacilityPick.custom(q),
                                  ),
                                ),
                            ],
                          ),
              ),
              if (widget.initialName.trim().isNotEmpty)
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, const _FacilityPick.clear()),
                  child: const Text('Clear selection'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
