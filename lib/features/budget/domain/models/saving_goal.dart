enum GoalType { short, mid, long }

GoalType goalTypeFromJson(Object? raw) {
  if (raw is! String) return GoalType.mid;
  for (final v in GoalType.values) {
    if (v.name == raw) return v;
  }
  return GoalType.mid;
}

class SavingGoal {
  const SavingGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.type,
    required this.createdAt,
    this.targetDate,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final GoalType type;
  final DateTime createdAt;
  final DateTime? targetDate;
  final bool isCompleted;

  double get progressPct =>
      targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0.0, 1.0);

  double get remaining => (targetAmount - savedAmount).clamp(0.0, targetAmount);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'targetDate': targetDate?.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory SavingGoal.fromJson(Map<String, dynamic> json) {
    final created =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();
    final tdRaw = json['targetDate'] as String?;
    final td = tdRaw != null ? DateTime.tryParse(tdRaw) : null;
    return SavingGoal(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
      savedAmount: (json['savedAmount'] as num?)?.toDouble() ?? 0,
      type: goalTypeFromJson(json['type']),
      createdAt: created,
      targetDate: td,
      isCompleted: (json['isCompleted'] as bool?) ?? false,
    );
  }

  SavingGoal copyWith({
    String? title,
    double? targetAmount,
    double? savedAmount,
    GoalType? type,
    DateTime? targetDate,
    bool? isCompleted,
  }) {
    return SavingGoal(
      id: id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      type: type ?? this.type,
      createdAt: createdAt,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

