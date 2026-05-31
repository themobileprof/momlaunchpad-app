import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/image_url.dart';
import 'online_image_url_field.dart';

/// Editor for up to [maxImages] external HTTPS image URLs on a post.
class OnlineImageUrlListEditor extends StatefulWidget {
  final List<String> initialUrls;
  final int maxImages;
  final ValueChanged<List<String>> onChanged;

  const OnlineImageUrlListEditor({
    super.key,
    this.initialUrls = const [],
    this.maxImages = 4,
    required this.onChanged,
  });

  @override
  State<OnlineImageUrlListEditor> createState() =>
      _OnlineImageUrlListEditorState();
}

class _OnlineImageUrlListEditorState extends State<OnlineImageUrlListEditor> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.initialUrls
        .map((url) => TextEditingController(text: url))
        .toList();
    if (_controllers.isEmpty) {
      _controllers.add(TextEditingController());
    }
    for (final c in _controllers) {
      c.addListener(_emit);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    final urls = _controllers
        .map((c) => normalizedHttpsImageUrl(c.text))
        .whereType<String>()
        .where(isValidHttpsImageUrl)
        .toList();
    widget.onChanged(urls);
    setState(() {});
  }

  void _addField() {
    if (_controllers.length >= widget.maxImages) return;
    final controller = TextEditingController();
    controller.addListener(_emit);
    setState(() => _controllers.add(controller));
  }

  void _removeField(int index) {
    if (_controllers.length <= 1) {
      _controllers.first.clear();
      _emit();
      return;
    }
    _controllers[index].dispose();
    setState(() => _controllers.removeAt(index));
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos (online links)',
          style: AppTypography.bodyTextMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Paste https:// links to images hosted elsewhere (up to ${widget.maxImages}). '
          'We do not upload files to MomLaunchpad servers.',
          style: AppTypography.caption.copyWith(color: AppColors.textLight),
        ),
        const SizedBox(height: AppSpacing.spaceSM),
        for (var i = 0; i < _controllers.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: OnlineImageUrlField(
                  controller: _controllers[i],
                  labelText: 'Image link ${i + 1}',
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: () => _removeField(i),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSM),
        ],
        if (_controllers.length < widget.maxImages)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addField,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add another photo'),
            ),
          ),
      ],
    );
  }
}
