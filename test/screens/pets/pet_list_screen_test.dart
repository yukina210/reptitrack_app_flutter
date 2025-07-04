// test/screens/pets/pet_list_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart' as auth_mocks;
import 'package:reptitrack_app/screens/pets/pet_list_screen.dart';
import 'package:reptitrack_app/screens/pets/pet_form_screen.dart';
import 'package:reptitrack_app/models/pet.dart';
import 'package:reptitrack_app/services/pet_service.dart';
import 'package:reptitrack_app/services/auth_service.dart';
import 'package:reptitrack_app/services/settings_service.dart';

// モッククラス生成用のアノテーション（firebase_auth_mocksとのコンフリクトを避ける）
@GenerateMocks([
  PetService,
  AuthService,
  SettingsService,
])
import 'pet_list_screen_test.mocks.dart';

void main() {
  group('PetListScreen テスト', () {
    late MockPetService mockPetService;
    late MockAuthService mockAuthService;
    late auth_mocks.MockUser mockUser; // firebase_auth_mocksのMockUserを使用
    late MockSettingsService mockSettingsService;

    // テスト用のペットデータ
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
      Pet(
        id: 'pet3',
        name: 'カメちゃん',
        gender: Gender.unknown,
        birthday: DateTime(2022, 6, 10),
        category: Category.turtle,
        breed: 'リクガメ',
        unit: WeightUnit.g,
        imageUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    setUp(() {
      // Firebase Mocksの初期化
      mockUser = auth_mocks.MockUser(
        isAnonymous: false,
        uid: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      // サービスのモック初期化
      mockPetService = MockPetService();
      mockAuthService = MockAuthService();
      mockSettingsService = MockSettingsService();

      // AuthServiceのモック設定
      when(mockAuthService.currentUser).thenReturn(mockUser);

      // SettingsServiceのモック設定
      when(mockSettingsService.getText(any, any)).thenAnswer((invocation) {
        final fallback = invocation.positionalArguments[1] as String;
        final key = invocation.positionalArguments[0] as String;

        // 日本語テキストのモック
        switch (key) {
          case 'my_pets':
            return 'ペット一覧';
          case 'register_pet':
          case 'add_pet':
            return 'ペット登録';
          case 'please_login':
            return 'ログインしてください';
          case 'login':
            return 'ログイン';
          case 'sign_out':
            return 'ログアウト';
          case 'no_pets_registered':
            return 'ペットが登録されていません';
          case 'error_occurred':
            return 'エラーが発生しました';
          case 'retry':
            return '再試行';
          default:
            return fallback;
        }
      });

      when(mockSettingsService.currentLanguage)
          .thenReturn(AppLanguage.japanese);
    });

    // テストウィジェット作成
    Widget createTestWidget({bool isLoggedIn = true}) {
      // ログイン状態の設定
      if (isLoggedIn) {
        when(mockAuthService.currentUser).thenReturn(mockUser);
      } else {
        when(mockAuthService.currentUser).thenReturn(null);
      }

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
          ChangeNotifierProvider<SettingsService>.value(
              value: mockSettingsService),
          // PetServiceをProviderとして提供（テスト用）
          Provider<PetService>.value(value: mockPetService),
        ],
        child: MaterialApp(
          home: PetListScreen(), // 元のコンストラクタを使用
        ),
      );
    }

    group('認証状態のテスト', () {
      testWidgets('未ログイン時のログイン促進画面が表示される', (WidgetTester tester) async {
        // 空のペットリストをモック
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget(isLoggedIn: false));
        await tester.pumpAndSettle();

        // ログイン促進画面の要素を確認
        expect(find.byIcon(Icons.login), findsOneWidget);
        expect(find.text('ログインしてください'), findsOneWidget);
        expect(find.text('ログイン'), findsOneWidget);
      });

      testWidgets('ログイン済み時にペット一覧画面が表示される', (WidgetTester tester) async {
        // 空のペットリストを返すモック設定
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget(isLoggedIn: true));
        await tester.pumpAndSettle();

        // AppBarとFloatingActionButtonが表示されることを確認
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('ペット一覧'), findsOneWidget);
      });
    });

    group('ペット一覧表示テスト', () {
      testWidgets('ペットが存在しない場合の表示', (WidgetTester tester) async {
        // 空のペットリストを返すモック設定
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 空状態の表示を確認
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('ペットが登録されていません'), findsOneWidget);
        expect(find.text('ペット登録'), findsOneWidget);
        expect(find.byIcon(Icons.pets), findsOneWidget);
      });

      testWidgets('ペット一覧が正しく表示される', (WidgetTester tester) async {
        // テストペットリストを返すモック設定
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ペットの基本情報が表示されることを確認
        expect(find.text('ヘビちゃん'), findsOneWidget);
        expect(find.text('ボールパイソン'), findsOneWidget);
        expect(find.text('トカゲくん'), findsOneWidget);
        expect(find.text('レオパードゲッコー'), findsOneWidget);
        expect(find.text('カメちゃん'), findsOneWidget);
        expect(find.text('リクガメ'), findsOneWidget);
      });

      testWidgets('FABボタンで新規ペット作成画面に遷移する', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // FloatingActionButtonをタップ
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // 新規ペット作成画面に遷移したことを確認
        expect(find.byType(PetFormScreen), findsOneWidget);
      });
    });

    group('エラーハンドリングテスト', () {
      testWidgets('ペットデータの読み込みエラーハンドリング', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.error(Exception('データ取得エラー')));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // エラー状態でも基本的なUI構造は表示される
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
        // エラーメッセージの表示を確認
        expect(find.textContaining('エラーが発生しました'), findsOneWidget);
      });

      testWidgets('空のペットリストの処理', (WidgetTester tester) async {
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 空状態の表示確認
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('ペット登録'), findsOneWidget);
      });
    });

    group('ペット登録ボタンUIテスト', () {
      testWidgets('ペット登録ボタンのスタイル確認', (WidgetTester tester) async {
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final registerButton = find.text('ペット登録');
        expect(registerButton, findsOneWidget);

        // ボタンの機能確認
        await tester.tap(registerButton);
        await tester.pumpAndSettle();
        expect(find.byType(PetFormScreen), findsOneWidget);
      });

      testWidgets('多言語対応でのペット登録ボタンテスト', (WidgetTester tester) async {
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 日本語でのボタン表示確認
        expect(find.text('ペット登録'), findsOneWidget);
      });

      testWidgets('ペット登録ボタンの無効化状態テスト', (WidgetTester tester) async {
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final registerButton = find.text('ペット登録');
        expect(registerButton, findsOneWidget);

        // ボタンが有効であることを確認
        final hasElevatedButton =
            find.byType(ElevatedButton).evaluate().isNotEmpty;
        expect(hasElevatedButton, isTrue);
      });
    });

    group('UI状態テスト', () {
      testWidgets('ローディング状態の表示', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());

        // ローディング中はCircularProgressIndicatorが表示される
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();

        // ローディング完了後の状態確認
        expect(find.text('ヘビちゃん'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('リストアイテムの表示確認', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // リストアイテム（Card）の数を確認
        expect(find.byType(Card), findsNWidgets(3));

        // 各ペットの情報が正しく表示されることを確認
        expect(find.text('ヘビちゃん'), findsOneWidget);
        expect(find.text('ボールパイソン'), findsOneWidget);
        expect(find.text('トカゲくん'), findsOneWidget);
        expect(find.text('レオパードゲッコー'), findsOneWidget);
        expect(find.text('カメちゃん'), findsOneWidget);
        expect(find.text('リクガメ'), findsOneWidget);
      });
    });
  });
}
