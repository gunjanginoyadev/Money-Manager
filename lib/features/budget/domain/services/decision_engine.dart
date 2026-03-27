import 'package:intl/intl.dart';

import '../models/budget_profile.dart';
import '../models/expense_decision.dart';

class DecisionEngine {
  const DecisionEngine();

  static String _fmt(num n) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(n);
  }

  ExpenseDecision evaluate({
    required BudgetProfile profile,
    required double effectiveMonthlyIncome,
    required double currentSpent,
    required double newExpense,
    String expenseLabel = 'This expense',
  }) {
    final availableBefore =
        effectiveMonthlyIncome - profile.totalObligations - currentSpent;
    final remaining = availableBefore - newExpense;
    final projection = remaining;

    if (remaining < 0) {
      final over = remaining.abs();
      return ExpenseDecision(
        status: DecisionStatus.notSafe,
        remainingBalance: remaining,
        endOfMonthProjection: projection,
        availableBefore: availableBefore,
        expenseAmount: newExpense,
        message:
            '"$expenseLabel" would exceed your available budget by ${_fmt(over)}. '
            'This may impact your EMI or essential payments next month.',
      );
    }

    if (remaining <= profile.safetyBuffer) {
      return ExpenseDecision(
        status: DecisionStatus.okay,
        remainingBalance: remaining,
        endOfMonthProjection: projection,
        availableBefore: availableBefore,
        expenseAmount: newExpense,
        message:
            '"$expenseLabel" is possible, but it will dip into your safety buffer. '
            'Consider if this can wait or if you can find a cheaper option.',
      );
    }

    return ExpenseDecision(
      status: DecisionStatus.safe,
      remainingBalance: remaining,
      endOfMonthProjection: projection,
      availableBefore: availableBefore,
      expenseAmount: newExpense,
      message:
          '"$expenseLabel" is within your budget. You\'ll still have ${_fmt(remaining)} left, '
          'with your buffer intact. Enjoy! 🎉',
    );
  }
}
