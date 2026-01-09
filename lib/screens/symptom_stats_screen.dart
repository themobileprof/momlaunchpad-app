import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/symptom.dart';
import '../providers/symptom_provider.dart';
import '../theme/colors.dart';
import 'symptom_history_screen.dart';

/// Screen displaying symptom statistics and visualizations
class SymptomStatsScreen extends ConsumerWidget {
  const SymptomStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(symptomStatsProvider);
    final recentAsync = ref.watch(recentSymptomsProvider(5));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SymptomHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(symptomStatsProvider);
          ref.invalidate(recentSymptomsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats cards
              statsAsync.when(
                data: (stats) => _buildStatsSection(context, stats),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => _buildError(context, ref, error.toString()),
              ),

              const SizedBox(height: 24),

              // Recent symptoms
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Symptoms',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SymptomHistoryScreen(),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              recentAsync.when(
                data: (symptoms) => _buildRecentSymptoms(context, symptoms),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildError(context, ref, error.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, SymptomStats stats) {
    return Column(
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                stats.totalSymptoms.toString(),
                Icons.health_and_safety,
                AppColors.primaryPink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Ongoing',
                stats.ongoing.toString(),
                Icons.warning_amber,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Resolved',
                stats.resolved.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // By Type Section
        if (stats.byType.isNotEmpty) ...[
          _buildSectionTitle('By Type'),
          const SizedBox(height: 12),
          _buildTypeBreakdown(stats.byType),
          const SizedBox(height: 24),
        ],

        // By Severity Section
        if (stats.bySeverity.isNotEmpty) ...[
          _buildSectionTitle('By Severity'),
          const SizedBox(height: 12),
          _buildSeverityBreakdown(stats.bySeverity),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTypeBreakdown(Map<String, int> byType) {
    final sortedEntries = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: sortedEntries.map((entry) {
            final percentage = (entry.value / byType.values.reduce((a, b) => a + b) * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.key.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Stack(
                      children: [
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: double.parse(percentage) / 100,
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primaryPink.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${entry.value} ($percentage%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSeverityBreakdown(Map<String, int> bySeverity) {
    final colors = {
      'mild': Colors.green,
      'moderate': Colors.orange,
      'severe': Colors.red,
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: bySeverity.entries.map((entry) {
            final color = colors[entry.key] ?? Colors.grey;
            return Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      entry.value.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.key.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRecentSymptoms(BuildContext context, List<Symptom> symptoms) {
    if (symptoms.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No symptoms recorded',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Symptoms are tracked from your chat',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: symptoms.map((symptom) {
        final severityColor = _getSeverityColor(symptom.severity);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getSymptomIcon(symptom.symptomType),
                color: severityColor,
                size: 20,
              ),
            ),
            title: Text(
              symptom.symptomTypeName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              symptom.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: symptom.isResolved
                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      symptom.severity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: severityColor,
                      ),
                    ),
                  ),
          ),
        );
      }).toList(),
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

  IconData _getSymptomIcon(String type) {
    switch (type) {
      case 'swelling':
        return Icons.water_drop;
      case 'nausea':
        return Icons.sick;
      case 'headache':
        return Icons.psychology;
      case 'back_pain':
        return Icons.accessibility_new;
      case 'cramping':
        return Icons.warning;
      case 'fatigue':
        return Icons.battery_0_bar;
      case 'insomnia':
        return Icons.bedtime;
      case 'bleeding':
        return Icons.emergency;
      default:
        return Icons.health_and_safety;
    }
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load data',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(symptomStatsProvider);
                  ref.invalidate(recentSymptomsProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
