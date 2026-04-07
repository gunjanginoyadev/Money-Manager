import 'spending_kind.dart';

/// One-tap expense shortcut on Home (amount + title + classification).
class QuickAddPreset {
  const QuickAddPreset({
    required this.amount,
    required this.title,
    required this.spendingKind,
    required this.subCategory,
  });

  final double amount;
  final String title;
  final SpendingKind spendingKind;
  final String subCategory;

  String get chipLabel {
    final a = amount == amount.roundToDouble()
        ? amount.round().toString()
        : amount.toString();
    return '₹$a · $title';
  }

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'title': title,
        'spendingKind': spendingKind.name,
        'subCategory': subCategory,
      };

  factory QuickAddPreset.fromJson(Map<String, dynamic> json) {
    final sk = parseSpendingKind(json['spendingKind']) ?? SpendingKind.want;
    final subs = spendingSubcategoriesByKind[sk] ?? const ['Other'];
    final rawSub = (json['subCategory'] as String?)?.trim();
    final sub = (rawSub != null && rawSub.isNotEmpty && subs.contains(rawSub))
        ? rawSub
        : subs.first;
    return QuickAddPreset(
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      title: (json['title'] as String?)?.trim() ?? '',
      spendingKind: sk,
      subCategory: sub,
    );
  }
}

/// Default shortcuts when nothing is stored yet.
const List<QuickAddPreset> kDefaultQuickAddPresets = [
  QuickAddPreset(
    amount: 100,
    title: 'Chai',
    spendingKind: SpendingKind.want,
    subCategory: 'Dining out',
  ),
  QuickAddPreset(
    amount: 500,
    title: 'Food',
    spendingKind: SpendingKind.want,
    subCategory: 'Dining out',
  ),
  QuickAddPreset(
    amount: 200,
    title: 'Commute',
    spendingKind: SpendingKind.need,
    subCategory: 'Transport',
  ),
];
