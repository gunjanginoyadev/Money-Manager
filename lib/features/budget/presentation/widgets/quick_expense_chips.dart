import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/models/transaction_entry.dart';
import '../viewmodels/budget_view_model.dart';
import 'manage_quick_add_sheet.dart';

/// One-tap debits for common spends — ties into the same flow as full “Add transaction”.
class QuickExpenseChips extends StatelessWidget {
  const QuickExpenseChips({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    final presets = vm.quickAddPresets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'QUICK ADD',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            TextButton(
              onPressed: vm.isLoading
                  ? null
                  : () => showManageQuickAddSheet(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Edit',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (presets.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'No shortcuts yet. Tap Edit to add amounts you use often.',
              style: GoogleFonts.sora(
                fontSize: 12,
                height: 1.35,
                color: AppColors.textSoft,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((p) {
              final label = p.chipLabel;
              return Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(99),
                child: InkWell(
                  onTap: vm.isLoading
                      ? null
                      : () => vm.addTransaction(
                            title: p.title,
                            amount: p.amount,
                            type: TransactionType.debit,
                            spendingKind: p.spendingKind,
                            subCategory: p.subCategory,
                            paymentMethod: PaymentMethod.online,
                          ),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
