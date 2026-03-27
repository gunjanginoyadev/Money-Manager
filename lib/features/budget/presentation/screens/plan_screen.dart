import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/home_shell_insets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shell_profile_nav_button.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../viewmodels/budget_view_model.dart';
import 'afford_decision_screen.dart';
import 'monthly_outlook_screen.dart';

/// Budget overview: safe-to-spend, obligations, and tools to decide discretionary spending.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    final profile = vm.profile;
    if (profile == null) return const SizedBox.shrink();

    final obligations = profile.fixedObligationsOnly;
    final safeDisplay = vm.currentAvailable.clamp(0.0, double.infinity);
    final income = vm.planIncomeBaselineDisplay;
    final incomeDenominator = vm.effectiveIncomeThisMonth;
    final usedPct = incomeDenominator > 0
        ? ((obligations + profile.basicExpenses + profile.safetyBuffer) /
                incomeDenominator *
            100)
            .clamp(0.0, 100.0)
        : 0.0;

    _HeroStatus heroStatus;
    if (vm.currentAvailable <= 0) {
      heroStatus = _HeroStatus.danger;
    } else if (vm.currentAvailable < profile.safetyBuffer) {
      heroStatus = _HeroStatus.warn;
    } else {
      heroStatus = _HeroStatus.safe;
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(
              onProfile: () =>
                  context.read<BudgetViewModel>().requestTab(3),
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
                  _HeroCard(
                    safeAmount: safeDisplay,
                    status: heroStatus,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DashStat(
                          label: 'Income',
                          value: CurrencyFormatter.formatRupee(income),
                          valueColor: AppColors.text,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DashStat(
                          label: 'Obligations',
                          value: CurrencyFormatter.formatRupee(obligations),
                          valueColor: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DashStat(
                          label: 'Essentials',
                          value: CurrencyFormatter.formatRupee(
                            profile.basicExpenses,
                          ),
                          valueColor: AppColors.warn,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DashStat(
                          label: 'Buffer',
                          value: CurrencyFormatter.formatRupee(
                            profile.safetyBuffer,
                          ),
                          valueColor: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ProgressCard(usedPct: usedPct),
                  const SizedBox(height: 14),
                  Text(
                    'Safe-to-spend is what remains after obligations, essentials, and your buffer.',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.textSoft,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PlanShortcutTile(
                    icon: Icons.bolt_rounded,
                    title: 'Afford a purchase?',
                    subtitle:
                        'Check a price before spending — dinner, gadgets, trips…',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const AffordDecisionScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _PlanShortcutTile(
                    icon: Icons.insights_outlined,
                    title: 'Monthly outlook',
                    subtitle:
                        'End-of-month balance, budget use, and timeline',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const MonthlyOutlookScreen(),
                        ),
                      );
                    },
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

enum _HeroStatus { safe, warn, danger }

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onProfile});

  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.safeAmount,
    required this.status,
  });

  final double safeAmount;
  final _HeroStatus status;

  @override
  Widget build(BuildContext context) {
    late final String statusText;
    late final Color dotColor;
    late final Color pillBg;
    late final Color pillBorder;

    switch (status) {
      case _HeroStatus.safe:
        statusText = 'You Are in Safe Zone';
        dotColor = AppColors.safe;
        pillBg = AppColors.safeDim;
        pillBorder = const Color(0x4422C55E);
      case _HeroStatus.warn:
        statusText = 'Watch Your Spending';
        dotColor = AppColors.warn;
        pillBg = AppColors.warnDim;
        pillBorder = const Color(0x44F59E0B);
      case _HeroStatus.danger:
        statusText = 'Over Budget — Be Careful';
        dotColor = AppColors.danger;
        pillBg = AppColors.dangerDim;
        pillBorder = const Color(0x44EF4444);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F32), Color(0xFF222840)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E3A5A)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SAFE TO SPEND THIS MONTH',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.formatRupee(safeAmount),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -2,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'After all obligations & buffer',
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: AppColors.textSoft,
                ),
              ),
              const SizedBox(height: 20),
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
                    Text(
                      statusText,
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: dotColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashStat extends StatelessWidget {
  const _DashStat({
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
            label.toUpperCase(),
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.usedPct});

  final double usedPct;

  @override
  Widget build(BuildContext context) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Breakdown',
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              Text(
                '${usedPct.round()}% committed',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  color: AppColors.textSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: usedPct / 100,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Obligations · Essentials · Buffer · Free',
            style: GoogleFonts.sora(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanShortcutTile extends StatelessWidget {
  const _PlanShortcutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
                  color: AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
