import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/transaction_entry.dart';
import '../screens/add_transaction_screen.dart';
import '../viewmodels/budget_view_model.dart';

void openEditTransaction(BuildContext context, TransactionEntry entry) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => AddTransactionScreen(transactionToEdit: entry),
    ),
  );
}

Future<void> confirmDeleteTransaction(
  BuildContext context,
  TransactionEntry entry,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete transaction?'),
      content: Text(
        'This removes the entry from your activity and reports.',
        style: GoogleFonts.sora(fontSize: 13, height: 1.35),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await context.read<BudgetViewModel>().deleteTransaction(entry.id);
}
