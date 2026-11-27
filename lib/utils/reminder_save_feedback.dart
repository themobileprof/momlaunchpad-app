import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reminder.dart';
import '../providers/reminders_provider.dart';
import '../theme/colors.dart';
import 'device_calendar.dart';

/// After creating/updating a reminder: ensure OS notification permission and
/// show a snackbar with optional "Phone calendar" action.
Future<void> showReminderSavedFeedback(
  BuildContext context,
  WidgetRef ref,
  Reminder reminder, {
  String message = 'Saved — your phone will remind you',
}) async {
  final granted =
      await ref.read(remindersProvider.notifier).enableDeviceNotifications();

  if (!context.mounted) return;

  final text = granted
      ? message
      : 'Saved. Turn on notifications in Settings so we can nudge you.';

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Phone calendar',
        textColor: Colors.white,
        onPressed: () => addReminderToDeviceCalendar(reminder),
      ),
    ),
  );
}
