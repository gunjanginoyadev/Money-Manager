import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../viewmodels/budget_view_model.dart';

/// Monthly projection — Plan tab summary or full [MonthlyOutlookScreen].
class ForecastSummaryWidget extends StatelessWidget {
  const ForecastSummaryWidget({super.key, this.showHeading = true});

  final bool showHeading;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    final profile = vm.profile;
    if (profile == null) return const SizedBox.shrink();

    final isSafe = vm.isInSafeZone;
    final wantsCap = vm.wantsBudgetThisMonth;
    final pctUsed = wantsCap > 0
        ? (vm.wantsSpentThisMonth / wantsCap).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeading) ...[
          const Text(
            'Monthly outlook',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSafe
                  ? AppColors.credit.withValues(alpha: 0.3)
                  : AppColors.warn.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'REMAINING IN WANTS BUDGET',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(vm.endOfMonthProjection),
                style: TextStyle(
                  color: isSafe ? AppColors.credit : AppColors.warn,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                wantsCap > 0
                    ? '30% Wants target minus want-tagged spending (same as Home)'
                    : 'Log income or set baseline on Home (50-30-20)',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSafe
                      ? const Color(0x224ADE80)
                      : const Color(0x22FFBF4A),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isSafe ? AppColors.credit : AppColors.warn,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      isSafe ? 'Healthy' : 'Tight month',
                      style: TextStyle(
                        color: isSafe ? AppColors.credit : AppColors.warn,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ForecastTile(
                label: 'Wants spent',
                value: CurrencyFormatter.format(vm.wantsSpentThisMonth),
                color: AppColors.debit,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ForecastTile(
                label: 'Left in Wants',
                value: CurrencyFormatter.format(vm.currentAvailable),
                color: AppColors.credit,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Wants budget use',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      wantsCap > 0
                          ? '${(pctUsed * 100).toStringAsFixed(0)}% of Wants target used'
                          : 'No Wants target yet',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      CurrencyFormatter.format(vm.currentAvailable),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pctUsed,
                  minHeight: 10,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    pctUsed > 0.85
                        ? AppColors.debit
                        : pctUsed > 0.65
                            ? AppColors.warn
                            : AppColors.credit,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: const [
                  _Legend(color: AppColors.debit, label: 'Spent'),
                  _Legend(color: AppColors.credit, label: 'Remaining'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Month at a glance',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              _TimelineItem(
                icon: Icons.circle,
                iconColor: AppColors.credit,
                title: 'Wants target (30%)',
                subtitle:
                    'Cap: ${CurrencyFormatter.format(vm.wantsBudgetThisMonth)}',
                isFirst: true,
              ),
              _TimelineItem(
                icon: Icons.circle,
                iconColor: AppColors.debit,
                title: 'Reference (Profile)',
                subtitle:
                    'Salary ${CurrencyFormatter.format(profile.monthlyIncome)} · EMI ${CurrencyFormatter.format(profile.emi)}',
              ),
              _TimelineItem(
                icon: Icons.circle,
                iconColor: AppColors.warn,
                title: 'Want-tagged spending',
                subtitle:
                    'This month: ${CurrencyFormatter.format(vm.wantsSpentThisMonth)}',
              ),
              _TimelineItem(
                icon: Icons.check_circle_rounded,
                iconColor: vm.endOfMonthProjection >= 0
                    ? AppColors.credit
                    : AppColors.debit,
                title: 'Remaining',
                subtitle:
                    '${CurrencyFormatter.format(vm.endOfMonthProjection)} left in Wants budget',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSafe ? const Color(0x124ADE80) : const Color(0x12FFBF4A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSafe
                  ? AppColors.credit.withValues(alpha: 0.3)
                  : AppColors.warn.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSafe
                    ? Icons.lightbulb_rounded
                    : Icons.warning_amber_rounded,
                color: isSafe ? AppColors.credit : AppColors.warn,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSafe
                      ? 'You still have room in your Wants budget (30%).'
                      : wantsCap <= 0
                          ? 'Log income or set a baseline on Home to see your Wants target.'
                          : 'You are at or over your Wants budget.',
                  style: TextStyle(
                    color: isSafe ? AppColors.credit : AppColors.warn,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ForecastTile extends StatelessWidget {
  const _ForecastTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, color: iconColor, size: 16),
              if (!isLast)
                Container(
                  width: 2,
                  height: 30,
                  color: AppColors.divider,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
