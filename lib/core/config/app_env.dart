import 'package:flutter/foundation.dart';

class AppEnv {
  // Public Firebase config (safe to ship in client apps).
  static const firebaseApiKey = 'AIzaSyAlc85KFZ2FOZwAx6XGJ6OhCNx9n9v01sQ';
  static const firebaseAppId = '1:854909411412:web:def3def3d02069609a4dc1';
  static const firebaseMessagingSenderId = '854909411412';
  static const firebaseProjectId = 'money-manager-6aa55';

  /// Web-only. If missing, we derive a sensible default from [firebaseProjectId].
  static const firebaseAuthDomain = 'money-manager-6aa55.firebaseapp.com';

  /// Optional. Most apps use `${projectId}.appspot.com`.
  static const firebaseStorageBucket = 'money-manager-6aa55.appspot.com';

  static const firebaseMeasurementId = '';

  static String get derivedAuthDomain {
    final pid = firebaseProjectId.trim();
    if (pid.isEmpty) return '';
    return '$pid.firebaseapp.com';
  }

  static String get derivedStorageBucket {
    final pid = firebaseProjectId.trim();
    if (pid.isEmpty) return '';
    return '$pid.appspot.com';
  }

  static bool get isFirebaseConfigured {
    if (firebaseApiKey.isEmpty ||
        firebaseAppId.isEmpty ||
        firebaseMessagingSenderId.isEmpty ||
        firebaseProjectId.isEmpty) {
      return false;
    }
    if (kIsWeb && (firebaseAuthDomain.isEmpty && derivedAuthDomain.isEmpty)) {
      return false;
    }
    return true;
  }
}
