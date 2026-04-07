import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_branding.dart';
import '../../../../core/layout/home_shell_insets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/month_utils.dart';
import '../widgets/liquidity_breakdown_card.dart';
import '../../domain/models/fifty_thirty_baseline_mode.dart';
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
    final baselineMode = vm.fiftyThirtyBaselineMode;
    final recent = vm.transactionsForMonth(month).take(5).toList();
    final liquidity = vm.monthLiquidityForMonth(month);

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
                  _MonthScopeBanner(monthLabel: MonthUtils.formatMonthYear(month)),
                  const SizedBox(height: 12),
                  LiquidityBreakdownCard(
                    snapshot: liquidity,
                    title: 'This month',
                    subtitle:
                        'Each new month starts a fresh tally here. Older entries are not deleted — open Report and pick any month or date range.',
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'All-time net: ${CurrencyFormatter.formatRupee(vm.lifetimeNet)}',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              color: AppColors.textSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FiftyThirtyTwentyCard(
                    snapshot: snap,
                    baselineMode: baselineMode,
                    onBaselineModeChanged: vm.setFiftyThirtyBaselineMode,
                  ),
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

class _MonthScopeBanner extends StatelessWidget {
  const _MonthScopeBanner({required this.monthLabel});

  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tracking · $monthLabel',
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Home shows this calendar month only. Use Report for past months or custom ranges.',
            style: GoogleFonts.sora(
              fontSize: 11,
              height: 1.35,
              color: AppColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _BaselineModeToggle extends StatelessWidget {
  const _BaselineModeToggle({
    required this.selected,
    required this.onChanged,
  });

  final FiftyThirtyBaselineMode selected;
  final Future<void> Function(FiftyThirtyBaselineMode mode) onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<FiftyThirtyBaselineMode>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.primaryGlow,
        selectedForegroundColor: AppColors.primary,
        foregroundColor: AppColors.textSoft,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      segments: [
        ButtonSegment<FiftyThirtyBaselineMode>(
          value: FiftyThirtyBaselineMode.profileSalary,
          label: Text(
            'Profile salary',
            style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          tooltip: 'Uses monthly income from Profile setup',
        ),
        ButtonSegment<FiftyThirtyBaselineMode>(
          value: FiftyThirtyBaselineMode.monthIncomeEntries,
          label: Text(
            'Month income',
            style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          tooltip: 'Uses sum of income entries this month',
        ),
      ],
      selected: {selected},
      onSelectionChanged: (Set<FiftyThirtyBaselineMode> next) {
        onChanged(next.first);
      },
    );
  }
}

class _FiftyThirtyTwentyCard extends StatelessWidget {
  const _FiftyThirtyTwentyCard({
    required this.snapshot,
    required this.baselineMode,
    required this.onBaselineModeChanged,
  });

  final FiftyThirtyTwentySnapshot snapshot;
  final FiftyThirtyBaselineMode baselineMode;
  final Future<void> Function(FiftyThirtyBaselineMode mode) onBaselineModeChanged;

  @override
  Widget build(BuildContext context) {
    final b = snapshot.incomeBaseline;
    if (b <= 0) {
      final msg = baselineMode == FiftyThirtyBaselineMode.monthIncomeEntries
          ? 'No income recorded this month yet. Add a salary or income entry, or switch to Profile salary.'
          : 'Set monthly income in your profile (or add income this month) to use the 50-30-20 view.';
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BaselineModeToggle(
              selected: baselineMode,
              onChanged: onBaselineModeChanged,
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSoft),
            ),
          ],
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
          const SizedBox(height: 8),
          _BaselineModeToggle(
            selected: baselineMode,
            onChanged: onBaselineModeChanged,
          ),
          const SizedBox(height: 8),
          Text(
            baselineMode == FiftyThirtyBaselineMode.profileSalary
                ? 'Targets: 50% Needs, 30% Wants, 20% Savings vs your Profile monthly income.'
                : 'Targets: 50% Needs, 30% Wants, 20% Savings vs income recorded this month (credits).',
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
