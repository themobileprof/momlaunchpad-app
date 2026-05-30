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

/// Full-screen form for creating or editing a visit record.
class DoctorVisitFormScreen extends ConsumerStatefulWidget {
  final DoctorVisit? existingVisit;

  const DoctorVisitFormScreen({super.key, this.existingVisit});

  @override
  ConsumerState<DoctorVisitFormScreen> createState() =>
      _DoctorVisitFormScreenState();
}

class _DoctorVisitFormScreenState extends ConsumerState<DoctorVisitFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _visitDate;
  late String _visitType;
  DateTime? _nextAppointment;

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

  final List<_MedicationEntry> _medications = [];
  final List<_LabEntry> _labResults = [];
  bool _isSaving = false;

  bool get _isEditing => widget.existingVisit != null;

  @override
  void initState() {
    super.initState();
    final visit = widget.existingVisit;
    _visitDate = visit?.visitDate.toLocal() ?? DateTime.now();
    _visitType = visit?.visitType ?? doctorVisitTypes.first;
    _nextAppointment = visit?.nextAppointmentAt?.toLocal();

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
    for (final entry in _medications) {
      entry.dispose();
    }
    for (final entry in _labResults) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _pickVisitDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_visitDate),
    );
    if (time == null || !mounted) return;

    setState(() {
      _visitDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
      initialTime: TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null || !mounted) return;

    setState(() {
      _nextAppointment = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  DoctorVisitPayload _buildPayload() {
    return DoctorVisitPayload(
      visitDate: _visitDate,
      visitType: _visitType,
      providerName: _trimOrNull(_providerController.text),
      facilityName: _trimOrNull(_facilityController.text),
      chiefComplaint: _trimOrNull(_complaintController.text),
      clinicalNotes: _trimOrNull(_notesController.text),
      diagnosis: _trimOrNull(_diagnosisController.text),
      treatmentPlan: _trimOrNull(_treatmentController.text),
      followUpInstructions: _trimOrNull(_followUpController.text),
      bloodPressureSystolic: _parseInt(_bpSysController.text),
      bloodPressureDiastolic: _parseInt(_bpDiaController.text),
      weightKg: _parseDouble(_weightController.text),
      heartRateBpm: _parseInt(_heartRateController.text),
      temperatureCelsius: _parseDouble(_tempController.text),
      fundalHeightCm: _parseDouble(_fundalController.text),
      fetalHeartRateBpm: _parseInt(_fhrController.text),
      gestationalAgeWeeks: _parseInt(_gaWeeksController.text),
      medications: _medications
          .map((e) => e.toMedication())
          .where((m) => m.name.isNotEmpty)
          .toList(),
      labResults: _labResults
          .map((e) => e.toLabResult())
          .where((l) => l.testName.isNotEmpty)
          .toList(),
      nextAppointmentAt: _nextAppointment,
      nextAppointmentNotes: _trimOrNull(_nextApptNotesController.text),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final payload = _buildPayload();
      if (_isEditing) {
        await ref.read(doctorVisitsProvider.notifier).saveVisit(
              id: widget.existingVisit!.id,
              payload: payload,
            );
      } else {
        await ref.read(doctorVisitsProvider.notifier).addVisit(payload);
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
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit visit' : 'Add visit',
          style: AppTypography.headingMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
            _sectionTitle('Visit details'),
            DropdownButtonFormField<String>(
              value: _visitType,
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
                decoration: const InputDecoration(labelText: 'Visit date & time'),
                child: Text(dateFormat.format(_visitDate)),
              ),
            ),
            const SizedBox(height: AppSpacing.spaceMD),
            AppTextField(
              controller: _providerController,
              label: 'Doctor / provider',
              hint: 'Dr. Smith',
            ),
            const SizedBox(height: AppSpacing.spaceMD),
            AppTextField(
              controller: _facilityController,
              label: 'Clinic / hospital',
            ),
            const SizedBox(height: AppSpacing.spaceLG),
            _sectionTitle('Reason for visit'),
            AppTextField(
              controller: _complaintController,
              label: 'Chief complaint',
              maxLines: 3,
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            _sectionTitle('Clinical notes'),
            AppTextField(
              controller: _notesController,
              label: 'Doctor observations',
              maxLines: 4,
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
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.spaceMD),
            AppTextField(
              controller: _followUpController,
              label: 'Follow-up instructions',
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.spaceLG),
            _buildMedicationsSection(),
            const SizedBox(height: AppSpacing.spaceLG),
            _buildLabResultsSection(),
            const SizedBox(height: AppSpacing.spaceLG),
            _sectionTitle('Next appointment'),
            InkWell(
              onTap: _pickNextAppointment,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Scheduled date & time'),
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
            const SizedBox(height: AppSpacing.spaceXL),
            AppButton(
              label: _isSaving ? 'Saving...' : 'Save visit',
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
              onPressed: () => setState(() => _medications.add(_MedicationEntry.empty())),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        if (_medications.isEmpty)
          Text(
            'No medications recorded',
            style: AppTypography.caption.copyWith(color: AppColors.textLight),
          ),
        ..._medications.asMap().entries.map((entry) {
          final index = entry.key;
          final med = entry.value;
          return AppCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
            child: Column(
              children: [
                AppTextField(controller: med.nameController, label: 'Medication'),
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
                const SizedBox(height: AppSpacing.spaceSM),
                AppTextField(
                  controller: med.instructionsController,
                  label: 'Instructions',
                  maxLines: 2,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
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
              onPressed: () => setState(() => _labResults.add(_LabEntry.empty())),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        if (_labResults.isEmpty)
          Text(
            'No lab results recorded',
            style: AppTypography.caption.copyWith(color: AppColors.textLight),
          ),
        ..._labResults.asMap().entries.map((entry) {
          final index = entry.key;
          final lab = entry.value;
          return AppCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
            child: Column(
              children: [
                AppTextField(controller: lab.testController, label: 'Test name'),
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
                const SizedBox(height: AppSpacing.spaceSM),
                AppTextField(
                  controller: lab.notesController,
                  label: 'Notes',
                  maxLines: 2,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
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
      instructionsController: TextEditingController(text: med.instructions ?? ''),
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
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
    );
  }

  void dispose() {
    testController.dispose();
    resultController.dispose();
    unitController.dispose();
    notesController.dispose();
  }
}
