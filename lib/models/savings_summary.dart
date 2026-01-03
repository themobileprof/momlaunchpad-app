/// Savings summary model
class SavingsSummary {
  final DateTime? expectedDeliveryDate;
  final double savingsGoal;
  final double totalSaved;
  final double progressPercentage;
  final int daysUntilDelivery;

  SavingsSummary({
    this.expectedDeliveryDate,
    required this.savingsGoal,
    required this.totalSaved,
    required this.progressPercentage,
    required this.daysUntilDelivery,
  });

  factory SavingsSummary.fromJson(Map<String, dynamic> json) {
    return SavingsSummary(
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.parse(json['expected_delivery_date'] as String)
          : null,
      savingsGoal: (json['savings_goal'] as num?)?.toDouble() ?? 0.0,
      totalSaved: (json['total_saved'] as num?)?.toDouble() ?? 0.0,
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      daysUntilDelivery: json['days_until_delivery'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (expectedDeliveryDate != null)
        'expected_delivery_date': expectedDeliveryDate!.toIso8601String(),
      'savings_goal': savingsGoal,
      'total_saved': totalSaved,
      'progress_percentage': progressPercentage,
      'days_until_delivery': daysUntilDelivery,
    };
  }
}
