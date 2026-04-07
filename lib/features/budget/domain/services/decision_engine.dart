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

  /// When **N** is unset (0), pace across ~one “outing” per **calendar week** still
  /// left in the month so early-month suggestions do not use the full **R** at once.
  static int inferredWeeklySlotsRemainingInMonth([DateTime? now]) {
    final today = now ?? DateTime.now();
    final last = DateTime(today.year, today.month + 1, 0);
    final daysLeft = last.day - today.day + 1;
    if (daysLeft <= 0) return 1;
    return math.max(1, (daysLeft / 7.0).ceil());
  }

  /// Uses your **N** when it is set (positive); otherwise [inferredWeeklySlotsRemainingInMonth].
  static int effectiveOutingCountForPacing({
    required int outingsRemaining,
    DateTime? now,
  }) {
    if (outingsRemaining > 0) return outingsRemaining;
    return inferredWeeklySlotsRemainingInMonth(now);
  }

  /// Single-purchase cap: min(remaining Wants **R**, **(R÷effectiveN)×0.8**).
  static double suggestedSpendCap({
    required double remainingWants,
    required int outingsRemaining,
    DateTime? now,
  }) {
    if (remainingWants <= 0) return 0;
    final n = effectiveOutingCountForPacing(
      outingsRemaining: outingsRemaining,
      now: now,
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
    String expenseLabel = 'This expense',
    DateTime? now,
  }) {
    if (monthlySpendBudget <= 0) {
      return ExpenseDecision(
        status: DecisionStatus.notSafe,
        remainingBalance: 0,
        endOfMonthProjection: 0,
        message:
            'Your Wants target (30% of income) is zero. Log income this month or adjust the 50-30-20 baseline on Home.',
        availableBefore: 0,
        expenseAmount: newExpense,
        suggestedSpendCap: null,
      );
    }

    final clock = now ?? DateTime.now();
    final availableBefore = monthlySpendBudget - spentThisMonth;
    final effectiveN = DecisionEngine.effectiveOutingCountForPacing(
      outingsRemaining: outingsRemaining,
      now: clock,
    );
    final suggestedCap = DecisionEngine.suggestedSpendCap(
      remainingWants: availableBefore,
      outingsRemaining: outingsRemaining,
      now: clock,
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
            '${outingsRemaining > 0 ? 'for each of your $outingsRemaining planned outing(s).' : '(we spread what is left across about $effectiveN week(s) until you add how many outings you expect on the Spend tab).'}.',
      );
    }

    if (newExpense > suggestedCap + 0.01 && suggestedCap > 0) {
      final overPreferred = newExpense - suggestedCap;
      final pacingHint = outingsRemaining > 0
          ? 'based on $outingsRemaining outing(s) you said you have left'
          : 'based on the weeks left this month — add your outing count on the Spend tab for a tighter number';
      return ExpenseDecision(
        status: DecisionStatus.okay,
        remainingBalance: remaining,
        endOfMonthProjection: projection,
        availableBefore: availableBefore,
        expenseAmount: newExpense,
        suggestedSpendCap: suggestedCap,
        message:
            '"$expenseLabel" (${_fmt(newExpense)}) fits your overall Wants budget, but it is ${_fmt(overPreferred)} above a comfortable single amount of about ${_fmt(suggestedCap)} ($pacingHint). '
            'If you can, aim closer to ${_fmt(suggestedCap)} so the rest of the month is easier.',
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
