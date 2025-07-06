// test/test_main.dart
// テスト専用のmain設定ファイル

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

/// テスト環境の初期化
class TestEnvironment {
  static bool _initialized = false;

  /// テスト環境を初期化
  static Future<void> initialize() async {
    if (_initialized) return;

    // Flutter の初期化
    WidgetsFlutterBinding.ensureInitialized();

    // Provider の型チェックを無効化（テスト環境でのみ）
    Provider.debugCheckInvalidValueType = null;

    // Firebase の初期化（テスト用設定）
    await _initializeFirebaseForTest();

    _initialized = true;
  }

  /// テスト用 Firebase 初期化
  static Future<void> _initializeFirebaseForTest() async {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'fake-api-key',
          appId: 'fake-app-id',
          messagingSenderId: 'fake-sender-id',
          projectId: 'fake-project-id',
          storageBucket: 'fake-storage-bucket',
        ),
      );
    } catch (e) {
      // Firebase が既に初期化されている場合は無視
      debugPrint('Firebase already initialized: $e');
    }
  }

  /// テスト用 MaterialApp ラッパー
  static Widget createTestApp({
    required Widget child,
    List<Provider>? additionalProviders,
  }) {
    return MaterialApp(
      home: MultiProvider(
        providers: additionalProviders ?? [],
        child: child,
      ),
      // テスト環境では不要なバナーを非表示
      debugShowCheckedModeBanner: false,
    );
  }

  /// テスト環境のクリーンアップ
  static void dispose() {
    // 必要に応じてクリーンアップ処理を追加
    _initialized = false;
  }
}

/// テスト用のグローバル設定
class TestConfig {
  // デフォルトのテストタイムアウト
  static const Duration defaultTimeout = Duration(seconds: 10);

  // テストデータの設定
  static const String testUserId = 'test-user-id';
  static const String testUserEmail = 'test@example.com';
  static const String testPassword = 'testPassword123';

  // ダミーの Firebase プロジェクト設定
  static const FirebaseOptions testFirebaseOptions = FirebaseOptions(
    apiKey: 'fake-api-key',
    appId: 'fake-app-id',
    messagingSenderId: 'fake-sender-id',
    projectId: 'reptitrack-test',
    storageBucket: 'fake-storage-bucket',
  );
}

/// テスト用のエラーハンドリング
class TestErrorHandler {
  /// エラーをキャッチして適切にログ出力
  static void handleError(Object error, StackTrace stackTrace) {
    debugPrint('Test Error: $error');
    debugPrint('Stack Trace: $stackTrace');
  }

  /// 非同期エラーのハンドリング
  static void handleAsyncError(Object error, StackTrace stackTrace) {
    debugPrint('Async Test Error: $error');
    debugPrint('Stack Trace: $stackTrace');
  }
}
