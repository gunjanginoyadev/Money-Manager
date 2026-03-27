import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/expense_decision.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.large = false});

  final DecisionStatus status;
  final bool large;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final Color bg;
    late final String label;
    late final IconData icon;

    switch (status) {
      case DecisionStatus.safe:
        color = AppColors.credit;
        bg = const Color(0x224ADE80);
        label = 'SAFE';
        icon = Icons.check_circle_rounded;
      case DecisionStatus.okay:
        color = AppColors.warn;
        bg = const Color(0x22FFBF4A);
        label = 'OKAY';
        icon = Icons.warning_amber_rounded;
      case DecisionStatus.notSafe:
        color = AppColors.debit;
        bg = const Color(0x22FF6B6B);
        label = 'NOT SAFE';
        icon = Icons.cancel_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 12,
        vertical: large ? 10 : 6,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: large ? 18 : 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: large ? 14 : 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
