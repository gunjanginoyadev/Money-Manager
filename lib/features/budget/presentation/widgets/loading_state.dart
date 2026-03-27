import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class LoadingState extends StatefulWidget {
  const LoadingState({super.key, this.lines = 4});

  final int lines;

  @override
  State<LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Column(
        children: List.generate(widget.lines, (index) {
          final width = index % 3 == 2 ? 0.6 : 1.0;
          return FractionallySizedBox(
            widthFactor: width,
            alignment: Alignment.centerLeft,
            child: Container(
              height: 14,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.divider.withValues(alpha: _anim.value),
              ),
            ),
          );
        }),
      ),
    );
  }
}
