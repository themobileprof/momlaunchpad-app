import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reminder.dart';
import '../services/api_service.dart';
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

  /// Get upcoming reminders (next 7 days)
  List<Reminder> get upcomingReminders {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return reminders
        .where((r) => 
            r.scheduledTime.isAfter(now) && 
            r.scheduledTime.isBefore(weekFromNow) &&
            !r.isCompleted
        )
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  /// Get overdue reminders
  List<Reminder> get overdueReminders {
    return reminders.where((r) => r.isOverdue).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
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

  /// Create new reminder
  Future<void> createReminder({
    required String title,
    String? description,
    required DateTime scheduledTime,
    required String priority,
  }) async {
    try {
      final reminder = await _apiService.createReminder(
        title: title,
        description: description,
        scheduledTime: scheduledTime,
        priority: priority,
      );
      
      state = state.copyWith(
        reminders: [...state.reminders, reminder],
      );
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
      await _apiService.updateReminder(
        id: id,
        title: title,
        description: description,
        scheduledTime: scheduledTime,
        priority: priority,
        isCompleted: isCompleted,
      );
      
      // Update local state
      final updatedReminders = state.reminders.map((r) {
        if (r.id == id) {
          return r.copyWith(
            title: title,
            description: description,
            scheduledTime: scheduledTime,
            priority: priority,
            isCompleted: isCompleted,
          );
        }
        return r;
      }).toList();
      
      state = state.copyWith(reminders: updatedReminders);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  /// Delete reminder
  Future<void> deleteReminder(String id) async {
    try {
      await _apiService.deleteReminder(id);
      
      final updatedReminders = state.reminders
          .where((r) => r.id != id)
          .toList();
      
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
final remindersProvider = NotifierProvider<RemindersNotifier, RemindersState>(RemindersNotifier.new);

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
