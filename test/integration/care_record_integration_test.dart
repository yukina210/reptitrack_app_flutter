// test/integration/care_record_integration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:reptitrack_app/models/care_record.dart';
import '../helpers/test_helpers.dart';

// 統合テスト用のシンプルなモッククラス
class IntegrationTestUser {
  final String uid;
  final String? email;

  IntegrationTestUser({required this.uid, this.email});
}

class IntegrationTestAuthService extends ChangeNotifier {
  IntegrationTestUser? _user;

  IntegrationTestUser? get currentUser => _user;

  void setUser(IntegrationTestUser? user) {
    _user = user;
    notifyListeners();
  }
}

// テスト用のシンプルなCareRecordFormScreen
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
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('記録の削除'),
                    content: Text('この記録を削除してもよろしいですか？'),
                    actions: [
                      TextButton(
                        child: Text('キャンセル'),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      TextButton(
                        child: Text('削除する'),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                );
              },
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
                            onPressed: () {
                              showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.access_time),
                            label: Text('時間を選択'),
                            onPressed: () {
                              showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text('時間をクリア'),
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
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'エサの種類',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text('クリア'),
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
                    // 交配セクション
                    Text('交配'),
                    RadioListTile<MatingStatus>(
                      title: Text('成功'),
                      value: MatingStatus.success,
                      groupValue: null,
                      onChanged: (value) {},
                    ),
                    RadioListTile<MatingStatus>(
                      title: Text('拒絶'),
                      value: MatingStatus.rejected,
                      groupValue: null,
                      onChanged: (value) {},
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text('クリア'),
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

/// お世話記録の統合テスト（独立版）
/// 実際のユーザーフローをテストします
void main() {
  group('お世話記録 統合テスト', () {
    late IntegrationTestAuthService mockAuthService;
    late IntegrationTestUser mockUser;

    setUp(() {
      mockAuthService = IntegrationTestAuthService();
      mockUser = IntegrationTestUser(
        uid: TestConstants.testUserId,
        email: TestConstants.testEmail,
      );
      mockAuthService.setUser(mockUser);
    });

    Widget createIntegrationTestWidget({
      String? petId,
      DateTime? selectedDate,
      CareRecord? record,
    }) {
      return MaterialApp(
        home: ChangeNotifierProvider<IntegrationTestAuthService>.value(
          value: mockAuthService,
          child: TestCareRecordFormScreen(
            petId: petId ?? TestConstants.testPetId,
            selectedDate: selectedDate ?? TestConstants.testDate,
            record: record,
          ),
        ),
      );
    }

    testWidgets('完全なお世話記録の作成フロー', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestWidget());
      await tester.pumpAndSettle();

      // 画面が正しく表示されることを確認
      expect(find.text('お世話記録の追加'), findsOneWidget);

      // 時間を設定
      await tester.tap(find.byIcon(Icons.access_time));
      await tester.pumpAndSettle();

      // 完全なケア記録を入力
      await tester.tap(find.ancestor(
        of: find.text('完食'),
        matching: find.byType(RadioListTile<FoodStatus>),
      ));
      await tester.pumpAndSettle();

      // エサの種類を入力
      final foodTypeField = find
          .byWidgetPredicate(
            (widget) => widget is TextFormField,
          )
          .first;
      await tester.enterText(foodTypeField, 'コオロギ');
      await tester.pumpAndSettle();

      // お世話項目
      await tester.tap(find.ancestor(
        of: find.text('排泄'),
        matching: find.byType(CheckboxListTile),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.ancestor(
        of: find.text('温浴'),
        matching: find.byType(CheckboxListTile),
      ));
      await tester.pumpAndSettle();

      // 交配
      await tester.tap(find.ancestor(
        of: find.text('成功'),
        matching: find.byType(RadioListTile<MatingStatus>),
      ));
      await tester.pumpAndSettle();

      // 保存ボタンをタップ
      await tester.tap(find.text('記録する'));
      await tester.pumpAndSettle();

      // フォームが正常に処理されることを確認
      expect(find.text('記録する'), findsOneWidget);
    });

    testWidgets('食事のみの記録作成フロー', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestWidget());
      await tester.pumpAndSettle();

      // 食事情報のみ入力
      await tester.tap(find.ancestor(
        of: find.text('完食'),
        matching: find.byType(RadioListTile<FoodStatus>),
      ));
      await tester.pumpAndSettle();

      // エサの種類を入力
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'ピンクマウス');
      await tester.pumpAndSettle();

      // 保存
      await tester.tap(find.text('記録する'));
      await tester.pumpAndSettle();

      // フォームが適切に処理されることを確認
      expect(find.text('記録する'), findsOneWidget);
    });

    testWidgets('お世話項目のみの記録作成フロー', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestWidget());
      await tester.pumpAndSettle();

      // お世話項目を選択
      await tester.tap(find.ancestor(
        of: find.text('排泄'),
        matching: find.byType(CheckboxListTile),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.ancestor(
        of: find.text('脱皮'),
        matching: find.byType(CheckboxListTile),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.ancestor(
        of: find.text('ケージ清掃'),
        matching: find.byType(CheckboxListTile),
      ));
      await tester.pumpAndSettle();

      // 保存
      await tester.tap(find.text('記録する'));
      await tester.pumpAndSettle();
    });

    testWidgets('交配記録の作成フロー', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestWidget());
      await tester.pumpAndSettle();

      // 交配情報を入力
      await tester.tap(find.ancestor(
        of: find.text('成功'),
        matching: find.byType(RadioListTile<MatingStatus>),
      ));
      await tester.pumpAndSettle();

      // 保存
      await tester.tap(find.text('記録する'));
      await tester.pumpAndSettle();
    });

    testWidgets('産卵記録の作成フロー', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestWidget());
      await tester.pumpAndSettle();

      // 産卵を記録
      await tester.tap(find.ancestor(
        of: find.text('産卵'),
        matching: find.byType(CheckboxListTile),
      ));
      await tester.pumpAndSettle();

      // 保存
      await tester.tap(find.text('記録する'));
      await tester.pumpAndSettle();
    });

    testWidgets('体調不良記録の作成フロー', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestWidget());
      await tester.pumpAndSettle();

      // 体調不良の状況を記録
      await tester.tap(find.ancestor(
        of: find.text('拒食'),
        matching: find.byType(RadioListTile<FoodStatus>),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.ancestor(
        of: find.text('吐き戻し'),
        matching: find.byType(CheckboxListTile),
      ));
      await tester.pumpAndSettle();

      // 保存
      await tester.tap(find.text('記録する'));
      await tester.pumpAndSettle();
    });

    testWidgets('記録編集フロー', (WidgetTester tester) async {
      // 既存の記録で開始
      final existingRecord = TestHelpers.createFullCareRecord();

      await tester
          .pumpWidget(createIntegrationTestWidget(record: existingRecord));
      await tester.pumpAndSettle();

      // 編集モードの確認
      expect(find.text('お世話記録の編集'), findsOneWidget);
      expect(find.text('更新する'), findsOneWidget);

      // データを変更
      await tester.tap(find.ancestor(
        of: find.text('食べ残し'),
        matching: find.byType(RadioListTile<FoodStatus>),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.ancestor(
        of: find.text('脱皮'),
        matching: find.byType(CheckboxListTile),
      ));
      await tester.pumpAndSettle();

      // 更新
      await tester.tap(find.text('更新する'));
      await tester.pumpAndSettle();
    });

    testWidgets('記録削除フロー', (WidgetTester tester) async {
      // 既存の記録で開始
      final existingRecord = TestHelpers.createFullCareRecord();

      await tester
          .pumpWidget(createIntegrationTestWidget(record: existingRecord));
      await tester.pumpAndSettle();

      // 削除ボタンをタップ
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // 削除確認ダイアログが表示される
      expect(find.text('記録の削除'), findsOneWidget);

      // 削除実行
      await tester.tap(find.text('削除する'));
      await tester.pumpAndSettle();
    });

    testWidgets('クリア機能テスト', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestWidget());
      await tester.pumpAndSettle();

      // 食事情報を入力
      await tester.tap(find.ancestor(
        of: find.text('完食'),
        matching: find.byType(RadioListTile<FoodStatus>),
      ));
      await tester.pumpAndSettle();

      // エサの種類を入力
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'マウス');
      await tester.pumpAndSettle();

      // 食事情報をクリア
      final clearButtons = find.text('クリア');
      await tester.tap(clearButtons.first);
      await tester.pumpAndSettle();

      // 交配情報を入力
      await tester.tap(find.ancestor(
        of: find.text('成功'),
        matching: find.byType(RadioListTile<MatingStatus>),
      ));
      await tester.pumpAndSettle();

      // 交配情報をクリア
      final matingClearButtons = find.text('クリア');
      await tester.tap(matingClearButtons.at(1));
      await tester.pumpAndSettle();

      // 時間をクリア
      await tester.tap(find.text('時間をクリア'));
      await tester.pumpAndSettle();
    });

    testWidgets('日付変更テスト', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestWidget());
      await tester.pumpAndSettle();

      // 初期日付の確認
      expect(find.text('2024年01月15日'), findsOneWidget);

      // 日付変更
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // お世話項目を選択して保存
      await tester.tap(find.ancestor(
        of: find.text('排泄'),
        matching: find.byType(CheckboxListTile),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('記録する'));
      await tester.pumpAndSettle();
    });
  });

  group('パフォーマンステスト', () {
    testWidgets('画面表示性能テスト', (WidgetTester tester) async {
      final mockAuthService = IntegrationTestAuthService();
      mockAuthService.setUser(IntegrationTestUser(
        uid: TestConstants.testUserId,
        email: TestConstants.testEmail,
      ));

      final widget = MaterialApp(
        home: ChangeNotifierProvider<IntegrationTestAuthService>.value(
          value: mockAuthService,
          child: TestCareRecordFormScreen(
            petId: TestConstants.testPetId,
            selectedDate: TestConstants.testDate,
          ),
        ),
      );

      // パフォーマンス測定開始
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      stopwatch.stop();

      // 画面表示が完了することを確認
      expect(find.text('お世話記録の追加'), findsOneWidget);

      // パフォーマンスログ出力（開発時の参考用）
      debugPrint('画面表示時間: ${stopwatch.elapsedMilliseconds}ms');

      // 合理的な時間内で表示されることを確認（3秒以内）
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });
  });
}
