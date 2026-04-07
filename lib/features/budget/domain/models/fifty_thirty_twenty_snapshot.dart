/// 50-30-20 budget targets vs actual spending for a month.
class FiftyThirtyTwentySnapshot {
  const FiftyThirtyTwentySnapshot({
    required this.incomeBaseline,
    required this.targetNeeds,
    required this.targetWants,
    required this.targetSavings,
    required this.spentNeeds,
    required this.spentWants,
    required this.spentSavings,
    required this.spentOther,
  });

  /// Usually [BudgetProfile.monthlyIncome], or recorded income if zero.
  final double incomeBaseline;

  final double targetNeeds;
  final double targetWants;
  final double targetSavings;

  /// Debit totals by bucket (Needs / Wants / Savings). [spentOther] is uncategorized.
  final double spentNeeds;
  final double spentWants;
  final double spentSavings;
  final double spentOther;

  double get ratioNeeds =>
      incomeBaseline > 0 ? spentNeeds / incomeBaseline : 0;
  double get ratioWants =>
      incomeBaseline > 0 ? spentWants / incomeBaseline : 0;
  double get ratioSavings =>
      incomeBaseline > 0 ? spentSavings / incomeBaseline : 0;

  bool get needsOverTarget => spentNeeds > targetNeeds + 0.01;
  bool get wantsOverTarget => spentWants > targetWants + 0.01;
  bool get savingsOverTarget => spentSavings > targetSavings + 0.01;
}
