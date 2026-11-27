import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart';

import '../models/reminder.dart';

/// Opens the device calendar insert UI for a reminder (native calendar apps).
Future<bool> addReminderToDeviceCalendar(Reminder reminder) async {
  final start = reminder.scheduledTime.toLocal();
  final end = start.add(const Duration(hours: 1));
  final event = Event(
    title: reminder.title,
    description: reminder.description,
    startDate: start,
    endDate: end,
    iosParams: const IOSParams(reminder: Duration(minutes: 30)),
  );

  try {
    return await Add2Calendar.addEvent2Cal(event);
  } catch (e) {
    debugPrint('Device calendar insert failed: $e');
    return false;
  }
}
