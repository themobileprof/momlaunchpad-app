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

enum DoctorVisitFormMode {
  /// Future appointment — essentials only.
  schedule,
  /// After the visit date — short update, optional details.
  update,
  /// Logging a visit that already happened.
  past,
}

/// Full-screen form for scheduling, updating, or logging a visit.
class DoctorVisitFormScreen extends ConsumerStatefulWidget {
  final DoctorVisit? existingVisit;
  final DoctorVisitFormMode? mode;

  const DoctorVisitFormScreen({
    super.key,
    this.existingVisit,
    this.mode,
  });

  @override
  ConsumerState<DoctorVisitFormScreen> createState() =>
      _DoctorVisitFormScreenState();
}

class _DoctorVisitFormScreenState extends ConsumerState<DoctorVisitFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late DoctorVisitFormMode _mode;
  late DateTime _visitDate;
  late String _visitType;
  DateTime? _nextAppointment;
  bool _showMoreDetails = false;

  final _providerController = TextEditingController();
  final _facilityController = TextEditingController();
  final _complaintController = TextEditingController();
  final _notesController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _followUpController = TextEditingController();
  final _nextApptNotesController = TextEditingController();
  final _bpSysController = TextEditingController();
  final _bpDiaController = TextEditingController();
  final _weightController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _tempController = TextEditingController();
  final _fundalController = TextEditingController();
  final _fhrController = TextEditingController();
  final _gaWeeksController = TextEditingController();
  final _pendingTestController = TextEditingController();

  final List<_MedicationEntry> _medications = [];
  final List<_LabEntry> _labResults = [];
  bool _isSaving = false;

  bool get _isEditing => widget.existingVisit != null;

  DoctorVisitFormMode _resolveMode() {
    if (widget.mode != null) return widget.mode!;
    final visit = widget.existingVisit;
    if (visit == null) return DoctorVisitFormMode.past;
    final now = DateTime.now();
    if (visit.visitDate.toLocal().isAfter(now) &&
        visit.debriefCompletedAt == null) {
      return DoctorVisitFormMode.schedule;
    }
    if (visit.debriefCompletedAt == null) return DoctorVisitFormMode.update;
    return DoctorVisitFormMode.past;
  }

  String get _title {
    switch (_mode) {
      case DoctorVisitFormMode.schedule:
        return _isEditing ? 'Edit scheduled visit' : 'Schedule visit';
      case DoctorVisitFormMode.update:
        return 'How did your visit go?';
      case DoctorVisitFormMode.past:
        return _isEditing ? 'Edit visit' : 'Log past visit';
    }
  }

  String get _saveLabel {
    switch (_mode) {
      case DoctorVisitFormMode.schedule:
        return 'Save appointment';
      case DoctorVisitFormMode.update:
        return 'Save update';
      case DoctorVisitFormMode.past:
        return 'Save visit';
    }
  }

  @override
  void initState() {
    super.initState();
    _mode = _resolveMode();
    final visit = widget.existingVisit;
    if (visit != null) {
      _visitDate = visit.visitDate.toLocal();
      _visitType = visit.visitType;
      _nextAppointment = visit.nextAppointmentAt?.toLocal();
    } else if (_mode == DoctorVisitFormMode.schedule) {
      final d = DateTime.now().add(const Duration(days: 7));
      _visitDate = DateTime(d.year, d.month, d.day, 9);
      _visitType = doctorVisitTypes.first;
    } else {
      _visitDate = DateTime.now();
      _visitType = doctorVisitTypes.first;
    }

    _providerController.text = visit?.providerName ?? '';
    _facilityController.text = visit?.facilityName ?? '';
    _complaintController.text = visit?.chiefComplaint ?? '';
    _notesController.text = visit?.clinicalNotes ?? '';
    _diagnosisController.text = visit?.diagnosis ?? '';
    _treatmentController.text = visit?.treatmentPlan ?? '';
    _followUpController.text = visit?.followUpInstructions ?? '';
    _nextApptNotesController.text = visit?.nextAppointmentNotes ?? '';
    _bpSysController.text = visit?.bloodPressureSystolic?.toString() ?? '';
    _bpDiaController.text = visit?.bloodPressureDiastolic?.toString() ?? '';
    _weightController.text = visit?.weightKg?.toString() ?? '';
    _heartRateController.text = visit?.heartRateBpm?.toString() ?? '';
    _tempController.text = visit?.temperatureCelsius?.toString() ?? '';
    _fundalController.text = visit?.fundalHeightCm?.toString() ?? '';
    _fhrController.text = visit?.fetalHeartRateBpm?.toString() ?? '';
    _gaWeeksController.text = visit?.gestationalAgeWeeks?.toString() ?? '';

    for (final med in visit?.medications ?? const <VisitMedication>[]) {
      _medications.add(_MedicationEntry.fromMedication(med));
    }
    for (final lab in visit?.labResults ?? const <VisitLabResult>[]) {
      _labResults.add(_LabEntry.fromLabResult(lab));
    }
    final pending = visit?.pendingTests
        .where((t) => t.status != 'completed')
        .map((t) => t.testName)
        .where((n) => n.isNotEmpty);
    if (pending != null && pending.isNotEmpty) {
      _pendingTestController.text = pending.first;
    }

    if (_mode != DoctorVisitFormMode.schedule &&
        (_diagnosisController.text.isNotEmpty ||
            _treatmentController.text.isNotEmpty ||
            _medications.isNotEmpty ||
            _labResults.isNotEmpty ||
            _pendingTestController.text.isNotEmpty ||
            _complaintController.text.isNotEmpty ||
            _bpSysController.text.isNotEmpty)) {
      _showMoreDetails = true;
    }
  }

  @override
  void dispose() {
    _providerController.dispose();
    _facilityController.dispose();
    _complaintController.dispose();
    _notesController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _followUpController.dispose();
    _nextApptNotesController.dispose();
    _bpSysController.dispose();
    _bpDiaController.dispose();
    _weightController.dispose();
    _heartRateController.dispose();
    _tempController.dispose();
    _fundalController.dispose();
    _fhrController.dispose();
    _gaWeeksController.dispose();
    _pendingTestController.dispose();
    for (final entry in _medications) {
      entry.dispose();
    }
    for (final entry in _labResults) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _pickVisitDateTime() async {
    final now = DateTime.now();
    final first = _mode == DoctorVisitFormMode.schedule
        ? DateTime(now.year, now.month, now.day)
        : DateTime(2020);
    final last = _mode == DoctorVisitFormMode.schedule
        ? now.add(const Duration(days: 730))
        : now;

    final date = await showDatePicker(
      context: context,
      initialDate: _visitDate.isAfter(last)
          ? last
          : (_visitDate.isBefore(first) ? first : _visitDate),
      firstDate: first,
      lastDate: last,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_visitDate),
    );
    if (time == null || !mounted) return;

    setState(() {
      _visitDate =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickNextAppointment() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _nextAppointment ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null || !mounted) return;

    setState(() {
      _nextAppointment =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  DoctorVisitPayload _buildPayload({required bool includeDetails}) {
    final existing = widget.existingVisit;
    // When details stay collapsed, keep any clinical data already on the visit.
    final keepExisting = !includeDetails && existing != null;

    return DoctorVisitPayload(
      visitDate: _visitDate,
      visitType: _visitType,
      providerName: _trimOrNull(_providerController.text),
      facilityName: _trimOrNull(_facilityController.text),
      chiefComplaint: includeDetails
          ? _trimOrNull(_complaintController.text)
          : existing?.chiefComplaint,
      clinicalNotes: _trimOrNull(_notesController.text),
      diagnosis: includeDetails
          ? _trimOrNull(_diagnosisController.text)
          : existing?.diagnosis,
      treatmentPlan: includeDetails
          ? _trimOrNull(_treatmentController.text)
          : existing?.treatmentPlan,
      followUpInstructions: includeDetails
          ? _trimOrNull(_followUpController.text)
          : existing?.followUpInstructions,
      bloodPressureSystolic: includeDetails
          ? _parseInt(_bpSysController.text)
          : existing?.bloodPressureSystolic,
      bloodPressureDiastolic: includeDetails
          ? _parseInt(_bpDiaController.text)
          : existing?.bloodPressureDiastolic,
      weightKg: includeDetails
          ? _parseDouble(_weightController.text)
          : existing?.weightKg,
      heartRateBpm: includeDetails
          ? _parseInt(_heartRateController.text)
          : existing?.heartRateBpm,
      temperatureCelsius: includeDetails
          ? _parseDouble(_tempController.text)
          : existing?.temperatureCelsius,
      fundalHeightCm: includeDetails
          ? _parseDouble(_fundalController.text)
          : existing?.fundalHeightCm,
      fetalHeartRateBpm: includeDetails
          ? _parseInt(_fhrController.text)
          : existing?.fetalHeartRateBpm,
      gestationalAgeWeeks: includeDetails
          ? _parseInt(_gaWeeksController.text)
          : existing?.gestationalAgeWeeks,
      medications: includeDetails
          ? _medications
              .map((e) => e.toMedication())
              .where((m) => m.name.isNotEmpty)
              .toList()
          : (keepExisting ? existing.medications : const []),
      labResults: includeDetails
          ? _labResults
              .map((e) => e.toLabResult())
              .where((l) => l.testName.isNotEmpty)
              .toList()
          : (keepExisting ? existing.labResults : const []),
      nextAppointmentAt:
          _mode == DoctorVisitFormMode.schedule ? null : _nextAppointment,
      nextAppointmentNotes: _mode == DoctorVisitFormMode.schedule
          ? null
          : _trimOrNull(_nextApptNotesController.text),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    if (_mode == DoctorVisitFormMode.schedule && !_visitDate.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a future date for a scheduled visit')),
      );
      return;
    }
    if (_mode != DoctorVisitFormMode.schedule && _visitDate.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use Schedule visit for appointments that have not happened yet'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final includeDetails =
        _mode != DoctorVisitFormMode.schedule && _showMoreDetails;
    try {
      final payload = _buildPayload(includeDetails: includeDetails);
      DoctorVisit saved;
      if (_isEditing) {
        saved = await ref.read(doctorVisitsProvider.notifier).saveVisit(
              id: widget.existingVisit!.id,
              payload: payload,
            );
      } else {
        saved = await ref.read(doctorVisitsProvider.notifier).addVisit(payload);
      }

      if (_mode == DoctorVisitFormMode.past ||
          _mode == DoctorVisitFormMode.update) {
        final pendingName = includeDetails
            ? _trimOrNull(_pendingTestController.text)
            : null;
        await ref.read(doctorVisitsProvider.notifier).debriefVisit(
              id: saved.id,
              payload: VisitDebriefPayload(
                pendingTests: pendingName == null
                    ? const []
                    : [
                        VisitPendingTest(
                          testName: pendingName,
                          status: 'pending',
                        ),
                      ],
                medications: includeDetails
                    ? _medications
                        .map((e) => e.toMedication())
                        .where((m) => m.name.isNotEmpty)
                        .toList()
                    : const [],
                markCompleted: true,
              ),
            );
      }

      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save visit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Scaffold(
      backgroundColor: context.appCanvas,
      appBar: MomAppBar(pageTitle: _title),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.spaceMD,
            AppSpacing.spaceSM,
            AppSpacing.spaceMD,
            AppSpacing.spaceXL,
          ),
          children: [
            Text(
              _mode == DoctorVisitFormMode.schedule
                  ? 'Just the essentials. We will ask how it went after the date.'
                  : 'A short update is enough. Add more details only if you want.',
              style: AppTypography.caption.copyWith(color: context.appInkSubtle),
            ),
            const SizedBox(height: AppSpacing.spaceMD),
            DropdownButtonFormField<String>(
              initialValue: _visitType,
              decoration: const InputDecoration(labelText: 'Visit type'),
              items: doctorVisitTypes
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(doctorVisitTypeLabels[type] ?? type),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _visitType = value);
              },
            ),
            const SizedBox(height: AppSpacing.spaceMD),
            InkWell(
              onTap: _pickVisitDateTime,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: _mode == DoctorVisitFormMode.schedule
                      ? 'When is it?'
                      : 'When was it?',
                ),
                child: Text(dateFormat.format(_visitDate)),
              ),
            ),
            const SizedBox(height: AppSpacing.spaceMD),
            AppTextField(
              controller: _providerController,
              label: 'Doctor / provider (optional)',
              hint: 'Dr. Smith',
            ),
            const SizedBox(height: AppSpacing.spaceMD),
            AppTextField(
              controller: _facilityController,
              label: 'Clinic / hospital (optional)',
            ),
            if (_mode == DoctorVisitFormMode.schedule) ...[
              const SizedBox(height: AppSpacing.spaceMD),
              AppTextField(
                controller: _notesController,
                label: 'Note (optional)',
                hint: 'Anything to remember before you go',
                maxLines: 2,
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.spaceLG),
              AppTextField(
                controller: _notesController,
                label: 'How did it go?',
                hint: 'What the doctor said, how you feel…',
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.spaceLG),
              _sectionTitle('Next appointment (optional)'),
              InkWell(
                onTap: _pickNextAppointment,
                child: InputDecorator(
                  decoration:
                      const InputDecoration(labelText: 'Scheduled date & time'),
                  child: Text(
                    _nextAppointment != null
                        ? dateFormat.format(_nextAppointment!)
                        : 'Not scheduled',
                  ),
                ),
              ),
              if (_nextAppointment != null) ...[
                const SizedBox(height: AppSpacing.spaceSM),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _nextAppointment = null),
                    child: const Text('Clear appointment'),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.spaceMD),
              AppTextField(
                controller: _nextApptNotesController,
                label: 'Appointment notes',
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              if (!_showMoreDetails)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _showMoreDetails = true),
                    child: const Text('Add more details'),
                  ),
                )
              else ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _showMoreDetails = false),
                    child: const Text('Hide extra details'),
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceSM),
                _sectionTitle('More details'),
                AppTextField(
                  controller: _complaintController,
                  label: 'Chief complaint',
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.spaceMD),
                AppTextField(
                  controller: _diagnosisController,
                  label: 'Diagnosis',
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.spaceMD),
                AppTextField(
                  controller: _treatmentController,
                  label: 'Treatment plan',
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.spaceMD),
                AppTextField(
                  controller: _followUpController,
                  label: 'Follow-up instructions',
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.spaceMD),
                AppTextField(
                  controller: _pendingTestController,
                  label: 'Test still to do',
                  hint: 'Blood work, scan…',
                ),
                const SizedBox(height: AppSpacing.spaceLG),
                _sectionTitle('Vitals'),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _bpSysController,
                        label: 'BP systolic',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSM),
                    Expanded(
                      child: AppTextField(
                        controller: _bpDiaController,
                        label: 'BP diastolic',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spaceMD),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _weightController,
                        label: 'Weight (kg)',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSM),
                    Expanded(
                      child: AppTextField(
                        controller: _heartRateController,
                        label: 'Heart rate',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spaceMD),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _tempController,
                        label: 'Temp (°C)',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSM),
                    Expanded(
                      child: AppTextField(
                        controller: _gaWeeksController,
                        label: 'Gestational weeks',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spaceMD),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _fundalController,
                        label: 'Fundal height (cm)',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSM),
                    Expanded(
                      child: AppTextField(
                        controller: _fhrController,
                        label: 'Fetal HR (bpm)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spaceLG),
                _buildMedicationsSection(),
                const SizedBox(height: AppSpacing.spaceLG),
                _buildLabResultsSection(),
              ],
            ],
            const SizedBox(height: AppSpacing.spaceXL),
            AppButton(
              label: _isSaving ? 'Saving...' : _saveLabel,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
      child: Text(title, style: AppTypography.bodyTextMedium),
    );
  }

  Widget _buildMedicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('Medications')),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _medications.add(_MedicationEntry.empty())),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        if (_medications.isEmpty)
          Text(
            'No medications recorded',
            style: AppTypography.caption.copyWith(color: context.appInkSubtle),
          ),
        ..._medications.asMap().entries.map((entry) {
          final index = entry.key;
          final med = entry.value;
          return AppCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
            child: Column(
              children: [
                AppTextField(
                  controller: med.nameController,
                  label: 'Medication',
                ),
                const SizedBox(height: AppSpacing.spaceSM),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: med.dosageController,
                        label: 'Dosage',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSM),
                    Expanded(
                      child: AppTextField(
                        controller: med.frequencyController,
                        label: 'Frequency',
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () {
                      setState(() {
                        med.dispose();
                        _medications.removeAt(index);
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLabResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('Lab results')),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _labResults.add(_LabEntry.empty())),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        if (_labResults.isEmpty)
          Text(
            'No lab results recorded',
            style: AppTypography.caption.copyWith(color: context.appInkSubtle),
          ),
        ..._labResults.asMap().entries.map((entry) {
          final index = entry.key;
          final lab = entry.value;
          return AppCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
            child: Column(
              children: [
                AppTextField(
                  controller: lab.testController,
                  label: 'Test name',
                ),
                const SizedBox(height: AppSpacing.spaceSM),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: lab.resultController,
                        label: 'Result',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSM),
                    Expanded(
                      child: AppTextField(
                        controller: lab.unitController,
                        label: 'Unit',
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () {
                      setState(() {
                        lab.dispose();
                        _labResults.removeAt(index);
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String? _trimOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int? _parseInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  double? _parseDouble(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }
}

class _MedicationEntry {
  final TextEditingController nameController;
  final TextEditingController dosageController;
  final TextEditingController frequencyController;
  final TextEditingController instructionsController;

  _MedicationEntry({
    required this.nameController,
    required this.dosageController,
    required this.frequencyController,
    required this.instructionsController,
  });

  factory _MedicationEntry.empty() {
    return _MedicationEntry(
      nameController: TextEditingController(),
      dosageController: TextEditingController(),
      frequencyController: TextEditingController(),
      instructionsController: TextEditingController(),
    );
  }

  factory _MedicationEntry.fromMedication(VisitMedication med) {
    return _MedicationEntry(
      nameController: TextEditingController(text: med.name),
      dosageController: TextEditingController(text: med.dosage),
      frequencyController: TextEditingController(text: med.frequency),
      instructionsController:
          TextEditingController(text: med.instructions ?? ''),
    );
  }

  VisitMedication toMedication() {
    return VisitMedication(
      name: nameController.text.trim(),
      dosage: dosageController.text.trim(),
      frequency: frequencyController.text.trim(),
      instructions: instructionsController.text.trim().isEmpty
          ? null
          : instructionsController.text.trim(),
    );
  }

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
    instructionsController.dispose();
  }
}

class _LabEntry {
  final TextEditingController testController;
  final TextEditingController resultController;
  final TextEditingController unitController;
  final TextEditingController notesController;

  _LabEntry({
    required this.testController,
    required this.resultController,
    required this.unitController,
    required this.notesController,
  });

  factory _LabEntry.empty() {
    return _LabEntry(
      testController: TextEditingController(),
      resultController: TextEditingController(),
      unitController: TextEditingController(),
      notesController: TextEditingController(),
    );
  }

  factory _LabEntry.fromLabResult(VisitLabResult lab) {
    return _LabEntry(
      testController: TextEditingController(text: lab.testName),
      resultController: TextEditingController(text: lab.result),
      unitController: TextEditingController(text: lab.unit ?? ''),
      notesController: TextEditingController(text: lab.notes ?? ''),
    );
  }

  VisitLabResult toLabResult() {
    return VisitLabResult(
      testName: testController.text.trim(),
      result: resultController.text.trim(),
      unit: unitController.text.trim().isEmpty ? null : unitController.text.trim(),
      notes:
          notesController.text.trim().isEmpty ? null : notesController.text.trim(),
    );
  }

  void dispose() {
    testController.dispose();
    resultController.dispose();
    unitController.dispose();
    notesController.dispose();
  }
}
