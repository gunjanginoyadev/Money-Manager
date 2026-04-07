enum DecisionStatus { safe, okay, notSafe }

class ExpenseDecision {
  const ExpenseDecision({
    required this.status,
    required this.remainingBalance,
    required this.endOfMonthProjection,
    required this.message,
    required this.availableBefore,
    required this.expenseAmount,
    this.suggestedSpendCap,
  });

  final DecisionStatus status;
  final double remainingBalance;
  final double endOfMonthProjection;
  final String message;
  /// Room in the Wants budget before this hypothetical expense (30% cap − want-tagged spend so far).
  final double availableBefore;
  final double expenseAmount;

  /// Recommended max: min(remaining Wants, (R÷effectiveN)×0.8). If N is 0, effectiveN is about one slot per week left in the month.
  final double? suggestedSpendCap;
}
