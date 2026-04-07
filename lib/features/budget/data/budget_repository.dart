import 'package:firebase_auth/firebase_auth.dart';

import '../domain/models/auth_mode.dart';
import '../domain/models/fifty_thirty_baseline_mode.dart';
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

  Future<FiftyThirtyBaselineMode> loadFiftyThirtyBaselineMode() async {
    final raw = await _localDataSource.loadFiftyThirtyBaselineMode();
    return fiftyThirtyBaselineModeFromStorage(raw);
  }

  Future<void> saveFiftyThirtyBaselineMode(FiftyThirtyBaselineMode mode) {
    return _localDataSource.saveFiftyThirtyBaselineMode(mode.storageValue);
  }

  /// Clears leftover SharedPreferences from older versions (stale profile from another account).
  Future<void> clearLegacyLocalCache() => _localDataSource.clearLegacyBudgetKeys();

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

  Future<BudgetProfile?> loadProfile() async {
    if (!isCloudReady) return null;
    return _firebaseSyncService.fetchRemoteProfile();
  }

  Future<List<ExpenseEntry>> loadExpenses() async {
    if (!isCloudReady) return const [];
    return _firebaseSyncService.fetchRemoteExpenses();
  }

  Future<List<TransactionEntry>> loadTransactions() async {
    if (!isCloudReady) return const [];
    return _firebaseSyncService.fetchRemoteTransactions();
  }

  Future<void> saveProfile(BudgetProfile profile) async {
    if (!isCloudReady) {
      throw StateError('You must be online to save your profile.');
    }
    await _firebaseSyncService.syncProfile(profile);
  }

  Future<void> addExpense({
    required BudgetProfile profile,
    required ExpenseEntry expense,
  }) async {
    if (!isCloudReady) {
      throw StateError('You must be online to add expenses.');
    }
    await _firebaseSyncService.syncProfile(profile);
    await _firebaseSyncService.upsertExpense(expense);
  }

  Future<void> addTransaction({
    required BudgetProfile profile,
    required TransactionEntry transaction,
  }) async {
    if (!isCloudReady) {
      throw StateError('You must be online to add transactions.');
    }
    await _firebaseSyncService.syncProfile(profile);
    await _firebaseSyncService.upsertTransaction(transaction);
  }

  Future<void> deleteTransaction({
    required BudgetProfile profile,
    required String transactionId,
  }) async {
    if (!isCloudReady) {
      throw StateError('You must be online.');
    }
    await _firebaseSyncService.syncProfile(profile);
    await _firebaseSyncService.removeTransaction(transactionId);
  }

  Future<void> deleteExpense({
    required BudgetProfile profile,
    required String expenseId,
  }) async {
    if (!isCloudReady) {
      throw StateError('You must be online.');
    }
    await _firebaseSyncService.syncProfile(profile);
    await _firebaseSyncService.removeExpense(expenseId);
  }

  Future<void> resetMonth(BudgetProfile profile) async {
    if (!isCloudReady) {
      throw StateError('You must be online to reset.');
    }
    await _firebaseSyncService.syncProfile(profile);
    await _firebaseSyncService.clearExpenses();
    await _firebaseSyncService.clearTransactions();
  }

  /// Deletes Firestore data and Firebase Auth user when signed in, then clears local prefs.
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
