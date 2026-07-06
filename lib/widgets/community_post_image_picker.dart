import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/service_providers.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/image_url.dart';

/// Picks photos from the device, uploads them, and returns server URLs for a post.
class CommunityPostImagePicker extends ConsumerStatefulWidget {
  final List<String> initialUrls;
  final int maxImages;
  final ValueChanged<List<String>> onChanged;
  final ValueChanged<bool>? onUploadingChanged;

  const CommunityPostImagePicker({
    super.key,
    this.initialUrls = const [],
    this.maxImages = 4,
    required this.onChanged,
    this.onUploadingChanged,
  });

  @override
  ConsumerState<CommunityPostImagePicker> createState() =>
      _CommunityPostImagePickerState();
}

class _CommunityPostImagePickerState
    extends ConsumerState<CommunityPostImagePicker> {
  late List<String> _urls;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _urls = List<String>.from(widget.initialUrls);
  }

  void _setUploading(bool value) {
    if (_uploading == value) return;
    setState(() => _uploading = value);
    widget.onUploadingChanged?.call(value);
  }

  void _emitUrls(List<String> urls) {
    _urls = urls;
    widget.onChanged(urls);
    setState(() {});
  }

  void _removeAt(int index) {
    final next = List<String>.from(_urls)..removeAt(index);
    _emitUrls(next);
  }

  Future<void> _pickAndUpload() async {
    if (_uploading || _urls.length >= widget.maxImages) return;

    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    _setUploading(true);
    try {
      final url = await ref
          .read(apiServiceProvider)
          .uploadCommunityPostImage(file.path);
      if (!mounted) return;
      _emitUrls([..._urls, url]);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) _setUploading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = _urls.length < widget.maxImages && !_uploading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos',
          style: AppTypography.bodyTextMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add up to ${widget.maxImages} photos (JPEG, PNG, or WebP, max 5MB each).',
          style: AppTypography.caption.copyWith(color: context.appInkSubtle),
        ),
        const SizedBox(height: AppSpacing.spaceSM),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _urls.length + (canAdd || _uploading ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.spaceSM),
            itemBuilder: (context, index) {
              if (index < _urls.length) {
                return _UploadedThumbnail(
                  url: _urls[index],
                  onRemove: () => _removeAt(index),
                );
              }
              return _AddPhotoTile(
                uploading: _uploading,
                onTap: canAdd ? _pickAndUpload : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UploadedThumbnail extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;

  const _UploadedThumbnail({
    required this.url,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMediaUrl(url) ?? url;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            resolved,
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 96,
              height: 96,
              color: context.appPrimary.withValues(alpha: 0.08),
              alignment: Alignment.center,
              child: Icon(Icons.broken_image_outlined, color: context.appInkSubtle),
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: context.appSurface,
            shape: const CircleBorder(),
            elevation: 1,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: context.appInkSubtle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final bool uploading;
  final VoidCallback? onTap;

  const _AddPhotoTile({
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appPrimary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 96,
          height: 96,
          child: uploading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: context.appPrimary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add',
                      style: AppTypography.caption.copyWith(
                        color: context.appPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
