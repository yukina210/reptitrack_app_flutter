// test/helpers/test_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:reptitrack_app/services/auth_service.dart';
import 'package:reptitrack_app/services/settings_service.dart';
import 'package:reptitrack_app/services/pet_service.dart';
import 'package:reptitrack_app/models/pet.dart';

class TestHelper {
  static bool _firebaseInitialized = false;

  /// Firebase のテスト初期化
  static Future<void> initializeFirebaseForTesting() async {
    if (_firebaseInitialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'fake-api-key',
        appId: 'fake-app-id',
        messagingSenderId: 'fake-sender-id',
        projectId: 'fake-project-id',
        storageBucket: 'fake-storage-bucket',
      ),
    );

    _firebaseInitialized = true;
  }

  /// テスト用の Widget ラッパー
  static Widget createTestApp({
    required Widget child,
    AuthService? authService,
    SettingsService? settingsService,
    PetService? petService,
  }) {
    return MultiProvider(
      providers: [
        if (authService != null)
          ChangeNotifierProvider<AuthService>.value(value: authService),
        if (settingsService != null)
          ChangeNotifierProvider<SettingsService>.value(value: settingsService),
        if (petService != null) Provider<PetService>.value(value: petService),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  /// テスト用の認証サービス（ログイン済み）
  static AuthService createMockAuthService({bool isLoggedIn = true}) {
    if (isLoggedIn) {
      return AuthService(); // 実際のサービスを使用
    } else {
      return AuthService(); // ログアウト状態のサービス
    }
  }

  /// テスト用のペットデータ
  static Pet createMockPet({
    String? id,
    String? name,
    Gender? gender,
    Category? category,
    String? breed,
    WeightUnit? unit,
  }) {
    return Pet(
      id: id ?? 'test-pet-id',
      name: name ?? 'テストペット',
      gender: gender ?? Gender.male,
      birthday: DateTime(2023, 1, 15),
      category: category ?? Category.snake,
      breed: breed ?? 'ボールパイソン',
      unit: unit ?? WeightUnit.g,
      imageUrl: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// テスト用のペットリスト
  static List<Pet> createMockPetList() {
    return [
      createMockPet(
        id: 'pet1',
        name: 'ヘビちゃん',
        gender: Gender.male,
        category: Category.snake,
        breed: 'ボールパイソン',
      ),
      createMockPet(
        id: 'pet2',
        name: 'トカゲくん',
        gender: Gender.female,
        category: Category.lizard,
        breed: 'レオパードゲッコー',
      ),
      createMockPet(
        id: 'pet3',
        name: 'カメちゃん',
        gender: Gender.unknown,
        category: Category.turtle,
        breed: 'リクガメ',
      ),
    ];
  }

  /// テスト用の設定サービス（日本語対応）
  static SettingsService createMockSettingsService() {
    return SettingsService(); // 実際のサービスを使用
  }

  /// Firebase エミュレーター接続（オプション）
  static Future<void> connectToEmulator() async {
    // Firebase Auth エミュレーター（ローカル開発時）
    // await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

    // Cloud Firestore エミュレーター（ローカル開発時）
    // FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }

  /// テスト後のクリーンアップ
  static void tearDown() {
    // 必要に応じてクリーンアップ処理を追加
  }

  /// Widget が存在することを確認するヘルパー
  static void expectWidgetExists(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Widget が複数存在することを確認するヘルパー
  static void expectWidgetsExist(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }

  /// Widget が存在しないことを確認するヘルパー
  static void expectWidgetNotExists(Finder finder) {
    expect(finder, findsNothing);
  }

  /// テキストの存在確認
  static void expectTextExists(String text) {
    expect(find.text(text), findsOneWidget);
  }

  /// アイコンの存在確認
  static void expectIconExists(IconData icon) {
    expect(find.byIcon(icon), findsOneWidget);
  }

  /// ボタンタップのシミュレーション
  static Future<void> tapButton(WidgetTester tester, Finder button) async {
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  /// テキスト入力のシミュレーション
  static Future<void> enterText(
    WidgetTester tester,
    Finder textField,
    String text,
  ) async {
    await tester.enterText(textField, text);
    await tester.pump();
  }

  /// デバッグ用：Widget ツリーの構造を出力
  static void debugWidgetTree(WidgetTester tester) {
    debugPrint(tester.allWidgets.map((w) => w.runtimeType).join('\n'));
  }

  /// デバッグ用：見つかったテキストを出力
  static void debugFoundTexts(WidgetTester tester) {
    final texts = tester
        .widgetList(find.byType(Text))
        .cast<Text>()
        .map((text) => text.data)
        .where((data) => data != null)
        .toList();
    debugPrint('Found texts: ${texts.join(', ')}');
  }
}
