import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_branding.dart';
import '../../../../core/layout/home_shell_insets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/budget_period_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/budget_profile.dart';
import '../../domain/models/fifty_thirty_baseline_mode.dart';
import '../../domain/models/fifty_thirty_twenty_snapshot.dart';
import '../../domain/models/month_liquidity_snapshot.dart';
import '../../domain/models/spending_kind.dart';
import '../../domain/models/transaction_entry.dart';
import '../viewmodels/budget_view_model.dart';
import 'add_transaction_screen.dart';
import '../widgets/quick_expense_chips.dart';
import '../widgets/regret_prompt_sheet.dart';
import '../widgets/spend_timeline_chart.dart';
import '../widgets/transaction_actions.dart';
import '../widgets/transaction_detail_sheet.dart';
import 'saving_goal_screen.dart';

/// Home: hero balance, cash/online split, budget targets, timeline, quick add, recent.
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  static void _openAdd(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const AddTransactionScreen()),
    );
  }

  static String _splitPresetShort(BudgetProfile profile) {
    final n = (profile.splitNeeds * 100).round();
    final w = (profile.splitWants * 100).round();
    final s = (profile.splitSavings * 100).round();
    return '$n/$w/$s';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    final profile = vm.profile;
    if (profile == null) return const SizedBox.shrink();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final due = context.read<BudgetViewModel>().nextRegretPromptForSession();
      if (due == null) return;
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => RegretPromptSheet(transaction: due),
      );
    });

    final periodStart = vm.currentBudgetPeriodStart;
    final snap = vm.fiftyThirtyTwentyForMonth(periodStart);
    final baselineMode = vm.fiftyThirtyBaselineMode;
    final recent = vm.transactionsForMonth(periodStart).take(5).toList();
    final liquidity = vm.monthLiquidityForMonth(periodStart);
    final pay = profile.salaryDayOfMonth.clamp(1, 31);
    final rangeLabel = BudgetPeriodUtils.formatBudgetPeriodRange(
      periodStart,
      pay,
    );
    final daysLeft = BudgetPeriodUtils.daysLeftInclusiveInPeriod(
      DateTime.now(),
      pay,
    );
    final monthSpendTitle =
        '${DateFormat('MMMM').format(periodStart)} spending';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        titleSpacing: 24,
        title: Text(
          kAppDisplayName,
          style: GoogleFonts.sora(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.text,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: vm.isLoading ? null : () => _openAdd(context),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.add_rounded,
                    color: AppColors.onAccent,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            HomeShellInsets.bottomNavHeight(context) + 32,
          ),
          physics: const ClampingScrollPhysics(),
          children: [
            _PeriodBadge(rangeLabel: rangeLabel, daysLeft: daysLeft),
            const SizedBox(height: 20),
            _HeroBalanceCard(liquidity: liquidity),
            const SizedBox(height: 20),
            _CashOnlineSplit(snapshot: liquidity),
            const SizedBox(height: 20),
            _SavingGoalHomeCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SavingGoalScreen()),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'BUDGET TARGETS · ${_splitPresetShort(profile)}',
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 12),
            _FiftyThirtyTwentyCard(
              snapshot: snap,
              profile: profile,
              baselineMode: baselineMode,
              onBaselineModeChanged: vm.setFiftyThirtyBaselineMode,
            ),
            const SizedBox(height: 24),
            SpendTimelineChart(
              series: vm.dailyExpenseTotalsForBudgetPeriod(periodStart),
              monthSpendTitle: monthSpendTitle,
            ),
            const SizedBox(height: 24),
            const QuickExpenseChips(),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent',
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.read<BudgetViewModel>().requestTab(1),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View all →',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'No transactions in this budget period yet. Tap + to add one.',
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
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < recent.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border,
                        ),
                      _HomeTxRow(item: recent[i], menuEnabled: !vm.isLoading),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PeriodBadge extends StatelessWidget {
  const _PeriodBadge({required this.rangeLabel, required this.daysLeft});

  final String rangeLabel;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.55),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.3,
                ),
                children: [
                  TextSpan(
                    text: rangeLabel,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: '  ·  $daysLeft days left'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({required this.liquidity});

  final MonthLiquiditySnapshot liquidity;

  @override
  Widget build(BuildContext context) {
    final net = liquidity.netMonth;
    final earned = liquidity.totalEarned;
    final spent = liquidity.totalSpent;
    final netAbs = CurrencyFormatter.formatRupee(net.abs());
    final body = netAbs.replaceFirst('₹', '').trim();
    final netColor = net < 0 ? AppColors.debit : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NET LEFT',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (net < 0)
                      Text(
                        '-',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: netColor,
                        ),
                      ),
                    Text(
                      '₹',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: netColor.withValues(alpha: 0.65),
                      ),
                    ),
                    Text(
                      body,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -2,
                        color: netColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _HeroStatTile(
                      label: 'Earned',
                      value: CurrencyFormatter.formatRupee(earned),
                      valueColor: AppColors.safe,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HeroStatTile(
                      label: 'Spent',
                      value: CurrencyFormatter.formatRupee(spent),
                      valueColor: AppColors.debit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatTile extends StatelessWidget {
  const _HeroStatTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.sora(
              fontSize: 11,
              color: AppColors.textMuted,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashOnlineSplit extends StatelessWidget {
  const _CashOnlineSplit({required this.snapshot});

  final MonthLiquiditySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _SplitCard(
                title: 'Cash',
                credit: s.creditCash,
                debit: s.debitCash,
                left: s.netCash,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SplitCard(
                title: 'Online',
                credit: s.creditOnline,
                debit: s.debitOnline,
                left: s.netOnline,
              ),
            ),
          ],
        ),
        if (s.hasUnspecified) ...[
          const SizedBox(height: 8),
          Text(
            'Some entries have no payment method — totals above may not include them.',
            style: GoogleFonts.sora(
              fontSize: 11,
              height: 1.35,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _SplitCard extends StatelessWidget {
  const _SplitCard({
    required this.title,
    required this.credit,
    required this.debit,
    required this.left,
  });

  final String title;
  final double credit;
  final double debit;
  final double left;

  @override
  Widget build(BuildContext context) {
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
            title.toUpperCase(),
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _SplitLine(
            label: 'In',
            value: CurrencyFormatter.formatRupee(credit),
            color: AppColors.safe,
          ),
          const SizedBox(height: 6),
          _SplitLine(
            label: 'Out',
            value: CurrencyFormatter.formatRupee(debit),
            color: AppColors.debit,
          ),
          const SizedBox(height: 6),
          _SplitLine(
            label: 'Left',
            value: CurrencyFormatter.formatRupee(left),
            color: AppColors.text,
          ),
        ],
      ),
    );
  }
}

class _SplitLine extends StatelessWidget {
  const _SplitLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.sora(fontSize: 11, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SavingGoalHomeCard extends StatelessWidget {
  const _SavingGoalHomeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    final g = vm.savingGoal;
    if (g == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.flag_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your goal',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Create one active goal to track progress.',
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: vm.isLoading ? null : onTap,
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Set up →'),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: vm.isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your goal',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              g.title,
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${CurrencyFormatter.formatRupee(g.savedAmount)} / ${CurrencyFormatter.formatRupee(g.targetAmount)}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: g.progressPct,
                minHeight: 6,
                backgroundColor: AppColors.surface2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  g.isCompleted ? AppColors.safe : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              g.isCompleted
                  ? 'Completed 🎉'
                  : 'Remaining: ${CurrencyFormatter.formatRupee(g.remaining)}',
              style: GoogleFonts.sora(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiftyThirtyTwentyCard extends StatelessWidget {
  const _FiftyThirtyTwentyCard({
    required this.snapshot,
    required this.profile,
    required this.baselineMode,
    required this.onBaselineModeChanged,
  });

  final FiftyThirtyTwentySnapshot snapshot;
  final BudgetProfile profile;
  final FiftyThirtyBaselineMode baselineMode;
  final Future<void> Function(FiftyThirtyBaselineMode mode)
  onBaselineModeChanged;

  String _splitLine() {
    final n = (profile.splitNeeds * 100).round();
    final w = (profile.splitWants * 100).round();
    final s = (profile.splitSavings * 100).round();
    return '$n% Needs · $w% Wants · $s% Savings';
  }

  @override
  Widget build(BuildContext context) {
    final b = snapshot.incomeBaseline;
    if (b <= 0) {
      final String msg;
      switch (baselineMode) {
        case FiftyThirtyBaselineMode.monthIncomeEntries:
          msg =
              'No income logged in this budget period yet. Add a salary/income entry, or open the tune menu above to switch baseline.';
        case FiftyThirtyBaselineMode.spendPool:
          msg =
              'Set monthly salary in Profile so the spend cap can be calculated, or open the tune menu above to switch baseline.';
        case FiftyThirtyBaselineMode.profileSalary:
          msg =
              'Set monthly income in Profile, add income in this period, or open the tune menu above to switch baseline.';
      }
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _BaselineMenu(
                  selected: baselineMode,
                  onSelected: onBaselineModeChanged,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              msg,
              style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSoft),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _splitLine(),
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.textSoft,
                  ),
                ),
              ),
              _BaselineMenu(
                selected: baselineMode,
                onSelected: onBaselineModeChanged,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BarRow(
            label: 'Needs',
            spent: snapshot.spentNeeds,
            target: snapshot.targetNeeds,
            color: AppColors.primary,
            over: snapshot.needsOverTarget,
          ),
          const SizedBox(height: 14),
          _BarRow(
            label: 'Wants',
            spent: snapshot.spentWants,
            target: snapshot.targetWants,
            color: AppColors.warn,
            over: snapshot.wantsOverTarget,
          ),
          const SizedBox(height: 14),
          _BarRow(
            label: 'Savings',
            spent: snapshot.spentSavings,
            target: snapshot.targetSavings,
            color: AppColors.savings,
            over: snapshot.savingsOverTarget,
          ),
        ],
      ),
    );
  }
}

class _BaselineMenu extends StatelessWidget {
  const _BaselineMenu({required this.selected, required this.onSelected});

  final FiftyThirtyBaselineMode selected;
  final Future<void> Function(FiftyThirtyBaselineMode mode) onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<FiftyThirtyBaselineMode>(
      tooltip: 'Budget baseline',
      color: AppColors.surface2,
      surfaceTintColor: Colors.transparent,
      initialValue: selected,
      onSelected: (v) => unawaited(onSelected(v)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: FiftyThirtyBaselineMode.monthIncomeEntries,
          child: Text(
            'Income logged this budget period',
            style: GoogleFonts.sora(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
        PopupMenuItem(
          value: FiftyThirtyBaselineMode.spendPool,
          child: Text(
            '20% of profile salary (alternate cap)',
            style: GoogleFonts.sora(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
        PopupMenuItem(
          value: FiftyThirtyBaselineMode.profileSalary,
          child: Text(
            'Profile salary',
            style: GoogleFonts.sora(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
      ],
      child: Icon(Icons.tune_rounded, size: 22, color: AppColors.textMuted),
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
    final fill = over ? AppColors.debit : color;
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
                fontSize: 12,
                color: over ? AppColors.debit : AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: AppColors.surface2),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: pct > 1 ? 1.0 : pct,
                  child: ColoredBox(color: fill),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

IconData _iconForTransaction(TransactionEntry t) {
  if (t.isCredit) {
    final c = t.incomeCategory?.toLowerCase() ?? '';
    if (c.contains('freelance') || c.contains('work')) {
      return Icons.work_outline_rounded;
    }
    if (c.contains('business')) return Icons.storefront_outlined;
    return Icons.payments_rounded;
  }
  switch (t.spendingKind) {
    case SpendingKind.need:
      return Icons.shopping_cart_outlined;
    case SpendingKind.want:
      return Icons.movie_filter_rounded;
    case SpendingKind.saving:
      return Icons.savings_outlined;
    case SpendingKind.other:
      return Icons.receipt_long_outlined;
    case null:
      return Icons.category_outlined;
  }
}

Color _iconBgForTransaction(TransactionEntry t) {
  if (t.isCredit) return AppColors.safe.withValues(alpha: 0.2);
  switch (t.spendingKind) {
    case SpendingKind.need:
      return const Color(0xFF3B82F6).withValues(alpha: 0.2);
    case SpendingKind.want:
      return AppColors.warn.withValues(alpha: 0.2);
    case SpendingKind.saving:
      return AppColors.primary.withValues(alpha: 0.2);
    case SpendingKind.other:
      return AppColors.textMuted.withValues(alpha: 0.2);
    case null:
      return AppColors.border.withValues(alpha: 0.5);
  }
}

Color _iconFgForTransaction(TransactionEntry t) {
  if (t.isCredit) return AppColors.safe;
  switch (t.spendingKind) {
    case SpendingKind.need:
      return const Color(0xFF60A5FA);
    case SpendingKind.want:
      return AppColors.warn;
    case SpendingKind.saving:
      return AppColors.primaryLight;
    case SpendingKind.other:
      return AppColors.textSoft;
    case null:
      return AppColors.textMuted;
  }
}

class _HomeTxRow extends StatelessWidget {
  const _HomeTxRow({required this.item, required this.menuEnabled});

  final TransactionEntry item;
  final bool menuEnabled;

  @override
  Widget build(BuildContext context) {
    final color = item.isCredit ? AppColors.safe : AppColors.danger;
    final ts = item.effectiveDate.toLocal();
    final dateStr = DateFormat('d MMM').format(ts);
    final cat = item.displayCategoryLine;
    final icon = _iconForTransaction(item);
    final bg = _iconBgForTransaction(item);
    final fg = _iconFgForTransaction(item);
    final amountText =
        '${item.isCredit ? '+' : '-'} ${CurrencyFormatter.formatRupee(item.amount)}';

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 2, top: 12, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => showTransactionDetailSheet(context, item),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 2, right: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: fg, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.sora(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface2,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      cat,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.sora(
                                        fontSize: 11,
                                        color: AppColors.textSoft,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              dateStr,
                              style: GoogleFonts.sora(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          amountText,
                          style: GoogleFonts.jetBrainsMono(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
                enabled: menuEnabled,
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 22,
                  color: AppColors.textMuted,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onSelected: (v) {
                  if (v == 'edit') openEditTransaction(context, item);
                  if (v == 'delete') confirmDeleteTransaction(context, item);
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
        ],
      ),
    );
  }
}
