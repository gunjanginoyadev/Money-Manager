import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/features/budget/domain/models/budget_profile.dart';
import 'package:money_manager/features/budget/domain/models/expense_decision.dart';
import 'package:money_manager/features/budget/domain/services/decision_engine.dart';

void main() {
  const profile = BudgetProfile(
    monthlyIncome: 50000,
    emi: 10000,
    rent: 12000,
    fixedBills: 5000,
    basicExpenses: 8000,
    safetyBuffer: 5000,
  );
  const engine = DecisionEngine();

  test('returns safe for healthy balance', () {
    final result = engine.evaluate(
      profile: profile,
      effectiveMonthlyIncome: 50000,
      currentSpent: 2000,
      newExpense: 3000,
    );
    expect(result.status, DecisionStatus.safe);
  });

  test('returns okay near safety buffer', () {
    final result = engine.evaluate(
      profile: profile,
      effectiveMonthlyIncome: 50000,
      currentSpent: 7000,
      newExpense: 3000,
    );
    expect(result.status, DecisionStatus.okay);
  });

  test('returns not safe when below zero', () {
    final result = engine.evaluate(
      profile: profile,
      effectiveMonthlyIncome: 50000,
      currentSpent: 18000,
      newExpense: 10000,
    );
    expect(result.status, DecisionStatus.notSafe);
  });
}
