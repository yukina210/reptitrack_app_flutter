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

      // AuthServiceにモックされたFirebaseAuthを注入
      authService = AuthService.withDependencies(
        firebaseAuth: mockFirebaseAuth,
        googleSignIn: mockGoogleSignIn,
      );
    });

    group('メール認証テスト', () {
      test('メールアドレスとパスワードでの新規登録が成功する', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';

        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('test-uid');
        when(mockUser.email).thenReturn(email);
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
        when(mockUser.uid).thenReturn('test-uid');
        when(mockUser.email).thenReturn(email);
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
            message: 'メールアドレスの形式が正しくありません',
          ),
        );

        // Act & Assert
        expect(
          () => authService.signInWithEmail(email, password),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('間違ったパスワードでログインが失敗する', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'wrongpassword';

        when(
          mockFirebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenThrow(
          FirebaseAuthException(
            code: 'wrong-password',
            message: 'パスワードが正しくありません',
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
        when(mockUser.uid).thenReturn('test-uid');
        when(mockUser.email).thenReturn('test@gmail.com');
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

      test('Google認証でFirebaseAuthExceptionが発生した場合', () async {
        // Arrange
        when(
          mockGoogleSignIn.signIn(),
        ).thenAnswer((_) async => mockGoogleSignInAccount);
        when(
          mockGoogleSignInAccount.authentication,
        ).thenAnswer((_) async => mockGoogleAuth);
        when(mockGoogleAuth.accessToken).thenReturn('access_token');
        when(mockGoogleAuth.idToken).thenReturn('id_token');
        when(mockFirebaseAuth.signInWithCredential(any)).thenThrow(
          FirebaseAuthException(
            code: 'network-request-failed',
            message: 'ネットワークエラーが発生しました',
          ),
        );

        // Act & Assert
        expect(
          () => authService.signInWithGoogle(),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('Apple認証テスト', () {
      // Apple認証は実際のプラグインが必要なため、Exceptionのテストのみ
      test('Apple認証でエラーが発生した場合の例外処理', () async {
        // Apple認証は実際のネイティブプラグインが必要なため、
        // ここではExceptionが適切にハンドリングされることのみ確認

        // Act & Assert
        expect(() => authService.signInWithApple(), throwsA(isA<Exception>()));
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

      test('存在しないメールアドレスでパスワードリセットが失敗する', () async {
        // Arrange
        const email = 'nonexistent@example.com';
        when(mockFirebaseAuth.sendPasswordResetEmail(email: email)).thenThrow(
          FirebaseAuthException(
            code: 'user-not-found',
            message: 'このメールアドレスのユーザーは存在しません',
          ),
        );

        // Act & Assert
        expect(
          () => authService.resetPassword(email),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('ログアウトテスト', () {
      test('ログアウトが成功する', () async {
        // Arrange
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});
        when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

        // Act
        await authService.signOut();

        // Assert
        verify(mockFirebaseAuth.signOut()).called(1);
        verify(mockGoogleSignIn.signOut()).called(1);
      });

      test('ログアウト時にFirebaseAuthExceptionが発生した場合', () async {
        // Arrange
        when(mockFirebaseAuth.signOut()).thenThrow(
          FirebaseAuthException(
            code: 'network-request-failed',
            message: 'ネットワークエラーが発生しました',
          ),
        );

        // Act & Assert
        expect(
          () => authService.signOut(),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('認証状態テスト', () {
      test('認証状態の変更を監視できる', () async {
        // Arrange
        when(
          mockFirebaseAuth.authStateChanges(),
        ).thenAnswer((_) => Stream.fromIterable([null, mockUser]));
        when(mockUser.uid).thenReturn('test-uid');

        // Act
        final authStream = authService.authStateChanges();

        // Assert
        expect(authStream, emitsInOrder([null, mockUser]));
      });

      test('現在のユーザーを取得できる', () {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('test-uid');

        // Act
        final currentUser = authService.currentUser;

        // Assert
        expect(currentUser, equals(mockUser));
        verify(mockFirebaseAuth.currentUser).called(1);
      });

      test('ログインしていない場合はnullが返される', () {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        // Act
        final currentUser = authService.currentUser;

        // Assert
        expect(currentUser, isNull);
        verify(mockFirebaseAuth.currentUser).called(1);
      });
    });

    group('エラーメッセージテスト', () {
      test('Firebase認証エラーメッセージが正しく変換される', () {
        // Test various error codes
        final testCases = [
          ('weak-password', 'パスワードが弱すぎます。より強力なパスワードを入力してください。'),
          ('email-already-in-use', 'このメールアドレスは既に使用されています。'),
          ('invalid-email', 'メールアドレスの形式が正しくありません。'),
          ('user-not-found', 'このメールアドレスのユーザーは存在しません。'),
          ('wrong-password', 'パスワードが正しくありません。'),
        ];

        for (final testCase in testCases) {
          final exception = FirebaseAuthException(
            code: testCase.$1,
            message: 'Original message',
          );

          final message = authService.getFirebaseErrorMessage(exception);
          expect(message, equals(testCase.$2));
        }
      });
    });
  });
}
