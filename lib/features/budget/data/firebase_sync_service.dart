import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_env.dart';
import '../domain/models/budget_profile.dart';
import '../domain/models/expense_entry.dart';
import '../domain/models/transaction_entry.dart';

class FirebaseSyncService {
  FirebaseSyncService();

  bool _initialized = false;
  String? _userId;

  Future<bool> initializeIfConfigured() async {
    if (!AppEnv.isFirebaseConfigured) return false;
    if (_initialized) return true;

    if (Firebase.apps.isEmpty) {
      if (kIsWeb) {
        final authDomain = AppEnv.firebaseAuthDomain.isNotEmpty
            ? AppEnv.firebaseAuthDomain
            : AppEnv.derivedAuthDomain;
        final storageBucket = AppEnv.firebaseStorageBucket.isNotEmpty
            ? AppEnv.firebaseStorageBucket
            : AppEnv.derivedStorageBucket;

        final options = FirebaseOptions(
          apiKey: AppEnv.firebaseApiKey,
          appId: AppEnv.firebaseAppId,
          messagingSenderId: AppEnv.firebaseMessagingSenderId,
          projectId: AppEnv.firebaseProjectId,
          authDomain: authDomain,
          storageBucket: storageBucket.isEmpty ? null : storageBucket,
          measurementId: AppEnv.firebaseMeasurementId.isEmpty
              ? null
              : AppEnv.firebaseMeasurementId,
        );
        await Firebase.initializeApp(options: options);
      } else {
        // Prefer native config (google-services.json / plist). If missing, fall back
        // to explicit options so Android + desktop can still run in dev.
        try {
          await Firebase.initializeApp();
        } catch (_) {
          final storageBucket = AppEnv.firebaseStorageBucket.isNotEmpty
              ? AppEnv.firebaseStorageBucket
              : AppEnv.derivedStorageBucket;
          final options = FirebaseOptions(
            apiKey: AppEnv.firebaseApiKey,
            appId: AppEnv.firebaseAppId,
            messagingSenderId: AppEnv.firebaseMessagingSenderId,
            projectId: AppEnv.firebaseProjectId,
            storageBucket: storageBucket.isEmpty ? null : storageBucket,
            measurementId: AppEnv.firebaseMeasurementId.isEmpty
                ? null
                : AppEnv.firebaseMeasurementId,
          );
          await Firebase.initializeApp(options: options);
        }
      }
    }
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _initialized = true;
    return true;
  }

  bool get isReady => _initialized && (_userId?.isNotEmpty ?? false);

  /// Drops anonymous sessions (email/password required). Sets [_userId] for email users.
  Future<void> syncAuthStateFromFirebase() async {
    if (!await initializeIfConfigured()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _userId = null;
      return;
    }
    if (user.isAnonymous) {
      await FirebaseAuth.instance.signOut();
      _userId = null;
      return;
    }
    _userId = user.uid;
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
    required bool isRegister,
  }) async {
    final enabled = await initializeIfConfigured();
    if (!enabled) return false;
    if (isRegister) {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _userId = credential.user?.uid;
    } else {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _userId = credential.user?.uid;
    }
    return _userId != null;
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    await FirebaseAuth.instance.signOut();
    _userId = null;
  }

  Future<void> syncProfile(BudgetProfile profile) async {
    if (!isReady) return;
    final userId = _userId!;

    final db = FirebaseFirestore.instance;
    await db.collection('users').doc(userId).set({
      'profile': profile.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> upsertExpense(ExpenseEntry expense) async {
    if (!isReady) return;
    final userId = _userId!;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expense.id)
        .set(expense.toJson(), SetOptions(merge: true));
  }

  Future<void> removeExpense(String expenseId) async {
    if (!isReady) return;
    final userId = _userId!;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  Future<void> _deleteAllDocsInCollection(
    CollectionReference<Map<String, dynamic>> ref,
  ) async {
    const batchSize = 400;
    while (true) {
      final snapshot = await ref.limit(batchSize).get();
      if (snapshot.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> clearExpenses() async {
    if (!isReady) return;
    final userId = _userId!;
    await _deleteAllDocsInCollection(
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('expenses'),
    );
  }

  Future<void> clearTransactions() async {
    if (!isReady) return;
    final userId = _userId!;
    await _deleteAllDocsInCollection(
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions'),
    );
  }

  /// Deletes all Firestore data under [users/{uid}], then deletes the Firebase Auth user.
  ///
  /// [password] is required for email/password accounts: Firebase must verify the user
  /// recently ([reauthenticateWithCredential]) before [User.delete], or deletion fails
  /// with `requires-recent-login`.
  Future<void> deleteAllUserDataAndAuthAccount({
    required String password,
  }) async {
    if (!await initializeIfConfigured()) {
      throw StateError('Firebase not configured');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      _userId = null;
      throw StateError('No signed-in user');
    }
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw StateError('This account has no email; deletion is not supported here.');
    }

    final cred = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(cred);

    final uid = user.uid;
    _userId = uid;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(uid);

    await _deleteAllDocsInCollection(userRef.collection('expenses'));
    await _deleteAllDocsInCollection(userRef.collection('transactions'));

    await userRef.delete();
    await user.delete();
    _userId = null;
  }

  Future<void> fullSync({
    required BudgetProfile profile,
    required List<ExpenseEntry> expenses,
  }) async {
    if (!isReady) return;
    await syncProfile(profile);
    for (final expense in expenses) {
      await upsertExpense(expense);
    }
  }

  Future<void> upsertTransaction(TransactionEntry transaction) async {
    if (!isReady) return;
    final userId = _userId!;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toJson(), SetOptions(merge: true));
  }

  Future<void> removeTransaction(String transactionId) async {
    if (!isReady) return;
    final userId = _userId!;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }

  Future<List<TransactionEntry>> fetchRemoteTransactions() async {
    if (!isReady) return const [];
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId!)
        .collection('transactions')
        .get();
    return snapshot.docs
        .map((doc) => TransactionEntry.fromJson(doc.data()))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<BudgetProfile?> fetchRemoteProfile() async {
    if (!isReady) return null;
    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(_userId!).get();
    final raw = snapshot.data()?['profile'];
    if (raw is! Map<String, dynamic>) return null;
    return BudgetProfile.fromJson(raw);
  }

  Future<List<ExpenseEntry>> fetchRemoteExpenses() async {
    if (!isReady) return const [];
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId!)
        .collection('expenses')
        .get();
    return snapshot.docs
        .map((doc) => ExpenseEntry.fromJson(doc.data()))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
}
