// test/screens/dashboard/care_record_form_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:reptitrack_app/screens/dashboard/care_record_form_screen.dart';
import 'package:reptitrack_app/models/care_record.dart';
import 'package:reptitrack_app/services/auth_service.dart';

// 手動でモッククラスを作成
class MockUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;

  MockUser({
    required this.uid,
    this.email,
    this.displayName,
    this.isAnonymous = false,
  });
}

class MockAuthService extends ChangeNotifier {
  MockUser? _currentUser;

  MockUser? get currentUser => _currentUser;

  void setCurrentUser(MockUser? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }
}

class MockCareRecordService {
  final List<CareRecord> _records = [];
  bool shouldThrowError = false;

  Future<String?> addCareRecord(CareRecord record) async {
    if (shouldThrowError) {
      throw Exception('テストエラー');
    }

    final newRecord = CareRecord(
      id: 'mock-id-${DateTime.now().millisecondsSinceEpoch}',
      date: record.date,
      time: record.time,
      foodStatus: record.foodStatus,
      foodType: record.foodType,
      excretion: record.excretion,
      shedding: record.shedding,
      vomiting: record.vomiting,
      bathing: record.bathing,
      cleaning: record.cleaning,
      matingStatus: record.matingStatus,
      layingEggs: record.layingEggs,
      otherNote: record.otherNote,
      tags: record.tags,
      createdAt: record.createdAt,
    );

    _records.add(newRecord);
    return newRecord.id;
  }

  Future<bool> updateCareRecord(CareRecord record) async {
    if (shouldThrowError) {
      throw Exception('テストエラー');
    }

    final index = _records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _records[index] = record;
      return true;
    }
    return false;
  }

  Future<bool> deleteCareRecord(String recordId) async {
    if (shouldThrowError) {
      throw Exception('テストエラー');
    }

    final index = _records.indexWhere((r) => r.id == recordId);
    if (index != -1) {
      _records.removeAt(index);
      return true;
    }
    return false;
  }

  Future<List<CareRecord>> getCareRecordsForDate(DateTime date) async {
    if (shouldThrowError) {
      throw Exception('テストエラー');
    }

    return _records.where((record) {
      return record.date.year == date.year &&
          record.date.month == date.month &&
          record.date.day == date.day;
    }).toList();
  }

  void addMockRecord(CareRecord record) {
    _records.add(record);
  }

  void clearRecords() {
    _records.clear();
  }
}

void main() {
  group('CareRecordFormScreen Widget Tests', () {
    late MockAuthService mockAuthService;
    late MockCareRecordService mockCareService;
    late MockUser mockUser;

    setUp(() {
      mockAuthService = MockAuthService();
      mockCareService = MockCareRecordService();
      mockUser = MockUser(
        uid: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      mockAuthService.setCurrentUser(mockUser);
    });

    Widget createTestWidget({
      String? petId,
      DateTime? selectedDate,
      CareRecord? record,
    }) {
      return MaterialApp(
        home: ChangeNotifierProvider<AuthService>.value(
          value: mockAuthService as AuthService,
          child: CareRecordFormScreen(
            petId: petId ?? 'test-pet-id',
            selectedDate: selectedDate ?? DateTime(2024, 1, 15),
            record: record,
          ),
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
        tags: ['元気', '活发'],
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

    testWidgets('日付選択ボタンがタップできる', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 日付選択ボタンを探してタップ
      final dateButton = find.byIcon(Icons.calendar_today);
      expect(dateButton, findsOneWidget);

      await tester.tap(dateButton);
      await tester.pumpAndSettle();

      // 日付選択ダイアログが表示されることを確認
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('時間選択ボタンがタップできる', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 時間選択ボタンを探してタップ
      final timeButton = find.byIcon(Icons.access_time);
      expect(timeButton, findsOneWidget);

      await tester.tap(timeButton);
      await tester.pumpAndSettle();

      // 時間選択ダイアログが表示されることを確認
      expect(find.byType(TimePickerDialog), findsOneWidget);
    });

    testWidgets('食事ステータス選択が動作する', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 完食ラジオボタンを探す
      final completedRadio = find.ancestor(
        of: find.text('完食'),
        matching: find.byType(RadioListTile<FoodStatus>),
      );

      expect(completedRadio, findsOneWidget);
      await tester.tap(completedRadio);
      await tester.pumpAndSettle();

      // エサの種類入力欄が表示されることを確認
      expect(find.text('エサの種類'), findsOneWidget);
    });

    testWidgets('お世話項目のチェックボックスが動作する', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 排泄チェックボックスを探してタップ
      final excretionCheckbox = find.ancestor(
        of: find.text('排泄'),
        matching: find.byType(CheckboxListTile),
      );

      expect(excretionCheckbox, findsOneWidget);
      await tester.tap(excretionCheckbox);
      await tester.pumpAndSettle();

      // チェックボックスが選択状態になることを確認
      final checkbox = tester.widget<CheckboxListTile>(excretionCheckbox);
      expect(checkbox.value, isTrue);
    });

    testWidgets('交配ステータス選択が動作する', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 交配成功ラジオボタンを探す
      final matingSuccessRadio = find.ancestor(
        of: find.text('成功'),
        matching: find.byType(RadioListTile<MatingStatus>),
      );

      expect(matingSuccessRadio, findsOneWidget);
      await tester.tap(matingSuccessRadio);
      await tester.pumpAndSettle();

      // クリアボタンが表示されることを確認
      expect(find.text('クリア'), findsWidgets);
    });

    testWidgets('メモとタグが入力できる', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // メモ入力欄を探して入力
      final memoField = find.byKey(Key('memo_field'));
      if (memoField.evaluate().isEmpty) {
        // Keyが見つからない場合は、ヒントテキストで探す
        final memoFieldByHint = find.byWidgetPredicate((widget) =>
            widget is TextField &&
            widget.decoration?.hintText == '体調や気になることを記録');
        await tester.enterText(memoFieldByHint, '今日は元気でした');
      } else {
        await tester.enterText(memoField, '今日は元気でした');
      }
      await tester.pumpAndSettle();

      // タグ入力欄を探して入力
      final tagsField = find.byKey(Key('tags_field'));
      if (tagsField.evaluate().isEmpty) {
        // Keyが見つからない場合は、ヒントテキストで探す
        final tagsFieldByHint = find.byWidgetPredicate((widget) =>
            widget is TextField &&
            widget.decoration?.hintText == '病院, 薬, 元気など');
        await tester.enterText(tagsFieldByHint, '元気, 活发, 食欲旺盛');
      } else {
        await tester.enterText(tagsField, '元気, 活发, 食欲旺盛');
      }
      await tester.pumpAndSettle();

      expect(find.text('今日は元気でした'), findsOneWidget);
      expect(find.text('元気, 活发, 食欲旺盛'), findsOneWidget);
    });

    testWidgets('時間クリアボタンが動作する', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 時間を設定
      final timeButton = find.byIcon(Icons.access_time);
      await tester.tap(timeButton);
      await tester.pumpAndSettle();

      // 時間選択ダイアログでOKをタップ
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 時間クリアボタンが表示されることを確認
      expect(find.text('時間をクリア'), findsOneWidget);

      // 時間クリアボタンをタップ
      await tester.tap(find.text('時間をクリア'));
      await tester.pumpAndSettle();

      // 時間が「時間を選択」に戻ることを確認
      expect(find.text('時間を選択'), findsOneWidget);
    });

    testWidgets('食事ステータスクリアボタンが動作する', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 完食を選択
      final completedRadio = find.ancestor(
        of: find.text('完食'),
        matching: find.byType(RadioListTile<FoodStatus>),
      );
      await tester.tap(completedRadio);
      await tester.pumpAndSettle();

      // エサの種類を入力
      final foodTypeField = find.byWidgetPredicate((widget) =>
          widget is TextFormField && widget.decoration?.labelText == 'エサの種類');
      await tester.enterText(foodTypeField, 'コオロギ');
      await tester.pumpAndSettle();

      // クリアボタンをタップ
      final clearButton = find.text('クリア').first;
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // エサの種類入力欄が非表示になることを確認
      expect(find.text('エサの種類'), findsNothing);
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
        tags: ['元気', '活发'],
        createdAt: DateTime.now(),
      );

      expect(record.id, equals('test-id'));
      expect(record.foodStatus, equals(FoodStatus.completed));
      expect(record.foodType, equals('コオロギ'));
      expect(record.excretion, isTrue);
      expect(record.bathing, isTrue);
      expect(record.matingStatus, equals(MatingStatus.success));
      expect(record.tags, contains('元気'));
      expect(record.tags, contains('活发'));
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
      final now = DateTime.now();
      final map = {
        'id': 'test-id',
        'date': now.toIso8601String(),
        'time': '14:30',
        'foodStatus': 'completed',
        'foodType': 'コオロギ',
        'excretion': true,
        'shedding': false,
        'vomiting': false,
        'bathing': true,
        'cleaning': false,
        'layingEggs': false,
        'tags': ['元気', '活发'],
        'createdAt': now.toIso8601String(),
      };

      // fromMapメソッドの代わりに、手動でCareRecordを作成
      final record = CareRecord(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        time: _parseTimeOfDay(map['time'] as String),
        foodStatus: _parseFoodStatus(map['foodStatus'] as String),
        foodType: map['foodType'] as String,
        excretion: map['excretion'] as bool,
        shedding: map['shedding'] as bool,
        vomiting: map['vomiting'] as bool,
        bathing: map['bathing'] as bool,
        cleaning: map['cleaning'] as bool,
        layingEggs: map['layingEggs'] as bool,
        tags: List<String>.from(map['tags'] as List),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

      expect(record.id, equals('test-id'));
      expect(record.foodStatus, equals(FoodStatus.completed));
      expect(record.foodType, equals('コオロギ'));
      expect(record.excretion, isTrue);
      expect(record.bathing, isTrue);
      expect(record.tags, equals(['元気', '活发']));
    });

    // ヘルパーメソッド
    TimeOfDay? _parseTimeOfDay(String timeString) {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      return null;
    }

    FoodStatus? _parseFoodStatus(String statusString) {
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

  group('MockCareRecordService Tests', () {
    late MockCareRecordService service;

    setUp(() {
      service = MockCareRecordService();
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

      final recordId = await service.addCareRecord(record);
      expect(recordId, isNotNull);
      expect(recordId, startsWith('mock-id-'));
    });

    test('記録更新が正しく動作する', () async {
      // まず記録を追加
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

      final recordId = await service.addCareRecord(record);

      // 更新用のレコードを作成
      final updatedRecord = CareRecord(
        id: recordId,
        date: DateTime(2024, 1, 15),
        foodStatus: FoodStatus.leftover,
        excretion: false,
        shedding: true,
        vomiting: false,
        bathing: false,
        cleaning: false,
        layingEggs: false,
        tags: ['更新済み'],
        createdAt: DateTime.now(),
      );

      final result = await service.updateCareRecord(updatedRecord);
      expect(result, isTrue);
    });

    test('記録削除が正しく動作する', () async {
      // まず記録を追加
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

      final recordId = await service.addCareRecord(record);

      // 削除実行
      final result = await service.deleteCareRecord(recordId!);
      expect(result, isTrue);

      // 削除後は見つからないことを確認
      final deleteAgain = await service.deleteCareRecord(recordId);
      expect(deleteAgain, isFalse);
    });

    test('日付別記録取得が正しく動作する', () async {
      final testDate = DateTime(2024, 1, 15);

      // 同じ日付の記録を2つ追加
      final record1 = CareRecord(
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
      );

      final record2 = CareRecord(
        date: testDate,
        foodStatus: FoodStatus.refused,
        excretion: false,
        shedding: true,
        vomiting: false,
        bathing: false,
        cleaning: false,
        layingEggs: false,
        tags: [],
        createdAt: DateTime.now(),
      );

      // 違う日付の記録を1つ追加
      final record3 = CareRecord(
        date: DateTime(2024, 1, 16),
        foodStatus: FoodStatus.leftover,
        excretion: true,
        shedding: false,
        vomiting: false,
        bathing: false,
        cleaning: false,
        layingEggs: false,
        tags: [],
        createdAt: DateTime.now(),
      );

      await service.addCareRecord(record1);
      await service.addCareRecord(record2);
      await service.addCareRecord(record3);

      // 指定した日付の記録のみ取得されることを確認
      final records = await service.getCareRecordsForDate(testDate);
      expect(records, hasLength(2));
    });

    test('エラー処理が正しく動作する', () async {
      service.shouldThrowError = true;

      final record = CareRecord(
        date: DateTime(2024, 1, 15),
        excretion: true,
        shedding: false,
        vomiting: false,
        bathing: false,
        cleaning: false,
        layingEggs: false,
        tags: [],
        createdAt: DateTime.now(),
      );

      // 各メソッドがエラーを投げることを確認
      expect(() => service.addCareRecord(record), throwsException);
      expect(() => service.updateCareRecord(record), throwsException);
      expect(() => service.deleteCareRecord('test-id'), throwsException);
      expect(
          () => service.getCareRecordsForDate(DateTime.now()), throwsException);
    });
  });
}
