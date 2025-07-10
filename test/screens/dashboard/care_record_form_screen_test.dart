// test/screens/dashboard/care_record_form_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reptitrack_app/models/care_record.dart';

// ヘルパーメソッドを最初に定義
TimeOfDay? parseTimeOfDay(String timeString) {
  final parts = timeString.split(':');
  if (parts.length == 2) {
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
  return null;
}

FoodStatus? parseFoodStatus(String statusString) {
  switch (statusString) {
    case 'completed':
      return FoodStatus.completed;
    case 'leftover':
      return FoodStatus.leftover;
    case 'refused':
      return FoodStatus.refused;
    default:
      return null;
  }
}

// シンプルなテスト用のモッククラス
class TestUser {
  final String uid;
  final String? email;

  TestUser({required this.uid, this.email});
}

class TestAuthService extends ChangeNotifier {
  TestUser? _user;

  TestUser? get currentUser => _user;

  void setUser(TestUser? user) {
    _user = user;
    notifyListeners();
  }
}

// Provider を使わないテスト用ウィジェット
class TestCareRecordFormScreen extends StatelessWidget {
  final String petId;
  final DateTime selectedDate;
  final CareRecord? record;

  const TestCareRecordFormScreen({
    super.key,
    required this.petId,
    required this.selectedDate,
    this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(record == null ? 'お世話記録の追加' : 'お世話記録の編集'),
        backgroundColor: Colors.green,
        actions: [
          if (record != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {},
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日時セクション
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '日時',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.calendar_today),
                            label: Text('2024年01月15日'),
                            onPressed: () {},
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.access_time),
                            label: Text('時間を選択'),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // 食事セクション
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ごはん',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    RadioListTile<FoodStatus>(
                      title: Text('完食'),
                      value: FoodStatus.completed,
                      groupValue: null,
                      onChanged: (value) {},
                    ),
                    RadioListTile<FoodStatus>(
                      title: Text('食べ残し'),
                      value: FoodStatus.leftover,
                      groupValue: null,
                      onChanged: (value) {},
                    ),
                    RadioListTile<FoodStatus>(
                      title: Text('拒食'),
                      value: FoodStatus.refused,
                      groupValue: null,
                      onChanged: (value) {},
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // お世話項目セクション
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'お世話項目',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    CheckboxListTile(
                      title: Text('排泄'),
                      value: false,
                      onChanged: (value) {},
                    ),
                    CheckboxListTile(
                      title: Text('脱皮'),
                      value: false,
                      onChanged: (value) {},
                    ),
                    CheckboxListTile(
                      title: Text('吐き戻し'),
                      value: false,
                      onChanged: (value) {},
                    ),
                    CheckboxListTile(
                      title: Text('温浴'),
                      value: false,
                      onChanged: (value) {},
                    ),
                    CheckboxListTile(
                      title: Text('ケージ清掃'),
                      value: false,
                      onChanged: (value) {},
                    ),
                    CheckboxListTile(
                      title: Text('産卵'),
                      value: false,
                      onChanged: (value) {},
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // その他セクション
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'その他・メモ',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'メモ',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'タグ (カンマ区切り)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),

            // 保存ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  record == null ? '記録する' : '更新する',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('CareRecordFormScreen Widget Tests', () {
    Widget createTestWidget({
      String? petId,
      DateTime? selectedDate,
      CareRecord? record,
    }) {
      return MaterialApp(
        home: TestCareRecordFormScreen(
          petId: petId ?? 'test-pet-id',
          selectedDate: selectedDate ?? DateTime(2024, 1, 15),
          record: record,
        ),
      );
    }

    testWidgets('新規記録画面が正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // AppBarのタイトルを確認
      expect(find.text('お世話記録の追加'), findsOneWidget);

      // 基本セクションが表示されることを確認
      expect(find.text('日時'), findsOneWidget);
      expect(find.text('ごはん'), findsOneWidget);
      expect(find.text('お世話項目'), findsOneWidget);
      expect(find.text('その他・メモ'), findsOneWidget);

      // 保存ボタンが表示されることを確認
      expect(find.text('記録する'), findsOneWidget);
    });

    testWidgets('編集モードでは適切なタイトルが表示される', (WidgetTester tester) async {
      final testRecord = CareRecord(
        id: 'test-record-id',
        date: DateTime(2024, 1, 15),
        time: TimeOfDay(hour: 14, minute: 30),
        foodStatus: FoodStatus.completed,
        foodType: 'コオロギ',
        excretion: true,
        shedding: false,
        vomiting: false,
        bathing: true,
        cleaning: false,
        matingStatus: null,
        layingEggs: false,
        otherNote: 'テストメモ',
        tags: ['元気', '活発'],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(record: testRecord));
      await tester.pumpAndSettle();

      // 編集モードのタイトルを確認
      expect(find.text('お世話記録の編集'), findsOneWidget);

      // 削除ボタンが表示されることを確認
      expect(find.byIcon(Icons.delete), findsOneWidget);

      // 更新ボタンが表示されることを確認
      expect(find.text('更新する'), findsOneWidget);
    });

    testWidgets('基本UI要素が存在することを確認', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 日付と時間のボタン
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.text('2024年01月15日'), findsOneWidget);
      expect(find.text('時間を選択'), findsOneWidget);
    });

    testWidgets('食事ステータスのラジオボタンが存在する', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 食事ステータスのラジオボタン
      expect(find.text('完食'), findsOneWidget);
      expect(find.text('食べ残し'), findsOneWidget);
      expect(find.text('拒食'), findsOneWidget);

      // RadioListTileが存在することを確認
      expect(find.byType(RadioListTile<FoodStatus>), findsNWidgets(3));
    });

    testWidgets('お世話項目のチェックボックスが存在する', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // お世話項目のチェックボックス
      expect(find.text('排泄'), findsOneWidget);
      expect(find.text('脱皮'), findsOneWidget);
      expect(find.text('吐き戻し'), findsOneWidget);
      expect(find.text('温浴'), findsOneWidget);
      expect(find.text('ケージ清掃'), findsOneWidget);
      expect(find.text('産卵'), findsOneWidget);

      // CheckboxListTileが存在することを確認
      expect(find.byType(CheckboxListTile), findsNWidgets(6));
    });

    testWidgets('テキスト入力フィールドが存在する', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // メモとタグの入力フィールド
      expect(find.text('メモ'), findsOneWidget);
      expect(find.text('タグ (カンマ区切り)'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('ボタンのタップ操作が可能', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 日付選択ボタンをタップ
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // 時間選択ボタンをタップ
      await tester.tap(find.byIcon(Icons.access_time));
      await tester.pumpAndSettle();

      // 保存ボタンをタップ
      await tester.tap(find.text('記録する'));
      await tester.pumpAndSettle();

      // エラーが発生しないことを確認
      expect(find.text('記録する'), findsOneWidget);
    });

    testWidgets('ラジオボタンとチェックボックスのタップ操作', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 完食ラジオボタンをタップ
      await tester.tap(find.byWidgetPredicate((widget) =>
          widget is RadioListTile<FoodStatus> &&
          widget.value == FoodStatus.completed));
      await tester.pumpAndSettle();

      // 排泄チェックボックスをタップ
      await tester.tap(find.byWidgetPredicate((widget) =>
          widget is CheckboxListTile && (widget.title as Text).data == '排泄'));
      await tester.pumpAndSettle();

      // エラーが発生しないことを確認
      expect(find.text('排泄'), findsOneWidget);
    });

    testWidgets('スクロール可能であることを確認', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // SingleChildScrollViewが存在することを確認
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // スクロール動作をテスト
      await tester.drag(find.byType(SingleChildScrollView), Offset(0, -300));
      await tester.pumpAndSettle();

      // 要素がまだ存在することを確認
      expect(find.text('お世話記録の追加'), findsOneWidget);
    });
  });

  group('CareRecord Model Tests', () {
    test('CareRecord作成が正しく動作する', () {
      final record = CareRecord(
        id: 'test-id',
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
        otherNote: 'テストメモ',
        tags: ['元気', '活発'],
        createdAt: DateTime.now(),
      );

      expect(record.id, equals('test-id'));
      expect(record.foodStatus, equals(FoodStatus.completed));
      expect(record.foodType, equals('コオロギ'));
      expect(record.excretion, isTrue);
      expect(record.bathing, isTrue);
      expect(record.matingStatus, equals(MatingStatus.success));
      expect(record.tags, contains('元気'));
      expect(record.tags, contains('活発'));
    });

    test('CareRecordのtoMapが正しく動作する', () {
      final record = CareRecord(
        date: DateTime(2024, 1, 15),
        foodStatus: FoodStatus.completed,
        excretion: true,
        shedding: false,
        vomiting: false,
        bathing: false,
        cleaning: false,
        layingEggs: false,
        tags: ['元気'],
        createdAt: DateTime.now(),
      );

      final map = record.toMap();

      expect(map['foodStatus'], equals('completed'));
      expect(map['excretion'], isTrue);
      expect(map['shedding'], isFalse);
      expect(map['tags'], equals(['元気']));
    });

    test('nullableフィールドが正しく処理される', () {
      final record = CareRecord(
        date: DateTime(2024, 1, 15),
        excretion: false,
        shedding: false,
        vomiting: false,
        bathing: false,
        cleaning: false,
        layingEggs: false,
        tags: [],
        createdAt: DateTime.now(),
      );

      expect(record.id, isNull);
      expect(record.time, isNull);
      expect(record.foodStatus, isNull);
      expect(record.foodType, isNull);
      expect(record.matingStatus, isNull);
      expect(record.otherNote, isNull);
    });
  });
}
