// test/helpers/test_helpers.dart
import 'package:flutter/material.dart';
import 'package:reptitrack_app/models/care_record.dart';

/// テスト用のヘルパークラス
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
      tags: ['元気', '活发', '良い調子'],
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
        time: TimeOfDay(hour: 10 + i, minute: 0),
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

  /// 特定の日付範囲のレコードを作成
  static List<CareRecord> createRecordsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    final records = <CareRecord>[];
    var currentDate = startDate;

    while (!currentDate.isAfter(endDate)) {
      records.add(createTestCareRecord(
        id: 'record-${currentDate.day}',
        date: currentDate,
        excretion: true,
        shedding: false,
        vomiting: false,
        bathing: false,
        cleaning: false,
        layingEggs: false,
      ));
      currentDate = currentDate.add(Duration(days: 1));
    }

    return records;
  }

  /// 交配記録を作成
  static CareRecord createMatingRecord(MatingStatus status) {
    return createTestCareRecord(
      matingStatus: status,
      excretion: false,
      shedding: false,
      vomiting: false,
      bathing: false,
      cleaning: false,
      layingEggs: false,
      tags: ['交配'],
    );
  }

  /// 産卵記録を作成
  static CareRecord createEggLayingRecord() {
    return createTestCareRecord(
      layingEggs: true,
      excretion: false,
      shedding: false,
      vomiting: false,
      bathing: false,
      cleaning: false,
      otherNote: '産卵を確認しました',
      tags: ['産卵', '重要'],
    );
  }

  /// 脱皮記録を作成
  static CareRecord createSheddingRecord() {
    return createTestCareRecord(
      shedding: true,
      excretion: false,
      vomiting: false,
      bathing: true, // 脱皮後の温浴
      cleaning: false,
      layingEggs: false,
      otherNote: '脱皮が完了しました',
      tags: ['脱皮', '成長'],
    );
  }

  /// 体調不良記録を作成
  static CareRecord createSickRecord() {
    return createTestCareRecord(
      foodStatus: FoodStatus.refused,
      excretion: false,
      shedding: false,
      vomiting: true,
      bathing: false,
      cleaning: false,
      layingEggs: false,
      otherNote: '体調が悪そうです。病院を検討中。',
      tags: ['体調不良', '要観察'],
    );
  }

  /// 健康チェック記録を作成
  static CareRecord createHealthCheckRecord() {
    return createTestCareRecord(
      foodStatus: FoodStatus.completed,
      excretion: true,
      shedding: false,
      vomiting: false,
      bathing: false,
      cleaning: true,
      layingEggs: false,
      otherNote: '健康状態良好。活発に動いています。',
      tags: ['健康', '活発', 'チェック'],
    );
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

/// テスト用のウィジェットファインダー
class TestFinders {
  /// 食事ステータスのラジオボタンを探す
  static Finder foodStatusRadio(FoodStatus status) {
    return find.byWidgetPredicate(
      (widget) => widget is RadioListTile<FoodStatus> && widget.value == status,
    );
  }

  /// 交配ステータスのラジオボタンを探す
  static Finder matingStatusRadio(MatingStatus status) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is RadioListTile<MatingStatus> && widget.value == status,
    );
  }

  /// 特定のラベルを持つTextFormFieldを探す
  static Finder textFormFieldByLabel(String label) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is TextFormField && widget.decoration?.labelText == label,
    );
  }

  /// 特定のタイトルを持つCheckboxListTileを探す
  static Finder checkboxByTitle(String title) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is CheckboxListTile && widget.title.toString().contains(title),
    );
  }

  /// アイコン付きボタンを探す
  static Finder iconButtonWithIcon(IconData icon) {
    return find.byWidgetPredicate(
      (widget) => widget is IconButton && (widget.icon as Icon).icon == icon,
    );
  }

  /// 特定のテキストとアイコンを持つボタンを探す
  static Finder buttonWithTextAndIcon(String text, IconData icon) {
    return find.byWidgetPredicate(
      (widget) =>
          (widget is ElevatedButton || widget is OutlinedButton) &&
          widget.child.toString().contains(text),
    );
  }
}

/// テスト用のアクションヘルパー
class TestActions {
  /// 食事ステータスを選択
  static Future<void> selectFoodStatus(
    WidgetTester tester,
    FoodStatus status,
  ) async {
    final radio = TestFinders.foodStatusRadio(status);
    await tester.tap(radio);
    await tester.pumpAndSettle();
  }

  /// 交配ステータスを選択
  static Future<void> selectMatingStatus(
    WidgetTester tester,
    MatingStatus status,
  ) async {
    final radio = TestFinders.matingStatusRadio(status);
    await tester.tap(radio);
    await tester.pumpAndSettle();
  }

  /// チェックボックスをトグル
  static Future<void> toggleCheckbox(
    WidgetTester tester,
    String title,
  ) async {
    final checkbox = TestFinders.checkboxByTitle(title);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
  }

  /// テキストフィールドに入力
  static Future<void> enterTextInField(
    WidgetTester tester,
    String label,
    String text,
  ) async {
    final field = TestFinders.textFormFieldByLabel(label);
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }

  /// 日付を選択
  static Future<void> selectDate(
    WidgetTester tester,
    DateTime date,
  ) async {
    // 日付選択ボタンをタップ
    final dateButton = find.byIcon(Icons.calendar_today);
    await tester.tap(dateButton);
    await tester.pumpAndSettle();

    // 日付ピッカーで日付を選択（簡略化）
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  /// 時間を選択
  static Future<void> selectTime(
    WidgetTester tester,
    TimeOfDay time,
  ) async {
    // 時間選択ボタンをタップ
    final timeButton = find.byIcon(Icons.access_time);
    await tester.tap(timeButton);
    await tester.pumpAndSettle();

    // 時間ピッカーでOKをタップ（簡略化）
    await tester.tap(find.text('OK'));
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

  /// 削除確認ダイアログで削除を実行
  static Future<void> confirmDelete(WidgetTester tester) async {
    // 削除ボタンをタップ
    final deleteButton = find.byIcon(Icons.delete);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // 確認ダイアログで削除を実行
    final confirmButton = find.byWidgetPredicate(
      (widget) =>
          widget is TextButton && widget.child.toString().contains('削除する'),
    );
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
  }

  /// 完全なケア記録を入力
  static Future<void> fillCompleteRecord(WidgetTester tester) async {
    // 食事情報
    await selectFoodStatus(tester, FoodStatus.completed);
    await enterTextInField(tester, 'エサの種類', 'コオロギ');

    // お世話項目
    await toggleCheckbox(tester, '排泄');
    await toggleCheckbox(tester, '温浴');

    // 交配
    await selectMatingStatus(tester, MatingStatus.success);

    // メモとタグ
    await enterTextInField(tester, 'メモ', 'とても元気でした');
    await enterTextInField(tester, 'タグ (カンマ区切り)', '元気, 活発, 良い調子');
  }
}
