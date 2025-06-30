// test/helpers/test_helper.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

class TestHelper {
  /// テスト用のFirebase初期化
  static Future<void> initializeFirebaseForTest() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Firebase Coreのモック設定
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/firebase_core'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'Firebase#initializeCore') {
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
            }
            return null;
          },
        );

    // Firebase Authのモック設定
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/firebase_auth'),
          (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'Auth#registerIdTokenListener':
              case 'Auth#registerAuthStateListener':
                return {'id': 1, 'user': null};
              default:
                return null;
            }
          },
        );
  }

  /// テスト用のランダムメールアドレス生成
  static String generateTestEmail() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'test_$timestamp@example.com';
  }

  /// テスト用のユーザーデータ
  static Map<String, dynamic> createMockUserData({
    String? uid,
    String? email,
    String? displayName,
  }) {
    return {
      'uid': uid ?? 'test-uid',
      'email': email ?? 'test@example.com',
      'displayName': displayName ?? 'Test User',
      'photoURL': null,
      'emailVerified': true,
      'isAnonymous': false,
      'creationTime': DateTime.now().millisecondsSinceEpoch,
      'lastSignInTime': DateTime.now().millisecondsSinceEpoch,
      'providerData': [],
    };
  }

  /// テスト用のペットデータ
  static Map<String, dynamic> createMockPetData({
    String? name,
    String? category,
    String? gender,
  }) {
    return {
      'pet_id': 'test-pet-id',
      'name': name ?? 'テストペット',
      'gender': gender ?? 'male',
      'birthday': null,
      'category': category ?? 'snake',
      'breed': 'テスト種類',
      'unit': 'g',
      'image_url': null,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// テスト用のお世話記録データ
  static Map<String, dynamic> createMockCareRecordData({
    String? date,
    String? foodStatus,
  }) {
    return {
      'care_id': 'test-care-id',
      'date': date ?? DateTime.now().toIso8601String().split('T')[0],
      'time': '12:00',
      'food_status': foodStatus ?? '完食',
      'food_type': 'コオロギ',
      'excretion': false,
      'shedding': false,
      'vomiting': false,
      'bathing': false,
      'cleaning': false,
      'mating_status': null,
      'laying_eggs': false,
      'other_note': '',
      'tags': [],
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// テスト用の体重記録データ
  static Map<String, dynamic> createMockWeightRecordData({
    String? date,
    double? weight,
  }) {
    return {
      'weight_id': 'test-weight-id',
      'date': date ?? DateTime.now().toIso8601String().split('T')[0],
      'weight_value': weight ?? 50.0,
      'memo': 'テストメモ',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// エラーハンドリングのテストヘルパー
  static void expectFirebaseAuthException(
    dynamic actual,
    String expectedCode,
    String expectedMessage,
  ) {
    expect(actual, isA<Exception>());
    final exception = actual as Exception;
    expect(exception.toString(), contains(expectedMessage));
  }

  /// 非同期テストのタイムアウト設定
  static const Duration testTimeout = Duration(seconds: 30);

  /// テスト用のダミー画像データ
  static List<int> get dummyImageBytes => [
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    0,
    0,
    0,
    13,
    73,
    72,
    68,
    82,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    1,
    8,
    6,
    0,
    0,
    0,
    31,
    21,
    196,
    137,
    0,
    0,
    0,
    13,
    73,
    68,
    65,
    84,
    120,
    156,
    99,
    248,
    15,
    0,
    0,
    1,
    0,
    1,
    0,
    24,
    221,
    141,
    219,
    0,
    0,
    0,
    0,
    73,
    69,
    78,
    68,
    174,
    66,
    96,
    130,
  ];

  /// テスト後のクリーンアップ
  static Future<void> cleanup() async {
    // 必要に応じてテスト後のクリーンアップ処理を追加
  }
}
