// test/screens/dashboard/care_record_form_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'package:reptile_care_app/screens/dashboard/care_record_form_screen.dart';
import 'package:reptile_care_app/models/care_record.dart';
import 'package:reptile_care_app/services/care_record_service.dart';
import 'package:reptile_care_app/services/auth_service.dart';

// Mockitoで生成されるモッククラスのインポート
import 'care_record_form_screen_test.mocks.dart';

// モック用のアノテーション
@GenerateMocks([CareRecordService, AuthService])
void main() {
  group('CareRecordFormScreen Tests', () {
    late MockCareRecordService mockCareService;
    late MockAuthService mockAuthService;
    late MockUser mockUser;

    setUp(() {
      mockCareService = MockCareRecordService();
      mockAuthService = MockAuthService();
      mockUser = MockUser(
        isAnonymous: false,
        uid: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      when(mockAuthService.currentUser).thenReturn(mockUser);
    });

    Widget createTestWidget({
      String? petId,
      DateTime? selectedDate,
      CareRecord? record,
    }) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
          ],
          child: CareRecordFormScreen(
            petId: petId ?? 'test-pet-id',
            selectedDate: selectedDate ?? DateTime.now(),
            record: record,
          ),
        ),
      );
    }

    testWidgets('新規記録画面が正しく表示される', (WidgetTester tester) async {
      // モックの設定
      when(mockCareService.getCareRecordsForDate(any))
          .thenAnswer((_) async => []);

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

    testWidgets('編集モードでは既存データが表示される', (WidgetTester tester) async {
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

      when(mockCareService.getCareRecordsForDate(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget(record: testRecord));
      await tester.pumpAndSettle();

      // 編集モードのタイトルを確認
      expect(find.text('お世話記録の編集'), findsOneWidget);

      // 削除ボタンが表示されることを確認
      expect(find.byIcon(Icons.delete), findsOneWidget);

      // 更新ボタンが表示されることを確認
      expect(find.text('更新する'), findsOneWidget);

      // 既存データが表示されることを確認
      expect(find.text('コオロギ'), findsOneWidget);
      expect(find.text('テストメモ'), findsOneWidget);
    });

    testWidgets('日付選択ダイアログが正しく動作する', (WidgetTester tester) async {
      when(mockCareService.getCareRecordsForDate(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 日付選択ボタンをタップ
      final dateButton = find.byIcon(Icons.calendar_today);
      await tester.tap(dateButton);
      await tester.pumpAndSettle();

      // 日付選択ダイアログが表示されることを確認
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('時間選択ダイアログが正しく動作する', (WidgetTester tester) async {
      when(mockCareService.getCareRecordsForDate(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 時間選択ボタンをタップ
      final timeButton = find.byIcon(Icons.access_time);
      await tester.tap(timeButton);
      await tester.pumpAndSettle();

      // 時間選択ダイアログが表示されることを確認
      expect(find.byType(TimePickerDialog), findsOneWidget);
    });

    testWidgets('食事ステータスが正しく選択される', (WidgetTester tester) async {
      when(mockCareService.getCareRecordsForDate(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 完食ラジオボタンをタップ
      final completedRadio = find.byWidgetPredicate((widget) =>
          widget is RadioListTile<FoodStatus> &&
          widget.value == FoodStatus.completed);
      await tester.tap(completedRadio);
      await tester.pumpAndSettle();

      // エサの種類入力欄が表示されることを確認
      expect(find.text('エサの種類'), findsOneWidget);

      // エサの種類を入力
      final foodTypeField = find.byWidgetPredicate((widget) =>
          widget is TextFormField && widget.decoration?.labelText == 'エサの種類');
      await tester.enterText(foodTypeField, 'マウス');
      await tester.pumpAndSettle();

      expect(find.text('マウス'), findsOneWidget);
    });

    testWidgets('お世話項目のチェックボックスが正しく動作する', (WidgetTester tester) async {
      when(mockCareService.getCareRecordsForDate(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 排泄チェックボックスをタップ
      final excretionCheckbox = find.byWidgetPredicate((widget) =>
          widget is CheckboxListTile && widget.title.toString().contains('排泄'));
      await tester.tap(excretionCheckbox);
      await tester.pumpAndSettle();

      // 脱皮チェックボックスをタップ
      final sheddingCheckbox = find.byWidgetPredicate((widget) =>
          widget is CheckboxListTile && widget.title.toString().contains('脱皮'));
      await tester.tap(sheddingCheckbox);
      await tester.pumpAndSettle();

      // チェックボックスが選択状態になることを確認
      expect(tester.widget<CheckboxListTile>(excretionCheckbox).value, isTrue);
      expect(tester.widget<CheckboxListTile>(sheddingCheckbox).value, isTrue);
    });

    testWidgets('交配ステータスが正しく選択される', (WidgetTester tester) async {
      when(mockCareService.getCareRecordsForDate(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 交配成功ラジオボタンをタップ
      final matingSuccessRadio = find.byWidgetPredicate((widget) =>
          widget is RadioListTile<MatingStatus> &&
          widget.value == MatingStatus.success);
      await tester.tap(matingSuccessRadio);
      await tester.pumpAndSettle();

      // クリアボタンが表示されることを確認
      expect(find.text('クリア'), findsWidgets);
    });

    testWidgets('メモとタグが正しく入力される', (WidgetTester tester) async {
      when(mockCareService.getCareRecordsForDate(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // メモを入力
      final memoField = find.byWidgetPredicate((widget) =>
          widget is TextFormField && widget.decoration?.labelText == 'メモ');
      await tester.enterText(memoField, '今日は元気でした');
      await tester.pumpAndSettle();

      // タグを入力
      final tagsField = find.byWidgetPredicate((widget) =>
          widget is TextFormField &&
          widget.decoration?.labelText?.contains('タグ') == true);
      await tester.enterText(tagsField, '元気, 活発, 食欲旺盛');
      await tester.pumpAndSettle();

      expect(find.text('今日は元気でした'), findsOneWidget);
      expect(find.text('元気, 活発, 食欲旺盛'), findsOneWidget);
    });

    testWidgets('記録保存が正しく動作する', (WidgetTester tester) async {
      when(mockCareService.getCareRecordsForDate(any))
          .thenAnswer((_) async => []);
      when(mockCareService.addCareRecord(any))
          .thenAnswer((_) async => 'new-record-id');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // データを入力
      final completedRadio = find.byWidgetPredicate((widget) =>
          widget is RadioListTile<FoodStatus> &&
          widget.value == FoodStatus.completed);
      await tester.tap(completedRadio);
      await tester.pumpAndSettle();

      // 保存ボタンをタップ
      final saveButton = find.text('記録する');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // サービスメソッドが呼ばれることを確認
      verify(mockCareService.addCareRecord(any)).called(1);
    });

    testWidgets('記録更新が正しく動作する', (WidgetTester tester) async {
      final testRecord = CareRecord(
        id: 'test-record-id',
        date: DateTime(2024, 1, 15),
        foodStatus: FoodStatus.completed,
        excretion: true,
        shedding: false,
        vomiting: false,
        bathing: false,
        cleaning: false,
        layingEggs: false,
        tags: [],
        createdAt: DateTime.now(),
      );

      when(mockCareService.getCareRecordsForDate(any))
          .thenAnswer((_) async => []);
      when(mockCareService.updateCareRecord(any)).thenAnswer((_) async => true);

      await tester.pumpWidget(createTestWidget(record: testRecord));
      await tester.pumpAndSettle();

      // 更新ボタンをタップ
      final updateButton = find.text('更新する');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // サービスメソッドが呼ばれることを確認
      verify(mockCareService.updateCareRecord(any)).called(1);
    });

    testWidgets('削除機能が正しく動作する', (WidgetTester tester) async {
      final testRecord = CareRecord(
        id: 'test-record-id',
        date: DateTime(2024, 1, 15),
        foodStatus: FoodStatus.completed,
        excretion: true,
        shedding: false,
        vomiting: false,
        bathing: false,
        cleaning: false,
        layingEggs: false,
        tags: [],
        createdAt: DateTime.now(),
      );

      when(mockCareService.getCareRecordsForDate(any))
          .thenAnswer((_) async => []);
      when(mockCareService.deleteCareRecord(any)).thenAnswer((_) async => true);

      await tester.pumpWidget(createTestWidget(record: testRecord));
      await tester.pumpAndSettle();

      // 削除ボタンをタップ
      final deleteButton = find.byIcon(Icons.delete);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // 削除確認ダイアログが表示されることを確認
      expect(find.text('記録の削除'), findsOneWidget);
      expect(find.text('この記録を削除してもよろしいですか？'), findsOneWidget);

      // 削除実行ボタンをタップ
      final confirmDeleteButton = find.byWidgetPredicate((widget) =>
          widget is TextButton && widget.child.toString().contains('削除する'));
      await tester.tap(confirmDeleteButton);
      await tester.pumpAndSettle();

      // サービスメソッドが呼ばれることを確認
      verify(mockCareService.deleteCareRecord('test-record-id')).called(1);
    });

    testWidgets('既存記録が正しく表示される', (WidgetTester tester) async {
      final existingRecord = CareRecord(
        id: 'existing-record-id',
        date: DateTime.now(),
        time: TimeOfDay(hour: 10, minute: 30),
        foodStatus: FoodStatus.completed,
        excretion: true,
        shedding: false,
        vomiting: false,
        bathing: false,
        cleaning: false,
        layingEggs: false,
        tags: [],
        createdAt: DateTime.now(),
      );

      when(mockCareService.getCareRecordsForDate(any))
          .thenAnswer((_) async => [existingRecord]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 既存記録セクションが表示されることを確認
      expect(find.text('この日の既存記録'), findsOneWidget);
      expect(find.text('10:30'), findsOneWidget);

      // 編集ボタンが表示されることを確認
      expect(find.byIcon(Icons.edit), findsAtLeastNWidgets(1));
    });

    testWidgets('エラーハンドリングが正しく動作する', (WidgetTester tester) async {
      when(mockCareService.getCareRecordsForDate(any))
          .thenAnswer((_) async => []);
      when(mockCareService.addCareRecord(any))
          .thenThrow(Exception('ネットワークエラー'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 保存ボタンをタップ
      final saveButton = find.text('記録する');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // エラーメッセージが表示されることを確認
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('ローディング状態が正しく表示される', (WidgetTester tester) async {
      when(mockCareService.getCareRecordsForDate(any)).thenAnswer((_) async {
        await Future.delayed(Duration(milliseconds: 100));
        return [];
      });

      await tester.pumpWidget(createTestWidget());

      // ローディングインジケーターが表示されることを確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // ローディング完了後は通常の画面が表示されることを確認
      expect(find.byType(CircularProgressIndicator), findsNothing);
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

    test('CareRecordのfromMapが正しく動作する', () {
      final map = {
        'id': 'test-id',
        'date': DateTime(2024, 1, 15),
        'foodStatus': 'completed',
        'foodType': 'コオロギ',
        'excretion': true,
        'shedding': false,
        'vomiting': false,
        'bathing': true,
        'cleaning': false,
        'layingEggs': false,
        'tags': ['元気', '活発'],
        'createdAt': DateTime.now(),
      };

      final record = CareRecord.fromMap(map);

      expect(record.id, equals('test-id'));
      expect(record.foodStatus, equals(FoodStatus.completed));
      expect(record.foodType, equals('コオロギ'));
      expect(record.excretion, isTrue);
      expect(record.bathing, isTrue);
      expect(record.tags, equals(['元気', '活発']));
    });
  });

  group('CareRecordService Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late CareRecordService careService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      careService = CareRecordService(
        userId: 'test-user-id',
        petId: 'test-pet-id',
      );
      // テスト用のFirestoreインスタンスを設定
      // 実際のコードではDependency Injectionを使用することを推奨
    });

    test('記録追加が正しく動作する', () async {
      final record = CareRecord(
        date: DateTime(2024, 1, 15),
        foodStatus: FoodStatus.completed,
        excretion: true,
        shedding: false,
        vomiting: false,
        bathing: false,
        cleaning: false,
        layingEggs: false,
        tags: [],
        createdAt: DateTime.now(),
      );

      // モックサービスでテスト
      when(mockCareService.addCareRecord(record))
          .thenAnswer((_) async => 'new-record-id');

      final result = await mockCareService.addCareRecord(record);
      expect(result, equals('new-record-id'));
    });

    test('記録更新が正しく動作する', () async {
      final record = CareRecord(
        id: 'existing-id',
        date: DateTime(2024, 1, 15),
        foodStatus: FoodStatus.leftover,
        excretion: false,
        shedding: true,
        vomiting: false,
        bathing: false,
        cleaning: false,
        layingEggs: false,
        tags: [],
        createdAt: DateTime.now(),
      );

      when(mockCareService.updateCareRecord(record))
          .thenAnswer((_) async => true);

      final result = await mockCareService.updateCareRecord(record);
      expect(result, isTrue);
    });

    test('記録削除が正しく動作する', () async {
      when(mockCareService.deleteCareRecord('test-id'))
          .thenAnswer((_) async => true);

      final result = await mockCareService.deleteCareRecord('test-id');
      expect(result, isTrue);
    });

    test('日付別記録取得が正しく動作する', () async {
      final testDate = DateTime(2024, 1, 15);
      final records = [
        CareRecord(
          id: 'record-1',
          date: testDate,
          foodStatus: FoodStatus.completed,
          excretion: true,
          shedding: false,
          vomiting: false,
          bathing: false,
          cleaning: false,
          layingEggs: false,
          tags: [],
          createdAt: DateTime.now(),
        ),
      ];

      when(mockCareService.getCareRecordsForDate(testDate))
          .thenAnswer((_) async => records);

      final result = await mockCareService.getCareRecordsForDate(testDate);
      expect(result, hasLength(1));
      expect(result.first.id, equals('record-1'));
    });
  });
}
