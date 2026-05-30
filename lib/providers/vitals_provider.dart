import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vital_reading.dart';
import '../services/api_service.dart';
import 'service_providers.dart';

class VitalsState {
  final List<VitalReading> readings;
  final bool isLoading;
  final String? error;

  const VitalsState({
    this.readings = const [],
    this.isLoading = false,
    this.error,
  });

  VitalsState copyWith({
    List<VitalReading>? readings,
    bool? isLoading,
    String? error,
  }) {
    return VitalsState(
      readings: readings ?? this.readings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  VitalReading? get latest => readings.isEmpty ? null : readings.first;
}

class VitalsNotifier extends Notifier<VitalsState> {
  late final ApiService _apiService;

  @override
  VitalsState build() {
    _apiService = ref.read(apiServiceProvider);
    return const VitalsState();
  }

  Future<void> fetchReadings({int limit = 30}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final readings = await _apiService.getVitalReadings(limit: limit);
      state = VitalsState(readings: readings, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load vital readings',
      );
    }
  }

  Future<VitalReading> addReading(VitalReadingPayload payload) async {
    try {
      final reading = await _apiService.createVitalReading(payload);
      state = state.copyWith(readings: [reading, ...state.readings]);
      return reading;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  Future<void> deleteReading(String id) async {
    try {
      await _apiService.deleteVitalReading(id);
      state = state.copyWith(
        readings: state.readings.where((r) => r.id != id).toList(),
      );
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }
}

final vitalsProvider = NotifierProvider<VitalsNotifier, VitalsState>(
  VitalsNotifier.new,
);
