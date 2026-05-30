import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/symptom.dart';
import '../providers/symptom_provider.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/symptom_resolve.dart';
import '../screens/symptom_stats_screen.dart';
import 'app_button.dart';
import 'glass_container.dart';
import 'symptom_source_chat_link.dart';

/// Surfaces the most recent ongoing symptom and offers a quick resolve action.
class OngoingSymptomPrompt extends ConsumerStatefulWidget {
  const OngoingSymptomPrompt({super.key});

  @override
  ConsumerState<OngoingSymptomPrompt> createState() =>
      _OngoingSymptomPromptState();
}

class _OngoingSymptomPromptState extends ConsumerState<OngoingSymptomPrompt> {
  String? _dismissedSymptomId;
  bool _isResolving = false;

  @override
  Widget build(BuildContext context) {
    final recentAsync = ref.watch(recentSymptomsProvider(20));

    return recentAsync.when(
      data: (symptoms) {
        final ongoing = _firstOngoing(symptoms);
        if (ongoing == null || ongoing.id == _dismissedSymptomId) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.spaceMD,
            AppSpacing.spaceMD,
            AppSpacing.spaceMD,
            0,
          ),
          child: GlassContainer(
            opacity: 0.92,
            padding: const EdgeInsets.all(AppSpacing.spaceMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.health_and_safety_outlined,
                      color: AppColors.primaryPink,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.spaceSM),
                    Expanded(
                      child: Text(
                        'Ongoing symptom check-in',
                        style: AppTypography.bodyTextMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spaceSM),
                Text(
                  'Has your ${ongoing.symptomTypeName.toLowerCase()} improved?',
                  style: AppTypography.bodyText.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceXS),
                Text(
                  ongoing.displayText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyText.copyWith(
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                SymptomSourceChatLink(
                  symptom: ongoing,
                  padding: const EdgeInsets.only(top: AppSpacing.spaceXS),
                ),
                const SizedBox(height: AppSpacing.spaceXS),
                Text(
                  'Reported ${DateFormat('MMM d').format(ongoing.reportedAt)}',
                  style: AppTypography.caption.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: AppSpacing.spaceMD),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Yes, resolved',
                        icon: Icons.check_circle_outline,
                        isLoading: _isResolving,
                        size: AppButtonSize.small,
                        onPressed: _isResolving
                            ? null
                            : () => _resolve(context, ongoing),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSM),
                    Expanded(
                      child: AppButton(
                        label: 'Still ongoing',
                        variant: AppButtonVariant.outline,
                        size: AppButtonSize.small,
                        onPressed: _isResolving
                            ? null
                            : () => setState(() {
                                  _dismissedSymptomId = ongoing.id;
                                }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spaceXS),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SymptomStatsScreen(),
                        ),
                      );
                    },
                    child: const Text('View health tracker'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  Symptom? _firstOngoing(List<Symptom> symptoms) {
    for (final symptom in symptoms) {
      if (!symptom.isResolved) return symptom;
    }
    return null;
  }

  Future<void> _resolve(BuildContext context, Symptom symptom) async {
    setState(() => _isResolving = true);
    final resolved = await markSymptomResolved(context, ref, symptom.id);
    if (!mounted) return;
    setState(() => _isResolving = false);
    if (resolved) {
      setState(() => _dismissedSymptomId = symptom.id);
    }
  }
}
