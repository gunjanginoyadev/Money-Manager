import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/budget/presentation/viewmodels/budget_view_model.dart';
import '../theme/app_theme.dart';
import 'no_internet_screen.dart';

bool _hasRealConnection(List<ConnectivityResult> results) {
  return results.any((e) => e != ConnectivityResult.none);
}

/// Blocks the app when offline and triggers [BudgetViewModel.initialize] once online.
class AppConnectivityGate extends StatefulWidget {
  const AppConnectivityGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppConnectivityGate> createState() => _AppConnectivityGateState();
}

class _AppConnectivityGateState extends State<AppConnectivityGate> {
  bool? _online;
  bool _wasOnline = true;
  bool _scheduledVmInit = false;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  Future<void> _startListening() async {
    final first = await Connectivity().checkConnectivity();
    if (!mounted) return;
    final online = _hasRealConnection(first);
    setState(() {
      _online = online;
      _wasOnline = online;
    });
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      final now = _hasRealConnection(results);
      setState(() => _online = now);
      if (now && !_wasOnline) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<BudgetViewModel>().refreshFromCloudIfSignedIn();
        });
      }
      _wasOnline = now;
    });
  }

  Future<void> _retry() async {
    final r = await Connectivity().checkConnectivity();
    if (!mounted) return;
    final online = _hasRealConnection(r);
    setState(() => _online = online);
    if (online) {
      _scheduledVmInit = true;
      await context.read<BudgetViewModel>().initialize();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_online == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (!_online!) {
      return NoInternetScreen(onRetry: _retry);
    }

    if (!_scheduledVmInit) {
      _scheduledVmInit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<BudgetViewModel>().initialize();
      });
    }

    return widget.child;
  }
}
