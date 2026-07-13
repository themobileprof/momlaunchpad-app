import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reminder.dart';

/// Request to focus a reminder on the Calendar tab from elsewhere in the app.
class CalendarNavigationFocus {
  final Reminder reminder;

  const CalendarNavigationFocus(this.reminder);
}

class HomeNavigationNotifier extends Notifier<CalendarNavigationFocus?> {
  @override
  CalendarNavigationFocus? build() => null;

  void focusReminder(Reminder reminder) {
    state = CalendarNavigationFocus(reminder);
  }

  void clear() {
    state = null;
  }
}

final homeNavigationProvider =
    NotifierProvider<HomeNavigationNotifier, CalendarNavigationFocus?>(
  HomeNavigationNotifier.new,
);

/// Tab indices in [HomeScreen] — Home, Calendar, Chat, Community.
const homeTabIndex = 0;
const calendarTabIndex = 1;
const chatTabIndex = 2;
const communityTabIndex = 3;

/// Switches the home shell to a primary tab (e.g. from dashboard quick links).
class HomeTabRequestNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void openTab(int index) => state = index;

  void clear() => state = null;
}

final homeTabRequestProvider =
    NotifierProvider<HomeTabRequestNotifier, int?>(HomeTabRequestNotifier.new);
