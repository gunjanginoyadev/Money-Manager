import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? 'AIzaSyAlc85KFZ2FOZwAx6XGJ6OhCNx9n9v01sQ';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '1:854909411412:web:def3def3d02069609a4dc1';
  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '854909411412';
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? 'money-manager-6aa55';
  static String get firebaseAuthDomain => dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'money-manager-6aa55.firebaseapp.com';
  static String get firebaseStorageBucket =>
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'money-manager-6aa55.firebasestorage.app';
  static String get firebaseMeasurementId =>
      dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '';

  static bool get isFirebaseConfigured {
    if (firebaseApiKey.isEmpty ||
        firebaseAppId.isEmpty ||
        firebaseMessagingSenderId.isEmpty ||
        firebaseProjectId.isEmpty) {
      return false;
    }
    if (kIsWeb && (firebaseAuthDomain.isEmpty || firebaseStorageBucket.isEmpty)) {
      return false;
    }
    return true;
  }
}
