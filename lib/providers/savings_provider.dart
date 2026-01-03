import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/savings_summary.dart';
import '../models/savings_entry.dart';
import '../services/api_service.dart';
import 'service_providers.dart';

/// Savings state
class SavingsState {
  final SavingsSummary? summary;
  final List<SavingsEntry> entries;
  final bool isLoading;
  final String? error;

  SavingsState({
    this.summary,
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  SavingsState copyWith({
    SavingsSummary? summary,
    List<SavingsEntry>? entries,
    bool? isLoading,
    String? error,
  }) {
    return SavingsState(
      summary: summary ?? this.summary,
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Savings provider (Notifier)
class SavingsNotifier extends Notifier<SavingsState> {
  late final ApiService _apiService;

  @override
  SavingsState build() {
    _apiService = ref.read(apiServiceProvider);
    return SavingsState();
  }

  /// Fetch savings summary and entries
  Future<void> fetchSavingsData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final summary = await _apiService.getSavingsSummary();
      final entries = await _apiService.getSavingsEntries();
      
      state = SavingsState(
        summary: summary,
        entries: entries,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load savings data',
      );
    }
  }

  /// Create new savings entry
  Future<void> addEntry({
    required double amount,
    required String description,
    DateTime? entryDate,
  }) async {
    try {
      final entry = await _apiService.createSavingsEntry(
        amount: amount,
        description: description,
        entryDate: entryDate,
      );
      
      // Refresh data after adding entry
      await fetchSavingsData();
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  /// Update expected delivery date
  Future<void> updateEDD(DateTime? edd) async {
    try {
      await _apiService.updateExpectedDeliveryDate(edd);
      // Refresh summary after update
      await fetchSavingsData();
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  /// Update savings goal
  Future<void> updateGoal(double goal) async {
    try {
      await _apiService.updateSavingsGoal(goal);
      // Refresh summary after update
      await fetchSavingsData();
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }
}

/// Savings provider instance
final savingsProvider = NotifierProvider<SavingsNotifier, SavingsState>(
  SavingsNotifier.new,
);
