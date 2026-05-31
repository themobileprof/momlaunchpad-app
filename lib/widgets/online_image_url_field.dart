import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/image_url.dart';

/// Single HTTPS image URL input with live preview.
class OnlineImageUrlField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? helperText;
  final ValueChanged<String>? onChanged;

  const OnlineImageUrlField({
    super.key,
    required this.controller,
    this.labelText = 'Image link (https://)',
    this.helperText,
    this.onChanged,
  });

  @override
  State<OnlineImageUrlField> createState() => _OnlineImageUrlFieldState();
}

class _OnlineImageUrlFieldState extends State<OnlineImageUrlField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_notifyChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_notifyChange);
    super.dispose();
  }

  void _notifyChange() {
    widget.onChanged?.call(widget.controller.text);
    setState(() {});
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    widget.controller.text = text;
    widget.controller.selection = TextSelection.collapsed(offset: text.length);
  }

  @override
  Widget build(BuildContext context) {
    final url = normalizedHttpsImageUrl(widget.controller.text);
    final showPreview = url != null && isValidHttpsImageUrl(url);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: widget.labelText,
            helperText: widget.helperText,
            suffixIcon: IconButton(
              tooltip: 'Paste link',
              onPressed: _pasteFromClipboard,
              icon: const Icon(Icons.content_paste_outlined),
            ),
          ),
          validator: httpsImageUrlValidator,
        ),
        if (showPreview) ...[
          const SizedBox(height: AppSpacing.spaceSM),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _previewError(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppColors.primaryPurple.withValues(alpha: 0.08),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _previewError() {
    return Container(
      color: AppColors.primaryPurple.withValues(alpha: 0.08),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      child: Text(
        'Could not load preview — check the link is public and uses https://',
        style: AppTypography.caption.copyWith(color: AppColors.textLight),
        textAlign: TextAlign.center,
      ),
    );
  }
}
