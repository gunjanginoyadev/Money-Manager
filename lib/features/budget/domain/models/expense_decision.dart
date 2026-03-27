enum DecisionStatus { safe, okay, notSafe }

class ExpenseDecision {
  const ExpenseDecision({
    required this.status,
    required this.remainingBalance,
    required this.endOfMonthProjection,
    required this.message,
    required this.availableBefore,
    required this.expenseAmount,
  });

  final DecisionStatus status;
  final double remainingBalance;
  final double endOfMonthProjection;
  final String message;
  /// Disposable cash before this hypothetical expense (income − obligations − spent so far).
  final double availableBefore;
  final double expenseAmount;
}
