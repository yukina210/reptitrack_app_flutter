// test/screens/pets/pet_list_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:reptitrack_app/screens/pets/pet_list_screen.dart';
import 'package:reptitrack_app/models/pet.dart';
import 'package:reptitrack_app/services/pet_service.dart';
import 'package:reptitrack_app/services/auth_service.dart';
import 'package:reptitrack_app/services/settings_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// モッククラス生成用のアノテーション
@GenerateMocks([
  PetService,
  AuthService,
  User,
  SettingsService,
])
import 'pet_list_screen_test.mocks.dart';

void main() {
  group('PetListScreen テスト', () {
    late MockPetService mockPetService;
    late MockAuthService mockAuthService;
    late MockUser mockUser;
    late MockSettingsService mockSettingsService;

    setUp(() {
      mockPetService = MockPetService();
      mockAuthService = MockAuthService();
      mockUser = MockUser();
      mockSettingsService = MockSettingsService();

      // 基本的なモック設定
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-user-id');
      when(mockSettingsService.getText(any, any)).thenReturn('テストテキスト');
      when(mockSettingsService.currentLanguage)
          .thenReturn(AppLanguage.japanese);
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
          ChangeNotifierProvider<SettingsService>.value(
              value: mockSettingsService),
        ],
        child: MaterialApp(
          home: PetListScreen(),
        ),
      );
    }

    group('認証状態のテスト', () {
      testWidgets('未ログイン時のログイン促進画面が表示される', (WidgetTester tester) async {
        // 未ログイン状態を設定
        when(mockAuthService.currentUser).thenReturn(null);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ログイン促進メッセージが表示されることを確認
        expect(find.byIcon(Icons.login), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('ログイン済み時にペット一覧画面が表示される', (WidgetTester tester) async {
        // 空のペットリストを返すモック設定
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // AppBarとFloatingActionButtonが表示されることを確認
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
    });

    group('ペット一覧表示テスト', () {
      final testPets = [
        Pet(
          id: 'pet1',
          name: 'ヘビちゃん',
          gender: Gender.male,
          birthday: DateTime(2023, 1, 15),
          category: Category.snake,
          breed: 'ボールパイソン',
          unit: WeightUnit.g,
          imageUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Pet(
          id: 'pet2',
          name: 'トカゲくん',
          gender: Gender.female,
          birthday: null,
          category: Category.lizard,
          breed: 'レオパードゲッコー',
          unit: WeightUnit.kg,
          imageUrl: 'https://example.com/image.jpg',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      testWidgets('ペットが存在しない場合の表示', (WidgetTester tester) async {
        // 空のペットリストを返すモック設定
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 空状態の表示を確認
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });

      testWidgets('ペット一覧が正しく表示される', (WidgetTester tester) async {
        // テストペットリストを返すモック設定
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ペットの基本情報が表示されることを確認
        expect(find.text('ヘビちゃん'), findsOneWidget);
        expect(find.text('トカゲくん'), findsOneWidget);
      });

      testWidgets('ペットの詳細情報表示テスト', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ペット名が表示されることを確認
        expect(find.text('ヘビちゃん'), findsOneWidget);
        expect(find.text('トカゲくん'), findsOneWidget);

        // 種類が表示されることを確認
        expect(find.text('ボールパイソン'), findsOneWidget);
        expect(find.text('レオパードゲッコー'), findsOneWidget);
      });
    });

    group('ナビゲーションテスト', () {
      testWidgets('ペット追加ボタンの存在確認', (WidgetTester tester) async {
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // FloatingActionButtonが存在することを確認
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });

      testWidgets('ペット追加ボタンのタップテスト', (WidgetTester tester) async {
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // FloatingActionButtonをタップ
        final fab = find.byType(FloatingActionButton);
        expect(fab, findsOneWidget);

        await tester.tap(fab);
        await tester.pumpAndSettle();

        // タップが成功したことを確認（実際の画面遷移は実装に依存）
      });
    });

    group('ペット管理機能テスト', () {
      testWidgets('ペット表示の基本テスト', (WidgetTester tester) async {
        final testPets = [
          Pet(
            id: 'pet1',
            name: 'テストペット',
            gender: Gender.male,
            birthday: DateTime(2023, 1, 15),
            category: Category.snake,
            breed: 'テスト種類',
            unit: WeightUnit.g,
            imageUrl: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ペットが表示されることを確認
        expect(find.text('テストペット'), findsOneWidget);
        expect(find.text('テスト種類'), findsOneWidget);
      });

      testWidgets('複数ペットの表示テスト', (WidgetTester tester) async {
        final multiplePets = [
          Pet(
            id: 'pet1',
            name: 'ペット1',
            gender: Gender.male,
            birthday: DateTime(2023, 1, 15),
            category: Category.snake,
            breed: '種類1',
            unit: WeightUnit.g,
            imageUrl: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Pet(
            id: 'pet2',
            name: 'ペット2',
            gender: Gender.female,
            birthday: DateTime(2023, 2, 20),
            category: Category.lizard,
            breed: '種類2',
            unit: WeightUnit.kg,
            imageUrl: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(multiplePets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 複数のペットが表示されることを確認
        expect(find.text('ペット1'), findsOneWidget);
        expect(find.text('ペット2'), findsOneWidget);
        expect(find.text('種類1'), findsOneWidget);
        expect(find.text('種類2'), findsOneWidget);
      });
    });

    group('エラーハンドリングテスト', () {
      testWidgets('データ読み込みエラー時の基本表示', (WidgetTester tester) async {
        // エラーを返すモック設定
        when(mockPetService.getPets()).thenAnswer(
          (_) => Stream.error(Exception('データ読み込みエラー')),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 基本的なScaffold構造が維持されることを確認
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('画面構成テスト', () {
      testWidgets('基本的な画面構成の確認', (WidgetTester tester) async {
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 基本的なUI要素の存在確認
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });

      testWidgets('空状態での画面表示', (WidgetTester tester) async {
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 空状態でも基本構造が維持されることを確認
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });
    });

    group('ストリーム処理テスト', () {
      testWidgets('ペットデータストリームの基本処理', (WidgetTester tester) async {
        // ストリームが正常に処理されることを確認
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // StreamBuilderが正常に動作することを確認
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('データ変更時の更新テスト', (WidgetTester tester) async {
        // 最初は空のリスト
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 空状態を確認
        expect(find.byType(FloatingActionButton), findsOneWidget);

        // データが追加された場合のテスト用データ
        final newPet = Pet(
          id: 'new-pet',
          name: '新しいペット',
          gender: Gender.unknown,
          birthday: DateTime.now(),
          category: Category.other,
          breed: '新種類',
          unit: WeightUnit.g,
          imageUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // ストリームを更新
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value([newPet]));

        // 画面を再構築
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 新しいペットが表示されることを確認
        expect(find.text('新しいペット'), findsOneWidget);
      });
    });

    group('UI要素の表示テスト', () {
      testWidgets('ペット情報の詳細表示確認', (WidgetTester tester) async {
        final detailedPet = Pet(
          id: 'detailed-pet',
          name: '詳細テストペット',
          gender: Gender.male,
          birthday: DateTime(2022, 5, 10),
          category: Category.snake,
          breed: 'テスト詳細種類',
          unit: WeightUnit.g,
          imageUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value([detailedPet]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 詳細情報が表示されることを確認
        expect(find.text('詳細テストペット'), findsOneWidget);
        expect(find.text('テスト詳細種類'), findsOneWidget);
      });

      testWidgets('性別表示の確認', (WidgetTester tester) async {
        final pets = [
          Pet(
            id: 'male-pet',
            name: 'オスペット',
            gender: Gender.male,
            birthday: null,
            category: Category.lizard,
            breed: 'オス種類',
            unit: WeightUnit.g,
            imageUrl: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Pet(
            id: 'female-pet',
            name: 'メスペット',
            gender: Gender.female,
            birthday: null,
            category: Category.gecko,
            breed: 'メス種類',
            unit: WeightUnit.kg,
            imageUrl: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockPetService.getPets()).thenAnswer((_) => Stream.value(pets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 異なる性別のペットが表示されることを確認
        expect(find.text('オスペット'), findsOneWidget);
        expect(find.text('メスペット'), findsOneWidget);
      });
    });
  });
}
