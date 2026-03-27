import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/budget/presentation/viewmodels/budget_view_model.dart';
import 'app_toast.dart';

/// Shows [BudgetViewModel] success/error messages as floating toasts and clears them.
class BudgetMessageToastListener extends StatefulWidget {
  const BudgetMessageToastListener({required this.child, super.key});

  final Widget child;

  @override
  State<BudgetMessageToastListener> createState() =>
      _BudgetMessageToastListenerState();
}

class _BudgetMessageToastListenerState extends State<BudgetMessageToastListener> {
  bool _scheduled = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    final hasMessage =
        vm.errorMessage != null || vm.successMessage != null;

    if (hasMessage && !_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scheduled = false;
        final v = context.read<BudgetViewModel>();
        final err = v.errorMessage;
        final ok = v.successMessage;
        if (err == null && ok == null) return;
        if (v.needsAuthSelection && err != null) {
          return;
        }
        final text = err ?? ok!;
        final isError = err != null;
        v.clearMessages();
        AppToast.show(context, message: text, isError: isError);
      });
    }

    return widget.child;
  }
}
