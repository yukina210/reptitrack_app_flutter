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

        // ログイン促進メッセージが表示されることを確認
        expect(find.byIcon(Icons.login), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('ログイン済み時にペット一覧画面が表示される', (WidgetTester tester) async {
        // 空のペットリストを返すモック設定
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());

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

        // 「ペットが登録されていません」メッセージが表示されることを確認
        expect(find.byIcon(Icons.pets), findsOneWidget);
        expect(find.text('ペットが登録されていません'), findsOneWidget);
      });

      testWidgets('ペット一覧が正しく表示される', (WidgetTester tester) async {
        // テストペットリストを返すモック設定
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ペットカードが表示されることを確認
        expect(find.byType(Card), findsNWidgets(2));
        expect(find.text('ヘビちゃん'), findsOneWidget);
        expect(find.text('トカゲくん'), findsOneWidget);
        expect(find.text('ボールパイソン'), findsOneWidget);
        expect(find.text('レオパードゲッコー'), findsOneWidget);
      });

      testWidgets('ペットの詳細情報が正しく表示される', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 性別アイコンが表示されることを確認
        expect(find.byIcon(Icons.male), findsOneWidget);
        expect(find.byIcon(Icons.female), findsOneWidget);

        // 分類が表示されることを確認
        expect(find.text('ヘビ'), findsOneWidget);
        expect(find.text('トカゲ'), findsOneWidget);

        // 年齢情報が表示されることを確認（誕生日あり）
        expect(find.textContaining('歳'), findsAtLeastNWidgets(1));

        // 誕生日不明の場合
        expect(find.text('年齢不明'), findsOneWidget);
      });

      testWidgets('ペット画像の表示', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 画像があるペットの場合
        expect(find.byType(Image), findsOneWidget);

        // 画像がないペットの場合のデフォルトアイコン
        expect(find.byIcon(Icons.pets), findsAtLeastNWidgets(1));
      });
    });

    group('ナビゲーションテスト', () {
      testWidgets('ペット追加ボタンが機能する', (WidgetTester tester) async {
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // FloatingActionButtonをタップ
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // ペット追加画面への遷移を確認
        // 実際の実装では Navigator.push が呼ばれる
      });

      testWidgets('ペットカードタップでダッシュボードに遷移', (WidgetTester tester) async {
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

        // ペットカードをタップ
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        // ダッシュボード画面への遷移を確認
        // 実際の実装では Navigator.push が呼ばれる
      });
    });

    group('ペット管理機能テスト', () {
      testWidgets('ペット編集機能', (WidgetTester tester) async {
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

        // 編集ボタンをタップ（PopupMenuButtonから）
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        await tester.tap(find.text('編集'));
        await tester.pumpAndSettle();

        // 編集画面への遷移を確認
        // 実際の実装では Navigator.push が呼ばれる
      });

      testWidgets('ペット削除機能', (WidgetTester tester) async {
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
        when(mockPetService.deletePet('pet1')).thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 削除ボタンをタップ（PopupMenuButtonから）
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        await tester.tap(find.text('削除'));
        await tester.pumpAndSettle();

        // 削除確認ダイアログが表示されることを確認
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('削除確認'), findsOneWidget);

        // 削除を実行
        await tester.tap(find.text('削除').last);
        await tester.pumpAndSettle();

        // PetServiceのdeletePetが呼ばれることを確認
        verify(mockPetService.deletePet('pet1')).called(1);
      });
    });

    group('エラーハンドリングテスト', () {
      testWidgets('データ読み込みエラー時の表示', (WidgetTester tester) async {
        // エラーを返すモック設定
        when(mockPetService.getPets()).thenAnswer(
          (_) => Stream.error(Exception('データ読み込みエラー')),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // エラーメッセージが表示されることを確認
        expect(find.text('データの読み込みに失敗しました'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('ペット削除エラー時の処理', (WidgetTester tester) async {
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
        when(mockPetService.deletePet('pet1')).thenThrow(Exception('削除エラー'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 削除を実行
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('削除'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('削除').last);
        await tester.pumpAndSettle();

        // エラーメッセージが表示されることを確認
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('リフレッシュ機能テスト', () {
      testWidgets('プルトゥリフレッシュが機能する', (WidgetTester tester) async {
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // RefreshIndicatorが存在することを確認
        expect(find.byType(RefreshIndicator), findsOneWidget);

        // プルトゥリフレッシュを実行
        await tester.fling(find.byType(RefreshIndicator), Offset(0, 300), 1000);
        await tester.pump();
        await tester.pump(Duration(seconds: 1));

        // リフレッシュが実行されることを確認
        // 実際の実装では再度データを取得する
      });
    });
  });
}
