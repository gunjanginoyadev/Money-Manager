import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/month_liquidity_snapshot.dart';

/// Earned / spent / net plus cash vs online for a month or custom range.
class LiquidityBreakdownCard extends StatelessWidget {
  const LiquidityBreakdownCard({
    super.key,
    required this.snapshot,
    required this.title,
    this.subtitle,
  });

  final MonthLiquiditySnapshot snapshot;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
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
            title,
            style: GoogleFonts.sora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.sora(
                fontSize: 11,
                height: 1.35,
                color: AppColors.textSoft,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _TotalRow(
            label: 'Earned',
            value: s.totalEarned,
            color: AppColors.safe,
          ),
          _TotalRow(
            label: 'Spent',
            value: s.totalSpent,
            color: AppColors.debit,
          ),
          _TotalRow(
            label: 'Net (left)',
            value: s.netMonth,
            color: s.netMonth >= 0 ? AppColors.safe : AppColors.debit,
            emphasize: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border.withValues(alpha: 0.85)),
          ),
          _ChannelBlock(
            label: 'Cash',
            earned: s.creditCash,
            spent: s.debitCash,
            left: s.netCash,
          ),
          const SizedBox(height: 12),
          _ChannelBlock(
            label: 'Online',
            earned: s.creditOnline,
            spent: s.debitOnline,
            left: s.netOnline,
          ),
          if (s.hasUnspecified) ...[
            const SizedBox(height: 12),
            _ChannelBlock(
              label: 'Unspecified',
              earned: s.creditUnspecified,
              spent: s.debitUnspecified,
              left: s.netUnspecified,
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    required this.color,
    this.emphasize = false,
  });

  final String label;
  final double value;
  final Color color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.sora(
              fontSize: emphasize ? 14 : 13,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.text,
            ),
          ),
          Text(
            CurrencyFormatter.formatRupee(value),
            style: GoogleFonts.jetBrainsMono(
              fontSize: emphasize ? 15 : 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelBlock extends StatelessWidget {
  const _ChannelBlock({
    required this.label,
    required this.earned,
    required this.spent,
    required this.left,
  });

  final String label;
  final double earned;
  final double spent;
  final double left;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSoft,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _Mini(
                caption: 'In',
                amount: earned,
                color: AppColors.safe,
              ),
            ),
            Expanded(
              child: _Mini(
                caption: 'Out',
                amount: spent,
                color: AppColors.debit,
              ),
            ),
            Expanded(
              child: _Mini(
                caption: 'Left',
                amount: left,
                color: AppColors.text,
                bold: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({
    required this.caption,
    required this.amount,
    required this.color,
    this.bold = false,
  });

  final String caption;
  final double amount;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caption,
          style: GoogleFonts.sora(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.formatRupee(amount),
          style: GoogleFonts.jetBrainsMono(
            fontSize: bold ? 12 : 11,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
