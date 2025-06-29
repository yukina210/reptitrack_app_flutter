// integration_test/social_auth_manual_test.dart
// ソーシャル認証は手動テスト用（実際のアカウントが必要なため）
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:reptitrack_app/main.dart' as app;
import '../test/helpers/auth_test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ソーシャル認証手動テスト', () {
    setUpAll(() async {
      // Firebase初期化
      await Firebase.initializeApp();
    });

    tearDown(() async {
      // 各テスト後のクリーンアップ
      await AuthTestHelper.deleteCurrentUser();
    });

    /// 注意: これらのテストは手動で実行し、実際のGoogle/Appleアカウントで
    /// 認証を行う必要があります。自動化テストスイートからは除外してください。

    testWidgets('Google認証手動テスト', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      print('=== Google認証手動テスト開始 ===');
      print('Googleログインボタンをタップしてください');

      await AuthTestHelper.tapGoogleSignInButton(tester);

      // 手動でGoogle認証を完了させる時間を確保
      await tester.pumpAndSettle(Duration(seconds: 30));

      // 認証成功後、ホーム画面に遷移することを確認
      AuthTestHelper.expectHomeScreen();
      print('Google認証テスト完了');
    }, timeout: Timeout(Duration(minutes: 2)));

    testWidgets('Apple認証手動テスト', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      print('=== Apple認証手動テスト開始 ===');
      print('Appleログインボタンをタップしてください');

      await AuthTestHelper.tapAppleSignInButton(tester);

      // 手動でApple認証を完了させる時間を確保
      await tester.pumpAndSettle(Duration(seconds: 30));

      // 認証成功後、ホーム画面に遷移することを確認
      AuthTestHelper.expectHomeScreen();
      print('Apple認証テスト完了');
    }, timeout: Timeout(Duration(minutes: 2)));

    testWidgets('Google認証 → ログアウト → 再ログイン', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      print('=== Google認証フルフローテスト ===');

      // Google認証でログイン
      await AuthTestHelper.tapGoogleSignInButton(tester);
      await tester.pumpAndSettle(Duration(seconds: 30));
      AuthTestHelper.expectHomeScreen();
      print('Google認証ログイン成功');

      // ログアウト
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ログアウト'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ログアウト').last);
      await tester.pumpAndSettle();

      AuthTestHelper.expectLoginScreen();
      print('ログアウト成功');

      // 再度Google認証でログイン
      await AuthTestHelper.tapGoogleSignInButton(tester);
      await tester.pumpAndSettle(Duration(seconds: 30));
      AuthTestHelper.expectHomeScreen();
      print('Google再認証成功');
    }, timeout: Timeout(Duration(minutes: 3)));
  });
}
