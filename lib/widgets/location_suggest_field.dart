import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

typedef LocationSuggestFetcher = Future<List<String>> Function(String query);

/// Text field with API-backed autocomplete suggestions (works on mobile).
class LocationSuggestField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final LocationSuggestFetcher fetchSuggestions;
  final bool enabled;
  final TextCapitalization textCapitalization;

  const LocationSuggestField({
    super.key,
    required this.controller,
    required this.label,
    required this.fetchSuggestions,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.words,
  });

  @override
  State<LocationSuggestField> createState() => _LocationSuggestFieldState();
}

class _LocationSuggestFieldState extends State<LocationSuggestField> {
  Timer? _debounce;
  Iterable<String> _options = const [];
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadOptions(String query) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      if (query.trim().length < 2) {
        setState(() => _options = const []);
        return;
      }
      try {
        final results = await widget.fetchSuggestions(query.trim());
        if (mounted) setState(() => _options = results);
      } catch (_) {
        if (mounted) setState(() => _options = const []);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (textEditingValue) {
        _loadOptions(textEditingValue.text);
        return _options;
      },
      onSelected: (selection) {
        widget.controller.text = selection;
        widget.controller.selection = TextSelection.collapsed(offset: selection.length);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: widget.enabled,
          textCapitalization: widget.textCapitalization,
          decoration: InputDecoration(
            labelText: widget.label,
            filled: true,
            fillColor: context.appSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        if (options.isEmpty) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: context.appSurface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, minWidth: 280),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.spaceXS),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
