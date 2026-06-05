import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/service_providers.dart';
import '../services/analytics_service.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Collects a star rating + optional testimonial (stored on server; GA4 gets metadata only).
class FeedbackSheet extends ConsumerStatefulWidget {
  const FeedbackSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: const FeedbackSheet(),
      ),
    );
  }

  @override
  ConsumerState<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<FeedbackSheet> {
  int _rating = 0;
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating')),
      );
      return;
    }
    setState(() => _submitting = true);
    final message = _controller.text.trim();
    try {
      await ref.read(apiServiceProvider).submitUserFeedback(
            rating: _rating,
            message: message.isEmpty ? null : message,
          );
      await ref.read(analyticsServiceProvider).logEvent(
        AnalyticsEvents.testimonialSubmitted,
        {
          AnalyticsParams.rating: _rating,
          AnalyticsParams.hasWrittenFeedback: message.isNotEmpty,
          AnalyticsParams.source: 'settings',
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send feedback. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spaceMD,
        0,
        AppSpacing.spaceMD,
        AppSpacing.spaceLG,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Share your experience', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.spaceXS),
          Text(
            'Your rating helps us improve. Optional comments are stored securely '
            'and may be used as testimonials with your permission.',
            style: AppTypography.caption.copyWith(color: context.appInkSubtle),
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = star),
                icon: Icon(
                  star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppColors.warning,
                  size: 36,
                ),
              );
            }),
          ),
          TextField(
            controller: _controller,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Tell us more (optional)',
              hintText: 'What do you love? What could be better?',
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit feedback'),
          ),
        ],
      ),
    );
  }
}
