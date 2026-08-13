import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reminder.dart';
import '../services/api_service.dart';
import '../services/google_calendar_sync_service.dart';
import 'google_calendar_sync_provider.dart';
import 'service_providers.dart';

/// Reminders state
class RemindersState {
  final List<Reminder> reminders;
  final bool isLoading;
  final String? error;

  RemindersState({
    this.reminders = const [],
    this.isLoading = false,
    this.error,
  });

  RemindersState copyWith({
    List<Reminder>? reminders,
    bool? isLoading,
    String? error,
  }) {
    return RemindersState(
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get reminders for today
  List<Reminder> get todayReminders {
    return reminders.where((r) => r.isToday).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  /// Get upcoming reminders (future dates, excluding today)
  List<Reminder> get upcomingReminders {
    final now = DateTime.now();
    return reminders
        .where((r) =>
            r.scheduledTime.isAfter(now) && !r.isToday && !r.isCompleted)
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  /// Get overdue reminders
  List<Reminder> get overdueReminders {
    return reminders.where((r) => r.isOverdue).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  /// Get past reminders (completed or past date)
  List<Reminder> get pastReminders {
    final now = DateTime.now();
    return reminders
        .where((r) => r.scheduledTime.isBefore(now) && !r.isToday)
        .toList()
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
  }
}

/// Reminders provider (Notifier)
class RemindersNotifier extends Notifier<RemindersState> {
  late final ApiService _apiService;

  @override
  RemindersState build() {
    _apiService = ref.read(apiServiceProvider);
    return RemindersState();
  }

  bool get _googleSyncEnabled => ref.read(googleCalendarSyncProvider).enabled;

  GoogleCalendarSyncService get _googleSync =>
      ref.read(googleCalendarSyncServiceProvider);

  void _replaceReminder(Reminder reminder) {
    final updated = state.reminders
        .map((r) => r.id == reminder.id ? reminder : r)
        .toList();
    state = state.copyWith(reminders: updated);
  }

  /// Fetch all reminders from backend
  Future<void> fetchReminders() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final reminders = await _apiService.getReminders();
      state = RemindersState(reminders: reminders, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load reminders',
      );
    }
  }

  /// Push existing reminders that are not yet linked to Google Calendar.
  Future<void> syncAllToGoogleCalendar() async {
    if (!_googleSyncEnabled) return;

    for (final reminder in state.reminders) {
      if (reminder.isCompleted) continue;
      if (reminder.googleCalendarEventId != null &&
          reminder.googleCalendarEventId!.isNotEmpty) {
        continue;
      }
      try {
        final linked = await _linkReminderToGoogle(reminder);
        _replaceReminder(linked);
      } catch (e) {
        debugPrint('Google Calendar backfill failed for ${reminder.id}: $e');
      }
    }
  }

  Future<Reminder> _linkReminderToGoogle(Reminder reminder) async {
    final eventId = await _googleSync.createEvent(reminder);
    return _apiService.updateReminder(
      id: reminder.id,
      googleCalendarEventId: eventId,
    );
  }

  Future<Reminder> _syncReminderChange(Reminder reminder) async {
    if (!_googleSyncEnabled) return reminder;

    try {
      final eventId = reminder.googleCalendarEventId;
      if (reminder.isCompleted) {
        if (eventId != null && eventId.isNotEmpty) {
          await _googleSync.deleteEvent(eventId);
          return await _apiService.updateReminder(
            id: reminder.id,
            googleCalendarEventId: '',
          );
        }
        return reminder;
      }

      if (eventId != null && eventId.isNotEmpty) {
        await _googleSync.updateEvent(reminder);
        return reminder;
      }

      return await _linkReminderToGoogle(reminder);
    } on GoogleCalendarSyncException catch (e) {
      debugPrint('Google Calendar sync failed: $e');
      return reminder;
    } catch (e) {
      debugPrint('Google Calendar sync failed: $e');
      return reminder;
    }
  }

  /// Add new reminder
  Future<Reminder> addReminder({
    required String title,
    String? description,
    required DateTime scheduledTime,
    required String priority,
  }) async {
    try {
      var reminder = await _apiService.createReminder(
        title: title,
        description: description,
        scheduledTime: scheduledTime,
        priority: priority,
      );

      reminder = await _syncReminderChange(reminder);

      state = state.copyWith(
        reminders: [...state.reminders, reminder],
      );
      return reminder;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  /// Update reminder
  Future<void> updateReminder({
    required String id,
    String? title,
    String? description,
    DateTime? scheduledTime,
    String? priority,
    bool? isCompleted,
  }) async {
    try {
      var reminder = await _apiService.updateReminder(
        id: id,
        title: title,
        description: description,
        scheduledTime: scheduledTime,
        priority: priority,
        isCompleted: isCompleted,
      );

      reminder = await _syncReminderChange(reminder);
      _replaceReminder(reminder);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  /// Delete reminder
  Future<void> deleteReminder(String id) async {
    try {
      final reminder = state.reminders.firstWhere((r) => r.id == id);
      if (_googleSyncEnabled &&
          reminder.googleCalendarEventId != null &&
          reminder.googleCalendarEventId!.isNotEmpty) {
        try {
          await _googleSync.deleteEvent(reminder.googleCalendarEventId!);
        } catch (e) {
          debugPrint('Google Calendar delete failed: $e');
        }
      }

      await _apiService.deleteReminder(id);

      final updatedReminders =
          state.reminders.where((r) => r.id != id).toList();

      state = state.copyWith(reminders: updatedReminders);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  /// Toggle reminder completion
  Future<void> toggleCompletion(String id) async {
    final reminder = state.reminders.firstWhere((r) => r.id == id);
    await updateReminder(id: id, isCompleted: !reminder.isCompleted);
  }
}

/// Reminders provider instance
final remindersProvider =
    NotifierProvider<RemindersNotifier, RemindersState>(RemindersNotifier.new);

/// Convenience provider for today's reminders
final todayRemindersProvider = Provider<List<Reminder>>((ref) {
  return ref.watch(remindersProvider).todayReminders;
});

/// Convenience provider for upcoming reminders
final upcomingRemindersProvider = Provider<List<Reminder>>((ref) {
  return ref.watch(remindersProvider).upcomingReminders;
});

/// Convenience provider for overdue reminders
final overdueRemindersProvider = Provider<List<Reminder>>((ref) {
  return ref.watch(remindersProvider).overdueReminders;
});
