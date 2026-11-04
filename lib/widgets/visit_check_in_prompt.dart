import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/doctor_visit.dart';
import '../providers/doctor_visits_provider.dart';
import '../providers/reminders_provider.dart';
import '../screens/doctor_visit_form_screen.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/visit_check_in_dismissals.dart';
import '../utils/visit_check_in_logic.dart';
import 'app_button.dart';
import 'glass_container.dart';

/// Home card for upcoming appointments, post-visit updates, or monthly visit logging.
class VisitCheckInPrompt extends ConsumerStatefulWidget {
  const VisitCheckInPrompt({super.key});

  @override
  ConsumerState<VisitCheckInPrompt> createState() => _VisitCheckInPromptState();
}

class _VisitCheckInPromptState extends ConsumerState<VisitCheckInPrompt> {
  Set<String> _dismissedKeys = {};
  DateTime? _monthlyDismissedAt;
  bool _prefsLoaded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadDismissals();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(doctorVisitsProvider.notifier).fetchVisits();
      ref.read(remindersProvider.notifier).fetchReminders();
    });
  }

  Future<void> _loadDismissals() async {
    final keys = await VisitCheckInDismissals.loadDismissedKeys();
    final monthly = await VisitCheckInDismissals.loadMonthlyDismissedAt();
    if (!mounted) return;
    setState(() {
      _dismissedKeys = keys;
      _monthlyDismissedAt = monthly;
      _prefsLoaded = true;
    });
  }

  Future<void> _dismiss(VisitCheckInContext checkIn) async {
    final key = checkIn.dismissalKey(DateTime.now());
    await VisitCheckInDismissals.dismiss(key);
    if (checkIn.kind == VisitCheckInKind.monthlyLog) {
      await VisitCheckInDismissals.dismissMonthly();
    }
    if (!mounted) return;
    setState(() {
      _dismissedKeys = {..._dismissedKeys, key};
      if (checkIn.kind == VisitCheckInKind.monthlyLog) {
        _monthlyDismissedAt = DateTime.now();
      }
    });
  }

  Future<void> _addAppointmentReminder(VisitCheckInContext checkIn) async {
    final visit = checkIn.visit!;
    final appt = checkIn.appointmentAt!;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(remindersProvider.notifier).addReminder(
            title: appointmentReminderTitle(visit),
            description: appointmentReminderDescription(visit).isEmpty
                ? null
                : appointmentReminderDescription(visit),
            scheduledTime: appt,
            priority: 'medium',
          );
      if (!mounted) return;
      await _dismiss(checkIn);
      messenger.showSnackBar(
        const SnackBar(content: Text('Appointment added to your calendar')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openForm({
    DoctorVisit? visit,
    required DoctorVisitFormMode mode,
    VisitCheckInContext? dismissMonthly,
  }) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorVisitFormScreen(
          existingVisit: visit,
          mode: mode,
        ),
      ),
    );
    if (!mounted) return;
    await ref.read(doctorVisitsProvider.notifier).fetchVisits();
    // Monthly prompt only — schedule/past saves clear other prompts via visit state.
    if (saved == true && dismissMonthly != null) {
      await _dismiss(dismissMonthly);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) return const SizedBox.shrink();

    final visitsState = ref.watch(doctorVisitsProvider);
    final remindersState = ref.watch(remindersProvider);
    final contextData = resolveVisitCheckIn(
      visits: visitsState.visits,
      reminders: remindersState.reminders,
      dismissedKeys: _dismissedKeys,
      monthlyDismissedAt: _monthlyDismissedAt,
    );

    if (contextData == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spaceMD,
        AppSpacing.spaceMD,
        AppSpacing.spaceMD,
        0,
      ),
      child: GlassContainer(
        opacity: 0.92,
        padding: const EdgeInsets.all(AppSpacing.spaceMD),
        child: _buildCard(context, contextData),
      ),
    );
  }

  Widget _buildCard(BuildContext context, VisitCheckInContext data) {
    switch (data.kind) {
      case VisitCheckInKind.upcomingAppointment:
        return _UpcomingAppointmentCard(
          visit: data.visit!,
          appointmentAt: data.appointmentAt!,
          isScheduledVisit: data.isScheduledVisit,
          busy: _busy,
          onAddReminder: () => _addAppointmentReminder(data),
          onDismiss: () => _dismiss(data),
        );
      case VisitCheckInKind.recentDebrief:
        return _RecentUpdateCard(
          visit: data.visit!,
          onUpdate: () => _openForm(
            visit: data.visit,
            mode: DoctorVisitFormMode.update,
          ),
          onDismiss: () => _dismiss(data),
        );
      case VisitCheckInKind.monthlyLog:
        return _MonthlyLogCard(
          onSchedule: () => _openForm(
            mode: DoctorVisitFormMode.schedule,
            dismissMonthly: data,
          ),
          onLogPast: () => _openForm(
            mode: DoctorVisitFormMode.past,
            dismissMonthly: data,
          ),
          onDismiss: () => _dismiss(data),
        );
    }
  }
}

class _UpcomingAppointmentCard extends StatelessWidget {
  final DoctorVisit visit;
  final DateTime appointmentAt;
  final bool isScheduledVisit;
  final bool busy;
  final VoidCallback onAddReminder;
  final VoidCallback onDismiss;

  const _UpcomingAppointmentCard({
    required this.visit,
    required this.appointmentAt,
    required this.isScheduledVisit,
    required this.busy,
    required this.onAddReminder,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat.yMMMd().add_jm().format(appointmentAt.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardHeader(
          icon: Icons.event_outlined,
          title: isScheduledVisit ? 'Scheduled visit' : 'Upcoming appointment',
        ),
        const SizedBox(height: AppSpacing.spaceSM),
        Text(
          '${visit.visitTypeLabel} · $formatted',
          style: AppTypography.bodyText.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (visit.providerName != null && visit.providerName!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            visit.providerName!,
            style: AppTypography.caption.copyWith(color: context.appInkSubtle),
          ),
        ],
        const SizedBox(height: AppSpacing.spaceMD),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Not now',
                variant: AppButtonVariant.secondary,
                onPressed: busy ? null : onDismiss,
              ),
            ),
            const SizedBox(width: AppSpacing.spaceSM),
            Expanded(
              child: AppButton(
                label: 'Add to calendar',
                isLoading: busy,
                onPressed: busy ? null : onAddReminder,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecentUpdateCard extends StatelessWidget {
  final DoctorVisit visit;
  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  const _RecentUpdateCard({
    required this.visit,
    required this.onUpdate,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat.yMMMd().format(visit.visitDate.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CardHeader(
          icon: Icons.medical_information_outlined,
          title: 'After your visit',
        ),
        const SizedBox(height: AppSpacing.spaceSM),
        Text(
          'How did your ${visit.visitTypeLabel.toLowerCase()} on $formatted go?',
          style: AppTypography.bodyText.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'A short update is enough — add more details only if you want.',
          style: AppTypography.caption.copyWith(color: context.appInkSubtle),
        ),
        const SizedBox(height: AppSpacing.spaceMD),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Not now',
                variant: AppButtonVariant.secondary,
                onPressed: onDismiss,
              ),
            ),
            const SizedBox(width: AppSpacing.spaceSM),
            Expanded(
              child: AppButton(
                label: 'Give update',
                onPressed: onUpdate,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MonthlyLogCard extends StatelessWidget {
  final VoidCallback onSchedule;
  final VoidCallback onLogPast;
  final VoidCallback onDismiss;

  const _MonthlyLogCard({
    required this.onSchedule,
    required this.onLogPast,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CardHeader(
          icon: Icons.local_hospital_outlined,
          title: 'Doctor visit check-in',
        ),
        const SizedBox(height: AppSpacing.spaceSM),
        Text(
          'Anything coming up, or a visit you already had?',
          style: AppTypography.bodyText.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.spaceMD),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Not now',
                variant: AppButtonVariant.secondary,
                onPressed: onDismiss,
              ),
            ),
            const SizedBox(width: AppSpacing.spaceSM),
            Expanded(
              child: AppButton(
                label: 'Schedule',
                variant: AppButtonVariant.secondary,
                onPressed: onSchedule,
              ),
            ),
            const SizedBox(width: AppSpacing.spaceSM),
            Expanded(
              child: AppButton(
                label: 'Log past',
                onPressed: onLogPast,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _CardHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: context.appAccent, size: 22),
        const SizedBox(width: AppSpacing.spaceSM),
        Expanded(
          child: Text(title, style: AppTypography.bodyTextMedium),
        ),
      ],
    );
  }
}
