// test/helpers/auth_test_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthTestHelper {
  static const String testEmailDomain = '@test-reptitrack.com';
  
  /// テスト用のユニークなメールアドレスを生成
  static String generateTestEmail() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'test$timestamp$testEmailDomain';
  }

  /// テスト用のパスワード（固定）
  static const String testPassword = 'TestPassword123!';

  /// 現在のユーザーを削除（テスト後のクリーンアップ）
  static Future<void> deleteCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
        print('テストユーザーを削除しました: ${user.email}');
      }
    } catch (e) {
      print('ユーザー削除エラー: $e');
    }
  }

  /// Firebase Authからサインアウト
  static Future<void> signOutCurrentUser() async {
    try {
      await FirebaseAuth.instance.signOut();
      print('サインアウト完了');
    } catch (e) {
      print('サインアウトエラー: $e');
    }
  }

  /// メールアドレスフィールドに入力
  static Future<void> enterEmail(WidgetTester tester, String email) async {
    final emailField = find.byType(TextFormField).first;
    await tester.enterText(emailField, email);
    await tester.pump();
  }

  /// パスワードフィールドに入力
  static Future<void> enterPassword(WidgetTester tester, String password) async {
    final passwordField = find.byType(TextFormField).at(1);
    await tester.enterText(passwordField, password);
    await tester.pump();
  }

  /// ログインフォームに入力
  static Future<void> fillLoginForm(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    await enterEmail(tester, email);
    await enterPassword(tester, password);
  }

  /// ログインボタンをタップして結果を待機
  static Future<void> tapLoginButton(WidgetTester tester) async {
    await tester.tap(find.text('ログイン'));
    await tester.pumpAndSettle(Duration(seconds: 10));
  }

  /// 新規登録ボタンをタップして結果を待機
  static Future<void> tapSignUpButton(WidgetTester tester) async {
    await tester.tap(find.text('新規登録'));
    await tester.pumpAndSettle(Duration(seconds: 10));
  }

  /// Google認証ボタンをタップ
  static Future<void> tapGoogleSignInButton(WidgetTester tester) async {
    await tester.tap(find.text('Googleアカウントでログイン'));
    await tester.pumpAndSettle(Duration(seconds: 10));
  }

  /// Apple認証ボタンをタップ
  static Future<void> tapAppleSignInButton(WidgetTester tester) async {
    await tester.tap(find.text('Appleアカウントでログイン'));
    await tester.pumpAndSettle(Duration(seconds: 10));
  }

  /// ログイン/新規登録モードを切り替え
  static Future<void> switchToSignUpMode(WidgetTester tester) async {
    await tester.tap(find.text('アカウントをお持ちでない方は登録'));
    await tester.pumpAndSettle();
  }

  static Future<void> switchToLoginMode(WidgetTester tester) async {
    await tester.tap(find.text('すでにアカウントをお持ちの方はログイン'));
    await tester.pumpAndSettle();
  }

  /// エラーメッセージの存在確認
  static void expectErrorMessage(String expectedMessage) {
    expect(find.text(expectedMessage), findsOneWidget);
  }

  /// ホーム画面への遷移確認
  static void expectHomeScreen() {
    expect(find.text('ペット一覧'), findsOneWidget);
  }

  /// ログイン画面の表示確認
  static void expectLoginScreen() {
    expect(find.text('ログイン'), findsOneWidget);
    expect(find.text('メールアドレス'), findsOneWidget);
    expect(find.text('パスワード'), findsOneWidget);
  }

  /// ローディング状態の確認
  static void expectLoadingState() {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }

  /// パスワードリセットダイアログを開く
  static Future<void> openPasswordResetDialog(WidgetTester tester) async {
    await tester.tap(find.text('パスワードをお忘れの方'));
    await tester.pumpAndSettle();
  }

  /// パスワードリセットを実行
  static Future<void> executePasswordReset(
    WidgetTester tester,
    String email,
  ) async {
    await openPasswordResetDialog(tester);
    
    // ダイアログ内のメールフィールドに入力
    final dialogEmailField = find.byType(TextFormField).last;
    await tester.enterText(dialogEmailField, email);
    
    // 送信ボタンをタップ
    await tester.tap(find.text('送信'));
    await tester.pumpAndSettle();
  }
}

// test/helpers/firebase_test_setup.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

class FirebaseTestSetup {
  static bool _initialized = false;

  /// テスト用のFirebase初期化
  static Future<void> setupFirebaseForTesting() async {
    if (_initialized) return;

    // Firebase Core のモックチャンネル設定
    const MethodChannel('plugins.flutter.io/firebase_core')
        .setMockMethodCallHandler((methodCall) async {
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
            }
          ];
        case 'Firebase#initializeApp':
          return {
            'name': methodCall.arguments['appName'] ?? '[DEFAULT]',
            'options': methodCall.arguments['options'],
            'pluginConstants': {},
          };
        default:
          return null;
      }
    });

    // Firebase Auth のモックチャンネル設定
    const MethodChannel('plugins.flutter.io/firebase_auth')
        .setMockMethodCallHandler((methodCall) async {
      switch (methodCall.method) {
        case 'Auth#registerIdTokenListener':
        case 'Auth#registerAuthStateListener':
          return {
            'user': null,
          };
        default:
          return null;
      }
    });

    _initialized = true;
  }

  /// テスト後のクリーンアップ
  static void tearDownFirebase() {
    const MethodChannel('plugins.flutter.io/firebase_core')
        .setMockMethodCallHandler(null);
    const MethodChannel('plugins.flutter.io/firebase_auth')
        .setMockMethodCallHandler(null);
    _initialized = false;
  }
}

// test/helpers/widget_test_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:reptitrack_app/services/auth_service.dart';
import 'package:reptitrack_app/screens/auth_screen.dart';

class WidgetTestHelper {
  /// 認証画面のテスト用ウィジェットを作成
  static Widget createAuthScreenWidget(AuthService authService) {
    return MaterialApp(
      home: ChangeNotifierProvider<AuthService>.value(
        value: authService,
        child: AuthScreen(),
      ),
      routes: {
        '/home': (context) => Scaffold(
          appBar: AppBar(title: Text('ペット一覧')),
          body: Center(child: Text('ホーム画面')),
        ),
      },
    );
  }

  /// スナックバーの表示を待機
  static Future<void> waitForSnackBar(WidgetTester tester) async {
    await tester.pump(); // スナックバーの表示をトリガー
    await tester.pump(Duration(milliseconds: 750)); // アニメーション完了まで待機
  }

  /// ダイアログの表示を待機
  static Future<void> waitForDialog(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }

  /// テキストフィールドの値を取得
  static String getTextFieldValue(WidgetTester tester, int index) {
    final textField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(index),
    );
    return textField.controller?.text ?? '';
  }

  /// ボタンが有効かどうかを確認
  static bool isButtonEnabled(WidgetTester tester, String buttonText) {
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, buttonText),
    );
    return button.onPressed != null;
  }
}