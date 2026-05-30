import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/doctor_visit.dart';
import '../services/api_service.dart';
import 'service_providers.dart';

class DoctorVisitsState {
  final List<DoctorVisit> visits;
  final bool isLoading;
  final String? error;

  const DoctorVisitsState({
    this.visits = const [],
    this.isLoading = false,
    this.error,
  });

  DoctorVisitsState copyWith({
    List<DoctorVisit>? visits,
    bool? isLoading,
    String? error,
  }) {
    return DoctorVisitsState(
      visits: visits ?? this.visits,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DoctorVisitsNotifier extends Notifier<DoctorVisitsState> {
  late final ApiService _apiService;

  @override
  DoctorVisitsState build() {
    _apiService = ref.read(apiServiceProvider);
    return const DoctorVisitsState();
  }

  Future<void> fetchVisits() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final visits = await _apiService.getDoctorVisits();
      state = DoctorVisitsState(visits: visits, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load visit records',
      );
    }
  }

  Future<DoctorVisit> addVisit(DoctorVisitPayload payload) async {
    try {
      final visit = await _apiService.createDoctorVisit(payload);
      state = state.copyWith(visits: [visit, ...state.visits]);
      return visit;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  Future<DoctorVisit> saveVisit({
    required String id,
    required DoctorVisitPayload payload,
  }) async {
    try {
      final visit = await _apiService.updateDoctorVisit(id: id, payload: payload);
      final updated = state.visits
          .map((v) => v.id == id ? visit : v)
          .toList()
        ..sort((a, b) => b.visitDate.compareTo(a.visitDate));
      state = state.copyWith(visits: updated);
      return visit;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  Future<void> deleteVisit(String id) async {
    try {
      await _apiService.deleteDoctorVisit(id);
      state = state.copyWith(
        visits: state.visits.where((v) => v.id != id).toList(),
      );
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }
}

final doctorVisitsProvider =
    NotifierProvider<DoctorVisitsNotifier, DoctorVisitsState>(
  DoctorVisitsNotifier.new,
);
