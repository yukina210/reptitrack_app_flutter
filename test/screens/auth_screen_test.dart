// test/screens/auth_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:reptitrack_app/screens/auth/auth_screen.dart';
import 'package:reptitrack_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// モッククラス生成のためのアノテーション
@GenerateMocks([AuthService, User])
import 'auth_screen_test.mocks.dart';

void main() {
  group('AuthScreen Widget Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: ChangeNotifierProvider<AuthService>.value(
          value: mockAuthService,
          child: const AuthScreen(),
        ),
      );
    }

    testWidgets('認証画面の初期表示確認', (tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('ログイン'), findsOneWidget);
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
      expect(find.text('Googleアカウントでログイン'), findsOneWidget);
      expect(find.text('Appleアカウントでログイン'), findsOneWidget);
      expect(find.text('パスワードをお忘れの方'), findsOneWidget);
    });

    testWidgets('ログインモードと新規登録モードの切り替え', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - 新規登録モードに切り替え
      await tester.tap(find.text('アカウントをお持ちでない方は登録'));
      await tester.pump();

      // Assert
      expect(find.text('新規登録'), findsOneWidget);
      expect(find.text('すでにアカウントをお持ちの方はログイン'), findsOneWidget);
      expect(find.text('パスワードをお忘れの方'), findsNothing);

      // Act - ログインモードに戻す
      await tester.tap(find.text('すでにアカウントをお持ちの方はログイン'));
      await tester.pump();

      // Assert
      expect(find.text('ログイン'), findsOneWidget);
      expect(find.text('パスワードをお忘れの方'), findsOneWidget);
    });

    testWidgets('メールアドレスとパスワードの入力フィールド', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      // Assert
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('ログインボタンのタップ', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // メールアドレスとパスワードを入力
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      // Mock設定
      when(
        mockAuthService.signInWithEmail('test@example.com', 'password123'),
      ).thenAnswer((_) async => null);

      // Act
      await tester.tap(find.text('ログイン'));
      await tester.pump();

      // Assert
      verify(
        mockAuthService.signInWithEmail('test@example.com', 'password123'),
      ).called(1);
    });

    testWidgets('Googleログインボタンのタップ', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Mock設定
      when(mockAuthService.signInWithGoogle()).thenAnswer((_) async => null);

      // Act
      await tester.tap(find.text('Googleアカウントでログイン'));
      await tester.pump();

      // Assert
      verify(mockAuthService.signInWithGoogle()).called(1);
    });

    testWidgets('Appleログインボタンのタップ', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Mock設定
      when(mockAuthService.signInWithApple()).thenAnswer((_) async => null);

      // Act
      await tester.tap(find.text('Appleアカウントでログイン'));
      await tester.pump();

      // Assert
      verify(mockAuthService.signInWithApple()).called(1);
    });

    testWidgets('パスワードリセットダイアログの表示', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act
      await tester.tap(find.text('パスワードをお忘れの方'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('パスワードのリセット'), findsOneWidget);
      expect(find.text('送信'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
    });

    testWidgets('バリデーションエラーの表示', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - 空の状態でログインボタンをタップ
      await tester.tap(find.text('ログイン'));
      await tester.pump();

      // Assert - バリデーションエラーが表示される
      expect(find.text('メールアドレスを入力してください'), findsOneWidget);
      expect(find.text('パスワードを入力してください'), findsOneWidget);
    });

    testWidgets('ローディング状態の表示', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // メールアドレスとパスワードを入力
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      // Mock設定（時間のかかる処理をシミュレート）
      when(
        mockAuthService.signInWithEmail('test@example.com', 'password123'),
      ).thenAnswer(
        (_) => Future.delayed(const Duration(seconds: 2), () => null),
      );

      // Act
      await tester.tap(find.text('ログイン'));
      await tester.pump(); // ローディング状態を確認するため即座にpump

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('認証エラーの表示', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // メールアドレスとパスワードを入力
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');

      // Mock設定（認証エラーをシミュレート）
      when(
        mockAuthService.signInWithEmail('test@example.com', 'wrongpassword'),
      ).thenThrow(
        FirebaseAuthException(
          code: 'wrong-password',
          message: 'パスワードが正しくありません',
        ),
      );

      // Act
      await tester.tap(find.text('ログイン'));
      await tester.pump();

      // Assert
      expect(find.text('パスワードが正しくありません'), findsOneWidget);
    });

    testWidgets('新規登録ボタンのタップ', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // 新規登録モードに切り替え
      await tester.tap(find.text('アカウントをお持ちでない方は登録'));
      await tester.pump();

      // メールアドレスとパスワードを入力
      await tester.enterText(
        find.byType(TextFormField).first,
        'newuser@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'newpassword123',
      );

      // Mock設定
      when(
        mockAuthService.registerWithEmail(
          'newuser@example.com',
          'newpassword123',
        ),
      ).thenAnswer((_) async => null);

      // Act
      await tester.tap(find.text('新規登録'));
      await tester.pump();

      // Assert
      verify(
        mockAuthService.registerWithEmail(
          'newuser@example.com',
          'newpassword123',
        ),
      ).called(1);
    });

    testWidgets('パスワードリセットの送信', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Mock設定
      when(
        mockAuthService.resetPassword('test@example.com'),
      ).thenAnswer((_) async {});

      // Act
      await tester.tap(find.text('パスワードをお忘れの方'));
      await tester.pumpAndSettle();

      // パスワードリセットダイアログでメールアドレスを入力
      await tester.enterText(
        find.byType(TextFormField).last,
        'test@example.com',
      );
      await tester.tap(find.text('送信'));
      await tester.pump();

      // Assert
      verify(mockAuthService.resetPassword('test@example.com')).called(1);
    });
  });
}
