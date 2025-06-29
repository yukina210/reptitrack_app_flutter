// integration_test/auth_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:reptitrack_app/main.dart' as app;
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('認証フロー統合テスト', () {
    late String testEmail;
    late String testPassword;

    setUpAll(() {
      // テスト用のユニークなメールアドレスを生成
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      testEmail = 'test$timestamp@example.com';
      testPassword = 'testPassword123';
    });

    tearDownAll(() async {
      // テスト後のクリーンアップ
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.delete();
        }
      } catch (e) {
        debugPrint('クリーンアップエラー: $e');
      }
    });

    testWidgets('メール認証でのサインアップからログアウトまでのフロー', (tester) async {
      // アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // 1. 新規登録画面に移動
      await tester.tap(find.text('アカウントをお持ちでない方は登録'));
      await tester.pumpAndSettle();

      // 2. メールアドレスとパスワードを入力
      await tester.enterText(find.byType(TextFormField).first, testEmail);
      await tester.enterText(find.byType(TextFormField).at(1), testPassword);

      // 3. 新規登録ボタンをタップ
      await tester.tap(find.text('新規登録'));
      await tester.pumpAndSettle(Duration(seconds: 5));

      // 4. ホーム画面に遷移されることを確認
      expect(find.text('ペット一覧'), findsOneWidget);

      // 5. 設定画面に移動
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // 6. ログアウト
      await tester.tap(find.text('ログアウト'));
      await tester.pumpAndSettle();

      // 確認ダイアログでログアウトを実行
      await tester.tap(find.text('ログアウト').last);
      await tester.pumpAndSettle();

      // 7. ログイン画面に戻ることを確認
      expect(find.text('ログイン'), findsOneWidget);
    });

    testWidgets('メール認証でのログインフロー', (tester) async {
      // 前提: 上記のテストでアカウントが作成されている

      // アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // 1. メールアドレスとパスワードを入力
      await tester.enterText(find.byType(TextFormField).first, testEmail);
      await tester.enterText(find.byType(TextFormField).at(1), testPassword);

      // 2. ログインボタンをタップ
      await tester.tap(find.text('ログイン'));
      await tester.pumpAndSettle(Duration(seconds: 5));

      // 3. ホーム画面に遷移されることを確認
      expect(find.text('ペット一覧'), findsOneWidget);
    });

    testWidgets('無効なメールアドレスでのログインエラー', (tester) async {
      // アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // 1. 無効なメールアドレスとパスワードを入力
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');

      // 2. ログインボタンをタップ
      await tester.tap(find.text('ログイン'));
      await tester.pumpAndSettle();

      // 3. エラーメッセージが表示されることを確認
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('パスワードリセット機能', (tester) async {
      // アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // 1. パスワードリセットリンクをタップ
      await tester.tap(find.text('パスワードをお忘れの方'));
      await tester.pumpAndSettle();

      // 2. メールアドレスを入力
      await tester.enterText(find.byType(TextFormField).last, testEmail);

      // 3. リセットボタンをタップ
      await tester.tap(find.text('送信'));
      await tester.pumpAndSettle();

      // 4. 成功メッセージが表示されることを確認
      expect(find.byType(SnackBar), findsOneWidget);
    });

    // Note: Google/Apple認証の統合テストは、実際のアカウントでの認証が必要なため
    // 自動化テストには不向きです。手動テストまたはE2Eテストで検証することを推奨します。
  });
}
