/// What income figure 50-30-20 targets on Home are based on.
enum FiftyThirtyBaselineMode {
  /// [BudgetProfile.monthlyIncome] (falls back to recorded month income if unset).
  profileSalary,

  /// Sum of credit (income) transactions for the selected month only.
  monthIncomeEntries,
}

extension FiftyThirtyBaselineModeX on FiftyThirtyBaselineMode {
  String get storageValue => name;
}

FiftyThirtyBaselineMode fiftyThirtyBaselineModeFromStorage(String? raw) {
  switch (raw) {
    case 'monthIncomeEntries':
      return FiftyThirtyBaselineMode.monthIncomeEntries;
    default:
      return FiftyThirtyBaselineMode.profileSalary;
  }
}
