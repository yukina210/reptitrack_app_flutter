// test/helpers/firebase_test_setup.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FirebaseTestSetup {
  static bool _initialized = false;

  /// テスト用のFirebase初期化（新しいAPI使用）
  static Future<void> setupFirebaseForTesting() async {
    if (_initialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();

    // Firebase Core のモックチャンネル設定（新しいAPI）
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_core'),
      (methodCall) async {
        switch (methodCall.method) {
          case 'Firebase#initializeCore':
            return [
              {
                'name': '[DEFAULT]',
                'options': {
                  'apiKey': 'test-api-key',
                  'appId': 'test-app-id',
                  'messagingSenderId': 'test-sender-id',
                  'projectId': 'test-project-id',
                  'storageBucket': 'test-storage-bucket',
                },
                'pluginConstants': {},
              },
            ];
          case 'Firebase#initializeApp':
            return {
              'name': methodCall.arguments?['appName'] ?? '[DEFAULT]',
              'options': methodCall.arguments?['options'],
              'pluginConstants': {},
            };
          default:
            return null;
        }
      },
    );

    // Firebase Auth のモックチャンネル設定（新しいAPI）
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_auth'),
      (methodCall) async {
        switch (methodCall.method) {
          case 'Auth#registerIdTokenListener':
          case 'Auth#registerAuthStateListener':
            return {'user': null};
          case 'Auth#signOut':
            return null;
          case 'Auth#createUserWithEmailAndPassword':
            return {
              'user': {
                'uid': 'test-uid',
                'email': methodCall.arguments?['email'],
                'emailVerified': false,
              },
            };
          case 'Auth#signInWithEmailAndPassword':
            return {
              'user': {
                'uid': 'test-uid',
                'email': methodCall.arguments?['email'],
                'emailVerified': true,
              },
            };
          case 'Auth#sendPasswordResetEmail':
            return null;
          default:
            return null;
        }
      },
    );

    // Firebase Firestore のモックチャンネル設定（新しいAPI）
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/cloud_firestore'),
      (methodCall) async {
        switch (methodCall.method) {
          case 'Firestore#enableNetwork':
          case 'Firestore#disableNetwork':
            return null;
          case 'DocumentReference#set':
          case 'DocumentReference#update':
          case 'DocumentReference#delete':
            return null;
          case 'DocumentReference#get':
            return {
              'data': {},
              'metadata': {'isFromCache': false, 'hasPendingWrites': false},
            };
          case 'Query#get':
            return {
              'documents': [],
              'metadata': {'isFromCache': false, 'hasPendingWrites': false},
            };
          default:
            return null;
        }
      },
    );

    _initialized = true;
  }

  /// テスト後のクリーンアップ（新しいAPI）
  static void tearDownFirebase() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_core'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_auth'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/cloud_firestore'),
      null,
    );
    _initialized = false;
  }

  /// Firebase エミュレーター接続設定
  static Future<void> connectToEmulator() async {
    try {
      // Firebase Auth エミュレーター
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

      // Cloud Firestore エミュレーター
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

      // デバッグ出力をdebugPrintに変更（Lintエラー対応）
      debugPrint('Firebase エミュレーターに接続しました');
    } catch (e) {
      debugPrint('Firebase エミュレーター接続エラー: $e');
    }
  }

  /// テスト用Firebase設定の作成
  static FirebaseOptions createTestFirebaseOptions() {
    return const FirebaseOptions(
      apiKey: 'test-api-key',
      appId: 'test-app-id',
      messagingSenderId: 'test-sender-id',
      projectId: 'test-project-id',
      storageBucket: 'test-storage-bucket',
    );
  }
}

// test/helpers/test_environment.dart
class TestEnvironment {
  static const bool useEmulator = true;
  static const String emulatorHost = 'localhost';
  static const int authEmulatorPort = 9099;
  static const int firestoreEmulatorPort = 8080;
  static const int storageEmulatorPort = 9199;

  /// テスト環境のセットアップ
  static Future<void> setup() async {
    if (useEmulator) {
      await _setupEmulator();
    } else {
      await FirebaseTestSetup.setupFirebaseForTesting();
    }
  }

  /// Firebase エミュレーターのセットアップ
  static Future<void> _setupEmulator() async {
    try {
      // Firebase初期化
      await Firebase.initializeApp(
        options: FirebaseTestSetup.createTestFirebaseOptions(),
      );

      // エミュレーター接続
      await FirebaseTestSetup.connectToEmulator();
    } catch (e) {
      debugPrint('エミュレーターセットアップエラー: $e');
      // エミュレーターが利用できない場合はモックを使用
      await FirebaseTestSetup.setupFirebaseForTesting();
    }
  }

  /// テスト環境のクリーンアップ
  static void tearDown() {
    FirebaseTestSetup.tearDownFirebase();
  }
}
