import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/pregnancy_timeline.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/widgets.dart';

class PregnancyWeekStory extends ConsumerStatefulWidget {
  final int? profileWeek;

  const PregnancyWeekStory({super.key, this.profileWeek});

  @override
  ConsumerState<PregnancyWeekStory> createState() =>
      _PregnancyWeekStoryState();
}

class _PregnancyWeekStoryState extends ConsumerState<PregnancyWeekStory> {
  late int _viewWeek;

  @override
  void initState() {
    super.initState();
    _viewWeek = widget.profileWeek != null
        ? clampPregnancyWeek(widget.profileWeek!)
        : 20;
  }

  @override
  void didUpdateWidget(covariant PregnancyWeekStory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profileWeek != null &&
        widget.profileWeek != oldWidget.profileWeek) {
      _viewWeek = clampPregnancyWeek(widget.profileWeek!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(pregnancyTimelineProvider);

    return timelineAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.spaceLG),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (byWeek) {
        final currentWeek = widget.profileWeek != null
            ? clampPregnancyWeek(widget.profileWeek!)
            : null;
        final entry = getPregnancyWeekEntry(byWeek, _viewWeek);
        final isCurrent =
            currentWeek != null && _viewWeek == currentWeek;

        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _viewWeek <= pregnancyWeekMin
                        ? null
                        : () => setState(() => _viewWeek--),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Pregnancy journey',
                          style: AppTypography.caption.copyWith(
                            color: context.appInkMuted,
                          ),
                        ),
                        Text(
                          isCurrent
                              ? 'Week ${entry.week} · You are here'
                              : 'Week ${entry.week}',
                          style: AppTypography.headingSmall.copyWith(
                            color: context.appInk,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _viewWeek >= pregnancyWeekMax
                        ? null
                        : () => setState(() => _viewWeek++),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spaceSM),
              Wrap(
                spacing: AppSpacing.spaceXS,
                runSpacing: AppSpacing.spaceXS,
                children: [
                  AppBadge(
                    label: trimesterLabel(entry.trimester),
                    variant: AppBadgeVariant.secondary,
                  ),
                  AppBadge(
                    label: monthLabel(entry.gestationalMonth),
                    variant: AppBadgeVariant.secondary,
                  ),
                  AppBadge(
                    label:
                        'About the size of a ${entry.babySizeLabel.toLowerCase()}',
                    variant: AppBadgeVariant.secondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              Text(
                entry.headline,
                style: AppTypography.bodyTextMedium.copyWith(
                  color: context.appPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.radiusLarge),
                child: Container(
                  width: double.infinity,
                  color: context.appSurfaceMuted,
                  padding: const EdgeInsets.all(AppSpacing.spaceMD),
                  child: Image.asset(
                    pregnancyFoetusAssetPath(entry.gestationalMonth),
                    fit: BoxFit.contain,
                    height: 180,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              _StoryCard(title: 'You', body: entry.momNarrative),
              const SizedBox(height: AppSpacing.spaceSM),
              _StoryCard(title: 'Your baby', body: entry.babyNarrative),
              if (entry.gentleTip != null) ...[
                const SizedBox(height: AppSpacing.spaceMD),
                Text.rich(
                  TextSpan(
                    text: 'Tip: ',
                    style: AppTypography.bodyTextMedium.copyWith(
                      color: context.appInk,
                    ),
                    children: [
                      TextSpan(
                        text: entry.gentleTip,
                        style: AppTypography.bodyText.copyWith(
                          color: context.appInkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (!isCurrent && currentWeek != null) ...[
                const SizedBox(height: AppSpacing.spaceMD),
                AppButton(
                  label: 'Jump to your week ($currentWeek)',
                  variant: AppButtonVariant.outline,
                  onPressed: () => setState(() => _viewWeek = currentWeek),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StoryCard extends StatelessWidget {
  final String title;
  final String body;

  const _StoryCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      decoration: BoxDecoration(
        color: context.appSurfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        border: Border.all(
          color: context.appPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTypography.label.copyWith(
              color: context.appInkMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceXS),
          Text(
            body,
            style: AppTypography.bodyText.copyWith(color: context.appInk),
          ),
        ],
      ),
    );
  }
}
