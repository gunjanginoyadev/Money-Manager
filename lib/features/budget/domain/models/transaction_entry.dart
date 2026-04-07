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
    this.regretScore,
    this.regretPromptAt,
    this.regretAnswered = false,
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

  /// Post-purchase feedback score for **Want** expenses: -2..+2.
  final int? regretScore;

  /// When to ask the “was it worth it?” prompt (usually createdAt/txDate + 24h).
  final DateTime? regretPromptAt;

  /// Whether the user has answered the prompt (prevents re-asking).
  final bool regretAnswered;

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
        'regretScore': regretScore,
        'regretPromptAt': regretPromptAt?.toIso8601String(),
        'regretAnswered': regretAnswered,
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
    final rpRaw = json['regretPromptAt'] as String?;
    final rpParsed = rpRaw != null ? DateTime.tryParse(rpRaw) : null;
    final rawScore = json['regretScore'];
    final score =
        rawScore is num ? rawScore.toInt().clamp(-2, 2) : null;
    final answered = (json['regretAnswered'] as bool?) ?? false;

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
      regretScore: score,
      regretPromptAt: rpParsed,
      regretAnswered: answered,
    );
  }

  TransactionEntry copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    DateTime? transactionDate,
    String? category,
    String? note,
    SpendingKind? spendingKind,
    String? subCategory,
    String? incomeCategory,
    PaymentMethod? paymentMethod,
    int? regretScore,
    DateTime? regretPromptAt,
    bool? regretAnswered,
  }) {
    return TransactionEntry(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      createdAt: createdAt,
      transactionDate: transactionDate ?? this.transactionDate,
      category: category ?? this.category,
      note: note ?? this.note,
      spendingKind: spendingKind ?? this.spendingKind,
      subCategory: subCategory ?? this.subCategory,
      incomeCategory: incomeCategory ?? this.incomeCategory,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      regretScore: regretScore ?? this.regretScore,
      regretPromptAt: regretPromptAt ?? this.regretPromptAt,
      regretAnswered: regretAnswered ?? this.regretAnswered,
    );
  }
}
