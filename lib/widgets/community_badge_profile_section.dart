import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community.dart';
import '../models/community_badge_request.dart';
import '../providers/service_providers.dart';
import '../services/api_service.dart';
import '../utils/community_badges.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_card.dart';
import 'community_author_row.dart';
import 'premium_upsell_dialog.dart';

/// Profile section: verified community badges and verification requests.
class CommunityBadgeProfileSection extends ConsumerStatefulWidget {
  const CommunityBadgeProfileSection({super.key});

  @override
  ConsumerState<CommunityBadgeProfileSection> createState() =>
      _CommunityBadgeProfileSectionState();
}

class _CommunityBadgeProfileSectionState
    extends ConsumerState<CommunityBadgeProfileSection> {
  MyCommunityBadges? _data;
  CommunityBadgeCatalog _catalog = const CommunityBadgeCatalog({});
  bool _loading = true;
  String? _error;
  String? _submittingBadgeType;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getMyCommunityBadges();
      var labels = <String, String>{};
      try {
        labels = Map<String, String>.from(
          (await api.getCommunityBadgeCatalog()).labels,
        );
      } catch (_) {}
      for (final t in data.requestableTypes) {
        labels[t.key] = t.label;
      }
      if (mounted) {
        setState(() {
          _data = data;
          _catalog = CommunityBadgeCatalog(labels);
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load badges');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestBadge(CommunityCatalogItem badgeType) async {
    final workplaceController = TextEditingController();
    final roleController = TextEditingController();
    final credentialController = TextEditingController();
    final linkController = TextEditingController();
    final messageController = TextEditingController();
    final credentialRequired = credentialRequiredForBadge(badgeType.key);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Request ${badgeType.label}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badgeType.description != null &&
                    badgeType.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.spaceMD),
                    child: Text(
                      badgeType.description!,
                      style: AppTypography.caption.copyWith(
                        color: context.appInkSubtle,
                      ),
                    ),
                  ),
                TextField(
                  controller: workplaceController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Workplace or facility',
                    hintText: 'Hospital, clinic, or program name',
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceSM),
                TextField(
                  controller: roleController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Role or job title',
                    hintText: 'e.g. Staff midwife, Clinic manager',
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceSM),
                TextField(
                  controller: credentialController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: credentialRequired
                        ? 'License or registration number'
                        : 'Employee or program ID (optional)',
                    hintText: credentialRequired
                        ? 'Professional license or registration'
                        : 'Optional identifier',
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceSM),
                TextField(
                  controller: linkController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Verification link (optional)',
                    hintText: 'Hospital page, registry profile, or LinkedIn',
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceSM),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Additional note (optional)',
                    hintText: 'Anything else reviewers should know',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit request'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      final details = BadgeRequestDetails(
        workplace: workplaceController.text,
        roleTitle: roleController.text,
        credentialId: credentialController.text,
        verificationUrl: linkController.text,
      );
      final validationError =
          validateBadgeRequestDetails(badgeType.key, details);
      if (validationError != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validationError)),
        );
        return;
      }

      setState(() => _submittingBadgeType = badgeType.key);
      try {
        await ref.read(apiServiceProvider).createCommunityBadgeRequest(
              badgeType: badgeType.key,
              details: details,
              message: messageController.text,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${badgeType.label} request submitted')),
        );
        await _load();
      } on ApiException catch (e) {
        if (!mounted) return;
        final showUpsell = e.message.toLowerCase().contains('premium') ||
            e.message.toLowerCase().contains('upgrade');
        if (showUpsell) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => const PremiumUpsellDialog(
              featureName: 'multiple badge requests',
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      } finally {
        if (mounted) setState(() => _submittingBadgeType = null);
      }
    } finally {
      workplaceController.dispose();
      roleController.dispose();
      credentialController.dispose();
      linkController.dispose();
      messageController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Community badges', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.spaceXS),
          Text(
            _data == null
                ? 'Request verification for expert badges shown on your community posts. '
                    'An admin reviews each request.'
                : _planLimitCaption(_data!),
            style: AppTypography.caption.copyWith(
              color: context.appInkSubtle,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (_error != null)
            _ErrorRow(message: _error!, onRetry: _load)
          else if (_data != null) ...[
            _buildEarnedBadges(_data!, _catalog),
            const SizedBox(height: AppSpacing.spaceMD),
            _buildRequestable(_data!, _catalog),
            if (_data!.requests.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.spaceMD),
              _buildRequestHistory(_data!, _catalog),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEarnedBadges(
    MyCommunityBadges data,
    CommunityBadgeCatalog catalog,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your badges', style: AppTypography.label),
        const SizedBox(height: AppSpacing.spaceSM),
        if (data.badges.isEmpty)
          Text(
            'No verified badges yet.',
            style: AppTypography.caption.copyWith(
              color: context.appInkSubtle,
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.spaceXS,
            runSpacing: AppSpacing.spaceXS,
            children: data.badges.map((key) {
              return CommunityBadgeChip(
                badgeType: key,
                label: catalog.labelFor(key),
              );
            }).toList(),
          ),
      ],
    );
  }

  String _planLimitCaption(MyCommunityBadges data) {
    if (data.isPremium) {
      return 'Premium: up to ${data.badgeLimit} verified badges '
          '(${data.badgeSlotsUsed} of ${data.badgeLimit} in use, including pending requests). '
          'An admin reviews each request.';
    }
    return 'Free plan: up to ${data.badgeLimits.free} verified badge(s) '
        '(${data.badgeSlotsUsed} of ${data.badgeLimit} in use). '
        'Premium members can hold up to ${data.badgeLimits.premium}. '
        'An admin reviews each request.';
  }

  Widget _buildRequestable(
    MyCommunityBadges data,
    CommunityBadgeCatalog catalog,
  ) {
    final available = <CommunityCatalogItem>[];
    for (final t in data.requestableTypes) {
      if (data.badges.contains(t.key)) continue;
      if (data.pendingRequestFor(t.key) != null) continue;
      available.add(t);
    }
    if (available.isEmpty) return const SizedBox.shrink();

    final atLimit = !data.canRequestMoreBadges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Request verification', style: AppTypography.label),
        const SizedBox(height: AppSpacing.spaceSM),
        if (atLimit) ...[
          Text(
            data.isPremium
                ? 'You are using all ${data.badgeLimit} badge slots '
                    '(verified badges and pending requests). '
                    'Revoke or wait for review before applying for another.'
                : data.badges.isNotEmpty
                    ? 'You already have your free-plan badge. '
                        'Upgrade to Premium to hold up to ${data.badgeLimits.premium} verified badges.'
                    : 'You already have a badge in review. '
                        'Wait for approval or upgrade to Premium for up to ${data.badgeLimits.premium} badges.',
            style: AppTypography.caption.copyWith(color: AppColors.warning),
          ),
          if (!data.isPremium) ...[
            const SizedBox(height: AppSpacing.spaceSM),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (ctx) => const PremiumUpsellDialog(
                    featureName: 'multiple badge requests',
                  ),
                ),
                child: const Text('Upgrade to Premium'),
              ),
            ),
          ],
        ] else
          ...available.map((t) {
          final busy = _submittingBadgeType == t.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.label, style: AppTypography.bodyTextMedium),
                      if (t.description != null && t.description!.isNotEmpty)
                        Text(
                          t.description!,
                          style: AppTypography.caption.copyWith(
                            color: context.appInkSubtle,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.spaceSM),
                FilledButton.tonal(
                  onPressed: busy ? null : () => _requestBadge(t),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Request'),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRequestHistory(
    MyCommunityBadges data,
    CommunityBadgeCatalog catalog,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Request history', style: AppTypography.label),
        const SizedBox(height: AppSpacing.spaceSM),
        ...data.requests.take(8).map((r) => _RequestTile(
              request: r,
              label: catalog.labelFor(r.badgeType),
            )),
      ],
    );
  }
}

class _RequestTile extends StatelessWidget {
  final CommunityBadgeRequest request;
  final String label;

  const _RequestTile({required this.request, required this.label});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (request.status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.warning,
    };
    final statusLabel = switch (request.status) {
      'approved' => 'Approved',
      'rejected' => 'Rejected',
      _ => 'Pending review',
    };
    final date = MaterialLocalizations.of(context)
        .formatShortDate(request.createdAt.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, size: 18, color: statusColor),
          const SizedBox(width: AppSpacing.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodyTextMedium),
                Text(
                  '$statusLabel · $date',
                  style: AppTypography.caption.copyWith(color: statusColor),
                ),
                ...formatBadgeRequestDetails(request.details).map(
                  (line) => Text(
                    line,
                    style: AppTypography.caption.copyWith(
                      color: context.appInkSubtle,
                    ),
                  ),
                ),
                if (request.message != null && request.message!.isNotEmpty)
                  Text(
                    'Note: ${request.message!}',
                    style: AppTypography.caption.copyWith(
                      color: context.appInkSubtle,
                    ),
                  ),
                if (request.adminNote != null &&
                    request.adminNote!.isNotEmpty &&
                    request.isRejected)
                  Text(
                    request.adminNote!,
                    style: AppTypography.caption.copyWith(
                      color: context.appInkSubtle,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRow({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
