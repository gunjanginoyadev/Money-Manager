import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/app_env.dart';
import '../../../../core/utils/month_utils.dart';
import '../../data/budget_repository.dart';
import '../../domain/models/auth_mode.dart';
import '../../domain/models/budget_profile.dart';
import '../../domain/models/fifty_thirty_twenty_snapshot.dart';
import '../../domain/models/expense_decision.dart';
import '../../domain/models/expense_entry.dart';
import '../../domain/models/spending_kind.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/models/transaction_entry.dart';
import '../../domain/services/decision_engine.dart';

class BudgetViewModel extends ChangeNotifier {
  BudgetViewModel(this._repository);

  final BudgetRepository _repository;
  final DecisionEngine _decisionEngine = const DecisionEngine();
  final Uuid _uuid = const Uuid();

  bool isLoading = true;
  bool isInitializing = true;
  bool cloudSyncEnabled = false;
  String? errorMessage;
  String? successMessage;
  AuthMode authMode = AuthMode.undecided;
  BudgetProfile? profile;
  List<ExpenseEntry> expenses = const [];
  List<TransactionEntry> transactions = const [];
  ExpenseDecision? lastDecision;

  /// When set, [HomeShell] switches to this tab once (Home=0, Report=1, Spend=2, Profile=3).
  int? pendingTabIndex;

  /// Month shown on the Report tab.
  DateTime activityMonth = MonthUtils.startOfMonth(DateTime.now());

  String? get userEmail => FirebaseAuth.instance.currentUser?.email;

  double totalSpentInMonth(DateTime month) => transactions
      .where(
        (e) =>
            !e.isCredit &&
            MonthUtils.isSameMonth(e.effectiveDate, month),
      )
      .fold<double>(0, (s, e) => s + e.amount);

  double totalReceivedInMonth(DateTime month) => transactions
      .where(
        (e) =>
            e.isCredit &&
            MonthUtils.isSameMonth(e.effectiveDate, month),
      )
      .fold<double>(0, (s, e) => s + e.amount);

  /// Current calendar month — used for budget / safe-to-spend.
  double get totalSpent => totalSpentInMonth(DateTime.now());

  double get totalReceived => totalReceivedInMonth(DateTime.now());

  /// Income baseline for Plan / "Can I spend" stats: [BudgetProfile.monthlyIncome] when set,
  /// otherwise credits recorded this month. Avoids double-counting salary entered in onboarding
  /// and again as an income transaction.
  double get planIncomeBaselineDisplay {
    final p = profile;
    if (p == null) return 0;
    if (p.monthlyIncome > 0) return p.monthlyIncome;
    return totalReceived;
  }

  /// Money “in” this month for budgeting: profile baseline or tracked credits, whichever is higher.
  /// Avoids double-counting when salary is both in profile and logged as income (same amount caps out once).
  /// Extra credits (freelance, gifts) raise the ceiling vs profile alone.
  double get effectiveIncomeThisMonth {
    final p = profile;
    if (p == null) return totalReceived;
    return math.max(p.monthlyIncome, totalReceived);
  }

  double get runningBalance => totalReceived - totalSpent;

  /// All-time net (credits minus debits), all months.
  double get lifetimeNet => transactions.fold<double>(
        0,
        (s, t) => s + (t.isCredit ? t.amount : -t.amount),
      );

  List<TransactionEntry> transactionsForMonth(DateTime month) {
    final m = MonthUtils.startOfMonth(month);
    return transactions
        .where((t) => MonthUtils.isSameMonth(t.effectiveDate, m))
        .toList()
      ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
  }

  /// 50-30-20 targets vs spending for [month] (expense debits only).
  FiftyThirtyTwentySnapshot fiftyThirtyTwentyForMonth(DateTime month) {
    final p = profile;
    final received = totalReceivedInMonth(month);
    final baseline = (p != null && p.monthlyIncome > 0)
        ? p.monthlyIncome
        : received;

    double needs = 0;
    double wants = 0;
    double savings = 0;
    double other = 0;
    for (final e in transactions) {
      if (e.isCredit) continue;
      if (!MonthUtils.isSameMonth(e.effectiveDate, month)) continue;
      final k = e.spendingKind;
      if (k == null) {
        other += e.amount;
        continue;
      }
      switch (k) {
        case SpendingKind.need:
          needs += e.amount;
        case SpendingKind.want:
        case SpendingKind.other:
          wants += e.amount;
        case SpendingKind.saving:
          savings += e.amount;
      }
    }

    return FiftyThirtyTwentySnapshot(
      incomeBaseline: baseline,
      targetNeeds: baseline * 0.5,
      targetWants: baseline * 0.3,
      targetSavings: baseline * 0.2,
      spentNeeds: needs,
      spentWants: wants,
      spentSavings: savings,
      spentOther: other,
    );
  }

  Future<void> signOut() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.disconnectCloud();
      authMode = AuthMode.undecided;
      await _repository.saveAuthMode(authMode);
      profile = null;
      expenses = [];
      transactions = [];
      lastDecision = null;
      cloudSyncEnabled = false;
      successMessage = null;
    } catch (_) {
      errorMessage = 'Could not sign out.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes Firestore data and Firebase Auth user when signed in, then clears local storage.
  /// Pass [password] when using email/password sign-in (required to re-authenticate).
  Future<void> deleteAccount({String? password}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteAccount(password: password);
      authMode = AuthMode.undecided;
      await _repository.saveAuthMode(authMode);
      profile = null;
      expenses = [];
      transactions = [];
      lastDecision = null;
      cloudSyncEnabled = false;
      successMessage = null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Incorrect password. Try again.';
        case 'requires-recent-login':
          errorMessage =
              'Session expired. Sign out, sign in again, then delete your account.';
        default:
          errorMessage = e.message ?? 'Could not delete account (${e.code}).';
      }
    } on FirebaseException catch (e) {
      errorMessage = e.message ?? 'Cloud error: ${e.code}';
    } on ArgumentError catch (e) {
      errorMessage = e.message?.toString() ?? 'Invalid input.';
    } catch (e) {
      errorMessage = e is StateError
          ? e.message
          : 'Could not delete account. Check your connection and try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setActivityMonth(DateTime month) {
    activityMonth = MonthUtils.startOfMonth(month);
    notifyListeners();
  }

  double get currentAvailable {
    final currentProfile = profile;
    if (currentProfile == null) return 0;
    return effectiveIncomeThisMonth -
        currentProfile.totalObligations -
        totalSpent;
  }

  /// After obligations, safety buffer, and spending tracked this month (same basis as [currentAvailable] + buffer).
  double get safeToSpendAfterTrackedSpending {
    final p = profile;
    if (p == null) return 0;
    return effectiveIncomeThisMonth - p.totalObligations - p.safetyBuffer - totalSpent;
  }

  double get endOfMonthProjection => currentAvailable;

  bool get isInSafeZone {
    final currentProfile = profile;
    if (currentProfile == null) return false;
    return currentAvailable > currentProfile.safetyBuffer;
  }

  bool get needsAuthSelection => authMode == AuthMode.undecided;

  Future<void> initialize() async {
    isInitializing = true;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      authMode = await _repository.loadAuthMode();
      if (authMode == AuthMode.offline || authMode == AuthMode.anonymous) {
        authMode = AuthMode.undecided;
        await _repository.saveAuthMode(authMode);
      }

      if (!AppEnv.isFirebaseConfigured) {
        errorMessage =
            'Firebase is not configured. Add FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID, and FIREBASE_PROJECT_ID to .env.';
        return;
      }

      final initOk = await _repository.initializeCloud();
      if (!initOk) {
        errorMessage = 'Could not initialize Firebase.';
        return;
      }

      await _repository.syncAuthStateFromFirebase();

      if (_repository.isCloudReady) {
        authMode = AuthMode.email;
        await _repository.saveAuthMode(authMode);
        await _bootstrapForAuthMode(AuthMode.email);
        return;
      }

      authMode = AuthMode.undecided;
      await _repository.saveAuthMode(authMode);
    } catch (_) {
      errorMessage = 'Unable to load your data. Please try again.';
    } finally {
      isInitializing = false;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> continueWithEmail({
    required String email,
    required String password,
    required bool isRegister,
  }) async {
    if (email.isEmpty || !email.contains('@') || password.length < 6) {
      errorMessage = 'Enter a valid email and password (min 6 chars).';
      notifyListeners();
      return;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final initialized = await _repository.initializeCloud();
      if (!initialized) {
        throw Exception('Firebase not configured');
      }
      final connected = await _repository.connectEmail(
        email: email,
        password: password,
        isRegister: isRegister,
      );
      if (!connected) {
        throw Exception('Email sign-in failed');
      }
      await _repository.syncAuthStateFromFirebase();
      authMode = AuthMode.email;
      await _repository.saveAuthMode(authMode);
      await _bootstrapForAuthMode(AuthMode.email);
      successMessage =
          isRegister ? 'Account created and signed in.' : 'Signed in successfully.';
    } catch (_) {
      errorMessage = 'Email sign-in failed. Verify credentials and Firebase Auth.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile(BudgetProfile updatedProfile) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      profile = updatedProfile;
      await _repository.saveProfile(updatedProfile);
      cloudSyncEnabled = _repository.isCloudReady;
      successMessage = 'Profile updated successfully.';
    } catch (_) {
      errorMessage = 'Failed to save profile.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  ExpenseDecision previewExpense(
    double amount, {
    String expenseLabel = 'This expense',
  }) {
    final currentProfile = profile;
    if (currentProfile == null) {
      return const ExpenseDecision(
        status: DecisionStatus.notSafe,
        remainingBalance: 0,
        endOfMonthProjection: 0,
        message: 'Complete your profile setup first.',
        availableBefore: 0,
        expenseAmount: 0,
      );
    }
    return _decisionEngine.evaluate(
      profile: currentProfile,
      effectiveMonthlyIncome: effectiveIncomeThisMonth,
      currentSpent: totalSpent,
      newExpense: amount,
      expenseLabel: expenseLabel,
    );
  }

  void requestTab(int index) {
    pendingTabIndex = index;
    notifyListeners();
  }

  void consumePendingTab() {
    pendingTabIndex = null;
    notifyListeners();
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    String? category,
    String? note,
    SpendingKind? spendingKind,
    String? subCategory,
    String? incomeCategory,
    DateTime? transactionDate,
    PaymentMethod paymentMethod = PaymentMethod.online,
  }) async {
    final currentProfile = profile;
    if (currentProfile == null) {
      errorMessage = 'Set up your profile first.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      final txDay = transactionDate ?? now;
      final transaction = TransactionEntry(
        id: _uuid.v4(),
        title: title,
        amount: amount,
        type: type,
        category: category,
        note: note,
        spendingKind: type == TransactionType.debit ? spendingKind : null,
        subCategory: type == TransactionType.debit ? subCategory : null,
        incomeCategory: type == TransactionType.credit ? incomeCategory : null,
        createdAt: now,
        transactionDate: txDay,
        paymentMethod: paymentMethod,
      );
      transactions = [...transactions, transaction]
        ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));

      await _repository.addTransaction(
        profile: currentProfile,
        transaction: transaction,
      );

      if (type == TransactionType.debit) {
        lastDecision = previewExpense(amount, expenseLabel: title);
      }

      _refreshDerivedExpensesFromTransactions();
      cloudSyncEnabled = _repository.isCloudReady;
      successMessage = type == TransactionType.credit
          ? 'Income recorded.'
          : 'Expense recorded.';
    } catch (_) {
      errorMessage = 'Unable to add transaction right now.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense({
    required String name,
    required double amount,
  }) async {
    await addTransaction(
      title: name,
      amount: amount,
      type: TransactionType.debit,
      category: 'Expense',
    );
  }

  Future<void> deleteTransaction(String id) async {
    final currentProfile = profile;
    if (currentProfile == null) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      transactions = transactions.where((e) => e.id != id).toList();
      await _repository.deleteTransaction(
        profile: currentProfile,
        transactionId: id,
      );
      _refreshDerivedExpensesFromTransactions();
      cloudSyncEnabled = _repository.isCloudReady;
      successMessage = 'Transaction removed.';
    } catch (_) {
      errorMessage = 'Unable to remove transaction.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    await deleteTransaction(id);
  }

  Future<void> resetCurrentMonth() async {
    final currentProfile = profile;
    if (currentProfile == null) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.resetMonth(currentProfile);
      expenses = const [];
      transactions = const [];
      lastDecision = null;
      successMessage = 'Month data reset. You can start fresh now.';
    } catch (_) {
      errorMessage = 'Unable to reset month data.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  Future<void> _bootstrapForAuthMode(AuthMode mode) async {
    if (mode != AuthMode.email) {
      cloudSyncEnabled = false;
      profile = await _repository.loadProfile();
      await _loadLocalTransactions();
      return;
    }
    await _repository.initializeCloud();
    await _repository.syncAuthStateFromFirebase();
    cloudSyncEnabled = _repository.isCloudReady;
    profile = await _repository.loadProfile();
    await _loadLocalTransactions();
    if (cloudSyncEnabled) {
      try {
        final restored = await _repository.restoreFromCloud();
        final restoredTransactions =
            await _repository.restoreTransactionsFromCloud();
        profile = restored.profile;
        expenses = restored.expenses;
        transactions = [...restoredTransactions]
          ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
        _refreshDerivedExpensesFromTransactions();
      } catch (_) {
        // First-run cloud data may not exist yet.
      }
    }
  }

  Future<void> _loadLocalTransactions() async {
    transactions = await _repository.loadTransactions();
    transactions = [...transactions]
      ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
    if (transactions.isEmpty) {
      expenses = await _repository.loadExpenses();
      if (expenses.isNotEmpty) {
        transactions = expenses
            .map(
              (e) => TransactionEntry(
                id: e.id,
                title: e.name,
                amount: e.amount,
                type: TransactionType.debit,
                createdAt: e.createdAt,
                transactionDate: e.createdAt,
                category: 'Expense',
                spendingKind: SpendingKind.other,
                subCategory: 'Other',
                paymentMethod: null,
              ),
            )
            .toList()
          ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
      }
    }
    _refreshDerivedExpensesFromTransactions();
  }

  void _refreshDerivedExpensesFromTransactions() {
    final debits = transactions.where((e) => !e.isCredit).toList()
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
    expenses = debits
        .map(
          (e) => ExpenseEntry(
            id: e.id,
            name: e.title,
            amount: e.amount,
            createdAt: e.createdAt,
          ),
        )
        .toList();
  }
}
