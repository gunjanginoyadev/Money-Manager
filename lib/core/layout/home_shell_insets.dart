import 'package:flutter/material.dart';

/// [HomeShell] uses a custom bottom bar; child [Scaffold]s must offset FABs and
/// scroll padding so they sit above that bar (not under it).
class HomeShellInsets {
  HomeShellInsets._();

  /// Space below scroll content so it clears the custom bottom bar ([HomeShell]
  /// `_BottomNav`). Does **not** include [MediaQuery.padding.bottom] — each tab
  /// screen uses [SafeArea], which already applies the system bottom inset.
  /// Adding both caused a large empty gap above the nav bar.
  static double bottomNavHeight(BuildContext context) {
    return 52;
  }

  /// Padding to place a floating action button above the bottom navigation bar.
  static EdgeInsets fabPadding(BuildContext context) {
    final safe = MediaQuery.paddingOf(context).bottom;
    return EdgeInsets.only(bottom: safe + bottomNavHeight(context));
  }
}
