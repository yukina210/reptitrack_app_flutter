// test/helpers/test_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:reptitrack_app/models/pet.dart';

/// TimeoutException のカスタム実装
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() =>
      'TimeoutException: $message (timeout: ${timeout.inSeconds}s)';
}

/// テスト用のヘルパー関数群
class TestHelpers {
  /// 画面に表示されているテキストの一覧をデバッグ出力
  static void debugPrintAllTexts(WidgetTester tester) {
    if (kDebugMode) {
      final textWidgets = find.byType(Text);
      debugPrint('=== 画面に表示されているテキスト一覧 ===');
      for (int i = 0; i < textWidgets.evaluate().length; i++) {
        try {
          final text = tester.widget<Text>(textWidgets.at(i));
          debugPrint('Text $i: "${text.data}"');
        } catch (e) {
          debugPrint('Text $i: データ取得エラー - $e');
        }
      }
      debugPrint('=====================================');
    }
  }

  /// 特定のウィジェットが見つかるまで待機
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      await tester.pump(interval);

      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }

    throw TimeoutException(
      'Widget not found within ${timeout.inSeconds} seconds',
      timeout,
    );
  }

  /// 安全なスクロール処理
  static Future<void> scrollToWidget(
    WidgetTester tester,
    Finder finder, {
    double scrollDelta = 300.0,
    int maxAttempts = 10,
  }) async {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }

      // 手動で下にスクロール
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, Offset(0, -scrollDelta));
        await tester.pumpAndSettle();
      } else {
        // Scrollableが見つからない場合はSingleChildScrollViewを試す
        final singleChildScrollView = find.byType(SingleChildScrollView);
        if (singleChildScrollView.evaluate().isNotEmpty) {
          await tester.drag(
              singleChildScrollView.first, Offset(0, -scrollDelta));
          await tester.pumpAndSettle();
        }
      }
    }

    if (finder.evaluate().isEmpty) {
      throw StateError(
          'Could not find widget after $maxAttempts scroll attempts');
    }
  }

  /// 安全なタップ処理
  static Future<void> safeTap(
    WidgetTester tester,
    Finder finder, {
    bool warnIfMissed = true,
  }) async {
    if (finder.evaluate().isEmpty) {
      if (warnIfMissed) {
        debugPrint('Warning: Widget not found for tap: $finder');
      }
      return;
    }

    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// 安全なテキスト入力
  static Future<void> safeEnterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    if (finder.evaluate().isEmpty) {
      throw StateError('TextFormField not found: $finder');
    }

    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// ラジオボタンの選択
  static Future<void> selectRadioButton(
    WidgetTester tester,
    String labelText,
  ) async {
    await safeTap(tester, find.text(labelText));
  }

  /// ドロップダウンの選択
  static Future<void> selectDropdownItem(
    WidgetTester tester,
    String itemText,
  ) async {
    // ドロップダウンを開く
    await safeTap(tester, find.byType(DropdownButtonFormField));

    // アイテムを選択
    await safeTap(tester, find.text(itemText).last);
  }

  /// フォームの検証エラーをチェック
  static void expectValidationError(String errorMessage) {
    expect(find.text(errorMessage), findsOneWidget);
  }

  /// SnackBarメッセージの表示をチェック
  static void expectSnackBarMessage(String message) {
    expect(find.text(message), findsOneWidget);
  }

  /// ラジオボタンの選択状態をチェック
  static void expectRadioSelection<T>(
    WidgetTester tester,
    T expectedValue,
  ) {
    final radio = find.byWidgetPredicate(
      (widget) => widget is Radio<T> && widget.value == expectedValue,
    );

    expect(radio, findsOneWidget);
    expect(
      tester.widget<Radio<T>>(radio).groupValue,
      equals(expectedValue),
    );
  }

  /// ドロップダウンの選択状態をチェック（表示テキストベース）
  static void expectDropdownHasText(String expectedText) {
    expect(find.text(expectedText), findsOneWidget);
  }

  /// テキストフィールドの値をチェック
  static void expectTextFieldValue(
    WidgetTester tester,
    int fieldIndex,
    String expectedValue,
  ) {
    final textField = find.byType(TextFormField).at(fieldIndex);
    final textFormField = tester.widget<TextFormField>(textField);
    expect(textFormField.controller?.text, equals(expectedValue));
  }

  /// 複数のテキストフィールドに順次入力
  static Future<void> fillTextFields(
    WidgetTester tester,
    List<String> texts,
  ) async {
    final textFields = find.byType(TextFormField);

    for (int i = 0; i < texts.length && i < textFields.evaluate().length; i++) {
      await safeEnterText(tester, textFields.at(i), texts[i]);
    }
  }

  /// 日付選択ボタンをタップしてダイアログを開く
  static Future<void> openDatePicker(
    WidgetTester tester,
    String buttonText,
  ) async {
    await safeTap(tester, find.text(buttonText));

    // ダイアログが表示されるまで待機
    await waitForWidget(tester, find.byType(DatePickerDialog));
  }

  /// 日付選択ダイアログでOKをタップ
  static Future<void> confirmDateSelection(WidgetTester tester) async {
    await safeTap(tester, find.text('OK'));
  }

  /// 日付選択ダイアログでキャンセルをタップ
  static Future<void> cancelDateSelection(WidgetTester tester) async {
    await safeTap(tester, find.text('キャンセル'));
  }

  /// PetFormScreen専用：カテゴリー選択
  static Future<void> selectPetCategory(
    WidgetTester tester,
    String categoryText,
  ) async {
    await selectDropdownItem(tester, categoryText);
  }

  /// PetFormScreen専用：性別選択
  static Future<void> selectPetGender(
    WidgetTester tester,
    String genderText,
  ) async {
    await selectRadioButton(tester, genderText);
  }

  /// PetFormScreen専用：体重単位選択
  static Future<void> selectWeightUnit(
    WidgetTester tester,
    String unitText,
  ) async {
    await selectRadioButton(tester, unitText);
  }

  /// PetFormScreen専用：完全なペット情報入力
  static Future<void> fillPetForm(
    WidgetTester tester, {
    required String name,
    required String breed,
    String? gender,
    String? category,
    String? unit,
    bool selectBirthday = false,
  }) async {
    // ペット名と種類を入力
    await fillTextFields(tester, [name, breed]);

    // 性別選択
    if (gender != null) {
      await selectPetGender(tester, gender);
    }

    // 分類選択
    if (category != null) {
      await selectPetCategory(tester, category);
    }

    // 体重単位選択
    if (unit != null) {
      await selectWeightUnit(tester, unit);
    }

    // 誕生日選択（オプション）
    if (selectBirthday) {
      await openDatePicker(tester, '誕生日を選択 (任意)');
      await confirmDateSelection(tester);
    }
  }

  /// ユニークなボタンFinder
  static Finder findButtonByText(String buttonText) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is ElevatedButton &&
          widget.child is Text &&
          (widget.child as Text).data == buttonText,
    );
  }

  /// 性別ラジオボタンのFinder
  static Finder findGenderRadio(Gender gender) {
    return find.byWidgetPredicate(
      (widget) => widget is Radio<Gender> && widget.value == gender,
    );
  }

  /// 体重単位ラジオボタンのFinder
  static Finder findWeightUnitRadio(WeightUnit unit) {
    return find.byWidgetPredicate(
      (widget) => widget is Radio<WeightUnit> && widget.value == unit,
    );
  }

  /// エラー状態のクリア
  static Future<void> clearErrors(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }
}
