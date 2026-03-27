import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_branding.dart';
import '../../../../core/layout/home_shell_insets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/month_utils.dart';
import '../../domain/models/fifty_thirty_twenty_snapshot.dart';
import '../../domain/models/transaction_entry.dart';
import '../viewmodels/budget_view_model.dart';
import '../widgets/add_transaction_sheet.dart';

/// Home: summary, 50-30-20 insight, recent transactions.
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  static void _openAdd(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    final profile = vm.profile;
    if (profile == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final month = MonthUtils.startOfMonth(now);
    final snap = vm.fiftyThirtyTwentyForMonth(month);
    final recent = vm.transactionsForMonth(month).take(5).toList();
    final totalBalance = vm.lifetimeNet;
    final monthIncome = vm.totalReceivedInMonth(month);
    final monthExpenses = vm.totalSpentInMonth(month);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    kAppDisplayName,
                    style: GoogleFonts.sora(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: vm.isLoading ? null : () => _openAdd(context),
                    icon: const Icon(Icons.add_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryGlow,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: ListView(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  HomeShellInsets.bottomNavHeight(context) + 4,
                ),
                children: [
                  _SummaryCard(
                    totalBalance: totalBalance,
                    income: monthIncome,
                    expenses: monthExpenses,
                  ),
                  const SizedBox(height: 16),
                  _FiftyThirtyTwentyCard(snapshot: snap),
                  const SizedBox(height: 20),
                  Text(
                    'Recent transactions',
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (recent.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'No transactions this month yet. Tap + to add one.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          color: AppColors.textSoft,
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < recent.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                indent: 56,
                                color: AppColors.border,
                              ),
                            _HomeTxRow(item: recent[i]),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          context.read<BudgetViewModel>().requestTab(1),
                      child: const Text('View all in Report'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalBalance,
    required this.income,
    required this.expenses,
  });

  final double totalBalance;
  final double income;
  final double expenses;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F32), Color(0xFF222840)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2E3A5A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL BALANCE',
            style: GoogleFonts.sora(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.formatRupee(totalBalance),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          Text(
            'All-time net (income − expenses)',
            style: GoogleFonts.sora(
              fontSize: 12,
              color: AppColors.textSoft,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Income (month)',
                  value: CurrencyFormatter.formatRupee(income),
                  color: AppColors.safe,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Expenses (month)',
                  value: CurrencyFormatter.formatRupee(expenses),
                  color: AppColors.debit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.sora(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FiftyThirtyTwentyCard extends StatelessWidget {
  const _FiftyThirtyTwentyCard({required this.snapshot});

  final FiftyThirtyTwentySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final b = snapshot.incomeBaseline;
    if (b <= 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Set monthly income in your profile to use the 50-30-20 view.',
          style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSoft),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '50 · 30 · 20 budget',
            style: GoogleFonts.sora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Targets are 50% Needs, 30% Wants, 20% Savings vs your monthly income.',
            style: GoogleFonts.sora(
              fontSize: 11,
              height: 1.35,
              color: AppColors.textSoft,
            ),
          ),
          const SizedBox(height: 14),
          _BarRow(
            label: 'Needs',
            spent: snapshot.spentNeeds,
            target: snapshot.targetNeeds,
            color: AppColors.safe,
            over: snapshot.needsOver50,
          ),
          const SizedBox(height: 10),
          _BarRow(
            label: 'Wants',
            spent: snapshot.spentWants,
            target: snapshot.targetWants,
            color: AppColors.warn,
            over: snapshot.wantsOver30,
          ),
          const SizedBox(height: 10),
          _BarRow(
            label: 'Savings',
            spent: snapshot.spentSavings,
            target: snapshot.targetSavings,
            color: AppColors.primary,
            over: snapshot.savingsOver20,
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.spent,
    required this.target,
    required this.color,
    required this.over,
  });

  final String label;
  final double spent;
  final double target;
  final Color color;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final pct = target > 0 ? (spent / target).clamp(0.0, 2.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            Text(
              '${CurrencyFormatter.formatRupee(spent)} / ${CurrencyFormatter.formatRupee(target)}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: over ? AppColors.debit : AppColors.textSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: pct > 1 ? 1.0 : pct,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              over ? AppColors.debit : color,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeTxRow extends StatelessWidget {
  const _HomeTxRow({required this.item});

  final TransactionEntry item;

  @override
  Widget build(BuildContext context) {
    final c = item.isCredit ? AppColors.safe : AppColors.danger;
    final d = item.effectiveDate.toLocal();
    final dateStr = '${d.day}/${d.month}/${d.year}';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      title: Text(
        item.title,
        style: GoogleFonts.sora(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.text,
        ),
      ),
      subtitle: Text(
        '${item.displayCategoryLine} · $dateStr',
        style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: Text(
        '${item.isCredit ? '+' : '-'} ${CurrencyFormatter.formatRupee(item.amount)}',
        style: GoogleFonts.jetBrainsMono(
          color: c,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
