import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/home_shell_insets.dart';
import '../../../../core/services/transaction_pdf_export.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/month_utils.dart';
import '../../domain/models/transaction_entry.dart';
import '../viewmodels/budget_view_model.dart';
import 'add_transaction_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';

/// Bank-style transaction history: month selector, list, PDF export.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  static void _openAddSheet(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const AddTransactionScreen(),
      ),
    );
  }

  static bool _canGoNextMonth(DateTime selected) {
    final next = DateTime(selected.year, selected.month + 1);
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    return !next.isAfter(thisMonth);
  }

  @override
  Widget build(BuildContext context) {
    final listBottomPad = HomeShellInsets.bottomNavHeight(context) + 4;
    final vm = context.watch<BudgetViewModel>();
    final profile = vm.profile;
    if (profile == null) return const SizedBox.shrink();

    final month = vm.activityMonth;
    final items = vm.transactionsForMonth(month);
    final monthLabel = MonthUtils.formatMonthYear(month);
    final canNext = _canGoNextMonth(month);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Activity',
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Add transaction',
                    onPressed:
                        vm.isLoading ? null : () => _openAddSheet(context),
                    icon: const Icon(Icons.add_rounded),
                    color: AppColors.primary,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryGlow,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Export PDF',
                    onPressed: items.isEmpty
                        ? null
                        : () => TransactionPdfExport.shareMonthStatement(
                              month: month,
                              items: items,
                              profile: profile,
                            ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    color: AppColors.primary,
                  ),
                  GestureDetector(
                    onTap: () =>
                        context.read<BudgetViewModel>().requestTab(2),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text('👤', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        context.read<BudgetViewModel>().setActivityMonth(
                              MonthUtils.addMonths(month, -1),
                            );
                      },
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: AppColors.text,
                    ),
                    Expanded(
                      child: Text(
                        monthLabel,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: !canNext
                          ? null
                          : () {
                              context.read<BudgetViewModel>().setActivityMonth(
                                    MonthUtils.addMonths(month, 1),
                                  );
                            },
                      icon: const Icon(Icons.chevron_right_rounded),
                      color: AppColors.text,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transactions',
                          style: GoogleFonts.sora(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (vm.isLoading)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: vm.isLoading && items.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: LoadingState(lines: 5),
                              )
                            : items.isEmpty
                                ? const EmptyState(
                                    title: 'No transactions this month',
                                    subtitle:
                                        'Tap the + button above to add income or expenses.',
                                    icon: Icons.receipt_long_outlined,
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.only(bottom: listBottomPad),
                                    physics: const ClampingScrollPhysics(),
                                    itemCount: items.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(
                                      height: 1,
                                      indent: 62,
                                      color: AppColors.border,
                                    ),
                                    itemBuilder: (context, i) {
                                      return _ActivityTxTile(item: items[i]);
                                    },
                                  ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTxTile extends StatelessWidget {
  const _ActivityTxTile({required this.item});

  final TransactionEntry item;

  @override
  Widget build(BuildContext context) {
    final color = item.isCredit ? AppColors.safe : AppColors.danger;
    final ts = item.createdAt.toLocal();
    final dateStr =
        '${ts.day} ${_months[ts.month - 1]}, ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          item.isCredit ? Icons.add_rounded : Icons.remove_rounded,
          color: color,
          size: 18,
        ),
      ),
      title: Text(
        item.title,
        style: GoogleFonts.sora(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        '${item.displayCategoryLine} · $dateStr',
        style: GoogleFonts.sora(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Text(
        '${item.isCredit ? '+' : '-'} ${CurrencyFormatter.formatRupee(item.amount)}',
        style: GoogleFonts.jetBrainsMono(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}
