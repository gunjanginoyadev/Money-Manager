/// What income figure 50-30-20 targets on Home are based on.
enum FiftyThirtyBaselineMode {
  /// [BudgetProfile.monthlyIncome] (falls back to recorded month income if unset).
  profileSalary,

  /// Sum of credit (income) transactions for the selected month — matches “salary I logged this month”.
  monthIncomeEntries,

  /// 20% of [BudgetProfile.monthlyIncome] — same cap as “Can I spend?”.
  spendPool,
}

extension FiftyThirtyBaselineModeX on FiftyThirtyBaselineMode {
  String get storageValue => name;
}

FiftyThirtyBaselineMode fiftyThirtyBaselineModeFromStorage(String? raw) {
  switch (raw) {
    case 'profileSalary':
      return FiftyThirtyBaselineMode.profileSalary;
    case 'spendPool':
      return FiftyThirtyBaselineMode.spendPool;
    case 'monthIncomeEntries':
    default:
      return FiftyThirtyBaselineMode.monthIncomeEntries;
  }
}
