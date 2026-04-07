import 'payment_method.dart';
import 'transaction_entry.dart';

/// Earned / spent / net by payment channel for a period (usually one month).
class MonthLiquiditySnapshot {
  const MonthLiquiditySnapshot({
    required this.creditCash,
    required this.creditOnline,
    required this.creditUnspecified,
    required this.debitCash,
    required this.debitOnline,
    required this.debitUnspecified,
  });

  final double creditCash;
  final double creditOnline;
  final double creditUnspecified;

  final double debitCash;
  final double debitOnline;
  final double debitUnspecified;

  double get netCash => creditCash - debitCash;
  double get netOnline => creditOnline - debitOnline;
  double get netUnspecified => creditUnspecified - debitUnspecified;

  double get totalEarned =>
      creditCash + creditOnline + creditUnspecified;
  double get totalSpent => debitCash + debitOnline + debitUnspecified;
  double get netMonth => totalEarned - totalSpent;

  bool get hasUnspecified =>
      creditUnspecified > 0.009 || debitUnspecified > 0.009;
}

/// Aggregates [transactions] (already filtered to the period you care about).
MonthLiquiditySnapshot liquiditySnapshotForTransactions(
  Iterable<TransactionEntry> transactions,
) {
  double cc = 0, co = 0, cu = 0, dc = 0, dou = 0, du = 0;
  for (final t in transactions) {
    final amount = t.amount;
    final pm = t.paymentMethod;
    if (t.isCredit) {
      switch (pm) {
        case PaymentMethod.cash:
          cc += amount;
        case PaymentMethod.online:
          co += amount;
        case null:
          cu += amount;
      }
    } else {
      switch (pm) {
        case PaymentMethod.cash:
          dc += amount;
        case PaymentMethod.online:
          dou += amount;
        case null:
          du += amount;
      }
    }
  }
  return MonthLiquiditySnapshot(
    creditCash: cc,
    creditOnline: co,
    creditUnspecified: cu,
    debitCash: dc,
    debitOnline: dou,
    debitUnspecified: du,
  );
}
