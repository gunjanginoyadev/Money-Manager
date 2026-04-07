import 'package:shared_preferences/shared_preferences.dart';

/// Persists only lightweight settings. Budget data lives in Firestore.
class BudgetLocalDataSource {
  static const _authModeKey = 'auth_mode';
  static const _fiftyThirtyBaselineModeKey = 'fifty_thirty_baseline_mode';

  /// Legacy keys from older builds — cleared on sign-in / startup.
  static const _legacyProfileKey = 'budget_profile';
  static const _legacyExpensesKey = 'budget_expenses';
  static const _legacyTransactionsKey = 'budget_transactions';

  Future<String?> loadAuthMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authModeKey);
  }

  Future<void> saveAuthMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authModeKey, mode);
  }

  Future<String?> loadFiftyThirtyBaselineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fiftyThirtyBaselineModeKey);
  }

  Future<void> saveFiftyThirtyBaselineMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fiftyThirtyBaselineModeKey, value);
  }

  /// Removes cached profile / expenses / transactions from older app versions.
  Future<void> clearLegacyBudgetKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyProfileKey);
    await prefs.remove(_legacyExpensesKey);
    await prefs.remove(_legacyTransactionsKey);
  }

  /// Full reset: auth mode + any legacy budget keys.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authModeKey);
    await prefs.remove(_fiftyThirtyBaselineModeKey);
    await prefs.remove(_legacyProfileKey);
    await prefs.remove(_legacyExpensesKey);
    await prefs.remove(_legacyTransactionsKey);
  }
}
