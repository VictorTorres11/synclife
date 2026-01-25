import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Configuração global para testes
class TestConfig {
  static bool _initialized = false;

  /// Inicializa o Firebase para testes
  static Future<void> initializeFirebase() async {
    if (_initialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock Firebase
    setupFirebaseAuthMocks();
    setupFirestoreMocks();

    _initialized = true;
  }

  /// Mock do Firebase Auth
  static void setupFirebaseAuthMocks() {
    const MethodChannel('plugins.flutter.io/firebase_core')
        .setMockMethodCallHandler((methodCall) async {
      if (methodCall.method == 'Firebase#initializeCore') {
        return [
          {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'fake-api-key',
              'appId': 'fake-app-id',
              'messagingSenderId': 'fake-sender-id',
              'projectId': 'fake-project-id',
            },
            'pluginConstants': {},
          }
        ];
      }
      return null;
    });

    const MethodChannel('plugins.flutter.io/firebase_auth')
        .setMockMethodCallHandler((methodCall) async {
      return null;
    });
  }

  /// Mock do Firestore
  static void setupFirestoreMocks() {
    const MethodChannel('plugins.flutter.io/cloud_firestore')
        .setMockMethodCallHandler((methodCall) async {
      return null;
    });

    const MethodChannel('plugins.flutter.io/firebase_analytics')
        .setMockMethodCallHandler((methodCall) async {
      return null;
    });

    const MethodChannel('plugins.flutter.io/firebase_crashlytics')
        .setMockMethodCallHandler((methodCall) async {
      return null;
    });

    const MethodChannel('plugins.flutter.io/firebase_performance')
        .setMockMethodCallHandler((methodCall) async {
      return null;
    });
  }
}
