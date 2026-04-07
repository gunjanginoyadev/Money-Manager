class SavingEntry {
  const SavingEntry({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
    this.transactionId,
  });

  final String id;
  final String goalId;
  final double amount;
  final DateTime date;
  final String? note;

  /// Linked `TransactionEntry.id` (Saving debit) when created from this app.
  final String? transactionId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'goalId': goalId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'transactionId': transactionId,
      };

  factory SavingEntry.fromJson(Map<String, dynamic> json) {
    final d = DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();
    return SavingEntry(
      id: json['id'] as String? ?? '',
      goalId: json['goalId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date: d,
      note: json['note'] as String?,
      transactionId: json['transactionId'] as String?,
    );
  }

  SavingEntry copyWith({
    double? amount,
    DateTime? date,
    String? note,
    String? transactionId,
  }) {
    return SavingEntry(
      id: id,
      goalId: goalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}

