// test/screens/pets/pet_list_screen_test.dart
import 'dart:async';
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
  SettingsService,
  User,
])
import 'pet_list_screen_test.mocks.dart';

void main() {
  // Provider の型チェックを無効化（テスト環境でのみ）
  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
  });

  group('PetListScreen テスト', () {
    late MockPetService mockPetService;
    late MockAuthService mockAuthService;
    late MockUser mockUser;
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
      // サービスのモック初期化
      mockPetService = MockPetService();
      mockAuthService = MockAuthService();
      mockUser = MockUser();
      mockSettingsService = MockSettingsService();

      // MockUserの設定
      when(mockUser.uid).thenReturn('test-user-id');
      when(mockUser.email).thenReturn('test@example.com');

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

      // PetServiceの基本的なモック設定
      when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));
      when(mockPetService.getAllPets()).thenAnswer((_) => Stream.value([]));
      when(mockPetService.getOwnPets()).thenAnswer((_) => Stream.value([]));
      when(mockPetService.getSharedPets()).thenAnswer((_) => Stream.value([]));
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
          // PetServiceもChangeNotifierProviderとして提供
          ChangeNotifierProvider<PetService>.value(value: mockPetService),
        ],
        child: MaterialApp(
          home: PetListScreen(),
        ),
      );
    }

    group('認証状態のテスト', () {
      testWidgets('未ログイン時のログイン促進画面が表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isLoggedIn: false));
        await tester.pumpAndSettle();

        // ログイン促進画面が表示されることを確認（複数の「ログインしてください」があることを許容）
        expect(find.text('ログインしてください'), findsAtLeastNWidgets(1));
        expect(find.text('ログイン'), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.login), findsOneWidget);
      });

      testWidgets('ログイン済み時にペット一覧画面が表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isLoggedIn: true));
        await tester.pumpAndSettle();

        // ペット一覧画面が表示されることを確認
        expect(find.text('ペット一覧'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
    });

    group('ペット一覧表示テスト', () {
      testWidgets('ペットが存在しない場合の表示', (WidgetTester tester) async {
        // 空のペットリストをモック
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 空の状態が表示されることを確認
        expect(find.text('ペットが登録されていません'), findsOneWidget);
        expect(find.byIcon(Icons.pets), findsOneWidget);
        expect(find.text('ペット登録'), findsOneWidget);
      });

      testWidgets('ペット一覧が正しく表示される', (WidgetTester tester) async {
        // ペットリストのモック設定
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ペット名が表示されることを確認
        expect(find.textContaining('ヘビちゃん'), findsOneWidget);
        expect(find.textContaining('トカゲくん'), findsOneWidget);
        expect(find.textContaining('カメちゃん'), findsOneWidget);

        // ペットの数だけカードが表示されることを確認
        expect(find.byType(Card), findsNWidgets(testPets.length));
      });

      testWidgets('FABボタンが存在する', (WidgetTester tester) async {
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // FABボタンが存在することを確認
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
    });

    group('エラーハンドリングテスト', () {
      testWidgets('ペットデータの読み込みエラーハンドリング', (WidgetTester tester) async {
        // エラーストリームをモック
        when(mockPetService.getPets()).thenAnswer(
          (_) => Stream.error(Exception('データ読み込みエラー')),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // エラーメッセージが表示されることを確認（部分的なマッチ）
        expect(find.textContaining('エラーが発生しました'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('再試行'), findsOneWidget);
      });

      testWidgets('空のペットリストの処理', (WidgetTester tester) async {
        // 空のペットリストをモック
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 空状態のメッセージが表示されることを確認
        expect(find.text('ペットが登録されていません'), findsOneWidget);
        expect(find.byIcon(Icons.pets), findsOneWidget);
      });
    });

    group('ペット登録ボタンUIテスト', () {
      testWidgets('ペット登録ボタンのスタイル確認', (WidgetTester tester) async {
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // FABボタンの存在確認
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        // FABボタンの色確認
        final fab = tester.widget<FloatingActionButton>(fabFinder);
        expect(fab.backgroundColor, Colors.green);
      });

      testWidgets('多言語対応でのペット登録ボタンテスト', (WidgetTester tester) async {
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 日本語表示のテスト（空状態でのボタン）
        expect(find.text('ペット登録'), findsOneWidget);
      });

      testWidgets('ペット登録ボタンの無効化状態テスト', (WidgetTester tester) async {
        // 通常状態
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // FABボタンが有効であることを確認
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        final fab = tester.widget<FloatingActionButton>(fabFinder);
        expect(fab.onPressed, isNotNull);
      });
    });

    group('UI状態テスト', () {
      testWidgets('ローディング状態の表示', (WidgetTester tester) async {
        // 遅延するストリームをモック
        final controller = StreamController<List<Pet>>();
        when(mockPetService.getPets()).thenAnswer((_) => controller.stream);

        await tester.pumpWidget(createTestWidget());
        await tester.pump(); // 初回レンダリング

        // ローディングインジケーターが表示されることを確認
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // データを送信してローディング終了
        controller.add(testPets);
        await tester.pumpAndSettle();

        // ローディングが終了してペット一覧が表示されることを確認
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.textContaining('ヘビちゃん'), findsOneWidget);

        controller.close();
      });

      testWidgets('リストアイテムの表示確認', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // デバッグ：実際に表示されているテキストを確認
        final texts = tester
            .widgetList(find.byType(Text))
            .cast<Text>()
            .map((text) => text.data)
            .where((data) => data != null)
            .toList();
        debugPrint('Found texts: $texts');

        // 各ペットの詳細情報が表示されることを確認（部分マッチで確認）
        expect(find.textContaining('ボールパイソン'), findsWidgets);
        expect(find.textContaining('レオパードゲッコー'), findsWidgets);
        expect(find.textContaining('リクガメ'), findsWidgets);

        // カードが適切に表示されることを確認
        expect(find.byType(Card), findsNWidgets(testPets.length));
      });
    });
  });
}
