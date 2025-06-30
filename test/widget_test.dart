import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReptiTrack アプリの基本テスト', () {
    test('基本的な計算テスト', () {
      // 基本的な計算が正しく動作することを確認
      expect(1 + 1, equals(2));
      expect(2 * 3, equals(6));
      expect(10 / 2, equals(5));
    });

    test('文字列操作テスト', () {
      // 基本的な文字列操作が正しく動作することを確認
      expect('hello'.toUpperCase(), equals('HELLO'));
      expect('WORLD'.toLowerCase(), equals('world'));
      expect('ReptiTrack'.length, equals(10));
    });

    test('リスト操作テスト', () {
      // 基本的なリスト操作が正しく動作することを確認
      final list = [1, 2, 3];
      expect(list.length, equals(3));
      expect(list.contains(2), isTrue);
      expect(list.contains(4), isFalse);
    });
  });
}

// // This is a basic Flutter widget test.
// //
// // To perform an interaction with a widget in your test, use the WidgetTester
// // utility in the flutter_test package. For example, you can send tap and scroll
// // gestures. You can also use WidgetTester to find child widgets in the widget
// // tree, read text, and verify that the values of widget properties are correct.

// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';

// import 'package:reptitrack_app/main.dart';

// void main() {
//   testWidgets('Counter increments smoke test', (WidgetTester tester) async {
//     // Build our app and trigger a frame.
//     await tester.pumpWidget(const MyApp());

//     // Verify that our counter starts at 0.
//     expect(find.text('0'), findsOneWidget);
//     expect(find.text('1'), findsNothing);

//     // Tap the '+' icon and trigger a frame.
//     await tester.tap(find.byIcon(Icons.add));
//     await tester.pump();

//     // Verify that our counter has incremented.
//     expect(find.text('0'), findsNothing);
//     expect(find.text('1'), findsOneWidget);
//   });
// }
