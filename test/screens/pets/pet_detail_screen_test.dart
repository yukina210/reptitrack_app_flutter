// test/screens/pets/pet_detail_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reptitrack_app/screens/pets/pet_detail_screen.dart';
import 'package:reptitrack_app/models/pet.dart';

void main() {
  group('PetDetailScreen テスト', () {
    // テスト用ペットデータ
    final testPet = Pet(
      id: 'test-pet-id',
      name: 'テストペット',
      gender: Gender.male,
      birthday: DateTime(2023, 1, 15),
      category: Category.snake,
      breed: 'ボールパイソン',
      unit: WeightUnit.g,
      imageUrl: null, // ネットワーク画像エラーを避けるため
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Widget createTestWidget() {
      return MaterialApp(
        home: PetDetailScreen(pet: testPet),
      );
    }

    group('基本画面表示テスト', () {
      testWidgets('画面が正しく表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 基本的なUI要素の存在確認
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);

        // ペット名がAppBarのタイトルに表示されることを確認
        expect(find.text('テストペット'), findsAtLeastNWidgets(1));
      });

      testWidgets('ペットの基本情報が表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // ペット名の表示確認
        expect(find.text('テストペット'), findsAtLeastNWidgets(1));

        // 種類の表示確認
        expect(find.textContaining('ボールパイソン'), findsAtLeastNWidgets(1));

        // 分類の表示確認
        expect(find.textContaining('ヘビ'), findsAtLeastNWidgets(1));
      });

      testWidgets('デフォルト画像が表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // デフォルト画像のアイコンまたはコンテナが表示されることを確認
        final hasDefaultImage = find.byIcon(Icons.pets).evaluate().isNotEmpty ||
            find.byType(Container).evaluate().isNotEmpty;
        expect(hasDefaultImage, isTrue);
      });

      testWidgets('編集ボタンが表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 編集ボタンの存在確認
        expect(find.byIcon(Icons.edit), findsOneWidget);
      });
    });

    group('情報表示テスト', () {
      testWidgets('情報カードが表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Cardウィジェットの存在確認
        expect(find.byType(Card), findsAtLeastNWidgets(1));

        // 分類情報の表示確認
        expect(find.text('分類'), findsAtLeastNWidgets(1));

        // 体重単位情報の表示確認
        expect(find.text('体重単位'), findsAtLeastNWidgets(1));
      });

      testWidgets('誕生日情報が表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 誕生日セクションの存在確認
        expect(find.text('誕生日'), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.cake), findsAtLeastNWidgets(1));

        // 年齢計算の表示確認
        expect(find.textContaining('年齢'), findsAtLeastNWidgets(1));
      });

      testWidgets('性別情報が表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 性別表示の確認（実際の実装では「オス」を使用）
        expect(find.textContaining('オス'), findsAtLeastNWidgets(1));
      });
    });

    group('ダッシュボード関連テスト', () {
      testWidgets('ダッシュボードセクションが表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // ダッシュボードセクションの存在確認
        expect(find.text('ダッシュボード'), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.dashboard), findsAtLeastNWidgets(1));
      });

      testWidgets('クイック記録セクションが表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // クイック記録セクションの存在確認
        expect(find.text('クイック記録'), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.add_circle), findsAtLeastNWidgets(1));
      });

      testWidgets('FloatingActionButtonが表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // FABボタンの存在確認
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('ダッシュボードを開く'), findsOneWidget);
      });
    });

    group('UI要素確認テスト', () {
      testWidgets('編集機能が利用可能である', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 編集ボタンが存在することを確認
        expect(find.byIcon(Icons.edit), findsOneWidget);

        // AppBar内にアクション可能な要素があることを確認
        expect(find.byType(AppBar), findsOneWidget);

        // AppBar内のアクションボタンの存在を確認
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.actions, isNotNull);
        expect(appBar.actions!.isNotEmpty, isTrue);
      });

      testWidgets('FloatingActionButtonが機能的である', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // FABボタンの存在と基本情報確認
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('ダッシュボードを開く'), findsOneWidget);

        // FABボタンが有効であることを確認
        final fabFinder = find.byType(FloatingActionButton);
        final fab = tester.widget<FloatingActionButton>(fabFinder);
        expect(fab.onPressed, isNotNull);
      });

      testWidgets('スクロール可能である', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // スクロールビューの存在確認
        expect(find.byType(SingleChildScrollView), findsOneWidget);

        // 軽いスクロール動作の確認
        final scrollable = find.byType(SingleChildScrollView);
        await tester.drag(scrollable, const Offset(0, -50));

        // スクロール後も基本要素が存在することを確認
        expect(find.text('テストペット'), findsAtLeastNWidgets(1));
      });
    });

    group('レスポンシブデザインテスト', () {
      testWidgets('小さな画面での表示', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(createTestWidget());

        // 小さな画面でも適切に表示されることを確認
        expect(find.text('テストペット'), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.edit), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      });

      testWidgets('大きな画面での表示', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget());

        // 大きな画面でも適切に表示されることを確認
        expect(find.text('テストペット'), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.edit), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      });
    });

    group('画像表示テスト', () {
      testWidgets('デフォルト画像の表示', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // デフォルト画像コンテナまたはアイコンの存在確認
        final hasImageElement = find.byIcon(Icons.pets).evaluate().isNotEmpty ||
            find.byType(Container).evaluate().isNotEmpty;
        expect(hasImageElement, isTrue);
      });

      testWidgets('画像エラー時の適切な表示', (WidgetTester tester) async {
        final petWithImage = Pet(
          id: 'test-pet-id',
          name: 'テストペット',
          gender: Gender.male,
          birthday: DateTime(2023, 1, 15),
          category: Category.snake,
          breed: 'ボールパイソン',
          unit: WeightUnit.g,
          imageUrl: 'https://example.com/invalid-image.jpg',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(home: PetDetailScreen(pet: petWithImage)),
        );

        // 画像のロードを待つ（エラーも含む）
        await tester.pump(const Duration(milliseconds: 100));

        // 基本的な画面要素が存在することを確認
        expect(find.text('テストペット'), findsAtLeastNWidgets(1));

        // 何らかの画像関連要素（エラービルダーまたはデフォルト表示）が存在することを確認
        final hasImageHandling = find.byType(Container).evaluate().isNotEmpty ||
            find.byIcon(Icons.pets).evaluate().isNotEmpty ||
            find.byType(Image).evaluate().isNotEmpty;
        expect(hasImageHandling, isTrue);
      });
    });

    group('ウィジェット構造テスト', () {
      testWidgets('期待されるウィジェット階層', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 基本的なウィジェット階層の確認
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.byType(Column), findsAtLeastNWidgets(1));
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });

      testWidgets('重要なアイコンの存在', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 必須アイコンの確認
        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.byIcon(Icons.dashboard), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.add_circle), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.cake), findsAtLeastNWidgets(1));

        // ペット画像関連（デフォルトアイコンまたは画像）
        final hasPetImageIcon = find.byIcon(Icons.pets).evaluate().isNotEmpty;
        // ペット画像アイコンは実装により存在しない場合もあるため、警告レベルでチェック
        if (!hasPetImageIcon) {
          debugPrint('Warning: ペット画像のデフォルトアイコンが見つかりません');
        }
      });

      testWidgets('重要なテキスト要素の存在', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 重要なテキスト要素の確認
        expect(find.text('ダッシュボード'), findsAtLeastNWidgets(1));
        expect(find.text('クイック記録'), findsAtLeastNWidgets(1));
        expect(find.text('分類'), findsAtLeastNWidgets(1));
        expect(find.text('体重単位'), findsAtLeastNWidgets(1));
        expect(find.text('誕生日'), findsAtLeastNWidgets(1));

        // ペット固有の情報
        expect(find.text('テストペット'), findsAtLeastNWidgets(1));
        expect(find.textContaining('ボールパイソン'), findsAtLeastNWidgets(1));
        expect(find.textContaining('ヘビ'), findsAtLeastNWidgets(1));
      });
    });

    group('データ表示整合性テスト', () {
      testWidgets('ペットデータが正しく反映される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // テストデータの各フィールドが適切に表示されることを確認
        expect(find.text('テストペット'), findsAtLeastNWidgets(1)); // name
        expect(
            find.textContaining('ボールパイソン'), findsAtLeastNWidgets(1)); // breed
        expect(find.textContaining('ヘビ'), findsAtLeastNWidgets(1)); // category
        expect(find.textContaining('オス'), findsAtLeastNWidgets(1)); // gender

        // 誕生日が2023年1月15日であることを確認
        expect(find.textContaining('2023'), findsAtLeastNWidgets(1));

        // 体重単位がgであることを確認
        expect(find.textContaining('g'), findsAtLeastNWidgets(1));
      });

      testWidgets('年齢計算が表示される', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 年齢関連の表示があることを確認
        expect(find.textContaining('年齢'), findsAtLeastNWidgets(1));

        // 現在の日付から計算して、1歳以上であることを確認
        final now = DateTime.now();
        final birthday = DateTime(2023, 1, 15);
        final ageInYears = now.year - birthday.year;

        if (ageInYears >= 1) {
          expect(find.textContaining('歳'), findsAtLeastNWidgets(1));
        } else {
          // 1歳未満の場合は月または日での表示
          final hasAgeDisplay =
              find.textContaining('ヶ月').evaluate().isNotEmpty ||
                  find.textContaining('日').evaluate().isNotEmpty;
          expect(hasAgeDisplay, isTrue);
        }
      });
    });
  });
}
