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
  ImagePicker,
])
import 'pet_form_screen_test.mocks.dart';

// カスタムモッククラスでFutureOr<String>エラーを回避
class TestMockUser extends Mock implements User {
  @override
  String get uid {
    return 'test-user-id';
  }

  @override
  String? get email {
    return 'test@example.com';
  }

  @override
  bool get emailVerified {
    return true;
  }

  @override
  String? get displayName {
    return 'Test User';
  }

  @override
  String? get photoURL {
    return null;
  }

  @override
  bool get isAnonymous {
    return false;
  }

  @override
  String? get phoneNumber {
    return null;
  }

  @override
  String? get providerId {
    return 'password';
  }

  @override
  String? get refreshToken {
    return 'mock-refresh-token';
  }

  @override
  String? get tenantId {
    return null;
  }
}

void main() {
  group('PetFormScreen テスト', () {
    late MockPetService mockPetService;
    late MockAuthService mockAuthService;
    late TestMockUser mockUser;

    setUp(() {
      mockPetService = MockPetService();
      mockAuthService = MockAuthService();
      mockUser = TestMockUser();

      // 基本的なモック設定
      when(mockAuthService.currentUser).thenReturn(mockUser);

      // PetServiceのメソッドのデフォルト設定
      when(mockPetService.addPet(any, imageFile: anyNamed('imageFile')))
          .thenAnswer((_) async {});
      when(mockPetService.updatePet(any, imageFile: anyNamed('imageFile')))
          .thenAnswer((_) async {});
    });

    Widget createTestWidget({Pet? pet}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
          Provider<PetService>.value(value: mockPetService),
        ],
        child: MaterialApp(
          home: PetFormScreen(pet: pet),
        ),
      );
    }

    // ヘルパー関数：安全なスクロール
    Future<void> safeScrollToElement(
      WidgetTester tester,
      Finder finder, {
      double scrollDelta = 300.0,
      int maxAttempts = 5,
    }) async {
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        if (finder.evaluate().isNotEmpty) {
          return;
        }

        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, Offset(0, -scrollDelta));
          await tester.pumpAndSettle();
        }
      }

      if (finder.evaluate().isEmpty) {
        throw StateError(
            'Could not find widget after $maxAttempts scroll attempts');
      }
    }

    // ヘルパー関数：ユニークなボタンFinder
    Finder findUniqueSubmitButton({bool isEdit = false}) {
      return find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton &&
            (widget.child is Text) &&
            (widget.child as Text).data == (isEdit ? '更新する' : '登録する'),
      );
    }

    group('新規ペット登録画面', () {
      testWidgets('画面が正しく表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 画面タイトルの確認
        expect(find.text('新規ペット登録'), findsOneWidget);

        // 必要なフィールドが表示されているか確認
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.text('ペット名'), findsOneWidget);
        expect(find.text('種類'), findsOneWidget);
        expect(find.text('性別'), findsOneWidget);
        expect(find.text('誕生日を選択 (任意)'), findsOneWidget);
        expect(find.text('分類'), findsOneWidget);
        expect(find.text('体重単位'), findsOneWidget);

        // 性別選択ラジオボタンの確認
        expect(find.text('オス'), findsOneWidget);
        expect(find.text('メス'), findsOneWidget);
        expect(find.text('不明'), findsOneWidget);

        // 体重単位選択ラジオボタンの確認
        expect(find.text('g'), findsAtLeastNWidgets(1));
        expect(find.text('kg'), findsOneWidget);
        expect(find.text('lbs'), findsOneWidget);

        // 登録ボタンの確認
        expect(findUniqueSubmitButton(), findsOneWidget);
      });

      testWidgets('ペット名の必須入力検証', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final submitButtonFinder = findUniqueSubmitButton();
        await safeScrollToElement(tester, submitButtonFinder);

        await tester.tap(submitButtonFinder);
        await tester.pumpAndSettle();

        expect(find.text('ペット名を入力してください'), findsOneWidget);
      });

      testWidgets('種類の必須入力検証', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).first,
          'テストペット',
        );

        final submitButtonFinder = findUniqueSubmitButton();
        await safeScrollToElement(tester, submitButtonFinder);

        await tester.tap(submitButtonFinder);
        await tester.pumpAndSettle();

        expect(find.text('種類を入力してください'), findsOneWidget);
      });

      testWidgets('性別選択ができる', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final maleRadioFinder = find.byWidgetPredicate(
          (widget) => widget is Radio<Gender> && widget.value == Gender.male,
        );

        await tester.tap(maleRadioFinder);
        await tester.pumpAndSettle();

        final maleRadio = tester.widget<Radio<Gender>>(maleRadioFinder);
        expect(maleRadio.groupValue, Gender.male);
      });

      testWidgets('分類選択ができる', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButtonFormField<Category>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('ヘビ').last);
        await tester.pumpAndSettle();

        expect(find.text('ヘビ'), findsOneWidget);
      });

      testWidgets('体重単位選択ができる', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final kgRadioFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Radio<WeightUnit> && widget.value == WeightUnit.kg,
        );

        await safeScrollToElement(tester, kgRadioFinder);

        await tester.tap(kgRadioFinder);
        await tester.pumpAndSettle();

        final kgRadio = tester.widget<Radio<WeightUnit>>(kgRadioFinder);
        expect(kgRadio.groupValue, WeightUnit.kg);
      });

      testWidgets('画像選択エリアが表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('ペット画像'), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      });

      testWidgets('誕生日選択ができる', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('誕生日を選択 (任意)'));
        await tester.pumpAndSettle();

        expect(find.byType(DatePickerDialog), findsOneWidget);

        final okButton = find.text('OK');
        expect(okButton, findsOneWidget);
        await tester.tap(okButton);
        await tester.pumpAndSettle();
      });

      testWidgets('正常な入力でペットが登録される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).first,
          'テストペット',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'テスト種類',
        );

        final maleRadioFinder = find.byWidgetPredicate(
          (widget) => widget is Radio<Gender> && widget.value == Gender.male,
        );
        await tester.tap(maleRadioFinder);
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButtonFormField<Category>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ヘビ').last);
        await tester.pumpAndSettle();

        final submitButtonFinder = findUniqueSubmitButton();
        await safeScrollToElement(tester, submitButtonFinder);
        await tester.tap(submitButtonFinder);
        await tester.pumpAndSettle();

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

        expect(find.text('ペット情報の編集'), findsOneWidget);
        expect(find.text('既存ペット'), findsOneWidget);
        expect(find.text('既存種類'), findsOneWidget);

        final femaleRadioFinder = find.byWidgetPredicate(
          (widget) => widget is Radio<Gender> && widget.value == Gender.female,
        );
        expect(femaleRadioFinder, findsOneWidget);
        expect(
          tester.widget<Radio<Gender>>(femaleRadioFinder).groupValue,
          Gender.female,
        );

        expect(findUniqueSubmitButton(isEdit: true), findsOneWidget);
      });

      testWidgets('ペット情報が更新される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(pet: testPet));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).first,
          '更新されたペット',
        );

        final updateButtonFinder = findUniqueSubmitButton(isEdit: true);
        await safeScrollToElement(tester, updateButtonFinder);
        await tester.tap(updateButtonFinder);
        await tester.pumpAndSettle();

        verify(mockPetService.updatePet(any, imageFile: anyNamed('imageFile')))
            .called(1);
      });
    });

    group('エラーハンドリング', () {
      testWidgets('ネットワークエラー時の処理', (WidgetTester tester) async {
        when(mockPetService.addPet(any, imageFile: anyNamed('imageFile')))
            .thenThrow(Exception('ネットワークエラー'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).first,
          'テストペット',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'テスト種類',
        );

        final submitButtonFinder = findUniqueSubmitButton();
        await safeScrollToElement(tester, submitButtonFinder);
        await tester.tap(submitButtonFinder);
        await tester.pumpAndSettle();

        expect(find.text('エラー: Exception: ネットワークエラー'), findsOneWidget);
      });
    });
  });
}
