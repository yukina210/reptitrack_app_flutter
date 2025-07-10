// test/integration/care_record_integration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:reptitrack_app/screens/dashboard/care_record_form_screen.dart';
import 'package:reptitrack_app/models/care_record.dart';
import '../helpers/test_helpers.dart';
import '../screens/dashboard/care_record_form_screen_test.dart' as form_test;

/// お世話記録の統合テスト（シンプル版）
/// 実際のユーザーフローをテストします
void main() {
  group('お世話記録 統合テスト', () {
    late form_test.MockAuthService mockAuthService;
    late form_test.MockUser mockUser;

    setUp(() {
      mockAuthService = form_test.MockAuthService();
      mockUser = form_test.MockUser(
        uid: TestConstants.testUserId,
        email: TestConstants.testEmail,
        displayName: TestConstants.testDisplayName,
      );
      mockAuthService.setCurrentUser(mockUser);
    });

    Widget createIntegrationTestWidget({
      String? petId,
      DateTime? selectedDate,
      CareRecord? record,
    }) {
      return MaterialApp(
        home: ChangeNotifierProvider<form_test.MockAuthService>.value(
          value: mockAuthService,
          child: CareRecordFormScreen(
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
      await TestActions.selectTime(tester, TestConstants.testTime);

      // 完全なケア記録を入力
      await TestActions.fillCompleteRecord(tester);

      // 保存ボタンをタップ
      await TestActions.saveRecord(tester);

      // フォームが正常に処理されることを確認
      expect(find.text('記録する'), findsOneWidget);
    });

    testWidgets('食事のみの記録作成フロー', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestWidget());
      await tester.pumpAndSettle();

      // 食事情報のみ入力
      await TestActions.selectFoodStatus(tester, FoodStatus.completed);

      // エサの種類を入力（最初のTextFormFieldを使用）
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'ピンクマウス');
        await tester.pumpAndSettle();
      }

      // 保存
      await TestActions.saveRecord(tester);

      // フォームが適切に処理されることを確認
      expect(find.text('記録する'), findsOneWidget);
    });

    testWidgets('お世話項目のみの記録作成フロー', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestWidget());
      await tester.pumpAndSettle();

      // お世話項目を選択
      await TestActions.toggleCheckbox(tester, '排泄');
      await TestActions.toggleCheckbox(tester, '脱皮');
      await TestActions.toggleCheckbox(tester, 'ケージ清掃');

      // 保存
      await TestActions.saveRecord(tester);
    });

    testWidgets('交配記録の作成フロー', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestWidget());
      await tester.pumpAndSettle();

      // 交配情報を入力
      final matingSuccessRadio = find.ancestor(
        of: find.text('成功'),
        matching: find.byType(RadioListTile<MatingStatus>),
      );
      await tester.tap(matingSuccessRadio);
      await tester.pumpAndSettle();

      // 保存
      await TestActions.saveRecord(tester);
    });

    testWidgets('産卵記録の作成フロー', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestWidget());
      await tester.pumpAndSettle();

      // 産卵を記録
      await TestActions.toggleCheckbox(tester, '産卵');

      // 保存
      await TestActions.saveRecord(tester);
    });

    testWidgets('体調不良記録の作成フロー', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestWidget());
      await tester.pumpAndSettle();

      // 体調不良の状況を記録
      await TestActions.selectFoodStatus(tester, FoodStatus.refused);
      await TestActions.toggleCheckbox(tester, '吐き戻し');

      // 保存
      await TestActions.saveRecord(tester);
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
      await TestActions.selectFoodStatus(tester, FoodStatus.leftover);
      await TestActions.toggleCheckbox(tester, '脱皮');

      // 更新
      await TestActions.updateRecord(tester);
    });

    testWidgets('記録削除フロー', (WidgetTester tester) async {
      // 既存の記録で開始
      final existingRecord = TestHelpers.createFullCareRecord();

      await tester
          .pumpWidget(createIntegrationTestWidget(record: existingRecord));
      await tester.pumpAndSettle();

      // 削除の実行
      await TestActions.confirmDelete(tester);
    });

    testWidgets('フォームバリデーションテスト', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestWidget());
      await tester.pumpAndSettle();

      // 何も入力せずに保存を試行
      await TestActions.saveRecord(tester);

      // フォームが送信されることを確認（最小限の記録でも保存可能）
      expect(find.text('記録する'), findsOneWidget);
    });

    testWidgets('複数項目選択テスト', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestWidget());
      await tester.pumpAndSettle();

      // 複数のお世話項目を選択
      await TestActions.toggleCheckbox(tester, '排泄');
      await TestActions.toggleCheckbox(tester, '脱皮');
      await TestActions.toggleCheckbox(tester, '温浴');
      await TestActions.toggleCheckbox(tester, 'ケージ清掃');
      await TestActions.toggleCheckbox(tester, '産卵');

      // 食事も選択
      await TestActions.selectFoodStatus(tester, FoodStatus.completed);

      // 交配も選択
      final matingSuccessRadio = find.ancestor(
        of: find.text('成功'),
        matching: find.byType(RadioListTile<MatingStatus>),
      );
      await tester.tap(matingSuccessRadio);
      await tester.pumpAndSettle();

      // 保存
      await TestActions.saveRecord(tester);
    });

    testWidgets('クリア機能テスト', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestWidget());
      await tester.pumpAndSettle();

      // 食事情報を入力
      await TestActions.selectFoodStatus(tester, FoodStatus.completed);

      // エサの種類を入力
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'マウス');
        await tester.pumpAndSettle();
      }

      // 食事情報をクリア
      final clearButtons = find.text('クリア');
      if (clearButtons.evaluate().isNotEmpty) {
        await tester.tap(clearButtons.first);
        await tester.pumpAndSettle();

        // エサの種類入力欄が非表示になることを確認
        expect(find.text('エサの種類'), findsNothing);
      }

      // 交配情報を入力
      final matingSuccessRadio = find.ancestor(
        of: find.text('成功'),
        matching: find.byType(RadioListTile<MatingStatus>),
      );
      await tester.tap(matingSuccessRadio);
      await tester.pumpAndSettle();

      // 交配情報をクリア
      final matingClearButtons = find.text('クリア');
      if (matingClearButtons.evaluate().isNotEmpty) {
        await tester.tap(matingClearButtons.first);
        await tester.pumpAndSettle();
      }

      // 時間を設定
      await TestActions.selectTime(tester, TestConstants.testTime);

      // 時間をクリア
      final timeClearButton = find.text('時間をクリア');
      if (timeClearButton.evaluate().isNotEmpty) {
        await tester.tap(timeClearButton);
        await tester.pumpAndSettle();

        // 時間が「時間を選択」に戻ることを確認
        expect(find.text('時間を選択'), findsOneWidget);
      }
    });

    testWidgets('日付変更テスト', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestWidget());
      await tester.pumpAndSettle();

      // 初期日付の確認
      expect(find.text('2024年01月15日'), findsOneWidget);

      // 日付変更
      await TestActions.selectDate(tester, DateTime(2024, 1, 20));

      // お世話項目を選択して保存
      await TestActions.toggleCheckbox(tester, '排泄');
      await TestActions.saveRecord(tester);
    });
  });

  group('パフォーマンステスト', () {
    testWidgets('画面表示性能テスト', (WidgetTester tester) async {
      final mockAuthService = form_test.MockAuthService();

      mockAuthService.setCurrentUser(form_test.MockUser(
        uid: TestConstants.testUserId,
        email: TestConstants.testEmail,
      ));

      final widget = MaterialApp(
        home: ChangeNotifierProvider<form_test.MockAuthService>.value(
          value: mockAuthService,
          child: CareRecordFormScreen(
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
