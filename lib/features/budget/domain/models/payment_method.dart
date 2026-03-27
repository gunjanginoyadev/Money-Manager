/// How the income or expense was paid (record-keeping).
enum PaymentMethod {
  online,
  cash,
}

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.online:
        return 'Online';
      case PaymentMethod.cash:
        return 'Cash';
    }
  }
}

PaymentMethod? parsePaymentMethod(Object? raw) {
  if (raw == null || raw is! String) return null;
  for (final v in PaymentMethod.values) {
    if (v.name == raw) return v;
  }
  return null;
}
