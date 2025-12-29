import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../providers/reminders_provider.dart';

/// Calendar/Reminders screen
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch reminders on load
    Future.microtask(() => ref.read(remindersProvider.notifier).fetchReminders());
  }

  @override
  Widget build(BuildContext context) {
    final remindersState = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar', style: AppTypography.headingMedium),
      ),
      body: remindersState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : remindersState.reminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(height: AppSpacing.spaceMD),
                      Text(
                        'No reminders yet',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppSpacing.spaceSM),
                      Text(
                        'Chat with me to get suggestions',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textLight.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.spaceMD),
                  children: [
                    if (remindersState.todayReminders.isNotEmpty) ...[
                      Text('Today', style: AppTypography.headingMedium),
                      const SizedBox(height: AppSpacing.spaceSM),
                      ...remindersState.todayReminders
                          .map((r) => _buildReminderCard(r.title, r.description ?? '')),
                      const SizedBox(height: AppSpacing.spaceLG),
                    ],
                    if (remindersState.upcomingReminders.isNotEmpty) ...[
                      Text('Upcoming', style: AppTypography.headingMedium),
                      const SizedBox(height: AppSpacing.spaceSM),
                      ...remindersState.upcomingReminders
                          .map((r) => _buildReminderCard(r.title, r.description ?? '')),
                    ],
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add reminder dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add reminder coming soon!')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildReminderCard(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.spaceMD),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spaceMD),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryPink,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600)),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.spaceXS),
                    Text(description, style: AppTypography.caption),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
