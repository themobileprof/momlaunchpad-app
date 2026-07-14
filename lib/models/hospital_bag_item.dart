/// A single hospital / delivery bag checklist item.
class HospitalBagItem {
  final String id;
  final String label;
  final String category;
  final double? price;
  final bool isPacked;
  final int sortOrder;

  const HospitalBagItem({
    required this.id,
    required this.label,
    required this.category,
    this.price,
    required this.isPacked,
    required this.sortOrder,
  });

  factory HospitalBagItem.fromJson(Map<String, dynamic> json) {
    return HospitalBagItem(
      id: json['id'] as String,
      label: json['label'] as String,
      category: json['category'] as String? ?? 'other',
      price: (json['price'] as num?)?.toDouble(),
      isPacked: json['is_packed'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  HospitalBagItem copyWith({
    String? label,
    String? category,
    double? price,
    bool? isPacked,
    int? sortOrder,
    bool clearPrice = false,
  }) {
    return HospitalBagItem(
      id: id,
      label: label ?? this.label,
      category: category ?? this.category,
      price: clearPrice ? null : (price ?? this.price),
      isPacked: isPacked ?? this.isPacked,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// API response for GET /api/hospital-bag.
class HospitalBagList {
  final List<HospitalBagItem> items;
  final String currency;
  final int packedCount;
  final int totalCount;
  final double totalPrice;

  const HospitalBagList({
    required this.items,
    required this.currency,
    required this.packedCount,
    required this.totalCount,
    required this.totalPrice,
  });

  factory HospitalBagList.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return HospitalBagList(
      items: rawItems
          .map((item) => HospitalBagItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      currency: json['currency'] as String? ?? 'NGN',
      packedCount: json['packed_count'] as int? ?? 0,
      totalCount: json['total_count'] as int? ?? 0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
    );
  }

  double get progress =>
      totalCount == 0 ? 0 : packedCount / totalCount;
}

/// Display labels for checklist categories.
class HospitalBagCategory {
  HospitalBagCategory._();

  static const order = [
    'documents',
    'for_mom',
    'for_baby',
    'for_partner',
    'other',
  ];

  static String label(String category) {
    switch (category) {
      case 'documents':
        return 'Documents';
      case 'for_mom':
        return 'For you';
      case 'for_baby':
        return 'For baby';
      case 'for_partner':
        return 'For partner / support';
      case 'other':
        return 'Other';
      default:
        return 'Other';
    }
  }
}
