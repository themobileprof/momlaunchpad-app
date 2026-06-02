import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vital_reading.dart';
import '../providers/vitals_provider.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/widgets.dart';

/// Bottom sheet for manually logging vital signs.
class LogVitalsSheet extends ConsumerStatefulWidget {
  const LogVitalsSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: const LogVitalsSheet(),
      ),
    );
  }

  @override
  ConsumerState<LogVitalsSheet> createState() => _LogVitalsSheetState();
}

class _LogVitalsSheetState extends ConsumerState<LogVitalsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _bpSysController = TextEditingController();
  final _bpDiaController = TextEditingController();
  final _weightController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _tempController = TextEditingController();
  final _fundalController = TextEditingController();
  final _fhrController = TextEditingController();
  final _gaWeeksController = TextEditingController();

  DateTime _recordedAt = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    _bpSysController.dispose();
    _bpDiaController.dispose();
    _weightController.dispose();
    _heartRateController.dispose();
    _tempController.dispose();
    _fundalController.dispose();
    _fhrController.dispose();
    _gaWeeksController.dispose();
    super.dispose();
  }

  Future<void> _pickRecordedAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _recordedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  bool _hasAnyMeasurement() {
    return [
      _bpSysController.text,
      _bpDiaController.text,
      _weightController.text,
      _heartRateController.text,
      _tempController.text,
      _fundalController.text,
      _fhrController.text,
      _gaWeeksController.text,
    ].any((value) => value.trim().isNotEmpty);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasAnyMeasurement()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one measurement')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(vitalsProvider.notifier).addReading(
            VitalReadingPayload(
              recordedAt: _recordedAt,
              bloodPressureSystolic: _parseInt(_bpSysController.text),
              bloodPressureDiastolic: _parseInt(_bpDiaController.text),
              weightKg: _parseDouble(_weightController.text),
              heartRateBpm: _parseInt(_heartRateController.text),
              temperatureCelsius: _parseDouble(_tempController.text),
              fundalHeightCm: _parseDouble(_fundalController.text),
              fetalHeartRateBpm: _parseInt(_fhrController.text),
              gestationalAgeWeeks: _parseInt(_gaWeeksController.text),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
          );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appCanvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spaceMD,
              AppSpacing.spaceSM,
              AppSpacing.spaceMD,
              AppSpacing.spaceMD,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
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
                Text('Log vitals', style: AppTypography.headingMedium),
                const SizedBox(height: AppSpacing.spaceSM),
                Text(
                  'Record what you measured at home or at a visit.',
                  style: AppTypography.caption.copyWith(color: context.appInkSubtle),
                ),
                const SizedBox(height: AppSpacing.spaceMD),
                InkWell(
                  onTap: _pickRecordedAt,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'When'),
                    child: Text(
                      MaterialLocalizations.of(context).formatFullDate(_recordedAt),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceMD),
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
                const SizedBox(height: AppSpacing.spaceMD),
                AppTextField(
                  controller: _notesController,
                  label: 'Notes (optional)',
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.spaceLG),
                AppButton(
                  label: _isSaving ? 'Saving...' : 'Save vitals',
                  onPressed: _isSaving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
