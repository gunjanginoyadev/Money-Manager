import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/app_env.dart';
import '../../../../core/utils/budget_period_utils.dart';
import '../../../../core/utils/month_utils.dart';
import '../../data/budget_repository.dart';
import '../../domain/models/auth_mode.dart';
import '../../domain/models/budget_profile.dart';
import '../../domain/models/month_liquidity_snapshot.dart';
import '../../domain/models/fifty_thirty_twenty_snapshot.dart';
import '../../domain/models/fifty_thirty_baseline_mode.dart';
import '../../domain/models/expense_decision.dart';
import '../../domain/models/expense_entry.dart';
import '../../domain/models/spending_kind.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/models/quick_add_preset.dart';
import '../../domain/models/saving_entry.dart';
import '../../domain/models/saving_goal.dart';
import '../../domain/models/transaction_entry.dart';
import '../../domain/services/decision_engine.dart';

class BudgetViewModel extends ChangeNotifier {
  BudgetViewModel(this._repository);

  final BudgetRepository _repository;
  final DecisionEngine _decisionEngine = const DecisionEngine();
  final Uuid _uuid = const Uuid();

  bool _initializeInFlight = false;

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
  SavingGoal? savingGoal;
  List<SavingEntry> savingEntries = const [];

  // Regret prompt (worth-it) UX: keep it lightweight and non-spammy.
  bool _regretPromptShownThisSession = false;

  /// When set, [HomeShell] switches to this tab once (Home=0, Report=1, Spend=2, Profile=3).
  int? pendingTabIndex;

  /// Start of the budget period selected on Report (aligned to [BudgetProfile.salaryDayOfMonth]).
  DateTime activityMonth = MonthUtils.startOfMonth(DateTime.now());

  /// 50-30-20 targets on Home: profile / month income / spend pool.
  FiftyThirtyBaselineMode fiftyThirtyBaselineMode =
      FiftyThirtyBaselineMode.monthIncomeEntries;

  /// Home “Quick add” shortcuts (device-local).
  List<QuickAddPreset> quickAddPresets = List<QuickAddPreset>.from(
    kDefaultQuickAddPresets,
  );

  String? get userEmail => FirebaseAuth.instance.currentUser?.email;

  int get _payDay => (profile?.salaryDayOfMonth ?? 1).clamp(1, 31);

  /// First day of the budget period that contains “today”.
  DateTime get currentBudgetPeriodStart =>
      BudgetPeriodUtils.startOfBudgetPeriodContaining(DateTime.now(), _payDay);

  /// Inclusive days left in the current budget period (for pacing).
  int get daysLeftInCurrentBudgetPeriod =>
      BudgetPeriodUtils.daysLeftInclusiveInPeriod(DateTime.now(), _payDay);

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

  double totalSpentInBudgetPeriod(DateTime periodStart) {
    final pay = _payDay;
    return transactions
        .where(
          (e) =>
              !e.isCredit &&
              BudgetPeriodUtils.isDateInBudgetPeriod(
                e.effectiveDate,
                periodStart,
                pay,
              ),
        )
        .fold<double>(0, (s, e) => s + e.amount);
  }

  double totalReceivedInBudgetPeriod(DateTime periodStart) {
    final pay = _payDay;
    return transactions
        .where(
          (e) =>
              e.isCredit &&
              BudgetPeriodUtils.isDateInBudgetPeriod(
                e.effectiveDate,
                periodStart,
                pay,
              ),
        )
        .fold<double>(0, (s, e) => s + e.amount);
  }

  /// Current **budget period** (payday-aligned), or calendar month if no profile.
  double get totalSpent => profile == null
      ? totalSpentInMonth(DateTime.now())
      : totalSpentInBudgetPeriod(currentBudgetPeriodStart);

  double get totalReceived => profile == null
      ? totalReceivedInMonth(DateTime.now())
      : totalReceivedInBudgetPeriod(currentBudgetPeriodStart);

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

  List<TransactionEntry> transactionsForBudgetPeriod(DateTime periodStart) {
    final p = profile;
    if (p == null) {
      final m = MonthUtils.startOfMonth(periodStart);
      return transactions
          .where((t) => MonthUtils.isSameMonth(t.effectiveDate, m))
          .toList()
        ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
    }
    final pay = _payDay;
    return transactions
        .where(
          (t) => BudgetPeriodUtils.isDateInBudgetPeriod(
                t.effectiveDate,
                periodStart,
                pay,
              ),
        )
        .toList()
      ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
  }

  /// Transactions in the budget period that starts at [periodStart] (Report / Home).
  List<TransactionEntry> transactionsForMonth(DateTime periodStart) {
    final p = profile;
    if (p == null) {
      final m = MonthUtils.startOfMonth(periodStart);
      return transactions
          .where((t) => MonthUtils.isSameMonth(t.effectiveDate, m))
          .toList()
        ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
    }
    final start =
        BudgetPeriodUtils.startOfBudgetPeriodContaining(periodStart, _payDay);
    return transactionsForBudgetPeriod(start);
  }

  /// Inclusive date range in local time (by calendar day).
  List<TransactionEntry> transactionsInDateRange(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    return transactions
        .where((t) {
          final d = t.effectiveDate.toLocal();
          return !d.isBefore(s) && !d.isAfter(e);
        })
        .toList()
      ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
  }

  MonthLiquiditySnapshot monthLiquidityForMonth(DateTime periodStart) {
    return liquiditySnapshotForTransactions(transactionsForMonth(periodStart));
  }

  MonthLiquiditySnapshot monthLiquidityForDateRange(DateTime start, DateTime end) {
    return liquiditySnapshotForTransactions(
      transactionsInDateRange(start, end),
    );
  }

  /// 50-30-20 targets vs spending for the budget period starting at [periodStart] (expense debits only).
  FiftyThirtyTwentySnapshot fiftyThirtyTwentyForMonth(DateTime periodStart) {
    final p = profile;
    final pay = _payDay;
    final start =
        BudgetPeriodUtils.startOfBudgetPeriodContaining(periodStart, pay);
    final received = totalReceivedInBudgetPeriod(start);
    final double baseline;
    switch (fiftyThirtyBaselineMode) {
      case FiftyThirtyBaselineMode.profileSalary:
        baseline = (p != null && p.monthlyIncome > 0)
            ? p.monthlyIncome
            : received;
      case FiftyThirtyBaselineMode.monthIncomeEntries:
        baseline = received;
      case FiftyThirtyBaselineMode.spendPool:
        baseline = (p != null && p.spendBudgetFromIncome > 0)
            ? p.spendBudgetFromIncome
            : received;
    }

    double needs = 0;
    double wants = 0;
    double savings = 0;
    double other = 0;
    for (final e in transactions) {
      if (e.isCredit) continue;
      if (!BudgetPeriodUtils.isDateInBudgetPeriod(
        e.effectiveDate,
        start,
        pay,
      )) {
        continue;
      }
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

    final sn = p?.splitNeeds ?? 0.5;
    final sw = p?.splitWants ?? 0.3;
    final ss = p?.splitSavings ?? 0.2;

    return FiftyThirtyTwentySnapshot(
      incomeBaseline: baseline,
      targetNeeds: baseline * sn,
      targetWants: baseline * sw,
      targetSavings: baseline * ss,
      spentNeeds: needs,
      spentWants: wants,
      spentSavings: savings,
      spentOther: other,
    );
  }

  /// One point per calendar day in the budget period: total **expense** debits that day.
  List<({DateTime day, double amount})> dailyExpenseTotalsForBudgetPeriod(
    DateTime periodStart,
  ) {
    final pay = _payDay;
    final start = BudgetPeriodUtils.startOfBudgetPeriodContaining(
      periodStart,
      pay,
    );
    final nextStart = BudgetPeriodUtils.nextBudgetPeriodStartAfter(start, pay);
    final byDay = <DateTime, double>{};
    for (final t in transactions) {
      if (t.isCredit) continue;
      if (!BudgetPeriodUtils.isDateInBudgetPeriod(
        t.effectiveDate,
        start,
        pay,
      )) {
        continue;
      }
      final d = BudgetPeriodUtils.calendarDay(t.effectiveDate.toLocal());
      byDay[d] = (byDay[d] ?? 0) + t.amount;
    }
    final out = <({DateTime day, double amount})>[];
    for (var d = BudgetPeriodUtils.calendarDay(start);
        d.isBefore(nextStart);
        d = d.add(const Duration(days: 1))) {
      out.add((day: d, amount: byDay[d] ?? 0));
    }
    return out;
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
      _initializeInFlight = false;
      fiftyThirtyBaselineMode = FiftyThirtyBaselineMode.monthIncomeEntries;
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

  void setActivityMonth(DateTime anyDateInPeriod) {
    final p = profile;
    if (p == null) {
      activityMonth = MonthUtils.startOfMonth(anyDateInPeriod);
    } else {
      activityMonth = BudgetPeriodUtils.startOfBudgetPeriodContaining(
        anyDateInPeriod,
        _payDay,
      );
    }
    notifyListeners();
  }

  /// Whether Report can go to the next budget period without passing “today’s” period.
  bool get canAdvanceReportToNextPeriod {
    final p = profile;
    if (p == null) return false;
    final pay = _payDay;
    final next =
        BudgetPeriodUtils.nextBudgetPeriodStartAfter(activityMonth, pay);
    final current = currentBudgetPeriodStart;
    return !next.isAfter(current);
  }

  void shiftActivityBudgetPeriod(int delta) {
    final p = profile;
    if (p == null) return;
    var cursor = activityMonth;
    final pay = _payDay;
    final n = delta.abs();
    for (var i = 0; i < n; i++) {
      cursor = delta > 0
          ? BudgetPeriodUtils.nextBudgetPeriodStartAfter(cursor, pay)
          : BudgetPeriodUtils.previousBudgetPeriodStart(cursor, pay);
    }
    activityMonth = cursor;
    notifyListeners();
  }

  /// 50-30-20 snapshot for the current budget period (same baseline as Home’s dropdown).
  FiftyThirtyTwentySnapshot get fiftyThirtySnapshotThisMonth =>
      fiftyThirtyTwentyForMonth(currentBudgetPeriodStart);

  /// 30% Wants cap for this month (matches Home “Wants” target).
  double get wantsBudgetThisMonth => fiftyThirtySnapshotThisMonth.targetWants;

  /// Want-tagged spending this month (same buckets as Home “Wants” bar).
  double get wantsSpentThisMonth => fiftyThirtySnapshotThisMonth.spentWants;

  /// Remaining in the **Wants** bucket: 30% of baseline − [wantsSpentThisMonth]. Aligns with Home when the same baseline mode is selected.
  double get currentAvailable {
    if (profile == null) return 0;
    final s = fiftyThirtySnapshotThisMonth;
    if (s.incomeBaseline <= 0) return 0;
    return s.targetWants - s.spentWants;
  }

  /// Same as [currentAvailable].
  double get safeToSpendAfterTrackedSpending => currentAvailable;

  double get endOfMonthProjection => currentAvailable;

  bool get isInSafeZone {
    if (profile == null) return false;
    final s = fiftyThirtySnapshotThisMonth;
    if (s.incomeBaseline <= 0) return false;
    return currentAvailable > 0;
  }

  /// **M** = R ÷ effective **N** (your N, or about one slot per week left when N is 0). Null if remaining Wants is negative.
  static double? maxPerOutingWants({
    required double remainingWants,
    required int outingsRemaining,
    required int daysLeftInBudgetPeriod,
  }) {
    if (remainingWants < 0) return null;
    final n = DecisionEngine.effectiveOutingCountForPacing(
      outingsRemaining: outingsRemaining,
      daysLeftInBudgetPeriod: daysLeftInBudgetPeriod,
    );
    return remainingWants / n;
  }

  /// Safer cap: **M × 0.8** (buffer for surprises).
  static double? bufferedMaxPerOutingWants({
    required double remainingWants,
    required int outingsRemaining,
    required int daysLeftInBudgetPeriod,
  }) {
    final m = maxPerOutingWants(
      remainingWants: remainingWants,
      outingsRemaining: outingsRemaining,
      daysLeftInBudgetPeriod: daysLeftInBudgetPeriod,
    );
    return m != null ? m * 0.8 : null;
  }

  /// Same rule as [DecisionEngine.effectiveOutingCountForPacing] (for UI copy).
  static int effectiveOutingCountForPacing({
    required int outingsRemaining,
    required int daysLeftInBudgetPeriod,
  }) =>
      DecisionEngine.effectiveOutingCountForPacing(
        outingsRemaining: outingsRemaining,
        daysLeftInBudgetPeriod: daysLeftInBudgetPeriod,
      );

  bool get needsAuthSelection => authMode == AuthMode.undecided;

  Future<void> initialize() async {
    if (_initializeInFlight) return;
    _initializeInFlight = true;
    isInitializing = true;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _loadQuickAddPresets();
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
        await _loadFiftyThirtyBaselinePreference();
        return;
      }

      authMode = AuthMode.undecided;
      await _repository.saveAuthMode(authMode);
    } on FirebaseException catch (e) {
      errorMessage = e.message ?? 'Firebase error: ${e.code}';
    } catch (e) {
      errorMessage = e is StateError ? e.message : 'Unable to load your data. Please try again.';
    } finally {
      isInitializing = false;
      isLoading = false;
      _initializeInFlight = false;
      notifyListeners();
    }
  }

  /// Called when connectivity returns after an outage (signed-in users).
  Future<void> refreshFromCloudIfSignedIn() async {
    if (isInitializing) return;
    await _repository.initializeCloud();
    await _repository.syncAuthStateFromFirebase();
    if (!_repository.isCloudReady) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _bootstrapForAuthMode(AuthMode.email);
      cloudSyncEnabled = _repository.isCloudReady;
      await _loadFiftyThirtyBaselinePreference();
    } on FirebaseException catch (e) {
      errorMessage = e.message ?? 'Could not sync (${e.code}).';
    } catch (e) {
      errorMessage = e is StateError
          ? e.message
          : 'Could not refresh data. Check your connection.';
    } finally {
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
        throw StateError('Firebase is not configured for this build.');
      }
      final connected = await _repository.connectEmail(
        email: email,
        password: password,
        isRegister: isRegister,
      );
      if (!connected) {
        throw StateError('Email sign-in failed.');
      }
      await _repository.syncAuthStateFromFirebase();
      authMode = AuthMode.email;
      await _repository.saveAuthMode(authMode);
      await _bootstrapForAuthMode(AuthMode.email);
      await _loadFiftyThirtyBaselinePreference();
      successMessage =
          isRegister ? 'Account created and signed in.' : 'Signed in successfully.';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
        case 'user-not-found':
          errorMessage = 'No account found for this email.';
        case 'wrong-password':
          errorMessage = 'Incorrect password. Try again.';
        case 'email-already-in-use':
          errorMessage = 'This email is already registered. Try signing in.';
        case 'weak-password':
          errorMessage = 'Password is too weak (min 6 characters).';
        case 'operation-not-allowed':
          errorMessage =
              'Email/password sign-in is disabled in Firebase Auth. Enable it in the Firebase console.';
        case 'network-request-failed':
          errorMessage = 'Network error. Check your connection and try again.';
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Wait a bit and try again.';
        case 'unauthorized-domain':
          errorMessage =
              'This web domain is not authorized for Firebase Auth. Add your domain in Firebase Console → Authentication → Settings → Authorized domains.';
        default:
          errorMessage = e.message ?? 'Auth error: ${e.code}';
      }
    } on FirebaseException catch (e) {
      errorMessage = e.message ?? 'Firebase error: ${e.code}';
    } on StateError catch (e) {
      errorMessage = e.message;
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
      final previousPay = profile?.salaryDayOfMonth;
      profile = updatedProfile;
      await _repository.saveProfile(updatedProfile);
      cloudSyncEnabled = _repository.isCloudReady;
      successMessage = 'Profile updated successfully.';
      if (previousPay != updatedProfile.salaryDayOfMonth) {
        setActivityMonth(DateTime.now());
      }
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
      return ExpenseDecision(
        status: DecisionStatus.notSafe,
        remainingBalance: 0,
        endOfMonthProjection: 0,
        message: 'Complete your profile setup first.',
        availableBefore: 0,
        expenseAmount: amount,
        suggestedSpendCap: null,
      );
    }
    final snap = fiftyThirtySnapshotThisMonth;
    if (snap.incomeBaseline <= 0) {
      return ExpenseDecision(
        status: DecisionStatus.notSafe,
        remainingBalance: 0,
        endOfMonthProjection: 0,
        message:
            'Log income in this budget period or change the 50-30-20 baseline on Home so your Wants target (30%) can be calculated.',
        availableBefore: 0,
        expenseAmount: amount,
        suggestedSpendCap: null,
      );
    }
    return _decisionEngine.evaluateSpendBudget(
      monthlySpendBudget: snap.targetWants,
      spentThisMonth: snap.spentWants,
      newExpense: amount,
      outingsRemaining: currentProfile.remainingOutingsCount,
      daysLeftInBudgetPeriod: daysLeftInCurrentBudgetPeriod,
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
    String? id,
    bool suppressGlobalLoading = false,
  }) async {
    final currentProfile = profile;
    if (currentProfile == null) {
      errorMessage = 'Set up your profile first.';
      notifyListeners();
      return;
    }

    if (!suppressGlobalLoading) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }
    try {
      final now = DateTime.now();
      final txDay = transactionDate ?? now;
      final isWantDebit = type == TransactionType.debit && spendingKind == SpendingKind.want;
      final transaction = TransactionEntry(
        id: id ?? _uuid.v4(),
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
        regretPromptAt: isWantDebit ? txDay.add(const Duration(hours: 24)) : null,
        regretAnswered: !isWantDebit,
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
      if (!suppressGlobalLoading) {
        isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> updateTransaction({
    required String id,
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

    final idx = transactions.indexWhere((e) => e.id == id);
    if (idx < 0) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final old = transactions[idx];
      final txDay = transactionDate ?? old.transactionDate ?? old.createdAt;
      final isDebit = type == TransactionType.debit;
      final sk = isDebit ? spendingKind : null;
      final wasWant = old.spendingKind == SpendingKind.want;
      final nowWant = isDebit && sk == SpendingKind.want;

      int? regretScore;
      DateTime? regretPromptAt;
      bool regretAnswered;

      if (!isDebit) {
        regretScore = null;
        regretPromptAt = null;
        regretAnswered = true;
      } else if (nowWant) {
        if (wasWant) {
          regretScore = old.regretScore;
          regretPromptAt = old.regretPromptAt;
          regretAnswered = old.regretAnswered;
        } else {
          regretScore = null;
          regretPromptAt = txDay.add(const Duration(hours: 24));
          regretAnswered = false;
        }
      } else {
        regretScore = null;
        regretPromptAt = null;
        regretAnswered = true;
      }

      final updated = TransactionEntry(
        id: old.id,
        title: title,
        amount: amount,
        type: type,
        createdAt: old.createdAt,
        transactionDate: txDay,
        category: category,
        note: note,
        spendingKind: sk,
        subCategory: isDebit ? subCategory : null,
        incomeCategory: type == TransactionType.credit ? incomeCategory : null,
        paymentMethod: paymentMethod,
        regretScore: regretScore,
        regretPromptAt: regretPromptAt,
        regretAnswered: regretAnswered,
      );

      transactions = [
        for (var i = 0; i < transactions.length; i++)
          if (i == idx) updated else transactions[i],
      ]..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));

      await _repository.upsertTransaction(
        profile: currentProfile,
        transaction: updated,
      );

      if (type == TransactionType.debit) {
        lastDecision = previewExpense(amount, expenseLabel: title);
      }

      _refreshDerivedExpensesFromTransactions();
      cloudSyncEnabled = _repository.isCloudReady;
      successMessage = 'Transaction updated.';
    } catch (_) {
      errorMessage = 'Unable to update transaction.';
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

  Future<void> deleteTransaction(
    String id, {
    bool suppressGlobalLoading = false,
  }) async {
    final currentProfile = profile;
    if (currentProfile == null) return;
    if (!suppressGlobalLoading) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }
    try {
      transactions = transactions.where((e) => e.id != id).toList();
      await _repository.deleteTransaction(
        profile: currentProfile,
        transactionId: id,
      );
      _refreshDerivedExpensesFromTransactions();
      cloudSyncEnabled = _repository.isCloudReady;
      if (!suppressGlobalLoading) {
        successMessage = 'Transaction removed.';
      }
    } catch (_) {
      errorMessage = 'Unable to remove transaction.';
    } finally {
      if (!suppressGlobalLoading) {
        isLoading = false;
      }
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

  /// Returns eligible Want debits that are due for a “was it worth it?” prompt.
  List<TransactionEntry> pendingRegretPrompts({int limit = 2}) {
    final now = DateTime.now();
    final due = transactions
        .where(
          (t) =>
              !t.isCredit &&
              t.spendingKind == SpendingKind.want &&
              t.regretAnswered == false &&
              t.regretPromptAt != null &&
              now.isAfter(t.regretPromptAt!),
        )
        .toList()
      ..sort((a, b) {
        final aa = a.regretPromptAt ?? a.effectiveDate;
        final bb = b.regretPromptAt ?? b.effectiveDate;
        return aa.compareTo(bb);
      });
    if (due.length <= limit) return due;
    return due.take(limit).toList();
  }

  /// One-per-session guard for showing the prompt UI.
  TransactionEntry? nextRegretPromptForSession() {
    if (_regretPromptShownThisSession) return null;
    final due = pendingRegretPrompts(limit: 1);
    if (due.isEmpty) return null;
    _regretPromptShownThisSession = true;
    return due.first;
  }

  Future<void> submitRegretScore({
    required String transactionId,
    required int score,
  }) async {
    final currentProfile = profile;
    if (currentProfile == null) return;

    final idx = transactions.indexWhere((t) => t.id == transactionId);
    if (idx < 0) return;

    final clamped = score.clamp(-2, 2);
    final updated = transactions[idx].copyWith(
      regretScore: clamped,
      regretAnswered: true,
    );

    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      transactions = [
        for (var i = 0; i < transactions.length; i++)
          if (i == idx) updated else transactions[i],
      ];
      await _repository.upsertTransaction(
        profile: currentProfile,
        transaction: updated,
      );
      successMessage = 'Saved.';
    } catch (_) {
      errorMessage = 'Unable to save feedback right now.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFiftyThirtyBaselinePreference() async {
    try {
      fiftyThirtyBaselineMode = await _repository.loadFiftyThirtyBaselineMode();
      notifyListeners();
    } catch (_) {
      // Keep default if prefs unavailable.
    }
  }

  Future<void> _loadQuickAddPresets() async {
    try {
      quickAddPresets = await _repository.loadQuickAddPresets();
      notifyListeners();
    } catch (_) {
      quickAddPresets = List<QuickAddPreset>.from(kDefaultQuickAddPresets);
    }
  }

  Future<void> setQuickAddPresets(List<QuickAddPreset> presets) async {
    final capped =
        presets.length > 12 ? presets.sublist(0, 12) : List<QuickAddPreset>.from(presets);
    quickAddPresets = capped;
    notifyListeners();
    try {
      await _repository.saveQuickAddPresets(quickAddPresets);
    } catch (_) {
      // Prefs failed; list still updated in memory for this session.
    }
  }

  Future<void> setFiftyThirtyBaselineMode(FiftyThirtyBaselineMode mode) async {
    if (fiftyThirtyBaselineMode == mode) return;
    fiftyThirtyBaselineMode = mode;
    notifyListeners();
    try {
      await _repository.saveFiftyThirtyBaselineMode(mode);
    } catch (_) {
      // Preference failed; UI mode still updated for this session.
    }
  }

  Future<void> _bootstrapForAuthMode(AuthMode mode) async {
    if (mode != AuthMode.email) {
      cloudSyncEnabled = false;
      profile = null;
      expenses = [];
      transactions = [];
      savingGoal = null;
      savingEntries = [];
      return;
    }
    await _repository.initializeCloud();
    await _repository.syncAuthStateFromFirebase();
    cloudSyncEnabled = _repository.isCloudReady;
    if (!cloudSyncEnabled) {
      profile = null;
      expenses = [];
      transactions = [];
      savingGoal = null;
      savingEntries = [];
      return;
    }
    await _repository.clearLegacyLocalCache();
    profile = await _repository.loadProfile();
    await _loadTransactionsFromCloud();
    await _loadSavingFromCloud();
    _syncActivityPeriodAfterProfileLoad();
  }

  Future<void> _loadSavingFromCloud() async {
    savingGoal = await _repository.loadSavingGoal();
    savingEntries = await _repository.loadSavingEntries();
    if (savingGoal == null) {
      // Keep entries empty if no goal (one active goal model).
      savingEntries = const [];
    } else {
      final gid = savingGoal!.id;
      savingEntries = savingEntries.where((e) => e.goalId == gid).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
  }

  Future<void> createSavingGoal({
    required String title,
    required double targetAmount,
    required GoalType type,
    DateTime? targetDate,
  }) async {
    final currentProfile = profile;
    if (currentProfile == null) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final goal = SavingGoal(
        id: _uuid.v4(),
        title: title.trim(),
        targetAmount: targetAmount,
        savedAmount: 0,
        type: type,
        createdAt: DateTime.now(),
        targetDate: targetDate,
        isCompleted: false,
      );
      savingGoal = goal;
      savingEntries = const [];
      await _repository.saveSavingGoal(profile: currentProfile, goal: goal);
      successMessage = 'Goal created.';
    } catch (_) {
      errorMessage = 'Unable to save goal right now.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  double _totalSavedForCurrentGoal() {
    final gid = savingGoal?.id;
    if (gid == null) return 0;
    return savingEntries
        .where((e) => e.goalId == gid)
        .fold<double>(0, (s, e) => s + e.amount);
  }

  Future<void> addSavingEntry({
    required double amount,
    String? note,
    DateTime? date,
  }) async {
    final currentProfile = profile;
    final goal = savingGoal;
    if (currentProfile == null || goal == null) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final when = date ?? DateTime.now();
      final txId = _uuid.v4();
      final entry = SavingEntry(
        id: _uuid.v4(),
        goalId: goal.id,
        amount: amount,
        date: when,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        transactionId: txId,
      );
      savingEntries = [entry, ...savingEntries];

      final totalSaved = _totalSavedForCurrentGoal();
      final completed = totalSaved >= goal.targetAmount;
      final updatedGoal = goal.copyWith(
        savedAmount: totalSaved,
        isCompleted: completed,
      );
      savingGoal = updatedGoal;

      // Keep reports / 50-30-20 correct: also log a Saving transaction.
      await addTransaction(
        title: 'Saved for goal: ${goal.title}',
        amount: amount,
        type: TransactionType.debit,
        spendingKind: SpendingKind.saving,
        subCategory: 'Goal',
        note: note,
        transactionDate: when,
        paymentMethod: PaymentMethod.online,
        id: txId,
        suppressGlobalLoading: true,
      );

      await _repository.addSavingEntry(profile: currentProfile, entry: entry);
      await _repository.saveSavingGoal(profile: currentProfile, goal: updatedGoal);
      successMessage = completed ? 'Goal completed!' : 'Saved.';
    } catch (_) {
      errorMessage = 'Unable to add saving entry right now.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSavingEntry({
    required String entryId,
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    final currentProfile = profile;
    final goal = savingGoal;
    if (currentProfile == null || goal == null) return;
    if (amount <= 0) return;

    final idx = savingEntries.indexWhere((e) => e.id == entryId);
    if (idx < 0) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final old = savingEntries[idx];
      final trimmed = note?.trim();
      final updated = SavingEntry(
        id: old.id,
        goalId: old.goalId,
        amount: amount,
        date: date,
        note: trimmed == null || trimmed.isEmpty ? null : trimmed,
        transactionId: old.transactionId,
      );
      savingEntries = [
        for (var i = 0; i < savingEntries.length; i++)
          if (i == idx) updated else savingEntries[i],
      ];

      final tid = old.transactionId;
      if (tid != null) {
        final tIdx = transactions.indexWhere((t) => t.id == tid);
        if (tIdx >= 0) {
          final t = transactions[tIdx];
          final newT = t.copyWith(
            amount: amount,
            note: updated.note,
            transactionDate: date,
            title: 'Saved for goal: ${goal.title}',
          );
          transactions = [
            for (var i = 0; i < transactions.length; i++)
              if (i == tIdx) newT else transactions[i],
          ];
          await _repository.upsertTransaction(
            profile: currentProfile,
            transaction: newT,
          );
          _refreshDerivedExpensesFromTransactions();
        }
      }

      final totalSaved = _totalSavedForCurrentGoal();
      final updatedGoal = goal.copyWith(
        savedAmount: totalSaved,
        isCompleted: totalSaved >= goal.targetAmount,
      );
      savingGoal = updatedGoal;

      await _repository.addSavingEntry(profile: currentProfile, entry: updated);
      await _repository.saveSavingGoal(profile: currentProfile, goal: updatedGoal);
      successMessage = 'Entry updated.';
    } catch (_) {
      errorMessage = 'Unable to update entry.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSavingEntry(String entryId) async {
    final currentProfile = profile;
    final goal = savingGoal;
    if (currentProfile == null || goal == null) return;

    final eIdx = savingEntries.indexWhere((e) => e.id == entryId);
    if (eIdx < 0) return;
    final entry = savingEntries[eIdx];

    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      savingEntries =
          savingEntries.where((e) => e.id != entryId).toList();

      final tid = entry.transactionId;
      if (tid != null) {
        await deleteTransaction(tid, suppressGlobalLoading: true);
      }

      await _repository.deleteSavingEntry(
        profile: currentProfile,
        entryId: entryId,
      );

      final totalSaved = _totalSavedForCurrentGoal();
      final updatedGoal = goal.copyWith(
        savedAmount: totalSaved,
        isCompleted: totalSaved >= goal.targetAmount,
      );
      savingGoal = updatedGoal;
      await _repository.saveSavingGoal(profile: currentProfile, goal: updatedGoal);
      successMessage = 'Entry removed.';
    } catch (_) {
      errorMessage = 'Unable to delete entry.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _syncActivityPeriodAfterProfileLoad() {
    final p = profile;
    if (p == null) return;
    activityMonth = BudgetPeriodUtils.startOfBudgetPeriodContaining(
      DateTime.now(),
      (p.salaryDayOfMonth).clamp(1, 31),
    );
  }

  Future<void> _loadTransactionsFromCloud() async {
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
