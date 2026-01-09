import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/symptom.dart';
import '../providers/symptom_provider.dart';
import '../theme/colors.dart';
import 'package:intl/intl.dart';

/// Screen displaying symptom history with filter options
class SymptomHistoryScreen extends ConsumerStatefulWidget {
  const SymptomHistoryScreen({super.key});

  @override
  ConsumerState<SymptomHistoryScreen> createState() =>
      _SymptomHistoryScreenState();
}

class _SymptomHistoryScreenState extends ConsumerState<SymptomHistoryScreen> {
  String? _selectedType;
  final int _limit = 50;

  // Common symptom types for filter
  final List<String> _symptomTypes = [
    'swelling',
    'nausea',
    'headache',
    'back_pain',
    'cramping',
    'vision_changes',
    'dizziness',
    'fatigue',
    'insomnia',
    'heartburn',
    'vomiting',
    'constipation',
    'bleeding',
    'contractions',
  ];

  @override
  Widget build(BuildContext context) {
    final params = SymptomHistoryParams(
      limit: _limit,
      type: _selectedType,
    );

    final historyAsync = ref.watch(symptomHistoryProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: historyAsync.when(
        data: (symptoms) => _buildSymptomList(symptoms),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(error.toString()),
      ),
    );
  }

  Widget _buildSymptomList(List<Symptom> symptoms) {
    if (symptoms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No symptoms recorded yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Symptoms are tracked from your chat conversations',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: symptoms.length,
      itemBuilder: (context, index) => _buildSymptomCard(symptoms[index]),
    );
  }

  Widget _buildSymptomCard(Symptom symptom) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final severityColor = _getSeverityColor(symptom.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Symptom type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    symptom.symptomTypeName,
                    style: const TextStyle(
                      color: AppColors.primaryPink,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                // Severity indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getSeverityIcon(symptom.severity),
                        size: 14,
                        color: severityColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        symptom.severity.toUpperCase(),
                        style: TextStyle(
                          color: severityColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              symptom.description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Details row
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildDetailChip(
                  Icons.access_time,
                  'Frequency: ${symptom.frequency}',
                ),
                if (symptom.onsetTime != null)
                  _buildDetailChip(
                    Icons.history,
                    'Onset: ${symptom.onsetTime}',
                  ),
              ],
            ),

            // Associated symptoms
            if (symptom.associatedSymptoms.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: symptom.associatedSymptoms
                    .map((s) => Chip(
                          label: Text(
                            s.split('_').join(' '),
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.grey[200],
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 12),

            // Footer
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(symptom.reportedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (symptom.isResolved)
                  const Chip(
                    label: Text(
                      'RESOLVED',
                      style: TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  )
                else
                  TextButton.icon(
                    onPressed: () => _resolveSymptom(symptom.id),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Mark Resolved'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'mild':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity) {
      case 'mild':
        return Icons.sentiment_satisfied;
      case 'moderate':
        return Icons.sentiment_neutral;
      case 'severe':
        return Icons.warning;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load symptoms',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(symptomHistoryProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Symptoms'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Symptom Type:'),
            const SizedBox(height: 8),
            DropdownButton<String?>(
              value: _selectedType,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
                ..._symptomTypes.map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(
                      type.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedType = value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedType = null);
              Navigator.pop(context);
            },
            child: const Text('Clear Filter'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveSymptom(String symptomId) async {
    try {
      await ref.read(resolveSymptomProvider(symptomId).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Symptom marked as resolved'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the list
        ref.invalidate(symptomHistoryProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resolve symptom: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
