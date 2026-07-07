import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_notification.dart';
import '../services/api_service.dart';
import 'service_providers.dart';

/// State for the "Rewards & updates" inbox.
class NotificationsState {
  final List<UserNotification> items;
  final bool isLoading;
  final String? error;
  final int unread;

  const NotificationsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.unread = 0,
  });

  NotificationsState copyWith({
    List<UserNotification>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? unread,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      unread: unread ?? this.unread,
    );
  }
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  late final ApiService _api;

  @override
  NotificationsState build() {
    _api = ref.read(apiServiceProvider);
    return const NotificationsState();
  }

  /// Loads the full list and recomputes the unread count from it.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _api.getNotifications();
      state = state.copyWith(
        items: items,
        unread: items.where((n) => n.isUnread).length,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  /// Lightweight unread refresh for the badge (best-effort, never throws).
  Future<void> refreshUnread() async {
    try {
      final count = await _api.getUnreadNotificationCount();
      state = state.copyWith(unread: count);
    } catch (_) {
      // badge is best-effort
    }
  }

  Future<void> markRead(String id) async {
    final updated = [
      for (final n in state.items)
        n.id == id && n.isUnread ? n.copyWith(readAt: DateTime.now()) : n,
    ];
    state = state.copyWith(
      items: updated,
      unread: updated.where((n) => n.isUnread).length,
    );
    try {
      await _api.markNotificationRead(id);
    } catch (_) {
      // optimistic; ignore transient failure
    }
  }

  Future<void> markAllRead() async {
    final now = DateTime.now();
    final updated = [
      for (final n in state.items) n.isUnread ? n.copyWith(readAt: now) : n,
    ];
    state = state.copyWith(items: updated, unread: 0);
    try {
      await _api.markAllNotificationsRead();
    } catch (_) {
      // optimistic; ignore transient failure
    }
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);
