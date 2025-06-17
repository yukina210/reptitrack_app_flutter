// lib/screens/auth/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'ログイン' : '新規登録'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // アプリロゴやイメージを表示
                _buildLogo(),
                SizedBox(height: 32.0),

                // エラーメッセージ
                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(8.0),
                    color: Colors.red[100],
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(height: 16.0),

                // メールアドレス入力
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'メールアドレス',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'メールアドレスを入力してください';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return '有効なメールアドレスを入力してください';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),

                // パスワード入力
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワードを入力してください';
                    }
                    if (value.length < 6) {
                      return 'パスワードは6文字以上にしてください';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.0),

                // ログイン／登録ボタン
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      child: Text(
                        _isLogin ? 'ログイン' : '新規登録',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                SizedBox(height: 16.0),

                // モード切り替え
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _errorMessage = null;
                    });
                  },
                  child: Text(
                    _isLogin ? 'アカウントをお持ちでない方は登録' : 'すでにアカウントをお持ちの方はログイン',
                  ),
                ),
                SizedBox(height: 16.0),

                // パスワードリセット（ログイン画面のみ表示）
                if (_isLogin)
                  TextButton(
                    onPressed: _showPasswordResetDialog,
                    child: Text('パスワードをお忘れの方'),
                  ),
                SizedBox(height: 24.0),

                // または
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('または'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                SizedBox(height: 24.0),

                // Googleログインボタン
                ElevatedButton.icon(
                  onPressed: () => _signInWithProvider('google'),
                  icon: Image.asset('assets/google_logo.png', height: 24.0),
                  label: Text('Googleアカウントでログイン'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
                SizedBox(height: 16.0),

                // Appleログインボタン
                ElevatedButton.icon(
                  onPressed: () => _signInWithProvider('apple'),
                  icon: Icon(Icons.apple, color: Colors.white),
                  label: Text('Appleアカウントでログイン'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ロゴを表示するウィジェット
  Widget _buildLogo() {
    return Column(
      children: [
        Image.asset('assets/app_logo.png', height: 120),
        SizedBox(height: 16.0),
        Text(
          'ReptiTrack',
          style: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
        Text(
          '爬虫類の飼育管理を簡単に',
          style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // フォーム送信処理
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        if (_isLogin) {
          await authService.signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
        } else {
          await authService.registerWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
        }

        // BuildContextの問題を修正
        if (mounted) {
          // 成功したらホーム画面に遷移
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } catch (e) {
        // エラー発生時の処理
        if (mounted) {
          setState(() {
            _errorMessage = _getFirebaseErrorMessage(e.toString());
          });
        }
      } finally {
        // finallyでreturnを使わない構造に修正
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // 外部プロバイダーでのログイン処理
  Future<void> _signInWithProvider(String provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (provider == 'google') {
        await authService.signInWithGoogle();
      } else if (provider == 'apple') {
        await authService.signInWithApple();
      }

      // BuildContextの問題を修正
      if (mounted) {
        // 成功したらホーム画面に遷移
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getFirebaseErrorMessage(e.toString());
        });
      }
    } finally {
      // finallyでreturnを使わない構造に修正
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // パスワードリセットダイアログの表示
  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('パスワードのリセット'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('登録したメールアドレスにパスワードリセット用のリンクを送信します。'),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'メールアドレス',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (_emailController.text.isNotEmpty) {
                    _resetPassword();
                  }
                },
                child: Text('送信'),
              ),
            ],
          ),
    );
  }

  // パスワードリセット処理を別メソッドに分離
  Future<void> _resetPassword() async {
    // 現在のコンテキストを保存
    final currentContext = context;

    // 非同期処理前にスナックバーを表示
    ScaffoldMessenger.of(
      currentContext,
    ).showSnackBar(SnackBar(content: Text('リセット用メールを送信中...')));

    try {
      await Provider.of<AuthService>(
        currentContext,
        listen: false,
      ).resetPassword(_emailController.text.trim());

      // 非同期処理後に mounted チェック
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('リセット用メールを送信しました。メールをご確認ください。')));
      }
    } catch (e) {
      // 非同期処理後に mounted チェック
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'エラーが発生しました: ${_getFirebaseErrorMessage(e.toString())}',
            ),
          ),
        );
      }
    }
  }

  // Firebaseエラーメッセージの日本語化
  String _getFirebaseErrorMessage(String errorMessage) {
    if (errorMessage.contains('user-not-found')) {
      return 'このメールアドレスのユーザーは見つかりませんでした';
    } else if (errorMessage.contains('wrong-password')) {
      return 'パスワードが間違っています';
    } else if (errorMessage.contains('weak-password')) {
      return 'パスワードが弱すぎます。6文字以上にしてください';
    } else if (errorMessage.contains('email-already-in-use')) {
      return 'このメールアドレスは既に使用されています';
    } else if (errorMessage.contains('invalid-email')) {
      return '無効なメールアドレス形式です';
    } else if (errorMessage.contains('network-request-failed')) {
      return 'ネットワークエラーが発生しました。インターネット接続を確認してください';
    } else {
      return 'エラーが発生しました: $errorMessage';
    }
  }
}
