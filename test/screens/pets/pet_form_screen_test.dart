// test/screens/pets/pet_form_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reptitrack_app/screens/pets/pet_form_screen.dart';
import 'package:reptitrack_app/models/pet.dart';
import 'package:reptitrack_app/services/pet_service.dart';
import 'package:reptitrack_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// モッククラス生成用のアノテーション
@GenerateMocks([
  PetService,
  AuthService,
  User,
  ImagePicker,
])
import 'pet_form_screen_test.mocks.dart';

void main() {
  group('PetFormScreen テスト', () {
    late MockPetService mockPetService;
    late MockAuthService mockAuthService;
    late MockUser mockUser;

    setUp(() {
      mockPetService = MockPetService();
      mockAuthService = MockAuthService();
      mockUser = MockUser();

      // 基本的なモック設定
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-user-id');
    });

    Widget createTestWidget({Pet? pet}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
        ],
        child: MaterialApp(
          home: PetFormScreen(pet: pet),
        ),
      );
    }

    group('新規ペット登録画面', () {
      testWidgets('画面が正しく表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle(); // すべてのアニメーションが完了するまで待機

        // 画面タイトルの確認
        expect(find.text('新規ペット登録'), findsOneWidget);

        // 必要なフィールドが表示されているか確認
        expect(find.byType(TextFormField), findsNWidgets(2)); // ペット名と種類
        expect(find.text('ペット名'), findsOneWidget);
        expect(find.text('種類'), findsOneWidget);
        expect(find.text('性別'), findsOneWidget);

        // 誕生日ボタンのテキストを修正
        expect(find.text('誕生日を選択 (任意)'), findsOneWidget);

        expect(find.text('分類'), findsOneWidget);
        expect(find.text('体重単位'), findsOneWidget);

        // 性別選択ラジオボタンの確認
        expect(find.text('オス'), findsOneWidget);
        expect(find.text('メス'), findsOneWidget);
        expect(find.text('不明'), findsOneWidget);

        // 体重単位選択ラジオボタンの確認
        expect(find.text('g'), findsOneWidget);
        expect(find.text('kg'), findsOneWidget);
        expect(find.text('lbs'), findsOneWidget);

        // 登録ボタンの確認
        expect(find.text('登録する'), findsOneWidget);
      });

      testWidgets('ペット名の必須入力検証', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // スクロール可能な場合は登録ボタンまでスクロール
        await tester.scrollUntilVisible(
          find.text('登録する'),
          500.0, // スクロール距離
        );

        // ペット名を空にして登録ボタンを押す
        await tester.tap(find.text('登録する'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // エラーメッセージが表示されることを確認
        expect(find.text('ペット名を入力してください'), findsOneWidget);
      });

      testWidgets('種類の必須入力検証', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ペット名のみ入力
        await tester.enterText(find.byType(TextFormField).first, 'テストペット');

        // 登録ボタンまでスクロール
        await tester.scrollUntilVisible(
          find.text('登録する'),
          500.0,
        );

        // 登録ボタンを押す
        await tester.tap(find.text('登録する'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // エラーメッセージが表示されることを確認
        expect(find.text('種類を入力してください'), findsOneWidget);
      });

      testWidgets('性別選択ができる', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 初期状態は「不明」が選択されていることを確認
        final unknownRadio = find.byWidgetPredicate(
          (widget) => widget is Radio<Gender> && widget.value == Gender.unknown,
        );
        expect(tester.widget<Radio<Gender>>(unknownRadio).groupValue,
            Gender.unknown);

        // 「オス」を選択
        await tester.tap(find.text('オス'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // 選択が変更されたことを確認
        final maleRadio = find.byWidgetPredicate(
          (widget) => widget is Radio<Gender> && widget.value == Gender.male,
        );
        expect(tester.widget<Radio<Gender>>(maleRadio).groupValue, Gender.male);
      });

      testWidgets('分類選択ができる', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ドロップダウンをタップ
        await tester.tap(find.byType(DropdownButtonFormField<Category>));
        await tester.pumpAndSettle();

        // ヘビを選択
        await tester.tap(find.text('ヘビ').last);
        await tester.pumpAndSettle();

        // 選択が変更されたことを確認
        expect(find.text('ヘビ'), findsOneWidget);
      });

      testWidgets('体重単位選択ができる', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 初期状態は「g」が選択されていることを確認
        final gRadio = find.byWidgetPredicate(
          (widget) =>
              widget is Radio<WeightUnit> && widget.value == WeightUnit.g,
        );
        expect(
            tester.widget<Radio<WeightUnit>>(gRadio).groupValue, WeightUnit.g);

        // 体重単位セクションまでスクロール
        await tester.scrollUntilVisible(
          find.text('kg'),
          500.0,
        );

        // 「kg」を選択
        await tester.tap(find.text('kg'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // 選択が変更されたことを確認
        final kgRadio = find.byWidgetPredicate(
          (widget) =>
              widget is Radio<WeightUnit> && widget.value == WeightUnit.kg,
        );
        expect(tester.widget<Radio<WeightUnit>>(kgRadio).groupValue,
            WeightUnit.kg);
      });

      testWidgets('画像選択エリアが表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 画像選択用のGestureDetectorが存在することを確認
        expect(find.byType(GestureDetector), findsAtLeastNWidgets(1));

        // 写真追加テキストが表示されることを確認
        expect(find.text('写真を追加'), findsOneWidget);
      });

      testWidgets('誕生日選択ができる', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 誕生日選択ボタンをタップ
        await tester.tap(find.text('誕生日を選択 (任意)'));
        await tester.pumpAndSettle();

        // 日付選択ダイアログが表示されることを確認
        expect(find.byType(DatePickerDialog), findsOneWidget);

        // キャンセルボタンをタップしてダイアログを閉じる
        await tester.tap(find.text('キャンセル'));
        await tester.pumpAndSettle();
      });

      testWidgets('正常な入力でペットが登録される', (WidgetTester tester) async {
        // PetServiceのモック設定
        when(mockPetService.addPet(any, imageFile: anyNamed('imageFile')))
            .thenAnswer((_) async => 'test-pet-id');

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // フォームに入力
        await tester.enterText(
          find.byType(TextFormField).first,
          'テストペット',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'テスト種類',
        );

        // 性別を選択
        await tester.tap(find.text('オス'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // 分類を選択
        await tester.tap(find.byType(DropdownButtonFormField<Category>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ヘビ').last);
        await tester.pumpAndSettle();

        // 登録ボタンまでスクロール
        await tester.scrollUntilVisible(
          find.text('登録する'),
          500.0,
        );

        // 登録ボタンをタップ
        await tester.tap(find.text('登録する'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // PetServiceのaddPetが呼ばれることを確認
        verify(mockPetService.addPet(any, imageFile: anyNamed('imageFile')))
            .called(1);
      });
    });

    group('ペット編集画面', () {
      final testPet = Pet(
        id: 'test-pet-id',
        name: '既存ペット',
        gender: Gender.female,
        birthday: DateTime(2023, 1, 15),
        category: Category.lizard,
        breed: '既存種類',
        unit: WeightUnit.g,
        imageUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testWidgets('既存ペット情報が正しく表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(pet: testPet));
        await tester.pumpAndSettle();

        // 画面タイトルの確認
        expect(find.text('ペット情報の編集'), findsOneWidget);

        // 既存の値が入力されているか確認
        expect(find.text('既存ペット'), findsOneWidget);
        expect(find.text('既存種類'), findsOneWidget);

        // 性別が正しく選択されているか確認
        final femaleRadio = find.byWidgetPredicate(
          (widget) => widget is Radio<Gender> && widget.value == Gender.female,
        );
        expect(tester.widget<Radio<Gender>>(femaleRadio).groupValue,
            Gender.female);

        // 更新ボタンが表示されているか確認
        expect(find.text('更新する'), findsOneWidget);
      });

      testWidgets('ペット情報が更新される', (WidgetTester tester) async {
        // PetServiceのモック設定
        when(mockPetService.updatePet(any, imageFile: anyNamed('imageFile')))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget(pet: testPet));
        await tester.pumpAndSettle();

        // ペット名を変更
        await tester.enterText(
          find.byType(TextFormField).first,
          '更新されたペット',
        );

        // 更新ボタンまでスクロール
        await tester.scrollUntilVisible(
          find.text('更新する'),
          500.0,
        );

        // 更新ボタンをタップ
        await tester.tap(find.text('更新する'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // PetServiceのupdatePetが呼ばれることを確認
        verify(mockPetService.updatePet(any, imageFile: anyNamed('imageFile')))
            .called(1);
      });
    });

    group('エラーハンドリング', () {
      testWidgets('ネットワークエラー時の処理', (WidgetTester tester) async {
        // PetServiceでエラーが発生するようにモック設定
        when(mockPetService.addPet(any, imageFile: anyNamed('imageFile')))
            .thenThrow(Exception('ネットワークエラー'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // フォームに入力
        await tester.enterText(
          find.byType(TextFormField).first,
          'テストペット',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'テスト種類',
        );

        // 登録ボタンまでスクロール
        await tester.scrollUntilVisible(
          find.text('登録する'),
          500.0,
        );

        // 登録ボタンをタップ
        await tester.tap(find.text('登録する'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // エラーメッセージが含まれたSnackBarが表示されることを確認
        expect(find.text('エラー: Exception: ネットワークエラー'), findsOneWidget);
      });
    });
  });
}
