import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/home_shell_insets.dart';
import '../../../../core/utils/budget_period_utils.dart';
import '../../../../core/services/transaction_pdf_export.dart';
import '../../../../core/widgets/shell_profile_nav_button.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/spending_kind.dart';
import '../../domain/models/transaction_entry.dart';
import '../viewmodels/budget_view_model.dart';
import 'add_transaction_screen.dart';
import '../widgets/liquidity_breakdown_card.dart';
import '../widgets/transaction_actions.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';

enum _ReportPeriod { month, custom }

enum _BucketFilter { needs, wants, savings }

enum _TypeFilter { income, expense }

/// Net balance accent (mockup blue).
const Color _kNetBlue = Color(0xFF448AFF);

/// Reports: month/custom period, quick filters, full filter sheet, PDF.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  _ReportPeriod _period = _ReportPeriod.month;

  DateTime? _customDraftStart;
  DateTime? _customDraftEnd;
  DateTime? _customAppliedStart;
  DateTime? _customAppliedEnd;

  _BucketFilter? _appliedBucket;
  _TypeFilter? _appliedType;

  _BucketFilter? _sheetDraftBucket;
  _TypeFilter? _sheetDraftType;

  List<TransactionEntry> _baseList(BudgetViewModel vm) {
    if (_period == _ReportPeriod.custom) {
      if (_customAppliedStart == null || _customAppliedEnd == null) {
        return [];
      }
      final s = DateTime(
        _customAppliedStart!.year,
        _customAppliedStart!.month,
        _customAppliedStart!.day,
      );
      final e = DateTime(
        _customAppliedEnd!.year,
        _customAppliedEnd!.month,
        _customAppliedEnd!.day,
        23,
        59,
        59,
      );
      return vm.transactions
          .where((t) {
            final d = t.effectiveDate.toLocal();
            return !d.isBefore(s) && !d.isAfter(e);
          })
          .toList()
        ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
    }
    return vm.transactionsForMonth(vm.activityMonth);
  }

  bool _matchesFilters(TransactionEntry t) {
    final typeF = _appliedType;
    if (typeF != null) {
      if (typeF == _TypeFilter.income && !t.isCredit) return false;
      if (typeF == _TypeFilter.expense && t.isCredit) return false;
    }
    final b = _appliedBucket;
    if (b != null) {
      if (t.isCredit) return false;
      final k = t.spendingKind;
      switch (b) {
        case _BucketFilter.needs:
          return k == SpendingKind.need;
        case _BucketFilter.wants:
          return k == SpendingKind.want || k == SpendingKind.other;
        case _BucketFilter.savings:
          return k == SpendingKind.saving;
      }
    }
    return true;
  }

  String _periodLabel(BudgetViewModel vm, int salaryDay) {
    if (_period == _ReportPeriod.custom &&
        _customAppliedStart != null &&
        _customAppliedEnd != null) {
      final a = _customAppliedStart!;
      final b = _customAppliedEnd!;
      return '${a.day}/${a.month}/${a.year} — ${b.day}/${b.month}/${b.year}';
    }
    return BudgetPeriodUtils.formatBudgetPeriodRange(
      vm.activityMonth,
      salaryDay,
    );
  }

  void _ensureCustomDraftInitialized() {
    final now = DateTime.now();
    _customDraftStart ??= _customAppliedStart ?? DateTime(now.year, now.month, 1);
    _customDraftEnd ??= _customAppliedEnd ?? now;
  }

  Future<void> _pickMonthYear(BudgetViewModel vm) async {
    final initial = vm.activityMonth;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: 'Select month',
    );
    if (!mounted || picked == null) return;
    vm.setActivityMonth(picked);
    setState(() {});
  }

  Future<void> _pickCustomFrom() async {
    _ensureCustomDraftInitialized();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDraftStart!,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _customDraftStart = picked;
      if (_customDraftEnd != null && _customDraftStart!.isAfter(_customDraftEnd!)) {
        _customDraftEnd = _customDraftStart;
      }
    });
  }

  Future<void> _pickCustomTo() async {
    _ensureCustomDraftInitialized();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDraftEnd ?? _customDraftStart ?? now,
      firstDate: _customDraftStart ?? DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (!mounted || picked == null) return;
    setState(() => _customDraftEnd = picked);
  }

  void _applyCustomDateRange() {
    _ensureCustomDraftInitialized();
    setState(() {
      _customAppliedStart = _customDraftStart;
      _customAppliedEnd = _customDraftEnd;
    });
  }

  void _quickAll() {
    setState(() {
      _appliedBucket = null;
      _appliedType = null;
    });
  }

  void _quickIncome() {
    setState(() {
      _appliedType = _TypeFilter.income;
      _appliedBucket = null;
    });
  }

  void _quickExpense() {
    setState(() {
      _appliedType = _TypeFilter.expense;
      _appliedBucket = null;
    });
  }

  void _quickNeeds() {
    setState(() {
      _appliedBucket = _BucketFilter.needs;
      _appliedType = null;
    });
  }

  void _openFilterSheet() {
    _sheetDraftBucket = _appliedBucket;
    _sheetDraftType = _appliedType;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReportFiltersSheet(
        initialBucket: _sheetDraftBucket,
        initialType: _sheetDraftType,
        onApply: (bucket, type) {
          setState(() {
            _appliedBucket = bucket;
            _appliedType = type;
          });
          Navigator.pop(ctx);
        },
        onClearAll: () {
          setState(() {
            _appliedBucket = null;
            _appliedType = null;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  bool get _filtersActive =>
      _appliedBucket != null || _appliedType != null;

  bool get _quickAllSelected =>
      _appliedBucket == null && _appliedType == null;

  bool get _quickIncomeSelected =>
      _appliedType == _TypeFilter.income && _appliedBucket == null;

  bool get _quickExpenseSelected =>
      _appliedType == _TypeFilter.expense && _appliedBucket == null;

  bool get _quickNeedsSelected =>
      _appliedBucket == _BucketFilter.needs && _appliedType == null;

  static void _openAdd(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const AddTransactionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listBottomPad = HomeShellInsets.bottomNavHeight(context) + 4;
    final vm = context.watch<BudgetViewModel>();
    final profile = vm.profile;
    if (profile == null) return const SizedBox.shrink();

    final month = vm.activityMonth;
    final base = _baseList(vm);
    final items = base.where(_matchesFilters).toList();
    final canNext = vm.canAdvanceReportToNextPeriod;
    final payD = profile.salaryDayOfMonth.clamp(1, 31);

    double income = 0;
    double expense = 0;
    for (final t in items) {
      if (t.isCredit) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    final net = income - expense;

    if (_period == _ReportPeriod.custom) {
      _ensureCustomDraftInitialized();
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
              child: Row(
                children: [
                  Text(
                    'Report',
                    style: GoogleFonts.sora(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Export PDF',
                    onPressed: items.isEmpty
                        ? null
                        : () => TransactionPdfExport.shareReport(
                              periodLabel: _periodLabel(vm, payD),
                              items: items,
                              profile: profile,
                            ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    color: AppColors.text,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Add transaction',
                    onPressed:
                        vm.isLoading ? null : () => _openAdd(context),
                    icon: const Icon(Icons.add_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryGlow,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  ShellProfileNavButton(
                    onPressed: () =>
                        context.read<BudgetViewModel>().requestTab(3),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SegmentedButton<_ReportPeriod>(
                            segments: const [
                              ButtonSegment(
                                value: _ReportPeriod.month,
                                label: Text('Pay period'),
                                icon: Icon(Icons.calendar_month_rounded, size: 18),
                              ),
                              ButtonSegment(
                                value: _ReportPeriod.custom,
                                label: Text('Custom'),
                                icon: Icon(Icons.content_cut_rounded, size: 18),
                              ),
                            ],
                            selected: {_period},
                            onSelectionChanged: (s) {
                              setState(() {
                                _period = s.first;
                                if (_period == _ReportPeriod.month) {
                                  _customDraftStart = null;
                                  _customDraftEnd = null;
                                  _customAppliedStart = null;
                                  _customAppliedEnd = null;
                                } else {
                                  final n = DateTime.now();
                                  _customDraftStart ??=
                                      DateTime(n.year, n.month, 1);
                                  _customDraftEnd ??= n;
                                }
                              });
                            },
                            style: SegmentedButton.styleFrom(
                              selectedBackgroundColor: AppColors.primary,
                              selectedForegroundColor: AppColors.onAccent,
                              foregroundColor: AppColors.textSoft,
                              side: const BorderSide(color: AppColors.border),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_period == _ReportPeriod.month) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      vm.shiftActivityBudgetPeriod(-1);
                                    },
                                    icon: const Icon(Icons.chevron_left_rounded),
                                    color: AppColors.text,
                                  ),
                                  Expanded(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _pickMonthYear(vm),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                BudgetPeriodUtils
                                                    .formatBudgetPeriodRange(
                                                  month,
                                                  payD,
                                                ),
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.sora(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.text,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Tap to pick a date in the period',
                                                style: GoogleFonts.sora(
                                                  fontSize: 11,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: !canNext
                                        ? null
                                        : () {
                                            vm.shiftActivityBudgetPeriod(1);
                                          },
                                    icon: const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                    color: AppColors.text,
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _DateCard(
                                    label: 'FROM',
                                    valueText: _customDraftStart != null
                                        ? DateFormat('d/M/y').format(
                                            _customDraftStart!,
                                          )
                                        : 'Pick date',
                                    onTap: _pickCustomFrom,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _DateCard(
                                    label: 'TO',
                                    valueText: _customDraftEnd != null
                                        ? DateFormat('d/M/y').format(
                                            _customDraftEnd!,
                                          )
                                        : 'Pick date',
                                    onTap: _pickCustomTo,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _customDraftStart != null &&
                                        _customDraftEnd != null
                                    ? _applyCustomDateRange
                                    : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Apply date range',
                                  style: GoogleFonts.sora(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _FilterChipBtn(
                                  icon: Icons.tune_rounded,
                                  label: 'Filters',
                                  selected: false,
                                  showDot: _filtersActive,
                                  onTap: _openFilterSheet,
                                ),
                                _FilterChipBtn(
                                  label: 'All',
                                  selected: _quickAllSelected,
                                  onTap: _quickAll,
                                ),
                                _FilterChipBtn(
                                  icon: Icons.arrow_upward_rounded,
                                  label: 'Income',
                                  selected: _quickIncomeSelected,
                                  onTap: _quickIncome,
                                ),
                                _FilterChipBtn(
                                  icon: Icons.arrow_downward_rounded,
                                  label: 'Expense',
                                  selected: _quickExpenseSelected,
                                  onTap: _quickExpense,
                                ),
                                _FilterChipBtn(
                                  icon: Icons.shopping_bag_outlined,
                                  label: 'Needs',
                                  selected: _quickNeedsSelected,
                                  onTap: _quickNeeds,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_period == _ReportPeriod.month)
                            LiquidityBreakdownCard(
                              snapshot: vm.monthLiquidityForMonth(month),
                              title: 'Period totals',
                              subtitle:
                                  'All transactions in ${BudgetPeriodUtils.formatBudgetPeriodRange(month, payD)}. Cash vs online uses the payment type on each entry.',
                            )
                          else if (_customAppliedStart != null &&
                              _customAppliedEnd != null)
                            LiquidityBreakdownCard(
                              snapshot: vm.monthLiquidityForDateRange(
                                _customAppliedStart!,
                                _customAppliedEnd!,
                              ),
                              title: 'Period totals',
                              subtitle:
                                  'All transactions in ${_periodLabel(vm, payD)}. Cash vs online uses the payment type on each entry.',
                            ),
                          const SizedBox(height: 14),
                          if (_filtersActive)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'INCOME / EXPENSE / NET below reflect filters; period card above does not.',
                                style: GoogleFonts.sora(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryPill(
                                  label: 'INCOME',
                                  value: income,
                                  valueColor: AppColors.safe,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _SummaryPill(
                                  label: 'EXPENSE',
                                  value: expense,
                                  valueColor: AppColors.danger,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _SummaryPill(
                                  label: 'NET',
                                  value: net,
                                  valueColor: _kNetBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Text(
                                'TRANSACTIONS',
                                style: GoogleFonts.sora(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface2,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  '${items.length}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSoft,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  if (vm.isLoading && items.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: LoadingState(lines: 5),
                      ),
                    )
                  else if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: listBottomPad),
                        child: const EmptyState(
                          title: 'No transactions match',
                          subtitle:
                              'Pick another month or range, adjust filters, or add a transaction.',
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, listBottomPad),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            if (i.isOdd) {
                              return const Divider(
                                height: 1,
                                indent: 72,
                                color: AppColors.border,
                              );
                            }
                            final index = i ~/ 2;
                            return _ReportTxTile(
                              item: items[index],
                              menuEnabled: !vm.isLoading,
                            );
                          },
                          childCount: items.length * 2 - 1,
                        ),
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

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.label,
    required this.valueText,
    required this.onTap,
  });

  final String label;
  final String valueText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                valueText,
                style: GoogleFonts.sora(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final double value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.formatRupee(value),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipBtn extends StatelessWidget {
  const _FilterChipBtn({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.showDot = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.primary.withValues(alpha: 0.25) : AppColors.surface,
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: AppColors.textSoft),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                if (showDot) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                if (selected && !showDot && label == 'All') ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportFiltersSheet extends StatefulWidget {
  const _ReportFiltersSheet({
    required this.initialBucket,
    required this.initialType,
    required this.onApply,
    required this.onClearAll,
  });

  final _BucketFilter? initialBucket;
  final _TypeFilter? initialType;
  final void Function(_BucketFilter?, _TypeFilter?) onApply;
  final VoidCallback onClearAll;

  @override
  State<_ReportFiltersSheet> createState() => _ReportFiltersSheetState();
}

class _ReportFiltersSheetState extends State<_ReportFiltersSheet> {
  _BucketFilter? _bucket;
  _TypeFilter? _type;

  @override
  void initState() {
    super.initState();
    _bucket = widget.initialBucket;
    _type = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Filters',
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onClearAll,
                child: const Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Category',
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SheetChip(
                label: 'All',
                icon: Icons.select_all_rounded,
                selected: _bucket == null,
                onTap: () => setState(() => _bucket = null),
              ),
              _SheetChip(
                label: 'Needs',
                icon: Icons.shopping_cart_outlined,
                selected: _bucket == _BucketFilter.needs,
                onTap: () => setState(
                  () => _bucket = _BucketFilter.needs,
                ),
              ),
              _SheetChip(
                label: 'Wants',
                icon: Icons.auto_awesome_rounded,
                selected: _bucket == _BucketFilter.wants,
                onTap: () => setState(
                  () => _bucket = _BucketFilter.wants,
                ),
              ),
              _SheetChip(
                label: 'Savings',
                icon: Icons.account_balance_rounded,
                selected: _bucket == _BucketFilter.savings,
                onTap: () => setState(
                  () => _bucket = _BucketFilter.savings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Type',
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SheetChip(
                label: 'All',
                selected: _type == null,
                onTap: () => setState(() => _type = null),
              ),
              _SheetChip(
                label: 'Income',
                icon: Icons.arrow_upward_rounded,
                selected: _type == _TypeFilter.income,
                onTap: () => setState(() => _type = _TypeFilter.income),
              ),
              _SheetChip(
                label: 'Expense',
                icon: Icons.arrow_downward_rounded,
                selected: _type == _TypeFilter.expense,
                onTap: () => setState(() => _type = _TypeFilter.expense),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => widget.onApply(_bucket, _type),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Apply filters',
                style: GoogleFonts.sora(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  const _SheetChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: selected ? AppColors.onAccent : AppColors.textSoft),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      checkmarkColor: AppColors.onAccent,
      labelStyle: GoogleFonts.sora(
        color: selected ? AppColors.onAccent : AppColors.text,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      backgroundColor: AppColors.surface2,
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

class _ReportTxTile extends StatelessWidget {
  const _ReportTxTile({
    required this.item,
    required this.menuEnabled,
  });

  final TransactionEntry item;
  final bool menuEnabled;

  @override
  Widget build(BuildContext context) {
    final color = item.isCredit ? AppColors.safe : AppColors.danger;
    final ts = item.effectiveDate.toLocal();
    final dateStr = DateFormat('d MMM, hh:mm a').format(ts);
    final cat = item.displayCategoryLine;
    final icon = _iconForTransaction(item);
    final bg = _iconBgForTransaction(item);
    final fg = _iconFgForTransaction(item);

    final amountText =
        '${item.isCredit ? '+' : '-'} ${CurrencyFormatter.formatRupee(item.amount)}';

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10, right: 2),
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
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: fg, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.sora(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
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
                                const SizedBox(width: 6),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    dateStr,
                                    style: GoogleFonts.sora(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
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
                            fontSize: 15,
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
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            onSelected: (v) {
              if (v == 'edit') openEditTransaction(context, item);
              if (v == 'delete') confirmDeleteTransaction(context, item);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
