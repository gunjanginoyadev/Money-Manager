class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.name,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String name;
  final double amount;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ExpenseEntry.fromJson(Map<String, dynamic> json) {
    return ExpenseEntry(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
