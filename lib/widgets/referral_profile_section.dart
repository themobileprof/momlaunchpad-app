import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/referral.dart';
import '../models/user_profile.dart';
import '../providers/service_providers.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_card.dart';

/// Profile section: referral code, share link, stats, and reward history.
class ReferralProfileSection extends ConsumerStatefulWidget {
  final UserProfile profile;

  const ReferralProfileSection({super.key, required this.profile});

  @override
  ConsumerState<ReferralProfileSection> createState() =>
      _ReferralProfileSectionState();
}

class _ReferralProfileSectionState extends ConsumerState<ReferralProfileSection> {
  List<ReferralRewardRecord>? _rewards;
  bool _loadingRewards = false;

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    setState(() => _loadingRewards = true);
    try {
      final rewards =
          await ref.read(apiServiceProvider).getMyReferralRewards();
      if (mounted) setState(() => _rewards = rewards);
    } catch (_) {
      if (mounted) setState(() => _rewards = const []);
    } finally {
      if (mounted) setState(() => _loadingRewards = false);
    }
  }

  Future<void> _copy(BuildContext context, String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final code = profile.referralCode;
    final link = profile.referralLink;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invite friends', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.spaceXS),
          Text(
            'Share your link. When someone signs up with your code, you earn '
            'reward points. An admin clears points when you receive your monthly reward.',
            style: AppTypography.caption.copyWith(
              color: context.appInkSubtle,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          _StatRow(
            label: 'People referred',
            value: '${profile.totalReferrals}',
          ),
          const SizedBox(height: AppSpacing.spaceSM),
          _StatRow(
            label: 'Pending reward points',
            value: '${profile.referralRewardPoints}',
            highlight: profile.referralRewardPoints > 0,
          ),
          if (code.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.spaceMD),
            Text('Your code', style: AppTypography.label),
            const SizedBox(height: AppSpacing.spaceXS),
            _CopyRow(
              value: code,
              onCopy: () => _copy(context, 'Referral code', code),
            ),
          ],
          if (link.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.spaceMD),
            Text('Your link', style: AppTypography.label),
            const SizedBox(height: AppSpacing.spaceXS),
            _CopyRow(
              value: link,
              onCopy: () => _copy(context, 'Referral link', link),
            ),
          ],
          const SizedBox(height: AppSpacing.spaceMD),
          Text('Reward history', style: AppTypography.label),
          const SizedBox(height: AppSpacing.spaceSM),
          if (_loadingRewards)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.spaceSM),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_rewards == null || _rewards!.isEmpty)
            Text(
              'No rewards recorded yet.',
              style: AppTypography.caption.copyWith(
                color: context.appInkSubtle,
              ),
            )
          else
            ..._rewards!.take(5).map(_rewardTile),
        ],
      ),
    );
  }

  Widget _rewardTile(ReferralRewardRecord r) {
    final date = MaterialLocalizations.of(context)
        .formatShortDate(r.createdAt.toLocal());
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.card_giftcard_outlined,
              size: 18, color: context.appPrimary),
          const SizedBox(width: AppSpacing.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.rewardDescription,
                  style: AppTypography.bodyTextMedium,
                ),
                Text(
                  '${r.referralsCount} referral${r.referralsCount == 1 ? '' : 's'} · $date',
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

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyTextMedium),
        Text(
          value,
          style: AppTypography.headingSmall.copyWith(
            color: highlight ? context.appPrimary : null,
          ),
        ),
      ],
    );
  }
}

class _CopyRow extends StatelessWidget {
  final String value;
  final VoidCallback onCopy;

  const _CopyRow({required this.value, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyTextMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: 'Copy',
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded),
        ),
      ],
    );
  }
}
