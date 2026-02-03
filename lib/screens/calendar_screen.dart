import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
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
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    Future.microtask(() => ref.read(remindersProvider.notifier).fetchReminders());
  }

  List<Reminder> _getRemindersForDay(DateTime day, List<Reminder> allReminders) {
    return allReminders.where((reminder) {
      final scheduled = reminder.scheduledTime.toLocal();
      return scheduled.year == day.year &&
          scheduled.month == day.month &&
          scheduled.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final remindersState = ref.watch(remindersProvider);
    final remindersForSelectedDay = _getRemindersForDay(_selectedDay, remindersState.reminders);

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: Text('Calendar', style: AppTypography.headingLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildCalendar(remindersState.reminders),
          const SizedBox(height: AppSpacing.spaceMD),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLG),
            child: Row(
              children: [
                Text(
                  '${_selectedDay.day}/${_selectedDay.month}',
                  style: AppTypography.headingMedium,
                ),
                const Spacer(),
                if (remindersForSelectedDay.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.blushPrimary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${remindersForSelectedDay.length} items',
                      style: AppTypography.caption.copyWith(
                          color: AppColors.textDark, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSM),
          Expanded(
            child: _buildReminderList(remindersForSelectedDay, remindersState),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Raise above floating navbar
        child: NeumorphicButton(
          borderRadius: 30,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: AppColors.blushPrimary,
          onPressed: () => _showAddReminderDialog(initialDate: _selectedDay),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: AppColors.textDark),
              SizedBox(width: 8),
              Text(
                'Add Reminder',
                style: AppTypography.button.copyWith(color: AppColors.textDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(List<Reminder> allReminders) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.spaceMD),
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceMD),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TableCalendar<Reminder>(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        headerStyle: HeaderStyle(
          titleCentered: true,
          titleTextStyle: AppTypography.headingMedium,
          leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppColors.textDark),
          rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppColors.textDark),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: AppColors.textMedium),
          defaultTextStyle: TextStyle(color: AppColors.textDark),
          selectedDecoration: const BoxDecoration(
            color: AppColors.blushPrimary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.blushPrimary.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.lavenderSecondary,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
        ),
        eventLoader: (day) => _getRemindersForDay(day, allReminders),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildReminderList(List<Reminder> reminders, RemindersState state) {
    if (state.isLoading) {
      return const LoadingState(message: 'Loading reminders...');
    }

    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No reminders for this day',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        top: AppSpacing.spaceMD,
        left: AppSpacing.spaceMD,
        right: AppSpacing.spaceMD,
        bottom: 120, // Space for floating navbar + FAB
      ),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return _buildReminderCard(reminder);
      },
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    bool isPast = reminder.scheduledTime.isBefore(DateTime.now()) && !reminder.isToday;
    
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
                        _formatTime(reminder.scheduledTime),
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

  String _formatTime(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    final hour = localDateTime.hour.toString().padLeft(2, '0');
    final minute = localDateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showAddReminderDialog({DateTime? initialDate}) {
    _showReminderDialog(initialDate: initialDate);
  }

  void _showEditReminderDialog(Reminder reminder) {
    _showReminderDialog(reminder: reminder);
  }

  void _showReminderDialog({Reminder? reminder, DateTime? initialDate}) {
    final titleController = TextEditingController(text: reminder?.title);
    final descriptionController = TextEditingController(text: reminder?.description);
    
    // Use initialDate (from selected calendar day) or reminder date or now + 1 hour
    DateTime selectedDate = reminder?.scheduledTime.toLocal() ?? 
                           initialDate ?? 
                           DateTime.now().add(const Duration(hours: 1));
                           
    // If using initialDate (which is usually midnight), set default time to now's hour + 1
    if (reminder == null && initialDate != null) {
      final now = DateTime.now();
      selectedDate = DateTime(
        initialDate.year,
        initialDate.month,
        initialDate.day,
        now.hour + 1,
        0,
      );
    }
                           
    String selectedPriority = reminder?.priority ?? 'medium';
    
    final isEditing = reminder != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Reminder' : 'Add Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Doctor Appointment',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.spaceMD),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.spaceMD),
                
                // Date & Time Picker
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (time != null) {
                        setState(() {
                          selectedDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year} ${_formatTime(selectedDate)}'),
                        const Icon(Icons.calendar_today, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceMD),

                // Priority Dropdown
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => selectedPriority = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;

                try {
                  if (isEditing) {
                    await ref.read(remindersProvider.notifier).updateReminder(
                      id: reminder.id,
                      title: titleController.text,
                      description: descriptionController.text,
                      scheduledTime: selectedDate,
                      priority: selectedPriority,
                    );
                  } else {
                    await ref.read(remindersProvider.notifier).addReminder(
                      title: titleController.text,
                      description: descriptionController.text,
                      scheduledTime: selectedDate,
                      priority: selectedPriority,
                    );
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
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
                    '${reminder.scheduledTime.day}/${reminder.scheduledTime.month}/${reminder.scheduledTime.year} • ${_formatTime(reminder.scheduledTime)}',
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
}
