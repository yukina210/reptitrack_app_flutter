#!/bin/bash

# scripts/setup_tests.sh - テスト環境セットアップスクリプト

set -e

# カラー出力設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# テストディレクトリ構造を作成
create_test_directories() {
    log_info "テストディレクトリ構造を作成中..."
    
    # 必要なディレクトリを作成
    mkdir -p test/screens/pets
    mkdir -p test/services
    mkdir -p test/models
    mkdir -p test/providers
    mkdir -p test/widgets
    mkdir -p test/helpers
    mkdir -p integration_test
    mkdir -p coverage
    mkdir -p test_reports
    
    log_success "テストディレクトリ構造を作成しました"
}

# Flutter テスト設定ファイルを作成
create_flutter_test_config() {
    log_info "Flutter テスト設定ファイルを作成中..."
    
    cat > test/flutter_test_config.dart << 'EOF'
// test/flutter_test_config.dart
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Firebase を初期化（テスト用）
  await Firebase.initializeApp();
  
  // テスト実行
  await testMain();
}
EOF
    
    log_success "Flutter テスト設定ファイルを作成しました"
}

# テストヘルパーファイルを作成
create_test_helpers() {
    log_info "テストヘルパーファイルを作成中..."
    
    cat > test/helpers/test_helper.dart << 'EOF'
// test/helpers/test_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:reptitrack_app/services/auth_service.dart';
import 'package:reptitrack_app/services/settings_service.dart';

class TestHelper {
  /// テスト用のWidget wrapper
  static Widget createTestApp({
    required Widget child,
    AuthService? authService,
    SettingsService? settingsService,
  }) {
    return MultiProvider(
      providers: [
        if (authService != null)
          ChangeNotifierProvider<AuthService>.value(value: authService),
        if (settingsService != null)
          ChangeNotifierProvider<SettingsService>.value(value: settingsService),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  /// テスト用のペットデータ
  static Map<String, dynamic> createMockPetData({
    String? name,
    String? category,
    String? gender,
  }) {
    return {
      'pet_id': 'test-pet-id',
      'name': name ?? 'テストペット',
      'gender': gender ?? 'male',
      'birthday': null,
      'category': category ?? 'snake',
      'breed': 'テスト種類',
      'unit': 'g',
      'image_url': null,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// フォーム入力ヘルパー
  static Future<void> enterTextInField(
    WidgetTester tester,
    String text,
    String labelText,
  ) async {
    final field = find.widgetWithText(TextFormField, labelText);
    await tester.enterText(field, text);
    await tester.pump();
  }

  /// ラジオボタン選択ヘルパー
  static Future<void> selectRadioOption(
    WidgetTester tester,
    String optionText,
  ) async {
    await tester.tap(find.text(optionText));
    await tester.pump();
  }

  /// ドロップダウン選択ヘルパー
  static Future<void> selectDropdownOption(
    WidgetTester tester,
    String optionText,
  ) async {
    await tester.tap(find.byType(DropdownButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(optionText).last);
    await tester.pumpAndSettle();
  }

  /// ダイアログの確認ボタンをタップ
  static Future<void> confirmDialog(WidgetTester tester) async {
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  /// ダイアログのキャンセルボタンをタップ
  static Future<void> cancelDialog(WidgetTester tester) async {
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
  }
}
EOF
    
    log_success "テストヘルパーファイルを作成しました"
}

# pubspec.yaml にテスト依存関係を追加
update_pubspec_for_tests() {
    log_info "pubspec.yaml にテスト依存関係を追加中..."
    
    # バックアップを作成
    cp pubspec.yaml pubspec.yaml.backup
    
    # テスト依存関係が既に存在するかチェック
    if grep -q "mockito:" pubspec.yaml; then
        log_warning "テスト依存関係は既に存在します"
        return
    fi
    
    # dev_dependencies セクションにテスト依存関係を追加
    cat >> pubspec.yaml << 'EOF'

  # テスト用依存関係
  mockito: ^5.4.2
  build_runner: ^2.4.6
  firebase_auth_mocks: ^0.13.0
  fake_cloud_firestore: ^2.4.1+1
  network_image_mock: ^2.1.1
EOF
    
    log_success "pubspec.yaml を更新しました"
}

# モック生成用の build.yaml を作成
create_build_yaml() {
    log_info "build.yaml を作成中..."
    
    cat > build.yaml << 'EOF'
targets:
  $default:
    builders:
      mockito|mockBuilder:
        options:
          # モック生成対象を指定
          mock_types:
            - "PetService"
            - "AuthService"
            - "SettingsService"
        generate_for:
          - test/**_test.dart
EOF
    
    log_success "build.yaml を作成しました"
}

# 統合テスト用の基本ファイルを作成
create_integration_test() {
    log_info "統合テスト用ファイルを作成中..."
    
    cat > integration_test/pet_registration_flow_test.dart << 'EOF'
// integration_test/pet_registration_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:reptitrack_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ペット登録フロー統合テスト', () {
    testWidgets('ペット登録から一覧表示までの完全フロー', (tester) async {
      // アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // ログイン処理（実際の認証実装に応じて調整）
      // TODO: 認証処理を実装

      // ペット追加ボタンをタップ
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // ペット情報を入力
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ペット名'),
        'テストペット',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '種類'),
        'ボールパイソン',
      );

      // 性別を選択
      await tester.tap(find.text('オス'));
      await tester.pump();

      // 分類を選択
      await tester.tap(find.byType(DropdownButton<Category>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ヘビ').last);
      await tester.pumpAndSettle();

      // 登録ボタンをタップ
      await tester.tap(find.text('登録する'));
      await tester.pumpAndSettle();

      // ペット一覧画面に戻ることを確認
      expect(find.text('テストペット'), findsOneWidget);
      expect(find.text('ボールパイソン'), findsOneWidget);

      // ペット編集テスト
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('編集'));
      await tester.pumpAndSettle();

      // ペット名を変更
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ペット名'),
        '更新されたペット',
      );

      // 更新ボタンをタップ
      await tester.tap(find.text('更新する'));
      await tester.pumpAndSettle();

      // 変更が反映されることを確認
      expect(find.text('更新されたペット'), findsOneWidget);

      // ペット削除テスト
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      // 削除確認ダイアログで削除を実行
      await tester.tap(find.text('削除').last);
      await tester.pumpAndSettle();

      // ペットが削除されたことを確認
      expect(find.text('更新されたペット'), findsNothing);
      expect(find.text('ペットが登録されていません'), findsOneWidget);
    });
  });
}
EOF
    
    log_success "統合テストファイルを作成しました"
}

# VS Code テスト設定を作成
create_vscode_test_config() {
    log_info "VS Code テスト設定を作成中..."
    
    mkdir -p .vscode
    
    cat > .vscode/launch.json << 'EOF'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Flutter Tests",
            "type": "dart",
            "request": "launch",
            "program": "test/",
            "flutterMode": "debug",
            "args": [
                "--coverage"
            ]
        },
        {
            "name": "Integration Tests",
            "type": "dart",
            "request": "launch",
            "program": "integration_test/",
            "flutterMode": "debug"
        }
    ]
}
EOF
    
    cat > .vscode/settings.json << 'EOF'
{
    "dart.flutterTestLogFile": "test_logs/flutter_test.log",
    "dart.testLogFile": "test_logs/dart_test.log",
    "dart.enableSdkFormatter": true,
    "dart.lineLength": 100,
    "files.associations": {
        "*.dart": "dart"
    }
}
EOF
    
    log_success "VS Code テスト設定を作成しました"
}

# テスト実行スクリプトを作成
create_test_runner() {
    log_info "テスト実行スクリプトを作成中..."
    
    cat > scripts/run_tests.sh << 'EOF'
#!/bin/bash

# scripts/run_tests.sh - 簡易テスト実行スクリプト

set -e

# カラー出力設定
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 依存関係の更新
log_info "依存関係を更新中..."
flutter pub get

# モッククラスの生成
log_info "モッククラスを生成中..."
dart run build_runner build --delete-conflicting-outputs

# 単体テストとウィジェットテストの実行
log_info "単体テスト・ウィジェットテストを実行中..."
flutter test --coverage

# カバレッジレポートの生成
if command -v genhtml &> /dev/null; then
    log_info "カバレッジレポートを生成中..."
    genhtml coverage/lcov.info -o coverage/html
    log_success "カバレッジレポート: coverage/html/index.html"
fi

log_success "テスト完了！"
EOF
    
    chmod +x scripts/run_tests.sh
    
    log_success "テスト実行スクリプトを作成しました"
}

# メイン処理
main() {
    log_info "ペット登録テスト環境のセットアップを開始..."
    
    # 必要なディレクトリが存在するかチェック
    if [[ ! -f "pubspec.yaml" ]]; then
        log_error "pubspec.yaml が見つかりません。Flutterプロジェクトのルートディレクトリで実行してください。"
        exit 1
    fi
    
    # テスト環境をセットアップ
    create_test_directories
    create_flutter_test_config
    create_test_helpers
    update_pubspec_for_tests
    create_build_yaml
    create_integration_test
    create_vscode_test_config
    create_test_runner
    
    log_info "依存関係を更新中..."
    flutter pub get
    
    echo ""
    log_success "テスト環境のセットアップが完了しました！"
    echo ""
    echo "次のステップ:"
    echo "1. テストファイルをプロジェクトに配置:"
    echo "   - pet_form_screen_test.dart を test/screens/pets/ に"
    echo "   - pet_list_screen_test.dart を test/screens/pets/ に"
    echo ""
    echo "2. モッククラスを生成:"
    echo "   dart run build_runner build --delete-conflicting-outputs"
    echo ""
    echo "3. テストを実行:"
    echo "   ./scripts/run_tests.sh"
    echo "   または"
    echo "   flutter test test/screens/pets/pet_form_screen_test.dart"
    echo ""
    echo "4. 統合テストを実行（実機/シミュレータ必要）:"
    echo "   flutter test integration_test/pet_registration_flow_test.dart"
    echo ""
}

# スクリプト実行
main "$@"