import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/home_shell_insets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shell_profile_nav_button.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../viewmodels/budget_view_model.dart';
import '../widgets/afford_decision_widget.dart';

/// Spend tab — Wants budget summary, outing pace, and “check a price” in one place.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    final profile = vm.profile;
    if (profile == null) return const SizedBox.shrink();

    final snap = vm.fiftyThirtySnapshotThisMonth;
    final budget = snap.targetWants;

    final _HeroStatus heroStatus;
    if (snap.incomeBaseline <= 0) {
      heroStatus = _HeroStatus.unset;
    } else if (vm.currentAvailable < 0) {
      heroStatus = _HeroStatus.danger;
    } else if (vm.currentAvailable <= budget * 0.15) {
      heroStatus = _HeroStatus.warn;
    } else {
      heroStatus = _HeroStatus.safe;
    }

    final bottomPad = HomeShellInsets.bottomNavHeight(context) + 4;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(
                onProfile: () =>
                    context.read<BudgetViewModel>().requestTab(3),
              ),
              _MonthlyWantsSummary(
                hasBaseline: snap.incomeBaseline > 0,
                monthlyBudget: budget,
                spentSoFar: snap.spentWants,
                remaining: vm.currentAvailable,
                status: heroStatus,
              ),
              const SizedBox(height: 12),
              if (snap.incomeBaseline > 0)
                _OutingPlansCard(
                  remaining: vm.currentAvailable,
                  initialOutings: profile.remainingOutingsCount,
                ),
              const SizedBox(height: 16),
              const AffordDecisionWidget(showHeading: true),
            ],
          ),
        ),
      ),
    );
  }
}

enum _HeroStatus { safe, warn, danger, unset }

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onProfile});

  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Row(
        children: [
          Text(
            'Can I spend?',
            style: GoogleFonts.sora(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.text,
            ),
          ),
          const Spacer(),
          ShellProfileNavButton(onPressed: onProfile),
        ],
      ),
    );
  }
}

/// This month’s Wants budget, spent so far, and remaining — no formulas.
class _MonthlyWantsSummary extends StatelessWidget {
  const _MonthlyWantsSummary({
    required this.hasBaseline,
    required this.monthlyBudget,
    required this.spentSoFar,
    required this.remaining,
    required this.status,
  });

  final bool hasBaseline;
  final double monthlyBudget;
  final double spentSoFar;
  final double remaining;
  final _HeroStatus status;

  @override
  Widget build(BuildContext context) {
    late final String statusText;
    late final Color dotColor;
    late final Color pillBg;
    late final Color pillBorder;

    switch (status) {
      case _HeroStatus.safe:
        statusText = 'On track for this month';
        dotColor = AppColors.safe;
        pillBg = AppColors.safeDim;
        pillBorder = const Color(0x4422C55E);
      case _HeroStatus.warn:
        statusText = 'Running low';
        dotColor = AppColors.warn;
        pillBg = AppColors.warnDim;
        pillBorder = const Color(0x44F59E0B);
      case _HeroStatus.danger:
        statusText = 'Over this month’s Wants budget';
        dotColor = AppColors.danger;
        pillBg = AppColors.dangerDim;
        pillBorder = const Color(0x44EF4444);
      case _HeroStatus.unset:
        statusText = 'Set income on Home first';
        dotColor = AppColors.warn;
        pillBg = AppColors.warnDim;
        pillBorder = const Color(0x44F59E0B);
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
          Text(
            'This month (Wants)',
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 14),
          if (!hasBaseline)
            Text(
              'Log income or pick a baseline on Home so we can show your monthly Wants budget here.',
              style: GoogleFonts.sora(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSoft,
              ),
            )
          else ...[
            _summaryRow(
              'This month’s budget',
              CurrencyFormatter.formatRupee(monthlyBudget),
              emphasize: false,
            ),
            const SizedBox(height: 10),
            _summaryRow(
              'Spent so far',
              CurrencyFormatter.formatRupee(spentSoFar),
              emphasize: false,
            ),
            const SizedBox(height: 10),
            _summaryRow(
              'Remaining',
              CurrencyFormatter.formatRupeeSigned(remaining),
              emphasize: true,
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: pillBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    statusText,
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: dotColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {required bool emphasize}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 13,
              color: AppColors.textSoft,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.jetBrainsMono(
              fontSize: emphasize ? 17 : 14,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}

class _OutingPlansCard extends StatefulWidget {
  const _OutingPlansCard({
    required this.remaining,
    required this.initialOutings,
  });

  final double remaining;
  final int initialOutings;

  @override
  State<_OutingPlansCard> createState() => _OutingPlansCardState();
}

class _OutingPlansCardState extends State<_OutingPlansCard> {
  late final TextEditingController _plansController;

  @override
  void initState() {
    super.initState();
    _plansController = TextEditingController(
      text: widget.initialOutings > 0 ? '${widget.initialOutings}' : '',
    );
    _plansController.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant _OutingPlansCard old) {
    super.didUpdateWidget(old);
    if (old.initialOutings != widget.initialOutings) {
      _plansController.text =
          widget.initialOutings > 0 ? '${widget.initialOutings}' : '';
    }
  }

  @override
  void dispose() {
    _plansController.dispose();
    super.dispose();
  }

  int get _plansParsed {
    final v = int.tryParse(_plansController.text.trim());
    if (v == null || v < 0) return 0;
    return v.clamp(0, 999);
  }

  Future<void> _savePlans() async {
    final vm = context.read<BudgetViewModel>();
    final p = vm.profile!;
    await vm.saveProfile(
      p.copyWith(remainingOutingsCount: _plansParsed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveN = BudgetViewModel.effectiveOutingCountForPacing(
      outingsRemaining: _plansParsed,
    );
    final comfortable = BudgetViewModel.maxPerOutingWants(
      remainingWants: widget.remaining,
      outingsRemaining: _plansParsed,
    );
    final safer = BudgetViewModel.bufferedMaxPerOutingWants(
      remainingWants: widget.remaining,
      outingsRemaining: _plansParsed,
    );

    return Container(
      width: double.infinity,
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
            'Planning more outings?',
            style: GoogleFonts.sora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Roughly how many times do you still plan to go out? We use that to suggest a comfortable amount each time.',
            style: GoogleFonts.sora(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSoft,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _plansController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
            decoration: InputDecoration(
              labelText: 'Outings left this month',
              hintText: 'e.g. 4',
              hintStyle: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.6),
              ),
              filled: true,
              fillColor: AppColors.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _savePlans,
              child: Text(
                'Save',
                style: GoogleFonts.sora(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_plansParsed <= 0 && widget.remaining > 0)
            Text(
              'No number saved yet — we’re pacing what’s left across about $effectiveN week(s) in this month. Add a count above for amounts tailored to you.',
              style: GoogleFonts.sora(
                fontSize: 12,
                height: 1.35,
                color: AppColors.textSoft,
              ),
            )
          else if (widget.remaining < 0)
            Text(
              'You’re already over this month’s Wants budget. Fix spending or adjust income on Home before planning outings here.',
              style: GoogleFonts.sora(fontSize: 12, color: AppColors.danger),
            )
          else if (comfortable != null && safer != null) ...[
            _softRow(
              'Comfortable per outing',
              CurrencyFormatter.formatRupee(comfortable),
              AppColors.primary,
            ),
            const SizedBox(height: 8),
            _softRow(
              'Safer target',
              CurrencyFormatter.formatRupee(safer),
              AppColors.safe,
            ),
            const SizedBox(height: 8),
            Text(
              'After each outing, lower the count or log spending so these stay accurate.',
              style: GoogleFonts.sora(
                fontSize: 11,
                height: 1.35,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _softRow(String label, String value, Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 12.5,
              color: AppColors.textSoft,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ),
      ],
    );
  }
}
