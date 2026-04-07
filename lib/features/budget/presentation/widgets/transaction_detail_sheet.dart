import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/spending_kind.dart';
import '../../domain/models/transaction_entry.dart';

/// Shows income / expense details in a bottom sheet (Home Recent, Report list).
bool _shouldShowSeparateLoggedAt(TransactionEntry t) {
  final a = t.effectiveDate.toLocal();
  final b = t.createdAt.toLocal();
  if (a.year != b.year || a.month != b.month || a.day != b.day) {
    return true;
  }
  if (a.hour != b.hour || a.minute != b.minute) return true;
  return false;
}

void showTransactionDetailSheet(BuildContext context, TransactionEntry t) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TransactionDetailSheet(transaction: t),
  );
}

class _TransactionDetailSheet extends StatelessWidget {
  const _TransactionDetailSheet({required this.transaction});

  final TransactionEntry transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isCredit = t.isCredit;
    final amountColor = isCredit ? AppColors.safe : AppColors.danger;
    final typeLabel = isCredit ? 'Income' : 'Expense';
    final amountPrefix = isCredit ? '+' : '−';
    final localEffective = t.effectiveDate.toLocal();
    final localCreated = t.createdAt.toLocal();
    final dateFmt = DateFormat('d MMM yyyy · h:mm a');

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Transaction',
                        style: GoogleFonts.sora(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCredit
                              ? AppColors.safe.withValues(alpha: 0.15)
                              : AppColors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCredit
                                ? AppColors.safe.withValues(alpha: 0.35)
                                : AppColors.danger.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          typeLabel,
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: amountColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '$amountPrefix ${CurrencyFormatter.formatRupee(t.amount)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: amountColor,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DetailBlock(
                        label: 'Title',
                        value: t.title.isEmpty ? '—' : t.title,
                      ),
                      _DetailBlock(
                        label: 'Category & payment',
                        value: t.displayCategoryLine,
                      ),
                      _DetailBlock(
                        label: 'Transaction date',
                        value: dateFmt.format(localEffective),
                      ),
                      if (_shouldShowSeparateLoggedAt(t))
                        _DetailBlock(
                          label: 'Logged in app',
                          value: dateFmt.format(localCreated),
                        ),
                      if (t.note != null && t.note!.trim().isNotEmpty)
                        _DetailBlock(
                          label: 'Note',
                          value: t.note!.trim(),
                        ),
                      if (!isCredit &&
                          t.spendingKind == SpendingKind.want &&
                          t.regretScore != null)
                        _DetailBlock(
                          label: 'Worth it? (Want)',
                          value: '${t.regretScore} / +2',
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'ID · ${t.id}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.sora(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
