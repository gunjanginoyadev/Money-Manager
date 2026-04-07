import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/transaction_entry.dart';
import '../viewmodels/budget_view_model.dart';

class RegretPromptSheet extends StatelessWidget {
  const RegretPromptSheet({super.key, required this.transaction});

  final TransactionEntry transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              'Quick check 👀',
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yesterday you spent ${CurrencyFormatter.formatRupee(t.amount)} on ${t.title}.',
              style: GoogleFonts.sora(
                fontSize: 12,
                height: 1.35,
                color: AppColors.textSoft,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Was it worth it?',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RegretChoice(
                  label: '😍 Loved it',
                  score: 2,
                  transactionId: t.id,
                ),
                _RegretChoice(
                  label: '🙂 Worth it',
                  score: 1,
                  transactionId: t.id,
                ),
                _RegretChoice(
                  label: '😐 Okay',
                  score: 0,
                  transactionId: t.id,
                ),
                _RegretChoice(
                  label: '😕 Not worth',
                  score: -1,
                  transactionId: t.id,
                ),
                _RegretChoice(
                  label: '😤 Regret',
                  score: -2,
                  transactionId: t.id,
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
              ),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegretChoice extends StatelessWidget {
  const _RegretChoice({
    required this.label,
    required this.score,
    required this.transactionId,
  });

  final String label;
  final int score;
  final String transactionId;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<BudgetViewModel>();
    final disabled = vm.isLoading;
    final Color border;
    if (score >= 2) {
      border = AppColors.safe.withValues(alpha: 0.6);
    } else if (score == 1) {
      border = AppColors.safe.withValues(alpha: 0.35);
    } else if (score == 0) {
      border = AppColors.border.withValues(alpha: 0.9);
    } else if (score == -1) {
      border = AppColors.warn.withValues(alpha: 0.55);
    } else {
      border = AppColors.danger.withValues(alpha: 0.6);
    }

    return OutlinedButton(
      onPressed: disabled
          ? null
          : () async {
              await vm.submitRegretScore(
                transactionId: transactionId,
                score: score,
              );
              if (context.mounted) Navigator.of(context).pop();
            },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: border),
        foregroundColor: AppColors.text,
        backgroundColor: AppColors.surface2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 12.5),
      ),
    );
  }
}

