import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hospital_bag_item.dart';
import '../services/api_service.dart';
import 'service_providers.dart';

class HospitalBagState {
  final List<HospitalBagItem> items;
  final String currency;
  final int packedCount;
  final int totalCount;
  final double totalPrice;
  final bool isLoading;
  final String? error;

  const HospitalBagState({
    this.items = const [],
    this.currency = 'NGN',
    this.packedCount = 0,
    this.totalCount = 0,
    this.totalPrice = 0,
    this.isLoading = false,
    this.error,
  });

  double get progress =>
      totalCount == 0 ? 0 : packedCount / totalCount;

  HospitalBagState copyWith({
    List<HospitalBagItem>? items,
    String? currency,
    int? packedCount,
    int? totalCount,
    double? totalPrice,
    bool? isLoading,
    String? error,
  }) {
    return HospitalBagState(
      items: items ?? this.items,
      currency: currency ?? this.currency,
      packedCount: packedCount ?? this.packedCount,
      totalCount: totalCount ?? this.totalCount,
      totalPrice: totalPrice ?? this.totalPrice,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  HospitalBagList toList() {
    return HospitalBagList(
      items: items,
      currency: currency,
      packedCount: packedCount,
      totalCount: totalCount,
      totalPrice: totalPrice,
    );
  }
}

class HospitalBagNotifier extends Notifier<HospitalBagState> {
  late final ApiService _apiService;

  @override
  HospitalBagState build() {
    _apiService = ref.read(apiServiceProvider);
    return const HospitalBagState();
  }

  void _applyList(HospitalBagList list) {
    state = HospitalBagState(
      items: list.items,
      currency: list.currency,
      packedCount: list.packedCount,
      totalCount: list.totalCount,
      totalPrice: list.totalPrice,
      isLoading: false,
    );
  }

  ({int packedCount, double totalPrice}) _recount(List<HospitalBagItem> items) {
    var packed = 0;
    var totalPrice = 0.0;
    for (final item in items) {
      if (item.isPacked) packed++;
      if (item.price != null) totalPrice += item.price!;
    }
    return (packedCount: packed, totalPrice: totalPrice);
  }

  Future<void> fetchItems() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _apiService.getHospitalBagItems();
      _applyList(list);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load hospital bag checklist',
      );
    }
  }

  Future<void> togglePacked(HospitalBagItem item) async {
    final previous = state.items;
    final optimistic = previous
        .map(
          (row) => row.id == item.id
              ? row.copyWith(isPacked: !row.isPacked)
              : row,
        )
        .toList();
    final counts = _recount(optimistic);
    state = state.copyWith(
      items: optimistic,
      packedCount: counts.packedCount,
      totalCount: optimistic.length,
      totalPrice: counts.totalPrice,
      error: null,
    );

    try {
      final updated = await _apiService.updateHospitalBagItem(
        id: item.id,
        isPacked: !item.isPacked,
      );
      final merged = optimistic
          .map((row) => row.id == updated.id ? updated : row)
          .toList();
      final mergedCounts = _recount(merged);
      state = state.copyWith(
        items: merged,
        packedCount: mergedCounts.packedCount,
        totalPrice: mergedCounts.totalPrice,
      );
    } on ApiException catch (e) {
      state = state.copyWith(items: previous, error: e.message);
      rethrow;
    } catch (_) {
      state = state.copyWith(items: previous);
      rethrow;
    }
  }

  Future<HospitalBagItem> addItem({
    required String label,
    String category = 'other',
    double? price,
  }) async {
    try {
      final created = await _apiService.createHospitalBagItem(
        label: label,
        category: category,
        price: price,
      );
      final items = [...state.items, created];
      final counts = _recount(items);
      state = state.copyWith(
        items: items,
        packedCount: counts.packedCount,
        totalCount: items.length,
        totalPrice: counts.totalPrice,
        error: null,
      );
      return created;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  Future<HospitalBagItem> updateItem({
    required String id,
    String? label,
    String? category,
    double? price,
    bool clearPrice = false,
  }) async {
    try {
      final updated = await _apiService.updateHospitalBagItem(
        id: id,
        label: label,
        category: category,
        price: price,
        clearPrice: clearPrice,
      );
      final items = state.items
          .map((row) => row.id == id ? updated : row)
          .toList();
      final counts = _recount(items);
      state = state.copyWith(
        items: items,
        packedCount: counts.packedCount,
        totalPrice: counts.totalPrice,
        error: null,
      );
      return updated;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    final previous = state.items;
    final filtered = previous.where((row) => row.id != id).toList();
    final counts = _recount(filtered);
    state = state.copyWith(
      items: filtered,
      packedCount: counts.packedCount,
      totalCount: filtered.length,
      totalPrice: counts.totalPrice,
      error: null,
    );

    try {
      await _apiService.deleteHospitalBagItem(id);
    } on ApiException catch (e) {
      state = state.copyWith(items: previous, error: e.message);
      rethrow;
    } catch (_) {
      state = state.copyWith(items: previous);
      rethrow;
    }
  }
}

final hospitalBagProvider =
    NotifierProvider<HospitalBagNotifier, HospitalBagState>(
  HospitalBagNotifier.new,
);
