// test/flutter_test_config.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // テストバインディングを初期化
  TestWidgetsFlutterBinding.ensureInitialized();

  // Firebase Core のモック設定
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
                  },
                  'pluginConstants': {},
                },
              ];
            case 'Firebase#initializeApp':
              return {
                'name': methodCall.arguments?['name'] ?? '[DEFAULT]',
                'options': {
                  'apiKey': 'fake-api-key',
                  'appId': 'fake-app-id',
                  'messagingSenderId': 'fake-sender-id',
                  'projectId': 'fake-project-id',
                  'storageBucket': 'fake-storage-bucket',
                },
                'pluginConstants': {},
              };
            default:
              return null;
          }
        },
      );

  // Firebase Auth のモック設定
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
                  'displayName': 'Test User',
                  'emailVerified': true,
                },
              };
            case 'Auth#sendPasswordResetEmail':
              return null;
            default:
              return null;
          }
        },
      );

  // Firebase Firestore のモック設定
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/cloud_firestore'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'Firestore#runTransaction':
            case 'DocumentReference#set':
            case 'DocumentReference#update':
            case 'DocumentReference#delete':
              return null;
            case 'DocumentReference#get':
              return {
                'data': {},
                'metadata': {'isFromCache': false, 'hasPendingWrites': false},
              };
            case 'Query#snapshots':
            case 'DocumentReference#snapshots':
              return {
                'documents': [],
                'metadata': {'isFromCache': false, 'hasPendingWrites': false},
              };
            default:
              return null;
          }
        },
      );

  // Google Sign In のモック設定
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/google_sign_in'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'init':
              return null;
            case 'signIn':
              return {
                'id': 'test-google-id',
                'email': 'test@gmail.com',
                'displayName': 'Test Google User',
                'photoUrl': 'https://example.com/photo.jpg',
              };
            case 'signOut':
            case 'disconnect':
              return null;
            default:
              return null;
          }
        },
      );

  // Sign in with Apple のモック設定
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('sign_in_with_apple'), (
        MethodCall methodCall,
      ) async {
        switch (methodCall.method) {
          case 'getAppleIDCredential':
            return {
              'userIdentifier': 'test-apple-id',
              'givenName': 'Test',
              'familyName': 'User',
              'email': 'test@privaterelay.appleid.com',
              'authorizationCode': 'fake-auth-code',
              'identityToken': 'fake-identity-token',
            };
          case 'isAvailable':
            return true;
          default:
            return null;
        }
      });

  await testMain();
}
