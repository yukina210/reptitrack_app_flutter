// test/flutter_test_config.dart
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Firebase初期化のモック
  const MethodChannel(
    'plugins.flutter.io/firebase_core',
  ).setMockMethodCallHandler((methodCall) async {
    if (methodCall.method == 'Firebase#initializeCore') {
      return [
        {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'fake-api-key',
            'appId': 'fake-app-id',
            'messagingSenderId': 'fake-sender-id',
            'projectId': 'fake-project-id',
          },
          'pluginConstants': {},
        },
      ];
    }
    if (methodCall.method == 'Firebase#initializeApp') {
      return {
        'name': '[DEFAULT]',
        'options': {
          'apiKey': 'fake-api-key',
          'appId': 'fake-app-id',
          'messagingSenderId': 'fake-sender-id',
          'projectId': 'fake-project-id',
        },
        'pluginConstants': {},
      };
    }
    return null;
  });

  // Firebase Auth のモック
  const MethodChannel(
    'plugins.flutter.io/firebase_auth',
  ).setMockMethodCallHandler((methodCall) async {
    return null;
  });

  await testMain();
}
