import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';

/// Schedules OS-level local notifications for in-app reminders/appointments.
class ReminderNotificationService {
  ReminderNotificationService();

  static const _channelId = 'momlaunchpad_reminders';
  static const _channelName = 'Appointments & reminders';
  static const _channelDescription =
      'Nudge you for clinic visits, vitamins, and saved reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> initialize({
    void Function(NotificationResponse response)? onTap,
  }) async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('Timezone init fallback: $e');
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Lagos'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: onTap,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  /// Android 13+ / iOS: request notification (+ exact alarm on Android) permission.
  Future<bool> requestPermission() async {
    if (!_initialized) await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidPlugin?.requestNotificationsPermission() ?? false;
      await androidPlugin?.requestExactAlarmsPermission();
      return granted;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  Future<bool> hasPermission() async {
    if (!_initialized) await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final options = await ios?.checkPermissions();
      return options?.isEnabled ?? false;
    }

    return true;
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (!_initialized) await initialize();
    if (reminder.isCompleted) {
      await cancelReminder(reminder.id);
      return;
    }

    final when = reminder.scheduledTime.toLocal();
    if (!when.isAfter(DateTime.now())) {
      await cancelReminder(reminder.id);
      return;
    }

    final id = notificationIdFor(reminder.id);
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    final body = (reminder.description?.trim().isNotEmpty == true)
        ? reminder.description!.trim()
        : 'Tap to open your calendar';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      styleInformation: BigTextStyleInformation(body),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    final payload = jsonEncode({
      'reminder_id': reminder.id,
      'type': 'reminder',
    });

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: reminder.title,
        body: body,
        scheduledDate: tzWhen,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Exact schedule failed, retrying inexact: $e');
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: reminder.title,
          body: body,
          scheduledDate: tzWhen,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      } catch (e2) {
        debugPrint('Failed to schedule reminder notification: $e2');
      }
    }
  }

  Future<void> cancelReminder(String reminderId) async {
    if (!_initialized) await initialize();
    await _plugin.cancel(id: notificationIdFor(reminderId));
  }

  /// Reconcile OS schedules with the current reminder list (call after fetch).
  Future<void> rescheduleAll(List<Reminder> reminders) async {
    if (!_initialized) await initialize();
    await _plugin.cancelAll();
    for (final reminder in reminders) {
      if (reminder.isCompleted) continue;
      if (!reminder.scheduledTime.toLocal().isAfter(DateTime.now())) continue;
      await scheduleReminder(reminder);
    }
  }

  /// Stable int id from UUID — Android/iOS notification ids are ints.
  static int notificationIdFor(String reminderId) {
    var hash = 0;
    for (final unit in reminderId.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
