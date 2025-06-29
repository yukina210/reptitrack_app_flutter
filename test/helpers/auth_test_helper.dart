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
  static Future<void> enterPassword(
    WidgetTester tester,
    String password,
  ) async {
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

  /// Googleサインインボタンをタップ
  static Future<void> tapGoogleSignInButton(WidgetTester tester) async {
    await tester.tap(find.text('Googleアカウントでログイン'));
    await tester.pumpAndSettle(Duration(seconds: 5));
  }

  /// Appleサインインボタンをタップ
  static Future<void> tapAppleSignInButton(WidgetTester tester) async {
    await tester.tap(find.text('Appleアカウントでログイン'));
    await tester.pumpAndSettle(Duration(seconds: 5));
  }

  /// 新規登録モードに切り替え
  static Future<void> switchToSignUpMode(WidgetTester tester) async {
    await tester.tap(find.text('アカウントをお持ちでない方は登録'));
    await tester.pumpAndSettle();
  }

  /// ログインモードに切り替え
  static Future<void> switchToLoginMode(WidgetTester tester) async {
    await tester.tap(find.text('すでにアカウントをお持ちの方はログイン'));
    await tester.pumpAndSettle();
  }

  /// ホーム画面が表示されることを確認
  static void expectHomeScreen() {
    expect(find.text('ペット一覧'), findsOneWidget);
  }

  /// ログイン画面が表示されることを確認
  static void expectLoginScreen() {
    expect(find.text('ログイン'), findsOneWidget);
    expect(find.text('メールアドレス'), findsOneWidget);
    expect(find.text('パスワード'), findsOneWidget);
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

  /// スナックバーの表示を待機
  static Future<void> waitForSnackBar(WidgetTester tester) async {
    await tester.pump(); // スナックバーの表示をトリガー
    await tester.pump(Duration(milliseconds: 750)); // アニメーション完了まで待機
  }

  /// エラーダイアログの表示を待機
  static Future<void> waitForErrorDialog(WidgetTester tester) async {
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  }

  /// ローディング状態を確認
  static void expectLoadingState() {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }

  /// フォームのバリデーションエラーを確認
  static void expectValidationError(String errorMessage) {
    expect(find.text(errorMessage), findsOneWidget);
  }

  /// テストデバッグ用のウィジェット情報を出力
  static void debugPrintWidgetTree(WidgetTester tester) {
    final widgets = find.byType(Widget);
    for (int i = 0; i < widgets.evaluate().length; i++) {
      try {
        final widget = tester.widget(widgets.at(i));
        print('Widget $i: ${widget.runtimeType}');
      } catch (e) {
        print('Widget $i: Unable to get widget - $e');
      }
    }
  }

  /// 特定のテキストが表示されるまで待機
  static Future<void> waitForText(
    WidgetTester tester,
    String text, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      await tester.pump(Duration(milliseconds: 100));

      if (find.text(text).evaluate().isNotEmpty) {
        stopwatch.stop();
        return;
      }
    }

    stopwatch.stop();
    throw TimeoutException(
      'Text "$text" not found within ${timeout.inSeconds} seconds',
      timeout,
    );
  }

  /// ウィジェットが表示されるまで待機
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      await tester.pump(Duration(milliseconds: 100));

      if (finder.evaluate().isNotEmpty) {
        stopwatch.stop();
        return;
      }
    }

    stopwatch.stop();
    throw TimeoutException(
      'Widget not found within ${timeout.inSeconds} seconds',
      timeout,
    );
  }
}

/// タイムアウト例外クラス
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message';
}
