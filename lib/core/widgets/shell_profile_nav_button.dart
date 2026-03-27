import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Profile shortcut used in tab app bars (Report, Spend) — same look everywhere.
class ShellProfileNavButton extends StatelessWidget {
  const ShellProfileNavButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            size: 20,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }
}
