// test/flutter_test_config.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // テストバインディングを初期化
  TestWidgetsFlutterBinding.ensureInitialized();

  // Firebase Core のモック設定
  setupFirebaseCoreMocks();

  // Firebase Auth のモック設定
  setupFirebaseAuthMocks();

  // Google Sign In のモック設定
  setupGoogleSignInMocks();

  // Apple Sign In のモック設定
  setupAppleSignInMocks();

  // テストを実行
  await testMain();
}

void setupFirebaseCoreMocks() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/firebase_core'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'Firebase#initializeCore':
              return [
                {
                  'name': '[DEFAULT]',
                  'options': {
                    'apiKey': 'fake-api-key',
                    'appId': 'fake-app-id',
                    'messagingSenderId': 'fake-sender-id',
                    'projectId': 'fake-project-id',
                    'storageBucket': 'fake-storage-bucket',
                    'authDomain': 'fake-auth-domain',
                  },
                  'pluginConstants': {},
                },
              ];
            case 'Firebase#initializeApp':
              return {
                'name': methodCall.arguments?['name'] ?? '[DEFAULT]',
                'options':
                    methodCall.arguments?['options'] ??
                    {
                      'apiKey': 'fake-api-key',
                      'appId': 'fake-app-id',
                      'messagingSenderId': 'fake-sender-id',
                      'projectId': 'fake-project-id',
                      'storageBucket': 'fake-storage-bucket',
                      'authDomain': 'fake-auth-domain',
                    },
                'pluginConstants': {},
              };
            default:
              return null;
          }
        },
      );
}

void setupFirebaseAuthMocks() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/firebase_auth'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'Auth#registerIdTokenListener':
            case 'Auth#registerAuthStateListener':
              return {'id': 1, 'user': null};
            case 'Auth#signOut':
              return null;
            case 'Auth#signInWithEmailAndPassword':
            case 'Auth#createUserWithEmailAndPassword':
              return {
                'user': {
                  'uid': 'test-uid',
                  'email': methodCall.arguments?['email'] ?? 'test@example.com',
                  'displayName': null,
                  'photoURL': null,
                  'emailVerified': false,
                  'isAnonymous': false,
                  'creationTime': DateTime.now().millisecondsSinceEpoch,
                  'lastSignInTime': DateTime.now().millisecondsSinceEpoch,
                  'providerData': [],
                },
                'additionalUserInfo': {
                  'isNewUser': true,
                  'profile': {},
                  'providerId': 'password',
                  'username': null,
                },
              };
            case 'Auth#sendPasswordResetEmail':
              return null;
            case 'Auth#signInWithCredential':
              return {
                'user': {
                  'uid': 'test-uid',
                  'email': 'test@example.com',
                  'displayName': 'Test User',
                  'photoURL': null,
                  'emailVerified': true,
                  'isAnonymous': false,
                  'creationTime': DateTime.now().millisecondsSinceEpoch,
                  'lastSignInTime': DateTime.now().millisecondsSinceEpoch,
                  'providerData': [],
                },
                'additionalUserInfo': {
                  'isNewUser': false,
                  'profile': {},
                  'providerId': 'google.com',
                  'username': null,
                },
              };
            case 'User#delete':
              return null;
            case 'User#sendEmailVerification':
              return null;
            case 'User#updateProfile':
              return null;
            case 'User#updatePassword':
              return null;
            case 'User#reauthenticateWithCredential':
              return null;
            default:
              return null;
          }
        },
      );
}

void setupGoogleSignInMocks() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/google_sign_in'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'init':
              return null;
            case 'signInSilently':
              return null;
            case 'signIn':
              return {
                'displayName': 'Test User',
                'email': 'test@gmail.com',
                'id': 'test-google-id',
                'photoUrl': null,
                'idToken': 'fake-id-token',
                'accessToken': 'fake-access-token',
              };
            case 'getTokens':
              return {
                'idToken': 'fake-id-token',
                'accessToken': 'fake-access-token',
              };
            case 'signOut':
              return null;
            case 'disconnect':
              return null;
            default:
              return null;
          }
        },
      );
}

void setupAppleSignInMocks() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('sign_in_with_apple'), (
        MethodCall methodCall,
      ) async {
        switch (methodCall.method) {
          case 'isAvailable':
            return true;
          case 'getAppleIDCredential':
            return {
              'userIdentifier': 'test-apple-user-id',
              'givenName': 'Test',
              'familyName': 'User',
              'email': 'test@icloud.com',
              'identityToken': 'fake-identity-token',
              'authorizationCode': 'fake-authorization-code',
            };
          default:
            return null;
        }
      });
}
