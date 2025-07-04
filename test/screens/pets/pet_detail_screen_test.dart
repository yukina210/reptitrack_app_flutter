// test/screens/pets/pet_detail_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:reptitrack_app/screens/pets/pet_detail_screen.dart';
import 'package:reptitrack_app/screens/pets/pet_form_screen.dart';
import 'package:reptitrack_app/models/pet.dart';
import 'package:reptitrack_app/models/care_record.dart';
import 'package:reptitrack_app/models/weight_record.dart';
import 'package:reptitrack_app/services/auth_service.dart';
import 'package:reptitrack_app/services/settings_service.dart';
import 'package:reptitrack_app/services/care_record_service.dart';
import 'package:reptitrack_app/services/weight_record_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// モッククラス生成用のアノテーション
@GenerateMocks([
  AuthService,
  User,
  SettingsService,
  CareRecordService,
  WeightRecordService,
])
import 'pet_detail_screen_test.mocks.dart';

void main() {
  group('PetDetailScreen テスト', () {
    late MockAuthService mockAuthService;
    late MockUser mockUser;
    late MockSettingsService mockSettingsService;
    late MockCareRecordService mockCareRecordService;
    late MockWeightRecordService mockWeightRecordService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockUser = MockUser();
      mockSettingsService = MockSettingsService();
      mockCareRecordService = MockCareRecordService();
      mockWeightRecordService = MockWeightRecordService();

      // 基本的なモック設定
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-user-id');
      when(mockSettingsService.getText(any, any)).thenReturn('テストテキスト');
      when(mockSettingsService.currentLanguage)
          .thenReturn(AppLanguage.japanese);
      when(mockCareRecordService.getCareRecords())
          .thenAnswer((_) => Stream.value([]));
      when(mockWeightRecordService.getWeightRecords())
          .thenAnswer((_) => Stream.value([]));
    });

    // テスト用のペットデータ
    final testPet = Pet(
      id: 'pet1',
      name: 'テストペット',
      gender: Gender.male,
      birthday: DateTime(2023, 1, 15),
      category: Category.snake,
      breed: 'ボールパイソン',
      unit: WeightUnit.g,
      imageUrl: 'https://example.com/image.jpg',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // テスト用のお世話記録データ
    final testCareRecords = [
      CareRecord(
        id: 'care1',
        date: DateTime.now(),
        time: TimeOfDay(hour: 14, minute: 30),
        foodStatus: FoodStatus.completed,
        foodType: 'マウス',
        excretion: true,
        shedding: false,
        vomiting: false,
        bathing: false,
        cleaning: false,
        matingStatus: null,
        layingEggs: false,
        otherNote: 'テストメモ',
        tags: ['健康', '正常'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CareRecord(
        id: 'care2',
        date: DateTime.now().subtract(Duration(days: 1)),
        time: TimeOfDay(hour: 10, minute: 0),
        foodStatus: FoodStatus.refused,
        foodType: 'コオロギ',
        excretion: false,
        shedding: true,
        vomiting: false,
        bathing: true,
        cleaning: false,
        matingStatus: null,
        layingEggs: false,
        otherNote: '脱皮前で食欲なし',
        tags: ['脱皮'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    // テスト用の体重記録データ
    final testWeightRecords = [
      WeightRecord(
        id: 'weight1',
        date: DateTime.now(),
        weightValue: 250.5,
        memo: '健康的な体重',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      WeightRecord(
        id: 'weight2',
        date: DateTime.now().subtract(Duration(days: 7)),
        weightValue: 248.2,
        memo: '少し軽い',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
          ChangeNotifierProvider<SettingsService>.value(
              value: mockSettingsService),
        ],
        child: MaterialApp(
          routes: {
            '/pet-form': (context) => PetFormScreen(
                pet: ModalRoute.of(context)!.settings.arguments as Pet?),
          },
          home: PetDetailScreen(pet: testPet),
        ),
      );
    }

    group('基本画面表示テスト', () {
      testWidgets('ペット詳細画面が正しく表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 基本的なUI要素の存在確認
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('テストペット'), findsOneWidget);
        expect(find.text('ボールパイソン'), findsOneWidget);
      });

      testWidgets('ペット情報の詳細が正しく表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ペット名の表示確認
        expect(find.text('テストペット'), findsOneWidget);

        // 種類の表示確認
        expect(find.text('ボールパイソン'), findsOneWidget);

        // 性別の表示確認（実装に応じて調整）
        expect(find.text('オス'), findsOneWidget);

        // 誕生日の表示確認
        expect(find.text('2023/01/15'), findsOneWidget);

        // 分類の表示確認
        expect(find.text('ヘビ'), findsOneWidget);
      });

      testWidgets('ペット画像の表示確認', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 画像ウィジェットの存在確認
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('編集ボタンの表示確認', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 編集ボタンの存在確認
        expect(find.byIcon(Icons.edit), findsOneWidget);
      });
    });

    group('お世話記録表示テスト', () {
      testWidgets('お世話記録が正しく表示される', (WidgetTester tester) async {
        when(mockCareRecordService.getCareRecords())
            .thenAnswer((_) => Stream.value(testCareRecords));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // お世話記録の存在確認
        expect(find.text('完食'), findsOneWidget);
        expect(find.text('拒食'), findsOneWidget);
        expect(find.text('マウス'), findsOneWidget);
        expect(find.text('コオロギ'), findsOneWidget);
        expect(find.text('テストメモ'), findsOneWidget);
        expect(find.text('脱皮前で食欲なし'), findsOneWidget);
      });

      testWidgets('お世話記録のカレンダー表示確認', (WidgetTester tester) async {
        when(mockCareRecordService.getCareRecords())
            .thenAnswer((_) => Stream.value(testCareRecords));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // カレンダーウィジェットの存在確認
        expect(find.byType(TableCalendar), findsOneWidget);
      });

      testWidgets('お世話記録の詳細情報表示確認', (WidgetTester tester) async {
        when(mockCareRecordService.getCareRecords())
            .thenAnswer((_) => Stream.value(testCareRecords));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 詳細情報の表示確認
        expect(find.text('排泄'), findsOneWidget);
        expect(find.text('脱皮'), findsOneWidget);
        expect(find.text('温浴'), findsOneWidget);
        expect(find.text('健康'), findsOneWidget);
        expect(find.text('正常'), findsOneWidget);
      });
    });

    group('体重記録表示テスト', () {
      testWidgets('体重記録が正しく表示される', (WidgetTester tester) async {
        when(mockWeightRecordService.getWeightRecords())
            .thenAnswer((_) => Stream.value(testWeightRecords));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 体重記録の存在確認
        expect(find.text('250.5'), findsOneWidget);
        expect(find.text('248.2'), findsOneWidget);
        expect(find.text('健康的な体重'), findsOneWidget);
        expect(find.text('少し軽い'), findsOneWidget);
      });

      testWidgets('体重グラフの表示確認', (WidgetTester tester) async {
        when(mockWeightRecordService.getWeightRecords())
            .thenAnswer((_) => Stream.value(testWeightRecords));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // グラフウィジェットの存在確認
        expect(find.byType(LineChart), findsOneWidget);
      });

      testWidgets('体重単位の表示確認', (WidgetTester tester) async {
        when(mockWeightRecordService.getWeightRecords())
            .thenAnswer((_) => Stream.value(testWeightRecords));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 体重単位の表示確認
        expect(find.text('g'), findsAtLeastNWidgets(1));
      });
    });

    group('ナビゲーションテスト', () {
      testWidgets('編集ボタンタップでペット編集画面に遷移する', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 編集ボタンをタップ
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        // ペット編集画面に遷移したことを確認
        expect(find.byType(PetFormScreen), findsOneWidget);
      });

      testWidgets('編集ボタンタップで正しいペット情報が渡される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 編集ボタンをタップ
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        // ペット編集画面に遷移し、正しいペット情報が表示されることを確認
        expect(find.byType(PetFormScreen), findsOneWidget);
        expect(find.text('テストペット'), findsOneWidget);
        expect(find.text('ボールパイソン'), findsOneWidget);
      });

      testWidgets('お世話記録追加ボタンのテスト', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // お世話記録追加ボタンの存在確認
        expect(find.byIcon(Icons.add), findsAtLeastNWidgets(1));

        // ボタンをタップ
        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pumpAndSettle();

        // タップが成功したことを確認（実際の画面遷移は実装に依存）
      });

      testWidgets('体重記録追加ボタンのテスト', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 体重記録追加ボタンの存在確認
        expect(find.byIcon(Icons.add), findsAtLeastNWidgets(1));
      });
    });

    group('データ読み込みテスト', () {
      testWidgets('お世話記録のローディング状態確認', (WidgetTester tester) async {
        when(mockCareRecordService.getCareRecords())
            .thenAnswer((_) => Stream.value(testCareRecords));

        await tester.pumpWidget(createTestWidget());

        // 初期ローディング状態の確認
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

        await tester.pumpAndSettle();

        // ローディング完了後の状態確認
        expect(find.text('完食'), findsOneWidget);
      });

      testWidgets('体重記録のローディング状態確認', (WidgetTester tester) async {
        when(mockWeightRecordService.getWeightRecords())
            .thenAnswer((_) => Stream.value(testWeightRecords));

        await tester.pumpWidget(createTestWidget());

        // 初期ローディング状態の確認
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

        await tester.pumpAndSettle();

        // ローディング完了後の状態確認
        expect(find.text('250.5'), findsOneWidget);
      });

      testWidgets('空のデータ状態の確認', (WidgetTester tester) async {
        when(mockCareRecordService.getCareRecords())
            .thenAnswer((_) => Stream.value([]));
        when(mockWeightRecordService.getWeightRecords())
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 空状態の表示確認（実装に応じて調整）
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.text('テストペット'), findsOneWidget);
      });
    });

    group('エラーハンドリングテスト', () {
      testWidgets('お世話記録の読み込みエラーハンドリング', (WidgetTester tester) async {
        when(mockCareRecordService.getCareRecords())
            .thenAnswer((_) => Stream.error(Exception('データ取得エラー')));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // エラー状態でも基本的なペット情報は表示されることを確認
        expect(find.text('テストペット'), findsOneWidget);
      });

      testWidgets('体重記録の読み込みエラーハンドリング', (WidgetTester tester) async {
        when(mockWeightRecordService.getWeightRecords())
            .thenAnswer((_) => Stream.error(Exception('データ取得エラー')));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // エラー状態でも基本的なペット情報は表示されることを確認
        expect(find.text('テストペット'), findsOneWidget);
      });
    });

    group('UI相互作用テスト', () {
      testWidgets('カレンダー日付選択のテスト', (WidgetTester tester) async {
        when(mockCareRecordService.getCareRecords())
            .thenAnswer((_) => Stream.value(testCareRecords));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // カレンダーの存在確認
        expect(find.byType(TableCalendar), findsOneWidget);

        // カレンダー上の日付をタップ（実装に応じて調整）
        final calendarWidget = find.byType(TableCalendar);
        if (calendarWidget.evaluate().isNotEmpty) {
          await tester.tap(calendarWidget);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('タブ切り替えのテスト', (WidgetTester tester) async {
        when(mockCareRecordService.getCareRecords())
            .thenAnswer((_) => Stream.value(testCareRecords));
        when(mockWeightRecordService.getWeightRecords())
            .thenAnswer((_) => Stream.value(testWeightRecords));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // タブバーの存在確認
        expect(find.byType(TabBar), findsOneWidget);
        expect(find.byType(TabBarView), findsOneWidget);

        // タブの切り替えテスト
        final tabs = find.byType(Tab);
        if (tabs.evaluate().length > 1) {
          await tester.tap(tabs.at(1));
          await tester.pumpAndSettle();
        }
      });

      testWidgets('スクロール動作のテスト', (WidgetTester tester) async {
        when(mockCareRecordService.getCareRecords())
            .thenAnswer((_) => Stream.value(testCareRecords));
        when(mockWeightRecordService.getWeightRecords())
            .thenAnswer((_) => Stream.value(testWeightRecords));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // スクロール可能なウィジェットの存在確認
        expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));

        // スクロール動作のテスト
        await tester.drag(
            find.byType(SingleChildScrollView).first, Offset(0, -200));
        await tester.pumpAndSettle();
      });
    });

    group('レスポンシブデザインテスト', () {
      testWidgets('小さな画面サイズでの表示確認', (WidgetTester tester) async {
        tester.view.physicalSize = Size(400, 600);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 小さな画面でも基本的な要素が表示されることを確認
        expect(find.text('テストペット'), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      });

      testWidgets('大きな画面サイズでの表示確認', (WidgetTester tester) async {
        tester.view.physicalSize = Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 大きな画面でも適切に表示されることを確認
        expect(find.text('テストペット'), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      });
    });

    group('アクセシビリティテスト', () {
      testWidgets('セマンティクス情報の確認', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // セマンティクス情報が適切に設定されていることを確認
        expect(find.bySemanticsLabel('編集'), findsOneWidget);
      });

      testWidgets('読み上げ対応の確認', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 読み上げ対応のためのウィジェットが存在することを確認
        expect(find.byType(Semantics), findsAtLeastNWidgets(1));
      });
    });

    group('パフォーマンステスト', () {
      testWidgets('大量データでの表示パフォーマンス確認', (WidgetTester tester) async {
        // 大量のお世話記録データを生成
        final largeCareRecords = List.generate(
            50,
            (index) => CareRecord(
                  id: 'care$index',
                  date: DateTime.now().subtract(Duration(days: index)),
                  time: TimeOfDay(hour: 14, minute: 30),
                  foodStatus: FoodStatus.completed,
                  foodType: 'テストフード$index',
                  excretion: index % 2 == 0,
                  shedding: false,
                  vomiting: false,
                  bathing: false,
                  cleaning: false,
                  matingStatus: null,
                  layingEggs: false,
                  otherNote: 'テストメモ$index',
                  tags: ['タグ$index'],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));

        when(mockCareRecordService.getCareRecords())
            .thenAnswer((_) => Stream.value(largeCareRecords));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 大量データでも適切に表示されることを確認
        expect(find.text('テストペット'), findsOneWidget);
        expect(find.text('テストフード0'), findsOneWidget);
      });
    });
  });
}
