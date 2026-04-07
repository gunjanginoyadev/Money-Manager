import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Compact daily spend bars for the budget period (spike = tallest amber bar).
class SpendTimelineChart extends StatelessWidget {
  const SpendTimelineChart({
    super.key,
    required this.series,
    required this.monthSpendTitle,
  });

  final List<({DateTime day, double amount})> series;
  final String monthSpendTitle;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const SizedBox.shrink();
    }
    final amounts = series.map((e) => e.amount).toList();
    final maxY = amounts.fold<double>(0, (a, b) => a > b ? a : b);
    final heaviestIdx = maxY > 0
        ? amounts.indexWhere((a) => (a - maxY).abs() < 0.01)
        : -1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'SPEND TIMELINE',
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    monthSpendTitle,
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  if (maxY > 0)
                    Text(
                      'Heaviest: ${CurrencyFormatter.formatRupee(maxY)}',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < series.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: _DayBar(
                            amount: series[i].amount,
                            maxY: maxY,
                            isHeaviest: i == heaviestIdx && maxY > 0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.amount,
    required this.maxY,
    required this.isHeaviest,
  });

  final double amount;
  final double maxY;
  final bool isHeaviest;

  @override
  Widget build(BuildContext context) {
    final maxSafe = maxY < 0.01 ? 1.0 : maxY;
    final t = (amount / maxSafe).clamp(0.0, 1.0);
    final h = (t * 48).clamp(3.0, 48.0);
    Color bg;
    if (isHeaviest && amount > 0) {
      bg = AppColors.warn;
    } else if (amount > 0 && t >= 0.35) {
      bg = AppColors.warn.withValues(alpha: 0.35);
    } else {
      bg = AppColors.surface2;
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: h,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
