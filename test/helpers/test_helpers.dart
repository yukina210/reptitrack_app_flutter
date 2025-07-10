// test/helpers/test_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reptitrack_app/models/care_record.dart';

/// テスト用のヘルパークラス（シンプル版）
class TestHelpers {
  /// テスト用のCareRecordを作成するファクトリメソッド
  static CareRecord createTestCareRecord({
    String? id,
    DateTime? date,
    TimeOfDay? time,
    FoodStatus? foodStatus,
    String? foodType,
    bool excretion = false,
    bool shedding = false,
    bool vomiting = false,
    bool bathing = false,
    bool cleaning = false,
    MatingStatus? matingStatus,
    bool layingEggs = false,
    String? otherNote,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return CareRecord(
      id: id,
      date: date ?? DateTime(2024, 1, 15),
      time: time,
      foodStatus: foodStatus,
      foodType: foodType,
      excretion: excretion,
      shedding: shedding,
      vomiting: vomiting,
      bathing: bathing,
      cleaning: cleaning,
      matingStatus: matingStatus,
      layingEggs: layingEggs,
      otherNote: otherNote,
      tags: tags ?? [],
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// 完全なケア記録のサンプルを作成
  static CareRecord createFullCareRecord() {
    return createTestCareRecord(
      id: 'full-test-record',
      date: DateTime(2024, 1, 15),
      time: TimeOfDay(hour: 14, minute: 30),
      foodStatus: FoodStatus.completed,
      foodType: 'コオロギ',
      excretion: true,
      shedding: false,
      vomiting: false,
      bathing: true,
      cleaning: false,
      matingStatus: MatingStatus.success,
      layingEggs: false,
      otherNote: 'とても元気でした',
      tags: ['元気', '活発', '良い調子'],
    );
  }

  /// 最小限のケア記録を作成
  static CareRecord createMinimalCareRecord() {
    return createTestCareRecord(
      date: DateTime(2024, 1, 15),
      excretion: false,
      shedding: false,
      vomiting: false,
      bathing: false,
      cleaning: false,
      layingEggs: false,
    );
  }

  /// 食事関連のケア記録を作成
  static CareRecord createFeedingRecord({
    FoodStatus status = FoodStatus.completed,
    String foodType = 'コオロギ',
  }) {
    return createTestCareRecord(
      foodStatus: status,
      foodType: foodType,
      excretion: false,
      shedding: false,
      vomiting: false,
      bathing: false,
      cleaning: false,
      layingEggs: false,
    );
  }

  /// 複数のテストレコードを作成
  static List<CareRecord> createMultipleRecords(int count,
      {DateTime? baseDate}) {
    final records = <CareRecord>[];
    final date = baseDate ?? DateTime(2024, 1, 15);

    for (int i = 0; i < count; i++) {
      records.add(createTestCareRecord(
        id: 'test-record-$i',
        date: date.add(Duration(days: i)),
        time: TimeOfDay(hour: 10 + (i % 12), minute: 0),
        excretion: i % 2 == 0,
        shedding: i % 3 == 0,
        vomiting: false,
        bathing: i % 4 == 0,
        cleaning: i % 5 == 0,
        layingEggs: false,
        tags: ['テスト$i'],
      ));
    }

    return records;
  }
}

/// テスト用の定数クラス
class TestConstants {
  static const String testUserId = 'test-user-id';
  static const String testPetId = 'test-pet-id';
  static const String testEmail = 'test@example.com';
  static const String testDisplayName = 'Test User';

  static final DateTime testDate = DateTime(2024, 1, 15);
  static final TimeOfDay testTime = TimeOfDay(hour: 14, minute: 30);

  static const List<String> commonTags = [
    '元気',
    '活発',
    '食欲旺盛',
    '健康',
    '要観察',
    '体調不良',
    '成長',
    '脱皮',
    '産卵',
    '交配',
  ];

  static const List<String> commonFoodTypes = [
    'コオロギ',
    'マウス',
    'ラット',
    'ピンクマウス',
    'デュビア',
    '人工飼料',
    '野菜',
    '果物',
  ];
}

/// テスト用のアクションヘルパー（基本的な操作のみ）
class TestActions {
  /// 食事ステータスを選択
  static Future<void> selectFoodStatus(
    WidgetTester tester,
    FoodStatus status,
  ) async {
    String statusText;
    switch (status) {
      case FoodStatus.completed:
        statusText = '完食';
        break;
      case FoodStatus.leftover:
        statusText = '食べ残し';
        break;
      case FoodStatus.refused:
        statusText = '拒食';
        break;
    }

    final radio = find.ancestor(
      of: find.text(statusText),
      matching: find.byType(RadioListTile<FoodStatus>),
    );
    await tester.tap(radio);
    await tester.pumpAndSettle();
  }

  /// チェックボックスをトグル
  static Future<void> toggleCheckbox(
    WidgetTester tester,
    String title,
  ) async {
    final checkbox = find.ancestor(
      of: find.text(title),
      matching: find.byType(CheckboxListTile),
    );
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
  }

  /// 記録を保存
  static Future<void> saveRecord(WidgetTester tester) async {
    final saveButton = find.text('記録する');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  }

  /// 記録を更新
  static Future<void> updateRecord(WidgetTester tester) async {
    final updateButton = find.text('更新する');
    await tester.tap(updateButton);
    await tester.pumpAndSettle();
  }

  /// 時間を選択（簡略化）
  static Future<void> selectTime(
    WidgetTester tester,
    TimeOfDay time,
  ) async {
    final timeButton = find.byIcon(Icons.access_time);
    await tester.tap(timeButton);
    await tester.pumpAndSettle();

    // OKボタンをタップ（実際の時間選択は簡略化）
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  /// 日付を選択（簡略化）
  static Future<void> selectDate(
    WidgetTester tester,
    DateTime date,
  ) async {
    final dateButton = find.byIcon(Icons.calendar_today);
    await tester.tap(dateButton);
    await tester.pumpAndSettle();

    // OKボタンをタップ（実際の日付選択は簡略化）
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  /// 完全なケア記録を入力
  static Future<void> fillCompleteRecord(WidgetTester tester) async {
    // 食事情報
    await selectFoodStatus(tester, FoodStatus.completed);

    // エサの種類を入力（最初のTextFormFieldを使用）
    final textFields = find.byType(TextFormField);
    if (textFields.evaluate().isNotEmpty) {
      await tester.enterText(textFields.first, 'コオロギ');
      await tester.pumpAndSettle();
    }

    // お世話項目
    await toggleCheckbox(tester, '排泄');
    await toggleCheckbox(tester, '温浴');

    // 交配
    final matingSuccessRadio = find.ancestor(
      of: find.text('成功'),
      matching: find.byType(RadioListTile<MatingStatus>),
    );
    if (matingSuccessRadio.evaluate().isNotEmpty) {
      await tester.tap(matingSuccessRadio);
      await tester.pumpAndSettle();
    }
  }

  /// 削除確認ダイアログで削除を実行
  static Future<void> confirmDelete(WidgetTester tester) async {
    // 削除ボタンをタップ
    final deleteButton = find.byIcon(Icons.delete);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // 確認ダイアログで削除を実行
    final confirmButton = find.text('削除する');
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
  }
}
