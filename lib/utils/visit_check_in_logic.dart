import '../models/doctor_visit.dart';
import '../models/reminder.dart';

enum VisitCheckInKind {
  upcomingAppointment,
  recentDebrief,
  monthlyLog,
}

class VisitCheckInContext {
  final VisitCheckInKind kind;
  final DoctorVisit? visit;
  final DateTime? appointmentAt;
  /// True when the upcoming slot is the visit's own scheduled date.
  final bool isScheduledVisit;

  const VisitCheckInContext({
    required this.kind,
    this.visit,
    this.appointmentAt,
    this.isScheduledVisit = false,
  });

  String dismissalKey(DateTime now) {
    switch (kind) {
      case VisitCheckInKind.upcomingAppointment:
        final visitId = visit!.id;
        final appt = appointmentAt!;
        return 'upcoming_${visitId}_${appt.toUtc().millisecondsSinceEpoch}';
      case VisitCheckInKind.recentDebrief:
        return 'debrief_${visit!.id}';
      case VisitCheckInKind.monthlyLog:
        return 'monthly_${now.year}_${now.month}';
    }
  }
}

const visitUpcomingWindowDays = 14;
const visitDebriefWindowDays = 14;
const visitMonthlyPromptDays = 30;

/// Picks the highest-priority home visit check-in prompt, if any.
VisitCheckInContext? resolveVisitCheckIn({
  required List<DoctorVisit> visits,
  required List<Reminder> reminders,
  required Set<String> dismissedKeys,
  DateTime? monthlyDismissedAt,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();

  final upcoming = _nearestUpcomingAppointment(visits, clock);
  if (upcoming != null) {
    final visit = upcoming.visit;
    final appt = upcoming.appointmentAt;
    final withinWindow =
        appt.difference(clock).inDays <= visitUpcomingWindowDays;
    if (withinWindow) {
      final context = VisitCheckInContext(
        kind: VisitCheckInKind.upcomingAppointment,
        visit: visit,
        appointmentAt: appt,
        isScheduledVisit: upcoming.isScheduledVisit,
      );
      if (!dismissedKeys.contains(context.dismissalKey(clock)) &&
          !hasMatchingAppointmentReminder(reminders, appt)) {
        return context;
      }
    }
  }

  for (final visit in visits) {
    if (!visitNeedsUpdate(visit, clock)) continue;
    final context = VisitCheckInContext(
      kind: VisitCheckInKind.recentDebrief,
      visit: visit,
    );
    if (!dismissedKeys.contains(context.dismissalKey(clock))) {
      return context;
    }
  }

  final monthlyAllowed = monthlyDismissedAt == null ||
      clock.difference(monthlyDismissedAt).inDays >= visitMonthlyPromptDays;
  if (monthlyAllowed) {
    final context = VisitCheckInContext(kind: VisitCheckInKind.monthlyLog);
    if (!dismissedKeys.contains(context.dismissalKey(clock))) {
      return context;
    }
  }

  return null;
}

({DoctorVisit visit, DateTime appointmentAt, bool isScheduledVisit})?
    _nearestUpcomingAppointment(
  List<DoctorVisit> visits,
  DateTime now,
) {
  DoctorVisit? bestVisit;
  DateTime? bestAppt;
  var bestIsScheduled = false;

  for (final visit in visits) {
    final visitDate = visit.visitDate.toLocal();
    if (visitDate.isAfter(now)) {
      if (bestAppt == null || visitDate.isBefore(bestAppt)) {
        bestAppt = visitDate;
        bestVisit = visit;
        bestIsScheduled = true;
      }
    }

    final appt = visit.nextAppointmentAt?.toLocal();
    if (appt != null && appt.isAfter(now)) {
      if (bestAppt == null || appt.isBefore(bestAppt)) {
        bestAppt = appt;
        bestVisit = visit;
        bestIsScheduled = false;
      }
    }
  }

  if (bestVisit == null || bestAppt == null) return null;
  return (
    visit: bestVisit,
    appointmentAt: bestAppt,
    isScheduledVisit: bestIsScheduled,
  );
}

/// Past visit that still needs a simple after-visit update.
bool visitNeedsUpdate(DoctorVisit visit, DateTime clock) {
  if (visit.debriefCompletedAt != null) return false;
  final visitDate = visit.visitDate.toLocal();
  if (visitDate.isAfter(clock)) return false;
  final daysSince = clock.difference(visitDate).inDays;
  return daysSince >= 0 && daysSince <= visitDebriefWindowDays;
}

bool isScheduledVisit(DoctorVisit visit, [DateTime? now]) {
  final clock = now ?? DateTime.now();
  return visit.visitDate.toLocal().isAfter(clock) &&
      visit.debriefCompletedAt == null;
}

bool hasMatchingAppointmentReminder(List<Reminder> reminders, DateTime appt) {
  for (final reminder in reminders) {
    if (reminder.isCompleted) continue;

    final sameDay = reminder.scheduledTime.year == appt.year &&
        reminder.scheduledTime.month == appt.month &&
        reminder.scheduledTime.day == appt.day;
    if (!sameDay) continue;

    final title = reminder.title.toLowerCase();
    if (title.contains('appointment') ||
        title.contains('doctor') ||
        title.contains('visit')) {
      return true;
    }

    if (reminder.scheduledTime.difference(appt).inHours.abs() <= 2) {
      return true;
    }
  }
  return false;
}

String appointmentReminderTitle(DoctorVisit visit) {
  final label = visit.visitTypeLabel;
  if (visit.providerName != null && visit.providerName!.trim().isNotEmpty) {
    return '$label with ${visit.providerName!.trim()}';
  }
  return '$label appointment';
}

String appointmentReminderDescription(DoctorVisit visit) {
  final parts = <String>[];
  if (visit.facilityName != null && visit.facilityName!.trim().isNotEmpty) {
    parts.add(visit.facilityName!.trim());
  }
  if (visit.nextAppointmentNotes != null &&
      visit.nextAppointmentNotes!.trim().isNotEmpty) {
    parts.add(visit.nextAppointmentNotes!.trim());
  }
  return parts.join(' · ');
}
