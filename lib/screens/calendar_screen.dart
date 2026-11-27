import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../providers/reminders_provider.dart';
import '../providers/home_navigation_provider.dart';
import '../providers/profile_provider.dart';
import '../models/journey_stage.dart';
import '../models/reminder.dart';
import '../utils/journey_helpers.dart';
import '../utils/reminder_save_feedback.dart';
import '../widgets/pregnancy_week_story.dart';
import '../widgets/widgets.dart';
import 'doctor_visit_form_screen.dart';

/// Calendar/Reminders screen - Manage pregnancy-related reminders
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  String? _handledFocusReminderId;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    Future.microtask(() => ref.read(remindersProvider.notifier).fetchReminders());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = ref.read(homeNavigationProvider);
      if (pending != null) _applyNavigationFocus(pending);
    });
  }

  void _applyNavigationFocus(CalendarNavigationFocus focus) {
    if (_handledFocusReminderId == focus.reminder.id) return;
    _handledFocusReminderId = focus.reminder.id;

    final date = focus.reminder.scheduledTime.toLocal();
    setState(() {
      _focusedDay = date;
      _selectedDay = date;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showReminderDetailsSheet(focus.reminder);
      ref.read(homeNavigationProvider.notifier).clear();
    });
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
    final profile = ref.watch(profileProvider).profile;
    final isPregnant =
        JourneyHelpers.stageOf(profile) == JourneyStage.pregnant;

    ref.listen(homeNavigationProvider, (previous, next) {
      if (next != null) _applyNavigationFocus(next);
    });

    return Scaffold(
      backgroundColor: context.appCanvas,
      appBar: const MomAppBar(pageTitle: 'Calendar'),
      body: Column(
        children: [
          if (isPregnant)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spaceMD,
                AppSpacing.spaceMD,
                AppSpacing.spaceMD,
                0,
              ),
              child: PregnancyWeekStory(profileWeek: profile?.pregnancyWeek),
            ),
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
                      color: AppColors.blushPrimary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${remindersForSelectedDay.length} items',
                      style: AppTypography.caption.copyWith(
                          color: context.appInk, fontWeight: FontWeight.bold),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 72),
        child: Material(
          color: context.appSurface,
          elevation: 8,
          shadowColor: AppColors.shadowTintFor(context.appBrightness),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AppButton(
                    label: 'Schedule appointment',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DoctorVisitFormScreen(
                            mode: DoctorVisitFormMode.schedule,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () =>
                        _showReminderDialog(initialDate: _selectedDay),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: context.appPrimary,
                      side: BorderSide(
                        color: context.appPrimary.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Reminder'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(List<Reminder> allReminders) {
    final primary = context.appPrimary;
    final surface = context.appSurface;
    final ink = context.appInk;
    final inkMuted = context.appInkMuted;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.spaceMD),
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceMD),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowTintFor(context.appBrightness),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          TableCalendar<Reminder>(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            headerStyle: HeaderStyle(
              titleCentered: true,
              titleTextStyle: AppTypography.headingMedium.copyWith(color: ink),
              leftChevronIcon: Icon(Icons.chevron_left_rounded, color: ink),
              rightChevronIcon: Icon(Icons.chevron_right_rounded, color: ink),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: inkMuted),
              defaultTextStyle: TextStyle(color: ink, fontWeight: FontWeight.w500),
              selectedDecoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                color: context.appOnPrimary,
                fontWeight: FontWeight.w700,
              ),
              todayDecoration: BoxDecoration(
                color: primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: primary, width: 1.5),
              ),
              todayTextStyle: TextStyle(
                color: ink,
                fontWeight: FontWeight.w700,
              ),
              markerDecoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              markerSize: 6,
              markerMargin: const EdgeInsets.symmetric(horizontal: 1),
              cellMargin: const EdgeInsets.all(6),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) =>
                  _buildDayCell(day, allReminders, primary, ink, inkMuted),
              todayBuilder: (context, day, focusedDay) =>
                  _buildDayCell(day, allReminders, primary, ink, inkMuted, isToday: true),
              selectedBuilder: (context, day, focusedDay) =>
                  _buildDayCell(day, allReminders, primary, ink, inkMuted, isSelected: true),
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return const SizedBox.shrink();

                return Positioned(
                  bottom: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      events.length.clamp(1, 3),
                      (index) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isSameDay(_selectedDay, day)
                              ? context.appOnPrimary
                              : primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            eventLoader: (day) => _getRemindersForDay(day, allReminders),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spaceLG,
              0,
              AppSpacing.spaceLG,
              AppSpacing.spaceSM,
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.spaceSM),
                Text(
                  'Has appointment',
                  style: AppTypography.caption.copyWith(color: inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildDayCell(
    DateTime day,
    List<Reminder> allReminders,
    Color primary,
    Color ink,
    Color inkMuted, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final events = _getRemindersForDay(day, allReminders);
    if (events.isEmpty && !isToday && !isSelected) return null;

    final hasEvents = events.isNotEmpty;
    Color? background;
    Border? border;
    Color textColor = ink;

    if (isSelected) {
      background = primary;
      textColor = context.appOnPrimary;
    } else if (isToday) {
      background = primary.withValues(alpha: 0.18);
      border = Border.all(color: primary, width: 1.5);
    } else if (hasEvents) {
      background = primary.withValues(alpha: 0.1);
      border = Border.all(color: primary.withValues(alpha: 0.35));
    }

    if (background == null && border == null) return null;

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: border,
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: textColor,
          fontWeight: isSelected || isToday || hasEvents
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildReminderList(List<Reminder> reminders, RemindersState state) {
    if (state.isLoading) {
      return const LoadingState(message: 'Loading reminders...');
    }

    if (reminders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLG),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 56,
                color: context.appPrimary.withValues(alpha: 0.35),
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              Text(
                'Nothing on this day',
                style: AppTypography.headingMedium.copyWith(color: context.appInk),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.spaceSM),
              Text(
                'Schedule a clinic visit or add a gentle reminder — it only takes a moment.',
                style: AppTypography.bodyText.copyWith(color: context.appInkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.spaceLG),
              AppButton(
                label: 'Schedule appointment',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DoctorVisitFormScreen(
                        mode: DoctorVisitFormMode.schedule,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.spaceSM),
              TextButton(
                onPressed: () => _showReminderDialog(initialDate: _selectedDay),
                child: Text(
                  'Add reminder',
                  style: AppTypography.button.copyWith(color: context.appPrimary),
                ),
              ),
            ],
          ),
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
    final isPast = reminder.scheduledTime.isBefore(DateTime.now()) && !reminder.isToday;
    
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
                        color: context.appInkSubtle,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(reminder.scheduledTime),
                        style: AppTypography.caption.copyWith(
                          fontSize: 12,
                          color: context.appInkSubtle,
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
        return context.appAccent;
      default:
        return context.appInkSubtle;
    }
  }

  String _formatTime(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    final hour = localDateTime.hour.toString().padLeft(2, '0');
    final minute = localDateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
                           
    final selectedPriority = reminder?.priority ?? 'medium';
    final isEditing = reminder != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.spaceLG,
            AppSpacing.spaceMD,
            AppSpacing.spaceLG,
            MediaQuery.of(context).viewInsets.bottom + AppSpacing.spaceLG,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appInkSubtle.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.spaceLG),
              Text(
                isEditing ? 'Edit reminder' : 'Quick reminder',
                style: AppTypography.headingMedium.copyWith(color: context.appInk),
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              TextField(
                controller: titleController,
                autofocus: !isEditing,
                decoration: const InputDecoration(
                  labelText: 'What for?',
                  hintText: 'e.g. Take folic acid',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date == null || !context.mounted) return;
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
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'When',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year} ${_formatTime(selectedDate)}',
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.spaceLG),
              AppButton(
                label: isEditing ? 'Save reminder' : 'Save reminder',
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) return;
                  try {
                    Reminder? saved;
                    if (isEditing) {
                      await ref.read(remindersProvider.notifier).updateReminder(
                            id: reminder.id,
                            title: titleController.text,
                            description: descriptionController.text,
                            scheduledTime: selectedDate,
                            priority: selectedPriority,
                          );
                      saved = ref
                          .read(remindersProvider)
                          .reminders
                          .where((r) => r.id == reminder.id)
                          .firstOrNull;
                    } else {
                      saved = await ref
                          .read(remindersProvider.notifier)
                          .addReminder(
                            title: titleController.text,
                            description: descriptionController.text,
                            scheduledTime: selectedDate,
                            priority: selectedPriority,
                          );
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    if (saved != null) {
                      await showReminderSavedFeedback(context, ref, saved);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save: $e')),
                      );
                    }
                  }
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: AppTypography.button.copyWith(color: context.appPrimary),
                ),
              ),
            ],
          ),
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
                  Icon(Icons.schedule_rounded, color: context.appPrimary),
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
                      _showReminderDialog(reminder: reminder);
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
