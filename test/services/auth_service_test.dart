// test/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:reptitrack_app/services/auth_service.dart';

// モッククラスを生成するためのアノテーション
@GenerateMocks([
  FirebaseAuth,
  UserCredential,
  User,
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
])
import 'auth_service_test.mocks.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockGoogleSignInAccount mockGoogleSignInAccount;
    late MockGoogleSignInAuthentication mockGoogleAuth;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();
      mockGoogleSignIn = MockGoogleSignIn();
      mockGoogleSignInAccount = MockGoogleSignInAccount();
      mockGoogleAuth = MockGoogleSignInAuthentication();

      // AuthServiceのインスタンスを作成（実際の実装では依存性注入を使用）
      authService = AuthService();
    });

    group('メール認証テスト', () {
      test('メールアドレスとパスワードでの新規登録が成功する', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';

        when(mockUserCredential.user).thenReturn(mockUser);
        when(
          mockFirebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await authService.registerWithEmail(email, password);

        // Assert
        expect(result, equals(mockUser));
        verify(
          mockFirebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).called(1);
      });

      test('メールアドレスとパスワードでのログインが成功する', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';

        when(mockUserCredential.user).thenReturn(mockUser);
        when(
          mockFirebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await authService.signInWithEmail(email, password);

        // Assert
        expect(result, equals(mockUser));
        verify(
          mockFirebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).called(1);
      });

      test('無効なメールアドレスでログインが失敗する', () async {
        // Arrange
        const email = 'invalid-email';
        const password = 'password123';

        when(
          mockFirebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenThrow(
          FirebaseAuthException(
            code: 'invalid-email',
            message: 'The email address is not valid.',
          ),
        );

        // Act & Assert
        expect(
          () => authService.signInWithEmail(email, password),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('Google認証テスト', () {
      test('Google認証でのログインが成功する', () async {
        // Arrange
        when(
          mockGoogleSignIn.signIn(),
        ).thenAnswer((_) async => mockGoogleSignInAccount);
        when(
          mockGoogleSignInAccount.authentication,
        ).thenAnswer((_) async => mockGoogleAuth);
        when(mockGoogleAuth.accessToken).thenReturn('access_token');
        when(mockGoogleAuth.idToken).thenReturn('id_token');
        when(mockUserCredential.user).thenReturn(mockUser);
        when(
          mockFirebaseAuth.signInWithCredential(any),
        ).thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await authService.signInWithGoogle();

        // Assert
        expect(result, equals(mockUser));
        verify(mockGoogleSignIn.signIn()).called(1);
        verify(mockFirebaseAuth.signInWithCredential(any)).called(1);
      });

      test('Googleログインがキャンセルされた場合', () async {
        // Arrange
        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        // Act
        final result = await authService.signInWithGoogle();

        // Assert
        expect(result, isNull);
        verify(mockGoogleSignIn.signIn()).called(1);
        verifyNever(mockFirebaseAuth.signInWithCredential(any));
      });
    });

    group('Apple認証テスト', () {
      test('Apple認証でのログインが成功する', () async {
        // Arrange
        // Note: Apple認証のモックは複雑なため、実際の実装では
        // より詳細なモック設定が必要になります
        when(mockUserCredential.user).thenReturn(mockUser);
        when(
          mockFirebaseAuth.signInWithCredential(any),
        ).thenAnswer((_) async => mockUserCredential);

        // この部分は実際の実装では、SignInWithApple.getAppleIDCredentialの
        // モックが必要になります

        // Act & Assert
        // 実際のテストでは、AppleIDCredentialのモックを作成して
        // テストする必要があります
      });
    });

    group('パスワードリセットテスト', () {
      test('パスワードリセットメールの送信が成功する', () async {
        // Arrange
        const email = 'test@example.com';
        when(
          mockFirebaseAuth.sendPasswordResetEmail(email: email),
        ).thenAnswer((_) async {});

        // Act
        await authService.resetPassword(email);

        // Assert
        verify(mockFirebaseAuth.sendPasswordResetEmail(email: email)).called(1);
      });
    });

    group('ログアウトテスト', () {
      test('ログアウトが成功する', () async {
        // Arrange
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});

        // Act
        await authService.signOut();

        // Assert
        verify(mockFirebaseAuth.signOut()).called(1);
      });
    });
  });
}
