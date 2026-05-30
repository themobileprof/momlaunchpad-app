import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/symptom.dart';
import '../models/vital_reading.dart';
import '../providers/symptom_provider.dart';
import '../providers/vitals_provider.dart';
import '../services/api_service.dart';
import '../utils/symptom_resolve.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/log_vitals_sheet.dart';
import '../widgets/symptom_source_chat_link.dart';
import 'symptom_history_screen.dart';

/// Health tracker with Symptoms and Vitals on separate tabs.
class SymptomStatsScreen extends ConsumerStatefulWidget {
  const SymptomStatsScreen({super.key});

  @override
  ConsumerState<SymptomStatsScreen> createState() => _SymptomStatsScreenState();
}

class _SymptomStatsScreenState extends ConsumerState<SymptomStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    Future.microtask(() => ref.read(vitalsProvider.notifier).fetchReadings());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openLogVitals() async {
    final saved = await LogVitalsSheet.show(context);
    if (saved == true && mounted) {
      await ref.read(vitalsProvider.notifier).fetchReadings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Tracker'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.health_and_safety_outlined),
              text: 'Symptoms',
            ),
            Tab(
              icon: Icon(Icons.monitor_heart_outlined),
              text: 'Vitals',
            ),
          ],
        ),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Symptom history',
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
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SymptomsTab(),
          _VitalsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: FloatingActionButton.extended(
                onPressed: _openLogVitals,
                backgroundColor: AppColors.primaryPink,
                icon: const Icon(Icons.add),
                label: const Text('Log vitals'),
              ),
            )
          : null,
    );
  }
}

class _SymptomsTab extends ConsumerWidget {
  const _SymptomsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(symptomStatsProvider);
    final recentAsync = ref.watch(recentSymptomsProvider(5));

    return RefreshIndicator(
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
            statsAsync.when(
              data: (stats) => _SymptomsTabContent.buildStatsSection(stats),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) =>
                  _SymptomsTabContent.buildError(context, ref, error.toString()),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Symptoms',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              data: (symptoms) => _SymptomsTabContent.buildRecentSymptoms(
                symptoms,
                context: context,
                ref: ref,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  _SymptomsTabContent.buildError(context, ref, error.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalsTab extends ConsumerWidget {
  const _VitalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vitalsProvider);
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return RefreshIndicator(
      onRefresh: () => ref.read(vitalsProvider.notifier).fetchReadings(),
      child: state.isLoading && state.readings.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                Text(
                  'Track blood pressure, weight, and other measurements over time.',
                  style: AppTypography.caption.copyWith(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                if (state.latest != null) ...[
                  _LatestVitalsRow(reading: state.latest!),
                  const SizedBox(height: 24),
                ],
                const Text(
                  'History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (state.error != null && state.readings.isEmpty)
                  _VitalsError(
                    message: state.error!,
                    onRetry: () => ref.read(vitalsProvider.notifier).fetchReadings(),
                  )
                else if (state.readings.isEmpty)
                  _VitalsEmpty(onLog: () => LogVitalsSheet.show(context))
                else
                  ...state.readings.map(
                    (reading) => _VitalReadingCard(
                      reading: reading,
                      dateFormat: dateFormat,
                      onDelete: () => _confirmDelete(context, ref, reading),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    VitalReading reading,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reading?'),
        content: const Text('This vital reading will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(vitalsProvider.notifier).deleteReading(reading.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}

class _LatestVitalsRow extends StatelessWidget {
  final VitalReading reading;

  const _LatestVitalsRow({required this.reading});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (reading.bloodPressureDisplay != null) {
      chips.add(_VitalChip(
        label: 'BP',
        value: reading.bloodPressureDisplay!.replaceAll(' mmHg', ''),
      ));
    }
    if (reading.weightKg != null) {
      chips.add(_VitalChip(label: 'Weight', value: '${reading.weightKg} kg'));
    }
    if (reading.heartRateBpm != null) {
      chips.add(_VitalChip(label: 'HR', value: '${reading.heartRateBpm} bpm'));
    }
    if (reading.fetalHeartRateBpm != null) {
      chips.add(_VitalChip(label: 'FHR', value: '${reading.fetalHeartRateBpm}'));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Latest',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }
}

class _VitalChip extends StatelessWidget {
  final String label;
  final String value;

  const _VitalChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(color: AppColors.textLight),
            ),
            Text(value, style: AppTypography.bodyTextMedium),
          ],
        ),
      ),
    );
  }
}

class _VitalReadingCard extends StatelessWidget {
  final VitalReading reading;
  final DateFormat dateFormat;
  final VoidCallback onDelete;

  const _VitalReadingCard({
    required this.reading,
    required this.dateFormat,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryPink.withValues(alpha: 0.12),
          child: const Icon(Icons.monitor_heart_outlined, color: AppColors.primaryPink),
        ),
        title: Text(
          dateFormat.format(reading.recordedAt.toLocal()),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reading.summaryLines.isNotEmpty)
              Text(reading.summaryLines.join(' • ')),
            if (reading.notes != null && reading.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  reading.notes!,
                  style: AppTypography.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _VitalsEmpty extends StatelessWidget {
  final VoidCallback onLog;

  const _VitalsEmpty({required this.onLog});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.monitor_heart_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No vitals logged yet',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap Log vitals to record measurements',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Log vitals'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VitalsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _VitalsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Symptom tab UI helpers (stats, charts, recent list).
class _SymptomsTabContent {
  static Widget buildStatsSection(SymptomStats stats) {
    return Column(
      children: [
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
        if (stats.byType.isNotEmpty) ...[
          _buildSectionTitle('By Type'),
          const SizedBox(height: 12),
          _buildTypeBreakdown(stats.byType),
          const SizedBox(height: 24),
        ],
        if (stats.bySeverity.isNotEmpty) ...[
          _buildSectionTitle('By Severity'),
          const SizedBox(height: 12),
          _buildSeverityBreakdown(stats.bySeverity),
        ],
      ],
    );
  }

  static Widget _buildStatCard(
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
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  static Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  static Widget _buildTypeBreakdown(Map<String, int> byType) {
    final sortedEntries = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: sortedEntries.map((entry) {
            final percentage =
                (entry.value / byType.values.reduce((a, b) => a + b) * 100)
                    .toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.key
                          .split('_')
                          .map((w) => w[0].toUpperCase() + w.substring(1))
                          .join(' '),
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
                              color: AppColors.primaryPink.withValues(alpha: 0.7),
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

  static Widget _buildSeverityBreakdown(Map<String, int> bySeverity) {
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
                    color: color.withValues(alpha: 0.1),
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

  static Widget buildRecentSymptoms(
    List<Symptom> symptoms, {
    required BuildContext context,
    required WidgetRef ref,
  }) {
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.1),
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
                    symptom.displayText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: symptom.isResolved
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: severityColor.withValues(alpha: 0.1),
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
                SymptomSourceChatLink(symptom: symptom),
                if (!symptom.isResolved)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          markSymptomResolved(context, ref, symptom.id),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Mark resolved'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  static Color _getSeverityColor(String severity) {
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

  static IconData _getSymptomIcon(String type) {
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

  static Widget buildError(BuildContext context, WidgetRef ref, String error) {
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
