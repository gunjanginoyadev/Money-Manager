import 'payment_method.dart';
import 'spending_kind.dart';

enum TransactionType { credit, debit }

class TransactionEntry {
  const TransactionEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.transactionDate,
    this.category,
    this.note,
    this.spendingKind,
    this.subCategory,
    this.incomeCategory,
    this.paymentMethod,
  });

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime createdAt;

  /// Business date (e.g. when the expense happened). Defaults to [createdAt] if null.
  final DateTime? transactionDate;

  DateTime get effectiveDate => transactionDate ?? createdAt;

  /// Legacy / display catch-all; prefer [spendingKind]+[subCategory] or [incomeCategory].
  final String? category;
  final String? note;

  /// Set for debit expenses (need / want / saving / other).
  final SpendingKind? spendingKind;

  /// Sub-label under [spendingKind], e.g. "Groceries".
  final String? subCategory;

  /// For credits: e.g. Salary, Freelance.
  final String? incomeCategory;

  /// Online transfer vs cash (optional for legacy data).
  final PaymentMethod? paymentMethod;

  bool get isCredit => type == TransactionType.credit;

  /// Line shown in lists and PDF.
  String get displayCategoryLine {
    String base;
    if (isCredit) {
      base = incomeCategory ?? category ?? 'Income';
    } else if (spendingKind != null) {
      final sub = subCategory?.trim();
      if (sub != null && sub.isNotEmpty) {
        base = '${spendingKind!.label} · $sub';
      } else {
        base = spendingKind!.label;
      }
    } else {
      base = category ?? 'Expense';
    }
    if (paymentMethod != null) {
      return '$base · ${paymentMethod!.label}';
    }
    return base;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'transactionDate': transactionDate?.toIso8601String(),
        'category': category,
        'note': note,
        'spendingKind': spendingKind?.name,
        'subCategory': subCategory,
        'incomeCategory': incomeCategory,
        'paymentMethod': paymentMethod?.name,
      };

  factory TransactionEntry.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final type = typeStr == TransactionType.credit.name
        ? TransactionType.credit
        : TransactionType.debit;

    final legacyCat = json['category'] as String?;
    final sk = parseSpendingKind(json['spendingKind']);
    final sub = json['subCategory'] as String?;
    final inc = json['incomeCategory'] as String?;
    final pm = parsePaymentMethod(json['paymentMethod']);

    final created =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();
    final txRaw = json['transactionDate'] as String?;
    final txParsed = txRaw != null ? DateTime.tryParse(txRaw) : null;

    return TransactionEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      type: type,
      createdAt: created,
      transactionDate: txParsed,
      category: legacyCat,
      note: json['note'] as String?,
      spendingKind: sk,
      subCategory: sub,
      incomeCategory: inc ??
          (type == TransactionType.credit ? legacyCat : null),
      paymentMethod: pm,
    );
  }
}
