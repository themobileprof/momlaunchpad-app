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

  Future<void> _openForm({DoctorVisit? visit}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorVisitFormScreen(existingVisit: visit),
      ),
    );
    if (saved == true && mounted) {
      ref.read(doctorVisitsProvider.notifier).fetchVisits();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorVisitsProvider);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: context.appCanvas,
      appBar: const MomAppBar(pageTitle: 'Visit records'),
      body: _buildBody(state, dateFormat),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: NeumorphicButton(
          filled: true,
          borderRadius: 30,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          onPressed: () => _openForm(),
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
        title: 'No visit records yet',
        description:
            'Log prenatal checkups, ultrasounds, medications, vitals, and follow-up appointments.',
        actionLabel: 'Add visit',
        onAction: () => _openForm(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(doctorVisitsProvider.notifier).fetchVisits(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spaceMD,
          AppSpacing.spaceSM,
          AppSpacing.spaceMD,
          120,
        ),
        itemCount: state.visits.length,
        itemBuilder: (context, index) {
          final visit = state.visits[index];
          return _VisitCard(
            visit: visit,
            dateFormat: dateFormat,
            onTap: () => _showVisitDetails(visit),
          );
        },
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
          _openForm(visit: visit);
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

  const _VisitCard({
    required this.visit,
    required this.dateFormat,
    required this.onTap,
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
              if (visit.isProviderRecorded)
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
