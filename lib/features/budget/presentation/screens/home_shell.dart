import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../viewmodels/budget_view_model.dart';
import 'auth_screen.dart';
import 'home_dashboard_screen.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'spend_tab_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _pendingTabScheduled = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    final pending = vm.pendingTabIndex;
    if (pending != null && !_pendingTabScheduled) {
      _pendingTabScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pendingTabScheduled = false;
        if (!mounted) return;
        final v = context.read<BudgetViewModel>();
        if (v.pendingTabIndex == null) return;
        final idx = v.pendingTabIndex!;
        v.consumePendingTab();
        setState(() => _selectedIndex = idx);
      });
    }

    if (vm.isInitializing) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF5A4FE0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGlow,
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 22),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Loading your data…',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (vm.needsAuthSelection) return const AuthScreen();
    if (vm.profile == null) return const OnboardingScreen();

    const pages = [
      HomeDashboardScreen(),
      ReportScreen(),
      SpendTabScreen(),
      ProfileScreen(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        extendBody: true,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: KeyedSubtree(
            key: ValueKey(_selectedIndex),
            child: pages[_selectedIndex],
          ),
        ),
        bottomNavigationBar: _BottomNav(
          selectedIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.assignment_outlined, 'Report'),
    (Icons.track_changes_rounded, 'Spend'),
    (Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Row(
        children: _items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final active = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primaryGlow
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      item.$1,
                      size: 22,
                      color: active ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: active
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                    child: Text(item.$2),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
