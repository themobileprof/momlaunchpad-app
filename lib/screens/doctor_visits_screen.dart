import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/doctor_visit.dart';
import '../providers/doctor_visits_provider.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/widgets.dart';
import '../utils/visit_check_in_logic.dart';
import 'doctor_visit_form_screen.dart';

/// List of doctor / prenatal visit records (micro EMR).
class DoctorVisitsScreen extends ConsumerStatefulWidget {
  const DoctorVisitsScreen({super.key});

  @override
  ConsumerState<DoctorVisitsScreen> createState() => _DoctorVisitsScreenState();
}

class _DoctorVisitsScreenState extends ConsumerState<DoctorVisitsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(doctorVisitsProvider.notifier).fetchVisits());
  }

  Future<void> _openForm({
    DoctorVisit? visit,
    DoctorVisitFormMode? mode,
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
    if (saved == true && mounted) {
      ref.read(doctorVisitsProvider.notifier).fetchVisits();
    }
  }

  Future<void> _chooseNewVisit() async {
    final choice = await showModalBottomSheet<DoctorVisitFormMode>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('Schedule visit'),
              subtitle: const Text('For an appointment that is coming up'),
              onTap: () => Navigator.pop(context, DoctorVisitFormMode.schedule),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Log past visit'),
              subtitle: const Text('For a visit that already happened'),
              onTap: () => Navigator.pop(context, DoctorVisitFormMode.past),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    await _openForm(mode: choice);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorVisitsProvider);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: context.appCanvas,
      appBar: const MomAppBar(pageTitle: 'Doctor visits'),
      body: _buildBody(state, dateFormat),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: NeumorphicButton(
          filled: true,
          borderRadius: 30,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          onPressed: _chooseNewVisit,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded),
              SizedBox(width: 8),
              Text('Add visit'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(DoctorVisitsState state, DateFormat dateFormat) {
    if (state.isLoading && state.visits.isEmpty) {
      return const LoadingState(message: 'Loading visit records...');
    }

    if (state.error != null && state.visits.isEmpty) {
      return ErrorState(
        description: state.error!,
        onRetry: () => ref.read(doctorVisitsProvider.notifier).fetchVisits(),
      );
    }

    if (state.visits.isEmpty) {
      return EmptyState(
        icon: Icons.medical_information_outlined,
        title: 'No visits yet',
        description:
            'Schedule an upcoming appointment, or log one you already had.',
        actionLabel: 'Schedule visit',
        onAction: () => _openForm(mode: DoctorVisitFormMode.schedule),
      );
    }

    final now = DateTime.now();
    final upcoming = state.visits
        .where(
          (v) =>
              isScheduledVisit(v, now) ||
              (v.nextAppointmentAt != null &&
                  v.nextAppointmentAt!.toLocal().isAfter(now)),
        )
        .toList();
    final needsUpdate =
        state.visits.where((v) => visitNeedsUpdate(v, now)).toList();
    final past = state.visits
        .where((v) => !isScheduledVisit(v, now) && !visitNeedsUpdate(v, now))
        .toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(doctorVisitsProvider.notifier).fetchVisits(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spaceMD,
          AppSpacing.spaceSM,
          AppSpacing.spaceMD,
          120,
        ),
        children: [
          if (upcoming.isNotEmpty) ...[
            Text('Upcoming', style: AppTypography.bodyTextMedium),
            const SizedBox(height: AppSpacing.spaceSM),
            ...upcoming.map(
              (visit) => _VisitCard(
                visit: visit,
                dateFormat: dateFormat,
                onTap: () => _showVisitDetails(visit),
              ),
            ),
            const SizedBox(height: AppSpacing.spaceMD),
          ],
          if (needsUpdate.isNotEmpty) ...[
            Text('Needs an update', style: AppTypography.bodyTextMedium),
            const SizedBox(height: AppSpacing.spaceSM),
            ...needsUpdate.map(
              (visit) => _VisitCard(
                visit: visit,
                dateFormat: dateFormat,
                badge: 'Update',
                onTap: () => _openForm(
                  visit: visit,
                  mode: DoctorVisitFormMode.update,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spaceMD),
          ],
          if (past.isNotEmpty) ...[
            Text('Past visits', style: AppTypography.bodyTextMedium),
            const SizedBox(height: AppSpacing.spaceSM),
            ...past.map(
              (visit) => _VisitCard(
                visit: visit,
                dateFormat: dateFormat,
                onTap: () => _showVisitDetails(visit),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showVisitDetails(DoctorVisit visit) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VisitDetailSheet(
        visit: visit,
        onEdit: () {
          Navigator.pop(context);
          final mode = visitNeedsUpdate(visit, DateTime.now())
              ? DoctorVisitFormMode.update
              : isScheduledVisit(visit)
                  ? DoctorVisitFormMode.schedule
                  : DoctorVisitFormMode.past;
          _openForm(visit: visit, mode: mode);
        },
        onDelete: () => _confirmDelete(visit),
      ),
    );
  }

  Future<void> _confirmDelete(DoctorVisit visit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete visit record?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Delete',
            variant: AppButtonVariant.danger,
            isFullWidth: false,
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(doctorVisitsProvider.notifier).deleteVisit(visit.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit record deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}

class _VisitCard extends StatelessWidget {
  final DoctorVisit visit;
  final DateFormat dateFormat;
  final VoidCallback onTap;
  final String? badge;

  const _VisitCard({
    required this.visit,
    required this.dateFormat,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  visit.visitTypeLabel,
                  style: AppTypography.bodyTextMedium,
                ),
              ),
              if (badge != null)
                AppBadge(
                  label: badge!,
                  variant: AppBadgeVariant.primary,
                )
              else if (visit.isProviderRecorded)
                const AppBadge(
                  label: 'Clinician',
                  variant: AppBadgeVariant.secondary,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceXS),
          Text(
            dateFormat.format(visit.visitDate.toLocal()),
            style: AppTypography.caption.copyWith(color: context.appInkSubtle),
          ),
          if (visit.providerName != null && visit.providerName!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.spaceXS),
            Text(
              visit.providerName!,
              style: AppTypography.caption,
            ),
          ],
          if (visit.diagnosis != null && visit.diagnosis!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.spaceSM),
            Text(
              visit.diagnosis!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyText,
            ),
          ],
          if (visit.hasUpcomingAppointment) ...[
            const SizedBox(height: AppSpacing.spaceSM),
            AppBadge(
              label:
                  'Next: ${dateFormat.format(visit.nextAppointmentAt!.toLocal())}',
              icon: Icons.event_available_outlined,
              variant: AppBadgeVariant.primary,
            ),
          ],
        ],
      ),
    );
  }
}

class _VisitDetailSheet extends StatelessWidget {
  final DoctorVisit visit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VisitDetailSheet({
    required this.visit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.appCanvas,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spaceMD,
              AppSpacing.spaceSM,
              AppSpacing.spaceMD,
              AppSpacing.spaceXL,
            ),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.spaceMD),
                  decoration: BoxDecoration(
                    color: context.appPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(visit.visitTypeLabel, style: AppTypography.headingLarge),
              const SizedBox(height: AppSpacing.spaceXS),
              Text(
                dateFormat.format(visit.visitDate.toLocal()),
                style: AppTypography.caption.copyWith(color: context.appInkSubtle),
              ),
              const SizedBox(height: AppSpacing.spaceLG),
              _DetailSection(
                title: 'Provider',
                lines: [
                  if (visit.providerName != null && visit.providerName!.isNotEmpty)
                    visit.providerName!,
                  if (visit.facilityName != null && visit.facilityName!.isNotEmpty)
                    visit.facilityName!,
                ],
              ),
              _DetailSection(
                title: 'Chief complaint',
                lines: [visit.chiefComplaint ?? '—'],
              ),
              _DetailSection(
                title: 'Vitals',
                lines: [
                  if (visit.bloodPressureDisplay != null)
                    'Blood pressure: ${visit.bloodPressureDisplay} mmHg',
                  if (visit.weightKg != null) 'Weight: ${visit.weightKg} kg',
                  if (visit.heartRateBpm != null)
                    'Heart rate: ${visit.heartRateBpm} bpm',
                  if (visit.temperatureCelsius != null)
                    'Temperature: ${visit.temperatureCelsius} °C',
                  if (visit.fundalHeightCm != null)
                    'Fundal height: ${visit.fundalHeightCm} cm',
                  if (visit.fetalHeartRateBpm != null)
                    'Fetal heart rate: ${visit.fetalHeartRateBpm} bpm',
                  if (visit.gestationalAgeWeeks != null)
                    'Gestational age: ${visit.gestationalAgeWeeks} weeks',
                ],
              ),
              _DetailSection(
                title: 'Observations',
                lines: [visit.clinicalNotes ?? '—'],
              ),
              _DetailSection(
                title: 'Diagnosis & plan',
                lines: [
                  if (visit.diagnosis != null && visit.diagnosis!.isNotEmpty)
                    'Diagnosis: ${visit.diagnosis}',
                  if (visit.treatmentPlan != null &&
                      visit.treatmentPlan!.isNotEmpty)
                    'Treatment: ${visit.treatmentPlan}',
                  if (visit.followUpInstructions != null &&
                      visit.followUpInstructions!.isNotEmpty)
                    'Follow-up: ${visit.followUpInstructions}',
                ],
              ),
              if (visit.medications.isNotEmpty)
                _DetailSection(
                  title: 'Medications',
                  lines: visit.medications
                      .map(
                        (m) =>
                            '${m.name} — ${m.dosage}, ${m.frequency}${m.instructions != null && m.instructions!.isNotEmpty ? ' (${m.instructions})' : ''}',
                      )
                      .toList(),
                ),
              if (visit.labResults.isNotEmpty)
                _DetailSection(
                  title: 'Lab results',
                  lines: visit.labResults
                      .map(
                        (l) =>
                            '${l.testName}: ${l.result}${l.unit != null && l.unit!.isNotEmpty ? ' ${l.unit}' : ''}',
                      )
                      .toList(),
                ),
              _DetailSection(
                title: 'Next appointment',
                lines: [
                  if (visit.nextAppointmentAt != null)
                    dateFormat.format(visit.nextAppointmentAt!.toLocal()),
                  if (visit.nextAppointmentNotes != null &&
                      visit.nextAppointmentNotes!.isNotEmpty)
                    visit.nextAppointmentNotes!,
                  if (visit.nextAppointmentAt == null &&
                      (visit.nextAppointmentNotes == null ||
                          visit.nextAppointmentNotes!.isEmpty))
                    '—',
                ],
              ),
              const SizedBox(height: AppSpacing.spaceLG),
              AppButton(label: 'Edit', onPressed: onEdit),
              const SizedBox(height: AppSpacing.spaceSM),
              AppButton(
                label: 'Delete',
                variant: AppButtonVariant.danger,
                onPressed: onDelete,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _DetailSection({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    final visible = lines.where((line) => line != '—').toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.bodyTextMedium),
          const SizedBox(height: AppSpacing.spaceXS),
          ...visible.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line, style: AppTypography.bodyText),
            ),
          ),
        ],
      ),
    );
  }
}
