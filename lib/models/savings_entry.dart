/// Savings entry model
class SavingsEntry {
  final String id;
  final double amount;
  final String description;
  final DateTime entryDate;
  final DateTime createdAt;

  SavingsEntry({
    required this.id,
    required this.amount,
    required this.description,
    required this.entryDate,
    required this.createdAt,
  });

  factory SavingsEntry.fromJson(Map<String, dynamic> json) {
    return SavingsEntry(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
      entryDate: json['entry_date'] != null
          ? DateTime.parse(json['entry_date'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'entry_date': entryDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
