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

/// Home card for upcoming appointments, post-visit debrief, or monthly visit logging.
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

  Future<void> _openDebriefSheet(DoctorVisit visit) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _VisitDebriefSheet(visit: visit),
    );
    if (mounted) {
      await ref.read(doctorVisitsProvider.notifier).fetchVisits();
      setState(() {});
    }
  }

  Future<void> _openNewVisitForm() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const DoctorVisitFormScreen()),
    );
    if (mounted) {
      await ref.read(doctorVisitsProvider.notifier).fetchVisits();
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
          busy: _busy,
          onAddReminder: () => _addAppointmentReminder(data),
          onDismiss: () => _dismiss(data),
        );
      case VisitCheckInKind.recentDebrief:
        return _RecentDebriefCard(
          visit: data.visit!,
          onDebrief: () => _openDebriefSheet(data.visit!),
          onDismiss: () => _dismiss(data),
        );
      case VisitCheckInKind.monthlyLog:
        return _MonthlyLogCard(
          onLogVisit: _openNewVisitForm,
          onDismiss: () => _dismiss(data),
        );
    }
  }
}

class _UpcomingAppointmentCard extends StatelessWidget {
  final DoctorVisit visit;
  final DateTime appointmentAt;
  final bool busy;
  final VoidCallback onAddReminder;
  final VoidCallback onDismiss;

  const _UpcomingAppointmentCard({
    required this.visit,
    required this.appointmentAt,
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
          title: 'Upcoming appointment',
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

class _RecentDebriefCard extends StatelessWidget {
  final DoctorVisit visit;
  final VoidCallback onDebrief;
  final VoidCallback onDismiss;

  const _RecentDebriefCard({
    required this.visit,
    required this.onDebrief,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat.yMMMd().format(visit.visitDate.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardHeader(
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
          'Log any tests still to do. We can add reminders if you want.',
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
                label: 'Log follow-up',
                onPressed: onDebrief,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MonthlyLogCard extends StatelessWidget {
  final VoidCallback onLogVisit;
  final VoidCallback onDismiss;

  const _MonthlyLogCard({
    required this.onLogVisit,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardHeader(
          icon: Icons.local_hospital_outlined,
          title: 'Doctor visit check-in',
        ),
        const SizedBox(height: AppSpacing.spaceSM),
        Text(
          'Any appointment coming up, or a visit you had recently?',
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
                label: 'Log visit',
                onPressed: onLogVisit,
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

class _VisitDebriefSheet extends ConsumerStatefulWidget {
  final DoctorVisit visit;

  const _VisitDebriefSheet({required this.visit});

  @override
  ConsumerState<_VisitDebriefSheet> createState() => _VisitDebriefSheetState();
}

class _PendingTestEntry {
  final TextEditingController nameController = TextEditingController();
  DateTime? dueBy;
  bool remind = true;

  void dispose() => nameController.dispose();
}

class _VisitDebriefSheetState extends ConsumerState<_VisitDebriefSheet> {
  final List<_PendingTestEntry> _tests = [_PendingTestEntry()];
  final TextEditingController _medicationController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    for (final entry in _tests) {
      entry.dispose();
    }
    _medicationController.dispose();
    super.dispose();
  }

  void _addTestRow() {
    setState(() => _tests.add(_PendingTestEntry()));
  }

  void _removeTestRow(int index) {
    if (_tests.length <= 1) {
      _tests.first.nameController.clear();
      setState(() {
        _tests.first.dueBy = null;
        _tests.first.remind = true;
      });
      return;
    }
    _tests[index].dispose();
    setState(() => _tests.removeAt(index));
  }

  Future<void> _pickDueDate(_PendingTestEntry entry) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: entry.dueBy ?? DateTime.now().add(const Duration(days: 7)),
    );
    if (date == null || !mounted) return;
    setState(() => entry.dueBy = date);
  }

  List<VisitPendingTest> _buildPendingTests() {
    final out = <VisitPendingTest>[];
    for (final row in _tests) {
      final name = row.nameController.text.trim();
      if (name.isEmpty) continue;
      out.add(VisitPendingTest(
        testName: name,
        dueBy: row.dueBy,
        status: 'pending',
      ));
    }
    return out;
  }

  List<VisitMedication> _buildMedications() {
    final name = _medicationController.text.trim();
    if (name.isEmpty) return const [];
    return [
      VisitMedication(
        name: name,
        dosage: '',
        frequency: 'As prescribed',
      ),
    ];
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final pendingTests = _buildPendingTests();
      final medications = _buildMedications();

      await ref.read(doctorVisitsProvider.notifier).debriefVisit(
            id: widget.visit.id,
            payload: VisitDebriefPayload(
              pendingTests: pendingTests,
              medications: medications,
              markCompleted: true,
            ),
          );

      for (final row in _tests) {
        final name = row.nameController.text.trim();
        if (name.isEmpty || !row.remind) continue;

        final due = row.dueBy ??
            DateTime.now().add(const Duration(days: 7));
        await ref.read(remindersProvider.notifier).addReminder(
              title: 'Test: $name',
              description: 'Follow-up from ${widget.visit.visitTypeLabel}',
              scheduledTime: DateTime(due.year, due.month, due.day, 9),
              priority: 'medium',
            );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit follow-up saved')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.spaceMD,
        AppSpacing.spaceMD,
        AppSpacing.spaceMD,
        AppSpacing.spaceMD + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Visit follow-up',
              style: AppTypography.headingSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Tests still to do (optional). Reminders are optional too.',
              style: AppTypography.caption.copyWith(color: context.appInkSubtle),
            ),
            const SizedBox(height: AppSpacing.spaceMD),
            for (var i = 0; i < _tests.length; i++) ...[
              TextField(
                controller: _tests[i].nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Test or scan ${i + 1}',
                  hintText: 'e.g. Glucose tolerance test',
                ),
              ),
              const SizedBox(height: AppSpacing.spaceXS),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDueDate(_tests[i]),
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                        _tests[i].dueBy == null
                            ? 'Due date (optional)'
                            : DateFormat.yMMMd().format(_tests[i].dueBy!.toLocal()),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: () => _removeTestRow(i),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Remind me'),
                value: _tests[i].remind,
                onChanged: (value) => setState(() => _tests[i].remind = value),
              ),
              const SizedBox(height: AppSpacing.spaceSM),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addTestRow,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add another test'),
              ),
            ),
            const Divider(height: AppSpacing.spaceXL),
            TextField(
              controller: _medicationController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Medication prescribed (optional)',
                hintText: 'Name only — for your records',
              ),
            ),
            const SizedBox(height: AppSpacing.spaceLG),
            AppButton(
              label: 'Save',
              isLoading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
