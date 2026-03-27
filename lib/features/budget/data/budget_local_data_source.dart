import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/budget_profile.dart';
import '../domain/models/expense_entry.dart';
import '../domain/models/transaction_entry.dart';

class BudgetLocalDataSource {
  static const _profileKey = 'budget_profile';
  static const _expensesKey = 'budget_expenses';
  static const _transactionsKey = 'budget_transactions';
  static const _authModeKey = 'auth_mode';

  Future<BudgetProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    return BudgetProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(BudgetProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<List<ExpenseEntry>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_expensesKey);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((item) => ExpenseEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveExpenses(List<ExpenseEntry> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = expenses.map((e) => e.toJson()).toList();
    await prefs.setString(_expensesKey, jsonEncode(encoded));
  }

  Future<List<TransactionEntry>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_transactionsKey);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((item) => TransactionEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTransactions(List<TransactionEntry> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = transactions.map((e) => e.toJson()).toList();
    await prefs.setString(_transactionsKey, jsonEncode(encoded));
  }

  Future<String?> loadAuthMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authModeKey);
  }

  Future<void> saveAuthMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authModeKey, mode);
  }

  /// Removes profile, expenses, transactions, and saved auth mode (full reset).
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_expensesKey);
    await prefs.remove(_transactionsKey);
    await prefs.remove(_authModeKey);
  }
}
