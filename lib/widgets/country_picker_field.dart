import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Searchable country picker (works well with long country lists on mobile).
class CountryPickerField extends StatelessWidget {
  final String? countryCode;
  final List<({String code, String name})> countries;
  final ValueChanged<String> onSelected;
  final String label;

  const CountryPickerField({
    super.key,
    required this.countryCode,
    required this.countries,
    required this.onSelected,
    this.label = 'Country',
  });

  String? get _selectedName {
    if (countryCode == null) return null;
    for (final c in countries) {
      if (c.code == countryCode) return c.name;
    }
    return null;
  }

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CountrySearchSheet(countries: countries),
    );
    if (selected != null) {
      onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: context.appSurface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          suffixIcon: Icon(Icons.arrow_drop_down_rounded),
        ),
        child: Text(
          _selectedName ?? 'Select country',
          style: AppTypography.bodyText.copyWith(
            color: _selectedName == null ? context.appInkSubtle : null,
          ),
        ),
      ),
    );
  }
}

class _CountrySearchSheet extends StatefulWidget {
  final List<({String code, String name})> countries;

  const _CountrySearchSheet({required this.countries});

  @override
  State<_CountrySearchSheet> createState() => _CountrySearchSheetState();
}

class _CountrySearchSheetState extends State<_CountrySearchSheet> {
  final _searchController = TextEditingController();
  late List<({String code, String name})> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.countries;
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.countries
          : widget.countries
              .where((c) => c.name.toLowerCase().contains(q) || c.code.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: AppSpacing.spaceSM),
          Text('Select country', style: AppTypography.bodyTextMedium),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.spaceMD),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search countries…',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final country = _filtered[index];
                return ListTile(
                  title: Text(country.name),
                  subtitle: Text(country.code),
                  onTap: () => Navigator.pop(context, country.code),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
