// test/test_setup.dart
// 全テストファイルで共通で使用するセットアップ

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'test_main.dart';

/// テストの共通セットアップ
void setupTests() {
  // 全テストで Provider の型チェックを無効化
  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
  });

  // 各テストの前にテスト環境を初期化
  setUp(() async {
    await TestEnvironment.initialize();
  });

  // 各テストの後にクリーンアップ
  tearDown(() {
    TestEnvironment.dispose();
  });
}

/// Widget テスト用のセットアップ
void setupWidgetTests() {
  setupTests();

  // Widget テスト特有の設定があれば追加
  setUpAll(() {
    // Widget テスト用の追加設定
  });
}

/// 統合テスト用のセットアップ
void setupIntegrationTests() {
  setupTests();

  // 統合テスト特有の設定があれば追加
  setUpAll(() {
    // 統合テスト用の追加設定
  });
}
