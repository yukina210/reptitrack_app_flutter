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

        // 画面タイトルの確認
        expect(find.text('新規ペット登録'), findsOneWidget);

        // 必要なフィールドが表示されているか確認
        expect(find.byType(TextFormField), findsNWidgets(2)); // ペット名と種類
        expect(find.text('ペット名'), findsOneWidget);
        expect(find.text('種類'), findsOneWidget);
        expect(find.text('性別'), findsOneWidget);
        expect(find.text('誕生日'), findsOneWidget);
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

        // ペット名を空にして登録ボタンを押す
        await tester.tap(find.text('登録する'));
        await tester.pump();

        // エラーメッセージが表示されることを確認
        expect(find.text('ペット名を入力してください'), findsOneWidget);
      });

      testWidgets('種類の必須入力検証', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // ペット名のみ入力して種類を空にして登録ボタンを押す
        await tester.enterText(find.byType(TextFormField).first, 'テストペット');
        await tester.tap(find.text('登録する'));
        await tester.pump();

        // エラーメッセージが表示されることを確認
        expect(find.text('種類を入力してください'), findsOneWidget);
      });

      testWidgets('性別選択ができる', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 初期状態は「不明」が選択されている
        final unknownRadio = find.byWidgetPredicate(
          (widget) => widget is Radio<Gender> && widget.value == Gender.unknown,
        );
        expect(tester.widget<Radio<Gender>>(unknownRadio).groupValue,
            Gender.unknown);

        // 「オス」を選択
        await tester.tap(find.text('オス'));
        await tester.pump();

        // 「オス」が選択されていることを確認
        final maleRadio = find.byWidgetPredicate(
          (widget) => widget is Radio<Gender> && widget.value == Gender.male,
        );
        expect(tester.widget<Radio<Gender>>(maleRadio).groupValue, Gender.male);
      });

      testWidgets('分類選択ができる', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 分類ドロップダウンをタップ
        await tester.tap(find.byType(DropdownButton<Category>));
        await tester.pumpAndSettle();

        // 「ヘビ」を選択
        await tester.tap(find.text('ヘビ').last);
        await tester.pumpAndSettle();

        // 「ヘビ」が選択されていることを確認
        expect(find.text('ヘビ'), findsOneWidget);
      });

      testWidgets('体重単位選択ができる', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 初期状態は「g」が選択されている
        final gRadio = find.byWidgetPredicate(
          (widget) =>
              widget is Radio<WeightUnit> && widget.value == WeightUnit.g,
        );
        expect(
            tester.widget<Radio<WeightUnit>>(gRadio).groupValue, WeightUnit.g);

        // 「kg」を選択
        await tester.tap(find.text('kg'));
        await tester.pump();

        // 「kg」が選択されていることを確認
        final kgRadio = find.byWidgetPredicate(
          (widget) =>
              widget is Radio<WeightUnit> && widget.value == WeightUnit.kg,
        );
        expect(tester.widget<Radio<WeightUnit>>(kgRadio).groupValue,
            WeightUnit.kg);
      });

      testWidgets('画像選択エリアが表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 画像選択エリアが表示されているか確認
        expect(find.byType(GestureDetector), findsAtLeastNWidgets(1));

        // 画像選択エリアをタップできるか確認
        final gestureDetector = find.byType(GestureDetector).first;
        await tester.tap(gestureDetector);
        await tester.pump();
        // 実際の画像選択はモック化が複雑なため、タップが可能であることのみ確認
      });

      testWidgets('誕生日選択ができる', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 誕生日フィールドをタップ
        await tester.tap(find.text('誕生日を選択'));
        await tester.pumpAndSettle();

        // 日付選択ダイアログが表示されることを確認
        expect(find.byType(DatePickerDialog), findsOneWidget);

        // キャンセルボタンをタップしてダイアログを閉じる
        await tester.tap(find.text('キャンセル'));
        await tester.pumpAndSettle();
      });

      testWidgets('正常な入力でペットが登録される', (WidgetTester tester) async {
        // PetServiceのモック設定
        when(mockPetService.addPet(any)).thenAnswer((_) async => 'test-pet-id');

        await tester.pumpWidget(createTestWidget());

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
        await tester.tap(find.text('オス'));
        await tester.pump();

        // 分類を選択
        await tester.tap(find.byType(DropdownButton<Category>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ヘビ').last);
        await tester.pumpAndSettle();

        // 体重単位を選択
        await tester.tap(find.text('kg'));
        await tester.pump();

        // 登録ボタンをタップ
        await tester.tap(find.text('登録する'));
        await tester.pump();

        // PetServiceのaddPetが呼ばれることを確認
        verify(mockPetService.addPet(any)).called(1);
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
        when(mockPetService.updatePet(any)).thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget(pet: testPet));

        // ペット名を変更
        await tester.enterText(
          find.byType(TextFormField).first,
          '更新されたペット',
        );

        // 更新ボタンをタップ
        await tester.tap(find.text('更新する'));
        await tester.pump();

        // PetServiceのupdatePetが呼ばれることを確認
        verify(mockPetService.updatePet(any)).called(1);
      });
    });

    group('エラーハンドリング', () {
      testWidgets('ネットワークエラー時の処理', (WidgetTester tester) async {
        // PetServiceでエラーが発生するようにモック設定
        when(mockPetService.addPet(any)).thenThrow(Exception('ネットワークエラー'));

        await tester.pumpWidget(createTestWidget());

        // フォームに入力
        await tester.enterText(
          find.byType(TextFormField).first,
          'テストペット',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'テスト種類',
        );

        // 登録ボタンをタップ
        await tester.tap(find.text('登録する'));
        await tester.pump();

        // エラー処理が適切に行われることを確認
        // （実際のアプリではSnackBarやダイアログでエラーメッセージを表示）
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });
  });
}
