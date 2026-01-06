import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../providers/reminders_provider.dart';
import '../widgets/widgets.dart';
import '../models/reminder.dart';

/// Calendar/Reminders screen - Manage pregnancy-related reminders
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(remindersProvider.notifier).fetchReminders());
  }

  @override
  Widget build(BuildContext context) {
    final remindersState = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar', style: AppTypography.headingMedium),
        actions: [
          if (remindersState.reminders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: () => _showFilterBottomSheet(),
              tooltip: 'Filter reminders',
            ),
        ],
      ),
      body: _buildBody(remindersState),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Reminder'),
        backgroundColor: AppColors.primaryPink,
        foregroundColor: AppColors.white,
      ),
    );
  }

  Widget _buildBody(RemindersState state) {
    if (state.isLoading) {
      return const LoadingState(message: 'Loading reminders...');
    }

    if (state.error != null) {
      return ErrorState(
        title: 'Failed to load reminders',
        description: state.error,
        onRetry: () => ref.read(remindersProvider.notifier).fetchReminders(),
      );
    }

    if (state.reminders.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'No reminders yet',
        description: 'Chat with me to get personalized\nreminder suggestions for your pregnancy',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(remindersProvider.notifier).fetchReminders(),
      color: AppColors.primaryPink,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.spaceMD),
        children: [
          // Today's reminders
          if (state.todayReminders.isNotEmpty) ...[
            _buildSectionHeader(
              'Today',
              count: state.todayReminders.length,
              color: AppColors.primaryPink,
            ),
            ...state.todayReminders.map(_buildReminderCard),
            const SizedBox(height: AppSpacing.spaceLG),
          ],

          // Upcoming reminders
          if (state.upcomingReminders.isNotEmpty) ...[
            _buildSectionHeader(
              'Upcoming',
              count: state.upcomingReminders.length,
              color: AppColors.primaryPurple,
            ),
            ...state.upcomingReminders.map(_buildReminderCard),
          ],

          // Past reminders (if any)
          if (state.pastReminders.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.spaceLG),
            _buildSectionHeader(
              'Past',
              count: state.pastReminders.length,
              color: AppColors.textLight,
            ),
            ...state.pastReminders.map((r) => _buildReminderCard(r, isPast: true)),
          ],

          // Bottom padding for FAB
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {int? count, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color ?? AppColors.primaryPink,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.spaceSM),
          Text(title, style: AppTypography.headingMedium),
          if (count != null) ...[
            const SizedBox(width: AppSpacing.spaceSM),
            AppBadge(
              label: count.toString(),
              variant: AppBadgeVariant.secondary,
              small: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder, {bool isPast = false}) {
    return Opacity(
      opacity: isPast ? 0.6 : 1.0,
      child: AppCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.spaceMD),
        onTap: () => _showReminderDetailsSheet(reminder),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority indicator
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: _getPriorityColor(reminder.priority),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.spaceMD),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reminder.title,
                          style: AppTypography.bodyText.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: isPast ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (!isPast)
                        _buildPriorityBadge(reminder.priority),
                    ],
                  ),
                  if (reminder.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      reminder.description!,
                      style: AppTypography.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(reminder.scheduledTime),
                        style: AppTypography.caption.copyWith(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textLight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditReminderDialog(reminder);
                } else if (value == 'delete') {
                  _confirmDeleteReminder(reminder);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    AppBadgeVariant variant;
    switch (priority.toLowerCase()) {
      case 'urgent':
        variant = AppBadgeVariant.error;
        break;
      case 'high':
        variant = AppBadgeVariant.warning;
        break;
      case 'medium':
        variant = AppBadgeVariant.primary;
        break;
      default:
        variant = AppBadgeVariant.secondary;
    }
    return AppBadge(
      label: priority.toUpperCase(),
      variant: variant,
      small: true,
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      case 'medium':
        return AppColors.primaryPink;
      default:
        return AppColors.textLight;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = dateTime.difference(now);
    
    if (diff.inDays == 0) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return 'Today at $hour:$minute';
    } else if (diff.inDays == 1) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return 'Tomorrow at $hour:$minute';
    } else if (diff.inDays == -1) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showAddReminderDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add reminder feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryPurple,
      ),
    );
  }

  void _showEditReminderDialog(Reminder reminder) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit reminder feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryPurple,
      ),
    );
  }

  void _showReminderDetailsSheet(Reminder reminder) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spaceLG),
            
            // Title and priority
            Row(
              children: [
                Expanded(
                  child: Text(reminder.title, style: AppTypography.headingLarge),
                ),
                _buildPriorityBadge(reminder.priority),
              ],
            ),
            
            const SizedBox(height: AppSpacing.spaceMD),
            
            // Description
            if (reminder.description?.isNotEmpty == true) ...[
              Text(reminder.description!, style: AppTypography.bodyText),
              const SizedBox(height: AppSpacing.spaceMD),
            ],
            
            // Time
            AppCard(
              variant: AppCardVariant.flat,
              backgroundColor: AppColors.backgroundLight,
              padding: const EdgeInsets.all(AppSpacing.spaceMD),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.primaryPurple),
                  const SizedBox(width: AppSpacing.spaceMD),
                  Text(
                    _formatDateTime(reminder.scheduledTime),
                    style: AppTypography.bodyText.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.spaceLG),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Edit',
                    variant: AppButtonVariant.outline,
                    icon: Icons.edit_rounded,
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditReminderDialog(reminder);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.spaceMD),
                Expanded(
                  child: AppButton(
                    label: 'Delete',
                    variant: AppButtonVariant.danger,
                    icon: Icons.delete_rounded,
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDeleteReminder(reminder);
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.spaceMD),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteReminder(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusLarge),
        ),
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Delete',
            variant: AppButtonVariant.danger,
            isFullWidth: false,
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(remindersProvider.notifier).deleteReminder(reminder.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder deleted'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete reminder: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showFilterBottomSheet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filter feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryPurple,
      ),
    );
  }
}
