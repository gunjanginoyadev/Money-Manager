/// Primary expense classification (50/30/20 style: need / want / saving + other).
enum SpendingKind {
  need,
  want,
  saving,
  other,
}

extension SpendingKindX on SpendingKind {
  String get label {
    switch (this) {
      case SpendingKind.need:
        return 'Need';
      case SpendingKind.want:
        return 'Want';
      case SpendingKind.saving:
        return 'Saving';
      case SpendingKind.other:
        return 'Other';
    }
  }

}

SpendingKind? parseSpendingKind(Object? raw) {
  if (raw == null || raw is! String) return null;
  for (final v in SpendingKind.values) {
    if (v.name == raw) return v;
  }
  return null;
}

/// Subcategories shown after the user picks a [SpendingKind].
const Map<SpendingKind, List<String>> spendingSubcategoriesByKind = {
  SpendingKind.need: [
    'Rent / Housing',
    'Utilities',
    'Groceries',
    'Transport',
    'Healthcare',
    'Insurance',
    'Loan EMI',
    'Other',
  ],
  SpendingKind.want: [
    'Dining out',
    'Entertainment',
    'Shopping',
    'Travel',
    'Subscriptions',
    'Hobbies',
    'Other',
  ],
  SpendingKind.saving: [
    'Emergency fund',
    'Investments',
    'Savings goal',
    'Transfer to savings',
    'Other',
  ],
  SpendingKind.other: [
    'Miscellaneous',
    'Fees',
    'Cash withdrawal',
    'Gift given',
    'Other',
  ],
};

const List<String> incomeCategories = [
  'Salary',
  'Freelance',
  'Business',
  'Gift',
  'Refund',
  'Other',
];
