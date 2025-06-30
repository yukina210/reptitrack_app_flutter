// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  // デフォルトコンストラクタ（本番用）
  AuthService()
    : _firebaseAuth = FirebaseAuth.instance,
      _googleSignIn = GoogleSignIn();

  // テスト用コンストラクタ（依存性注入）
  AuthService.withDependencies({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn;

  // 現在のユーザーを取得
  User? get currentUser => _firebaseAuth.currentUser;

  // 認証状態の変更を監視
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  // メールアドレスとパスワードで新規登録
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // メールアドレスとパスワードでログイン
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Googleアカウントでログイン
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // ユーザーがログインをキャンセル
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _firebaseAuth.signInWithCredential(
        credential,
      );
      notifyListeners();
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Googleログインでエラーが発生しました: $e');
    }
  }

  // Appleアカウントでログイン
  Future<User?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential result = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );
      notifyListeners();
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Appleログインでエラーが発生しました: $e');
    }
  }

  // パスワードリセットメールを送信
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ログアウト
  Future<void> signOut() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('ログアウトでエラーが発生しました: $e');
    }
  }

  // アカウント削除
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // FirebaseAuthExceptionのハンドリング
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'weak-password':
        message = 'パスワードが弱すぎます。より強力なパスワードを入力してください。';
        break;
      case 'email-already-in-use':
        message = 'このメールアドレスは既に使用されています。';
        break;
      case 'invalid-email':
        message = 'メールアドレスの形式が正しくありません。';
        break;
      case 'user-disabled':
        message = 'このアカウントは無効化されています。';
        break;
      case 'user-not-found':
        message = 'このメールアドレスのユーザーは存在しません。';
        break;
      case 'wrong-password':
        message = 'パスワードが正しくありません。';
        break;
      case 'too-many-requests':
        message = 'ログイン試行回数が多すぎます。しばらく時間をおいてから再試行してください。';
        break;
      case 'network-request-failed':
        message = 'ネットワークエラーが発生しました。インターネット接続を確認してください。';
        break;
      case 'requires-recent-login':
        message = 'この操作には再ログインが必要です。';
        break;
      default:
        message = 'エラーが発生しました: ${e.message}';
    }

    return Exception(message);
  }

  // ユーザーの認証状態確認
  bool get isAuthenticated => currentUser != null;

  // メールアドレス確認済みかチェック
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // メール確認を送信
  Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // ユーザー情報の更新
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
      notifyListeners();
    }
  }

  // パスワード変更
  Future<void> updatePassword(String newPassword) async {
    final user = currentUser;
    if (user != null) {
      try {
        await user.updatePassword(newPassword);
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      }
    }
  }

  // 再認証（パスワード変更やアカウント削除前に必要）
  Future<void> reauthenticateWithPassword(String password) async {
    final user = currentUser;
    if (user != null && user.email != null) {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      try {
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      }
    }
  }
}
