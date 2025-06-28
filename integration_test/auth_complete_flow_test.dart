// integration_test/auth_complete_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:reptitrack_app/main.dart' as app;
import '../test/helpers/auth_test_helper.dart';
import '../test/helpers/firebase_test_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('認証機能完全フローテスト', () {
    late String testEmail;

    setUpAll(() async {
      // Firebase初期化
      await Firebase.initializeApp();
      testEmail = AuthTestHelper.generateTestEmail();
    });

    tearDown(() async {
      // 各テスト後のクリーンアップ
      await AuthTestHelper.deleteCurrentUser();
    });

    group('メール認証フルフロー', () {
      testWidgets('新規登録 → ログアウト → 再ログイン フロー', (tester) async {
        // アプリを起動
        app.main();
        await tester.pumpAndSettle();

        // === 新規登録フェーズ ===
        print('=== 新規登録フェーズ ===');
        
        // 新規登録モードに切り替え
        await AuthTestHelper.switchToSignUpMode(tester);
        
        // フォームに入力
        await AuthTestHelper.fillLoginForm(
          tester,
          testEmail,
          AuthTestHelper.testPassword,
        );
        
        // 新規登録実行
        await AuthTestHelper.tapSignUpButton(tester);
        
        // ホーム画面への遷移確認
        AuthTestHelper.expectHomeScreen();
        print('新規登録成功: $testEmail');

        // === ログアウトフェーズ ===
        print('=== ログアウトフェーズ ===');
        
        // 設定画面に移動
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();
        
        // ログアウトボタンをタップ
        await tester.tap(find.text('ログアウト'));
        await tester.pumpAndSettle();
        
        // 確認ダイアログでログアウト実行
        await tester.tap(find.text('ログアウト').last);
        await tester.pumpAndSettle();
        
        // ログイン画面に戻ることを確認
        AuthTestHelper.expectLoginScreen();
        print('ログアウト成功');

        // === 再ログインフェーズ ===
        print('=== 再ログインフェーズ ===');
        
        // 同じ認証情報でログイン
        await AuthTestHelper.fillLoginForm(
          tester,
          testEmail,
          AuthTestHelper.testPassword,
        );
        
        await AuthTestHelper.tapLoginButton(tester);
        
        // ホーム画面への遷移確認
        AuthTestHelper.expectHomeScreen();
        print('再ログイン成功');
      });

      testWidgets('バリデーションエラーテスト', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // 空のフォームでログイン試行
        await AuthTestHelper.tapLoginButton(tester);
        await tester.pump();

        // バリデーションエラーの確認
        expect(find.text('メールアドレスを入力してください'), findsOneWidget);
        expect(find.text('パスワードを入力してください'), findsOneWidget);

        // 無効なメールアドレスを入力
        await AuthTestHelper.enterEmail(tester, 'invalid-email');
        await AuthTestHelper.tapLoginButton(tester);
        await tester.pump();

        expect(find.text('有効なメールアドレスを入力してください'), findsOneWidget);
      });

      testWidgets('存在しないアカウントでログイン試行', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        final nonExistentEmail = AuthTestHelper.generateTestEmail();
        
        await AuthTestHelper.fillLoginForm(
          tester,
          nonExistentEmail,
          'wrongpassword',
        );
        
        await AuthTestHelper.tapLoginButton(tester);

        // エラーメッセージの表示確認
        await AuthTestHelper.waitForSnackBar(tester);
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('パスワードリセット機能', () {
      testWidgets('パスワードリセットフロー', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // 事前にテストアカウントを作成
        await AuthTestHelper.switchToSignUpMode(tester);
        await AuthTestHelper.fillLoginForm(
          tester,
          testEmail,
          AuthTestHelper.testPassword,
        );
        await AuthTestHelper.tapSignUpButton(tester);
        AuthTestHelper.expectHomeScreen();

        // ログアウト
        await AuthTestHelper.signOutCurrentUser();
        await tester.pumpAndSettle();

        // パスワードリセット実行
        await AuthTestHelper.executePasswordReset(tester, testEmail);

        // 成功メッセージの確認
        await AuthTestHelper.waitForSnackBar(tester);
        expect(find.text('パスワードリセットメールを送信しました'), findsOneWidget);
      });
    });

    group('UI/UX テスト', () {
      testWidgets('ローディング状態のテスト', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await AuthTestHelper.fillLoginForm(
          tester,
          testEmail,
          AuthTestHelper.testPassword,
        );

        // ログインボタンをタップしてすぐにローディング確認
        await tester.tap(find.text('ログイン'));
        await tester.pump(Duration(milliseconds: 100));

        // ローディングインジケーターの表示確認
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('モード切り替えテスト', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // 初期状態（ログインモード）の確認
        expect(find.text('ログイン'), findsOneWidget);
        expect(find.text('パスワードをお忘れの方'), findsOneWidget);

        // 新規登録モードに切り替え
        await AuthTestHelper.switchToSignUpMode(tester);
        expect(find.text('新規登録'), findsOneWidget);
        expect(find.text('パスワードをお忘れの方'), findsNothing);

        // ログインモードに戻す
        await AuthTestHelper.switchToLoginMode(tester);
        expect(find.text('ログイン'), findsOneWidget);
        expect(find.text('パスワードをお忘れの方'), findsOneWidget);
      });
    });

    group('セッション管理テスト', () {
      testWidgets('アプリ再起動時のセッション保持', (tester) async {
        // 最初にログイン
        app.main();
        await tester.pumpAndSettle();

        await AuthTestHelper.switchToSignUpMode(tester);
        await AuthTestHelper.fillLoginForm(
          tester,
          testEmail,
          AuthTestHelper.testPassword,
        );
        await AuthTestHelper.tapSignUpButton(tester);
        AuthTestHelper.expectHomeScreen();

        // アプリを再起動（シミュレーション）
        await tester.binding.defaultBinaryMessenger.send(
          'flutter/platform',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('SystemNavigator.pop'),
          ),
        );

        // アプリを再度起動
        app.main();
        await tester.pumpAndSettle();

        // ログイン状態が保持されていることを確認
        // 注意：実際の実装では、AuthServiceがauthStateChangesを監視して
        // 自動的にホーム画面に遷移するようになっている必要があります
        AuthTestHelper.expectHomeScreen();
      });
    });
  });
}

// integration_test/social_auth_manual_test.dart
// ソーシャル認証は手動テスト用（実際のアカウントが必要なため）
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:reptitrack_app/main.dart' as app;
import '../test/helpers/auth_test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ソーシャル認証手動テスト', () {
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
  });
}