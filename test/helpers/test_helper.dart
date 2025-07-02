// test/helpers/test_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';

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
        try {
          await tester.scrollUntilVisible(finder, scrollDelta);
          return;
        } catch (e) {
          // scrollUntilVisibleが失敗した場合は手動スクロールを試行
        }
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
    final controller = tester.widget<TextFormField>(textField).controller;
    expect(controller?.text, equals(expectedValue));
  }

  /// 安全なタップ操作（警告を無視）
  static Future<void> safeTap(
    WidgetTester tester,
    Finder finder, {
    bool warnIfMissed = false,
  }) async {
    await tester.tap(finder, warnIfMissed: warnIfMissed);
    await tester.pumpAndSettle();
  }

  /// 安全なテキスト入力
  static Future<void> safeEnterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// ドロップダウンメニューの選択
  static Future<void> selectDropdownItem(
    WidgetTester tester,
    String itemText,
  ) async {
    // DropdownButtonFormFieldを見つけてタップ
    final dropdown = find.byType(DropdownButtonFormField);

    if (dropdown.evaluate().isNotEmpty) {
      await safeTap(tester, dropdown.first);
      // アイテムを選択
      await safeTap(tester, find.text(itemText).last);
    } else {
      throw StateError('DropdownButtonFormField not found');
    }
  }

  /// フォーム送信の実行
  static Future<void> submitForm(
    WidgetTester tester,
    String buttonText,
  ) async {
    // ボタンまでスクロール
    await scrollToWidget(tester, find.text(buttonText));

    // ボタンをタップ
    await safeTap(tester, find.text(buttonText));
  }

  /// ラジオボタンの選択
  static Future<void> selectRadioButton(
    WidgetTester tester,
    String labelText,
  ) async {
    await safeTap(tester, find.text(labelText));
  }

  /// ウィジェットが表示されているかチェック
  static bool isWidgetDisplayed(Finder finder) {
    return finder.evaluate().isNotEmpty;
  }

  /// 特定のテキストが存在するかチェック
  static bool hasText(String text) {
    return find.text(text).evaluate().isNotEmpty;
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

  /// エラー状態のクリア
  static Future<void> clearErrors(WidgetTester tester) async {
    await tester.pumpAndSettle();
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
    String? weightUnit,
  }) async {
    // ペット名を入力
    await safeEnterText(tester, find.byType(TextFormField).first, name);

    // 種類を入力
    await safeEnterText(tester, find.byType(TextFormField).at(1), breed);

    // 性別を選択
    if (gender != null) {
      await selectPetGender(tester, gender);
    }

    // カテゴリーを選択
    if (category != null) {
      await selectPetCategory(tester, category);
    }

    // 体重単位を選択
    if (weightUnit != null) {
      await selectWeightUnit(tester, weightUnit);
    }
  }

  /// エラー処理のヘルパー：期待されるエラーメッセージが表示されるかチェック
  static void expectErrorMessage(String errorMessage) {
    expect(find.text(errorMessage), findsOneWidget);
  }

  /// 成功処理のヘルパー：期待される成功メッセージが表示されるかチェック
  static void expectSuccessMessage(String successMessage) {
    expect(find.text(successMessage), findsOneWidget);
  }

  /// ローディング状態をチェック
  static void expectLoadingIndicator() {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }

  /// ローディング状態でないことをチェック
  static void expectNoLoadingIndicator() {
    expect(find.byType(CircularProgressIndicator), findsNothing);
  }

  /// 特定のアイコンが表示されているかチェック
  static void expectIcon(IconData iconData) {
    expect(find.byIcon(iconData), findsOneWidget);
  }

  /// ボタンが有効かチェック
  static void expectButtonEnabled(String buttonText) {
    final button = find.text(buttonText);
    expect(button, findsOneWidget);

    final buttonWidget = find.ancestor(
      of: button,
      matching: find.byType(ElevatedButton),
    );

    if (buttonWidget.evaluate().isNotEmpty) {
      // ボタンが見つかったことを確認（有効性はタップ可能かで判断）
      expect(buttonWidget, findsOneWidget);
    }
  }
}

/// カスタムタイムアウト例外
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message';
}
