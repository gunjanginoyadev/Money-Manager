import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/expense_decision.dart';
import '../viewmodels/budget_view_model.dart';

/// "Can I afford this?" tool — Plan tab summary or full [AffordDecisionScreen].
class AffordDecisionWidget extends StatefulWidget {
  const AffordDecisionWidget({super.key, this.showHeading = true});

  final bool showHeading;

  @override
  State<AffordDecisionWidget> createState() => _AffordDecisionWidgetState();
}

class _AffordDecisionWidgetState extends State<AffordDecisionWidget> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();

  ExpenseDecision? _result;
  int? _selectedQuickAmount;

  static const _quickAmounts = [500, 1000, 2000, 5000, 10000];
  static const _categories = [
    '🎬 Movie',
    '🛍️ Shopping',
    '🍕 Food',
    '✈️ Travel',
    '🎮 Gaming',
    '💊 Health',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _clearResult() {
    if (_result != null) setState(() => _result = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeading) ...[
          Text(
            'Can I afford this?',
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check discretionary spends — dinner, gadgets, trips, and more.',
            style: GoogleFonts.sora(
              fontSize: 12,
              color: AppColors.textSoft,
            ),
          ),
          const SizedBox(height: 14),
        ],
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HOW MUCH?',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '₹',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                        letterSpacing: -2,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: GoogleFonts.jetBrainsMono(
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2A3040),
                          letterSpacing: -2,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) {
                        setState(() => _selectedQuickAmount = null);
                        _clearResult();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts.map((v) {
                  final active = _selectedQuickAmount == v;
                  return GestureDetector(
                    onTap: () {
                      _amountController.text = v.toString();
                      setState(() => _selectedQuickAmount = v);
                      _clearResult();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primaryGlow
                            : AppColors.surface2,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: active ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        v >= 1000 ? '₹${v ~/ 1000}K' : '₹$v',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active ? AppColors.primary : AppColors.textSoft,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Text('📝', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _titleController,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    color: AppColors.text,
                  ),
                  decoration: InputDecoration(
                    hintText: "What's this for? (optional)",
                    hintStyle: GoogleFonts.sora(
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (_) => _clearResult(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final selected = _titleController.text.trim() == cat;
            return GestureDetector(
              onTap: () {
                _titleController.text = cat;
                setState(() {});
                _clearResult();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryGlow : AppColors.surface2,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  cat,
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.textSoft,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _checkNow,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                alignment: Alignment.center,
                child: Text(
                  'Check now ⚡',
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(
                CurvedAnimation(
                  parent: anim,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          ),
          child: _result == null
              ? const SizedBox.shrink(key: ValueKey('empty'))
              : Padding(
                  key: ValueKey(_result!.remainingBalance),
                  padding: const EdgeInsets.only(top: 18),
                  child: _ResultCard(decision: _result!),
                ),
        ),
      ],
    );
  }

  void _checkNow() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final titleRaw = _titleController.text.trim();
    final label = titleRaw.isEmpty ? 'This expense' : titleRaw;

    final vm = context.read<BudgetViewModel>();
    final decision = vm.previewExpense(amount, expenseLabel: label);

    setState(() => _result = decision);
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.decision});
  final ExpenseDecision decision;

  @override
  Widget build(BuildContext context) {
    late final String emoji;
    late final String title;
    late final String subtitle;
    late final Color titleColor;
    late final Color borderColor;
    late final Color bgDim;
    late final String bufferLine;

    switch (decision.status) {
      case DecisionStatus.safe:
        emoji = '🟢';
        title = 'SAFE — Go Ahead!';
        subtitle = 'No financial risk detected';
        titleColor = AppColors.safe;
        borderColor = const Color(0x4422C55E);
        bgDim = AppColors.safeDim;
        bufferLine = '✅ Maintained';
      case DecisionStatus.okay:
        emoji = '🟡';
        title = 'OKAY — Slight Risk';
        subtitle = 'You can proceed, but be mindful';
        titleColor = AppColors.warn;
        borderColor = const Color(0x44F59E0B);
        bgDim = AppColors.warnDim;
        bufferLine = '⚠️ Touching Buffer';
      case DecisionStatus.notSafe:
        emoji = '🔴';
        title = 'NOT SAFE';
        subtitle = 'Avoid this expense right now';
        titleColor = AppColors.danger;
        borderColor = const Color(0x44EF4444);
        bgDim = AppColors.dangerDim;
        bufferLine = '❌ At Risk';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgDim,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.sora(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        color: AppColors.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x22000000),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _BreakRow(
                  label: 'Available before',
                  value: CurrencyFormatter.formatRupee(decision.availableBefore),
                  valueColor: AppColors.text,
                ),
                const SizedBox(height: 10),
                _BreakRow(
                  label: 'This expense',
                  value:
                      '-${CurrencyFormatter.formatRupee(decision.expenseAmount)}',
                  valueColor: AppColors.danger,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                _BreakRow(
                  label: 'Remaining after',
                  value: CurrencyFormatter.formatRupeeSigned(
                    decision.remainingBalance,
                  ),
                  valueColor: AppColors.text,
                ),
                const SizedBox(height: 10),
                _BreakRow(
                  label: 'Buffer safety',
                  value: bufferLine,
                  valueColor: titleColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x22000000),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              decision.message,
              style: GoogleFonts.sora(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakRow extends StatelessWidget {
  const _BreakRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 13,
            color: AppColors.textSoft,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
