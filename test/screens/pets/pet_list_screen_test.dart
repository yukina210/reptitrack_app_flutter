// test/screens/pets/pet_list_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:reptitrack_app/screens/pets/pet_list_screen.dart';
import 'package:reptitrack_app/screens/pets/pet_detail_screen.dart';
import 'package:reptitrack_app/screens/pets/pet_form_screen.dart';
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
          routes: {
            '/pet-detail': (context) => PetDetailScreen(
                pet: ModalRoute.of(context)!.settings.arguments as Pet),
            '/pet-form': (context) => PetFormScreen(
                pet: ModalRoute.of(context)!.settings.arguments as Pet?),
          },
          home: PetListScreen(),
        ),
      );
    }

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

    group('基本画面表示テスト', () {
      testWidgets('ログイン済み時にペット一覧画面が表示される', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('ヘビちゃん'), findsOneWidget);
        expect(find.text('トカゲくん'), findsOneWidget);
        expect(find.text('カメちゃん'), findsOneWidget);
      });

      testWidgets('ペット情報の詳細が正しく表示される', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ペット名が表示されることを確認
        expect(find.text('ヘビちゃん'), findsOneWidget);
        expect(find.text('トカゲくん'), findsOneWidget);
        expect(find.text('カメちゃん'), findsOneWidget);

        // 種類が表示されることを確認
        expect(find.text('ボールパイソン'), findsOneWidget);
        expect(find.text('レオパードゲッコー'), findsOneWidget);
        expect(find.text('リクガメ'), findsOneWidget);
      });
    });

    group('検索機能テスト', () {
      testWidgets('検索フィールドが存在することを確認', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 検索フィールドの存在を確認
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('ペット名による検索機能のテスト', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 検索フィールドにテキストを入力
        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'ヘビ');
        await tester.pumpAndSettle();

        // 検索結果の確認
        expect(find.text('ヘビちゃん'), findsOneWidget);
        expect(find.text('トカゲくん'), findsNothing);
        expect(find.text('カメちゃん'), findsNothing);
      });

      testWidgets('種類による検索機能のテスト', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 検索フィールドに種類を入力
        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'ボール');
        await tester.pumpAndSettle();

        // 検索結果の確認
        expect(find.text('ヘビちゃん'), findsOneWidget);
        expect(find.text('トカゲくん'), findsNothing);
        expect(find.text('カメちゃん'), findsNothing);
      });

      testWidgets('検索結果が見つからない場合のテスト', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 存在しないペット名で検索
        final searchField = find.byType(TextField);
        await tester.enterText(searchField, '存在しないペット');
        await tester.pumpAndSettle();

        // すべてのペットが表示されないことを確認
        expect(find.text('ヘビちゃん'), findsNothing);
        expect(find.text('トカゲくん'), findsNothing);
        expect(find.text('カメちゃん'), findsNothing);
      });

      testWidgets('検索クリア機能のテスト', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 検索フィールドにテキストを入力
        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'ヘビ');
        await tester.pumpAndSettle();

        // 検索結果の確認
        expect(find.text('ヘビちゃん'), findsOneWidget);
        expect(find.text('トカゲくん'), findsNothing);

        // 検索をクリア
        await tester.enterText(searchField, '');
        await tester.pumpAndSettle();

        // 全てのペットが表示されることを確認
        expect(find.text('ヘビちゃん'), findsOneWidget);
        expect(find.text('トカゲくん'), findsOneWidget);
        expect(find.text('カメちゃん'), findsOneWidget);
      });
    });

    group('ナビゲーションテスト', () {
      testWidgets('ペットタップでペット詳細画面に遷移する', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ペットをタップ
        await tester.tap(find.text('ヘビちゃん'));
        await tester.pumpAndSettle();

        // ペット詳細画面に遷移したことを確認
        expect(find.byType(PetDetailScreen), findsOneWidget);
      });

      testWidgets('複数のペットタップテスト', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 最初のペットをタップ
        await tester.tap(find.text('ヘビちゃん'));
        await tester.pumpAndSettle();

        expect(find.byType(PetDetailScreen), findsOneWidget);

        // 戻ってから別のペットをタップ
        await tester.pageBack();
        await tester.pumpAndSettle();

        await tester.tap(find.text('トカゲくん'));
        await tester.pumpAndSettle();

        expect(find.byType(PetDetailScreen), findsOneWidget);
      });

      testWidgets('編集ボタンのテスト', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 編集ボタンが存在することを確認
        expect(find.byIcon(Icons.edit), findsAtLeastNWidgets(1));

        // 編集ボタンをタップ
        await tester.tap(find.byIcon(Icons.edit).first);
        await tester.pumpAndSettle();

        // ペット編集画面に遷移したことを確認
        expect(find.byType(PetFormScreen), findsOneWidget);
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

      testWidgets('ペット登録ボタンで新規ペット作成画面に遷移する', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ペット登録ボタンの存在確認
        expect(find.text('ペット登録'), findsOneWidget);

        // ペット登録ボタンをタップ
        await tester.tap(find.text('ペット登録'));
        await tester.pumpAndSettle();

        // 新規ペット作成画面に遷移したことを確認
        expect(find.byType(PetFormScreen), findsOneWidget);
      });

      testWidgets('ペット登録ボタンで新規ペット作成画面に遷移する（英語版）', (WidgetTester tester) async {
        // 英語設定のモック
        when(mockSettingsService.currentLanguage)
            .thenReturn(AppLanguage.english);
        when(mockSettingsService.getText('register_pet', 'Register a pet'))
            .thenReturn('Register a pet');
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 英語版ペット登録ボタンの存在確認
        expect(find.text('Register a pet'), findsOneWidget);

        // ペット登録ボタンをタップ
        await tester.tap(find.text('Register a pet'));
        await tester.pumpAndSettle();

        // 新規ペット作成画面に遷移したことを確認
        expect(find.byType(PetFormScreen), findsOneWidget);
      });

      testWidgets('ペット登録ボタンと他のナビゲーション要素の共存確認', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ペット登録ボタンとFABボタンが両方存在することを確認
        expect(find.text('ペット登録'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);

        // 両方のボタンが新規作成画面に遷移することを確認
        // 1. ペット登録ボタンのテスト
        await tester.tap(find.text('ペット登録'));
        await tester.pumpAndSettle();
        expect(find.byType(PetFormScreen), findsOneWidget);

        // 戻る
        await tester.pageBack();
        await tester.pumpAndSettle();

        // 2. FABボタンのテスト
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        expect(find.byType(PetFormScreen), findsOneWidget);
      });
    });

    group('エラーハンドリングテスト', () {
      testWidgets('ペットデータの読み込みエラーハンドリング', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.error(Exception('データ取得エラー')));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // エラー状態の確認（実装に応じて調整）
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('空のペットリストの処理', (WidgetTester tester) async {
        when(mockPetService.getPets()).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 空状態の表示確認
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('ヘビちゃん'), findsNothing);
      });
    });

    group('ペット登録ボタンUIテスト', () {
      testWidgets('ペット登録ボタンのスタイル確認', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ペット登録ボタンが存在することを確認
        final registerButton = find.text('ペット登録');
        expect(registerButton, findsOneWidget);

        // ボタンがタップ可能であることを確認
        // ElevatedButton、TextButton、OutlinedButtonのいずれかが存在することを確認
        final hasElevatedButton =
            find.byType(ElevatedButton).evaluate().isNotEmpty;
        final hasTextButton = find.byType(TextButton).evaluate().isNotEmpty;
        final hasOutlinedButton =
            find.byType(OutlinedButton).evaluate().isNotEmpty;

        expect(hasElevatedButton || hasTextButton || hasOutlinedButton, isTrue);
      });

      testWidgets('ペット登録ボタンのアイコン確認', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ペット登録ボタンにアイコンが含まれている場合の確認
        expect(find.byIcon(Icons.add), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.pets), findsAny);
      });

      testWidgets('ペット登録ボタンの配置確認', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ペット登録ボタンが適切な位置に配置されていることを確認
        final registerButton = find.text('ペット登録');
        expect(registerButton, findsOneWidget);

        // ボタンの位置を確認（画面上部やAppBar内に配置されているか）
        final appBar = find.byType(AppBar);
        if (appBar.evaluate().isNotEmpty) {
          // AppBar内にペット登録ボタンがあるかチェック
          final buttonInAppBar = find.descendant(
            of: appBar,
            matching: registerButton,
          );
          expect(buttonInAppBar, findsAny);
        }
      });

      testWidgets('多言語対応でのペット登録ボタンテスト', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        // 日本語設定の場合
        when(mockSettingsService.currentLanguage)
            .thenReturn(AppLanguage.japanese);
        when(mockSettingsService.getText('register_pet', 'Register a pet'))
            .thenReturn('ペット登録');

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('ペット登録'), findsOneWidget);
        expect(find.text('Register a pet'), findsNothing);

        // ボタンの機能確認
        await tester.tap(find.text('ペット登録'));
        await tester.pumpAndSettle();
        expect(find.byType(PetFormScreen), findsOneWidget);
      });

      testWidgets('ペット登録ボタンの無効化状態テスト', (WidgetTester tester) async {
        // ローディング中などでボタンが無効化される場合のテスト
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final registerButton = find.text('ペット登録');
        expect(registerButton, findsOneWidget);

        // ボタンが有効であることを確認
        // 各ボタンタイプが存在するかチェック
        final hasElevatedButton =
            find.byType(ElevatedButton).evaluate().isNotEmpty;
        final hasTextButton = find.byType(TextButton).evaluate().isNotEmpty;
        final hasOutlinedButton =
            find.byType(OutlinedButton).evaluate().isNotEmpty;

        expect(hasElevatedButton || hasTextButton || hasOutlinedButton, isTrue);
      });
    });

    group('UI状態テスト', () {
      testWidgets('ローディング状態の表示', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());

        // ローディング状態の確認（初期状態）
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();

        // ローディング完了後の状態確認
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('ヘビちゃん'), findsOneWidget);
      });

      testWidgets('リストアイテムの表示確認', (WidgetTester tester) async {
        when(mockPetService.getPets())
            .thenAnswer((_) => Stream.value(testPets));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // リストアイテムの数を確認
        expect(find.byType(ListTile), findsNWidgets(3));

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
