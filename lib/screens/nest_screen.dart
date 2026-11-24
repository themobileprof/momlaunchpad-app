import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nest.dart';
import '../providers/service_providers.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/widgets.dart';

/// Delivery nest waitlist — description + interest survey (feature not live yet).
class NestScreen extends ConsumerStatefulWidget {
  const NestScreen({super.key});

  @override
  ConsumerState<NestScreen> createState() => _NestScreenState();
}

class _NestScreenState extends ConsumerState<NestScreen> {
  NestInterestResponse? _existing;
  String? _interested;
  final _moreInfoController = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  String? _error;
  bool _saved = false;

  static const _options = [
    ('yes', 'Yes — I would use this'),
    ('no', 'No — not for me'),
    ('maybe', 'Maybe — depends on the details'),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _moreInfoController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(apiServiceProvider).getNestInterest();
      if (!mounted) return;
      setState(() {
        _existing = result.response;
        _interested = result.response?.interested;
        _moreInfoController.text = result.response?.moreInfo ?? '';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final answer = _interested;
    if (answer == null || answer.isEmpty) {
      setState(() => _error = 'Please choose an option');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _saved = false;
    });
    try {
      final saved = await ref.read(apiServiceProvider).submitNestInterest(
            interested: answer,
            moreInfo: _moreInfoController.text.trim().isEmpty
                ? null
                : _moreInfoController.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _existing = saved;
        _saved = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not save your answer');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MomAppBar(pageTitle: 'Delivery nest'),
      body: _loading
          ? const LoadingState(message: 'Loading…')
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spaceMD,
                AppSpacing.spaceMD,
                AppSpacing.spaceMD,
                120,
              ),
              children: [
                Text(
                  'Coming soon — we are shaping this with moms before we open it.',
                  style: AppTypography.bodyText.copyWith(
                    color: context.appInkSubtle,
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceLG),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.spaceMD),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What Delivery nest is for',
                        style: AppTypography.headingSmall,
                      ),
                      const SizedBox(height: AppSpacing.spaceSM),
                      Text(
                        'A private place to prepare money for delivery — hospital fees, transport, baby items — with people who already love you. You set a goal tied to your due date. MomLaunchpad does not hold the money: transfers still happen the way your family already does (bank, cash, wallet).',
                        style: AppTypography.bodyText,
                      ),
                      const SizedBox(height: AppSpacing.spaceMD),
                      Text(
                        'How your tribe helps',
                        style: AppTypography.headingSmall,
                      ),
                      const SizedBox(height: AppSpacing.spaceSM),
                      _bullet(
                        'You invite close family and friends with a personal link.',
                      ),
                      _bullet(
                        'Each month they get a gentle nudge to gift toward your nest — and can record what they sent or pledged.',
                      ),
                      _bullet(
                        'You see who has joined and what has been recorded, so you are not chasing people one by one on WhatsApp.',
                      ),
                      _bullet(
                        'Near your due date, the nest helps you see if you are close to the amount you planned for birth.',
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.spaceMD),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.spaceMD),
                    child: Text(
                      _error!,
                      style: AppTypography.bodyText.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                if (_saved) ...[
                  const SizedBox(height: AppSpacing.spaceMD),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.spaceMD),
                    child: Text(
                      _existing?.interested == 'yes'
                          ? 'Thanks — we saved your answer. We will prioritize building Nest for moms like you.'
                          : 'Thanks — we saved your answer.',
                      style: AppTypography.bodyText.copyWith(
                        color: context.appPrimary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.spaceLG),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.spaceMD),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Would you want this?',
                        style: AppTypography.headingSmall,
                      ),
                      const SizedBox(height: AppSpacing.spaceXS),
                      Text(
                        'A short signal helps us decide what to build next. You can update your answer anytime.',
                        style: AppTypography.caption.copyWith(
                          color: context.appInkSubtle,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spaceMD),
                      ..._options.map((opt) {
                        final (value, label) = opt;
                        final selected = _interested == value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _interested = value),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.spaceMD,
                                vertical: AppSpacing.spaceSM,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? context.appPrimary
                                      : context.appInkSubtle.withValues(alpha: 0.25),
                                ),
                                color: selected
                                    ? context.appPrimary.withValues(alpha: 0.08)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: selected
                                        ? context.appPrimary
                                        : context.appInkSubtle,
                                    size: 22,
                                  ),
                                  const SizedBox(width: AppSpacing.spaceSM),
                                  Expanded(
                                    child: Text(label, style: AppTypography.bodyText),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: AppSpacing.spaceMD),
                      AppTextField(
                        controller: _moreInfoController,
                        label: 'More info (optional)',
                        hint:
                            'What would make Nest useful? Who would you invite? Any worries?',
                        maxLines: 4,
                        maxLength: 2000,
                      ),
                      const SizedBox(height: AppSpacing.spaceMD),
                      GradientButton(
                        label: _busy
                            ? 'Saving…'
                            : _existing != null
                                ? 'Update answer'
                                : 'Send answer',
                        isLoading: _busy,
                        onPressed: _busy || _interested == null ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: AppTypography.bodyText),
          Expanded(child: Text(text, style: AppTypography.bodyText)),
        ],
      ),
    );
  }
}
