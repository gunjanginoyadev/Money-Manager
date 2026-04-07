import 'dart:math' as math;

import 'package:intl/intl.dart';

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

  /// When **N** is unset (0), pace across ~one “outing” per week still left in the **budget period**.
  static int inferredWeeklySlotsFromDaysLeft(int daysLeftInBudgetPeriod) {
    if (daysLeftInBudgetPeriod <= 0) return 1;
    return math.max(1, (daysLeftInBudgetPeriod / 7.0).ceil());
  }

  /// Uses your **N** when it is set (positive); otherwise [inferredWeeklySlotsFromDaysLeft].
  static int effectiveOutingCountForPacing({
    required int outingsRemaining,
    required int daysLeftInBudgetPeriod,
  }) {
    if (outingsRemaining > 0) return outingsRemaining;
    return inferredWeeklySlotsFromDaysLeft(daysLeftInBudgetPeriod);
  }

  /// Single-purchase cap: min(remaining Wants **R**, **(R÷effectiveN)×0.8**).
  static double suggestedSpendCap({
    required double remainingWants,
    required int outingsRemaining,
    required int daysLeftInBudgetPeriod,
  }) {
    if (remainingWants <= 0) return 0;
    final n = effectiveOutingCountForPacing(
      outingsRemaining: outingsRemaining,
      daysLeftInBudgetPeriod: daysLeftInBudgetPeriod,
    );
    final perBuffered = (remainingWants / n) * 0.8;
    return math.min(remainingWants, perBuffered);
  }

  /// Wants check: budget − spent − new expense; per-outing hint when [outingsRemaining] > 0.
  ExpenseDecision evaluateSpendBudget({
    required double monthlySpendBudget,
    required double spentThisMonth,
    required double newExpense,
    required int outingsRemaining,
    required int daysLeftInBudgetPeriod,
    String expenseLabel = 'This expense',
    DateTime? now,
  }) {
    if (monthlySpendBudget <= 0) {
      return ExpenseDecision(
        status: DecisionStatus.notSafe,
        remainingBalance: 0,
        endOfMonthProjection: 0,
        message:
            'Your Wants target (30% of income) is zero. Log income in this budget period or adjust the 50-30-20 baseline on Home.',
        availableBefore: 0,
        expenseAmount: newExpense,
        suggestedSpendCap: null,
      );
    }

    final availableBefore = monthlySpendBudget - spentThisMonth;
    final effectiveN = DecisionEngine.effectiveOutingCountForPacing(
      outingsRemaining: outingsRemaining,
      daysLeftInBudgetPeriod: daysLeftInBudgetPeriod,
    );
    final suggestedCap = DecisionEngine.suggestedSpendCap(
      remainingWants: availableBefore,
      outingsRemaining: outingsRemaining,
      daysLeftInBudgetPeriod: daysLeftInBudgetPeriod,
    );
    final remaining = availableBefore - newExpense;
    final projection = remaining;
    final tightThreshold = monthlySpendBudget * 0.1;

    if (remaining < 0) {
      final over = remaining.abs();
      return ExpenseDecision(
        status: DecisionStatus.notSafe,
        remainingBalance: remaining,
        endOfMonthProjection: projection,
        availableBefore: availableBefore,
        expenseAmount: newExpense,
        suggestedSpendCap: suggestedCap > 0 ? suggestedCap : null,
        message:
            '"$expenseLabel" (${_fmt(newExpense)}) is ${_fmt(over)} more than you have left in your Wants budget (${_fmt(availableBefore)}). '
            'Try to keep similar spends to about ${_fmt(suggestedCap)} or less '
            '${outingsRemaining > 0 ? 'for each of your $outingsRemaining planned outing(s).' : '(we spread what is left across about $effectiveN week(s) in this budget period until you add how many outings you expect on the Spend tab).'}.',
      );
    }

    if (newExpense > suggestedCap + 0.01 && suggestedCap > 0) {
      final overPreferred = newExpense - suggestedCap;
      final pacingHint = outingsRemaining > 0
          ? 'based on $outingsRemaining outing(s) you said you have left'
          : 'based on the weeks left in this budget period — add your outing count on the Spend tab for a tighter number';
      return ExpenseDecision(
        status: DecisionStatus.okay,
        remainingBalance: remaining,
        endOfMonthProjection: projection,
        availableBefore: availableBefore,
        expenseAmount: newExpense,
        suggestedSpendCap: suggestedCap,
        message:
            '"$expenseLabel" (${_fmt(newExpense)}) fits your overall Wants budget, but it is ${_fmt(overPreferred)} above a comfortable single amount of about ${_fmt(suggestedCap)} ($pacingHint). '
            'If you can, aim closer to ${_fmt(suggestedCap)} so the rest of this budget period is easier.',
      );
    }

    if (remaining < tightThreshold) {
      return ExpenseDecision(
        status: DecisionStatus.okay,
        remainingBalance: remaining,
        endOfMonthProjection: projection,
        availableBefore: availableBefore,
        expenseAmount: newExpense,
        suggestedSpendCap: suggestedCap,
        message:
            '"$expenseLabel" fits, but only ${_fmt(remaining)} would remain in your Wants budget.',
      );
    }

    return ExpenseDecision(
      status: DecisionStatus.safe,
      remainingBalance: remaining,
      endOfMonthProjection: projection,
      availableBefore: availableBefore,
      expenseAmount: newExpense,
      suggestedSpendCap: suggestedCap,
      message:
          '"$expenseLabel" is within your Wants plan. You would still have about ${_fmt(remaining)} left after.',
    );
  }
}
