import 'package:firebase_auth/firebase_auth.dart';

import '../domain/models/auth_mode.dart';
import '../domain/models/budget_profile.dart';
import '../domain/models/expense_entry.dart';
import '../domain/models/transaction_entry.dart';
import 'budget_local_data_source.dart';
import 'firebase_sync_service.dart';

class BudgetRepository {
  BudgetRepository({
    required BudgetLocalDataSource localDataSource,
    required FirebaseSyncService firebaseSyncService,
  })  : _localDataSource = localDataSource,
        _firebaseSyncService = firebaseSyncService;

  final BudgetLocalDataSource _localDataSource;
  final FirebaseSyncService _firebaseSyncService;

  bool get isCloudReady => _firebaseSyncService.isReady;

  Future<bool> initializeCloud() => _firebaseSyncService.initializeIfConfigured();

  Future<void> syncAuthStateFromFirebase() =>
      _firebaseSyncService.syncAuthStateFromFirebase();

  Future<AuthMode> loadAuthMode() async {
    final raw = await _localDataSource.loadAuthMode();
    return AuthModeX.fromValue(raw);
  }

  Future<void> saveAuthMode(AuthMode mode) {
    return _localDataSource.saveAuthMode(mode.value);
  }

  Future<bool> connectEmail({
    required String email,
    required String password,
    required bool isRegister,
  }) {
    return _firebaseSyncService.signInWithEmail(
      email: email,
      password: password,
      isRegister: isRegister,
    );
  }

  Future<void> disconnectCloud() => _firebaseSyncService.signOut();

  Future<BudgetProfile?> loadProfile() => _localDataSource.loadProfile();

  Future<List<ExpenseEntry>> loadExpenses() => _localDataSource.loadExpenses();

  Future<List<TransactionEntry>> loadTransactions() =>
      _localDataSource.loadTransactions();

  Future<void> saveProfile(BudgetProfile profile) async {
    await _localDataSource.saveProfile(profile);
    try {
      await _firebaseSyncService.syncProfile(profile);
    } catch (_) {
      // Cloud sync is optional. Local persistence remains the source of truth.
    }
  }

  Future<void> addExpense({
    required BudgetProfile profile,
    required ExpenseEntry expense,
  }) async {
    final current = await _localDataSource.loadExpenses();
    final expenses = [...current, expense];
    await _localDataSource.saveExpenses(expenses);
    try {
      await _firebaseSyncService.syncProfile(profile);
      await _firebaseSyncService.upsertExpense(expense);
    } catch (_) {
      // Cloud sync is optional. Local persistence remains the source of truth.
    }
  }

  Future<void> addTransaction({
    required BudgetProfile profile,
    required TransactionEntry transaction,
  }) async {
    final current = await _localDataSource.loadTransactions();
    final updated = [...current, transaction];
    await _localDataSource.saveTransactions(updated);
    try {
      await _firebaseSyncService.syncProfile(profile);
      await _firebaseSyncService.upsertTransaction(transaction);
    } catch (_) {
      // Local persistence remains source of truth.
    }
  }

  Future<void> deleteTransaction({
    required BudgetProfile profile,
    required String transactionId,
  }) async {
    final current = await _localDataSource.loadTransactions();
    final updated = current.where((e) => e.id != transactionId).toList();
    await _localDataSource.saveTransactions(updated);
    try {
      await _firebaseSyncService.syncProfile(profile);
      await _firebaseSyncService.removeTransaction(transactionId);
    } catch (_) {
      // Local persistence remains source of truth.
    }
  }

  Future<void> deleteExpense({
    required BudgetProfile profile,
    required String expenseId,
  }) async {
    final current = await _localDataSource.loadExpenses();
    final expenses = current.where((e) => e.id != expenseId).toList();
    await _localDataSource.saveExpenses(expenses);
    try {
      await _firebaseSyncService.syncProfile(profile);
      await _firebaseSyncService.removeExpense(expenseId);
    } catch (_) {
      // Cloud sync is optional. Local persistence remains the source of truth.
    }
  }

  Future<void> forceSync({
    required BudgetProfile profile,
    required List<ExpenseEntry> expenses,
  }) async {
    final enabled = await _firebaseSyncService.initializeIfConfigured();
    if (!enabled) {
      throw Exception('Firebase not configured');
    }
    await _firebaseSyncService.fullSync(profile: profile, expenses: expenses);
    final transactions = await _localDataSource.loadTransactions();
    for (final tx in transactions) {
      await _firebaseSyncService.upsertTransaction(tx);
    }
  }

  Future<({BudgetProfile profile, List<ExpenseEntry> expenses})> restoreFromCloud()
  async {
    final profile = await _firebaseSyncService.fetchRemoteProfile();
    if (profile == null) {
      throw Exception('No cloud profile found');
    }
    final expenses = await _firebaseSyncService.fetchRemoteExpenses();
    await _localDataSource.saveProfile(profile);
    await _localDataSource.saveExpenses(expenses);
    return (profile: profile, expenses: expenses);
  }

  Future<List<TransactionEntry>> restoreTransactionsFromCloud() async {
    final data = await _firebaseSyncService.fetchRemoteTransactions();
    await _localDataSource.saveTransactions(data);
    return data;
  }

  Future<void> resetMonth(BudgetProfile profile) async {
    await _localDataSource.saveExpenses(const []);
    await _localDataSource.saveTransactions(const []);
    try {
      await _firebaseSyncService.syncProfile(profile);
      await _firebaseSyncService.clearExpenses();
      await _firebaseSyncService.clearTransactions();
    } catch (_) {
      // Local state is still reset if cloud is unavailable.
    }
  }

  /// Clears local storage. If Firebase is configured and a non-anonymous user is
  /// signed in, deletes all Firestore data under `users/{uid}` and the Auth account.
  ///
  /// [password] must be the account password when a Firebase email user is signed in
  /// (required for re-authentication before account deletion).
  Future<void> deleteAccount({String? password}) async {
    final enabled = await _firebaseSyncService.initializeIfConfigured();
    if (enabled) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        final pwd = password?.trim() ?? '';
        if (pwd.isEmpty) {
          throw ArgumentError(
            'Enter your account password to confirm deletion.',
          );
        }
        await _firebaseSyncService.deleteAllUserDataAndAuthAccount(
          password: pwd,
        );
      }
    }
    await _localDataSource.clearAll();
  }
}
