import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/symptom.dart';
import '../services/symptom_service.dart';
import 'service_providers.dart';

/// Symptom service provider
final symptomServiceProvider = Provider<SymptomService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SymptomService(storage: storage);
});

/// Symptom history provider
final symptomHistoryProvider = FutureProvider.autoDispose
    .family<List<Symptom>, SymptomHistoryParams>((ref, params) async {
  final service = ref.watch(symptomServiceProvider);
  return service.getHistory(
    limit: params.limit,
    type: params.type,
  );
});

/// Recent symptoms provider
final recentSymptomsProvider =
    FutureProvider.autoDispose.family<List<Symptom>, int>((ref, limit) async {
  final service = ref.watch(symptomServiceProvider);
  return service.getRecent(limit: limit);
});

/// Symptom stats provider
final symptomStatsProvider = FutureProvider.autoDispose<SymptomStats>((ref) async {
  final service = ref.watch(symptomServiceProvider);
  return service.getStats();
});

/// Provider for resolving symptoms
final resolveSymptomProvider =
    FutureProvider.autoDispose.family<void, String>((ref, symptomId) async {
  final service = ref.watch(symptomServiceProvider);
  await service.resolveSymptom(symptomId);
  
  // Invalidate related providers to refresh data
  ref.invalidate(symptomHistoryProvider);
  ref.invalidate(recentSymptomsProvider);
  ref.invalidate(symptomStatsProvider);
});

/// Parameters for symptom history query
class SymptomHistoryParams {
  final int limit;
  final String? type;

  SymptomHistoryParams({
    this.limit = 50,
    this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomHistoryParams &&
          runtimeType == other.runtimeType &&
          limit == other.limit &&
          type == other.type;

  @override
  int get hashCode => limit.hashCode ^ type.hashCode;
}
