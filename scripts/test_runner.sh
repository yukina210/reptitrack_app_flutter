#!/bin/bash

# scripts/test_runner.sh - 改善版テスト実行スクリプト

set -e  # エラー時に終了

# カラー出力設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
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

# 使用方法を表示
show_usage() {
    echo "使用方法: ./scripts/test_runner.sh [オプション]"
    echo ""
    echo "オプション:"
    echo "  --all          すべてのテストを実行"
    echo "  --unit         単体テストのみ実行"
    echo "  --widget       ウィジェットテストのみ実行"
    echo "  --integration  統合テストのみ実行"
    echo "  --coverage     カバレッジレポートを生成"
    echo "  --clean        テスト前にクリーンアップ"
    echo "  --help         このヘルプを表示"
    echo ""
    echo "例:"
    echo "  ./scripts/test_runner.sh --unit --coverage"
    echo "  ./scripts/test_runner.sh --all --clean"
}

# 依存関係チェック
check_dependencies() {
    log_info "依存関係をチェック中..."
    
    # Flutter SDKの確認
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter SDKが見つかりません。インストールしてください。"
        exit 1
    fi
    
    # Dart SDKの確認
    if ! command -v dart &> /dev/null; then
        log_error "Dart SDKが見つかりません。"
        exit 1
    fi
    
    # lcovの確認（カバレッジ用）
    if [[ "$COVERAGE" == "true" ]] && ! command -v lcov &> /dev/null; then
        log_warning "lcovが見つかりません。カバレッジレポートHTMLは生成されません。"
        log_info "インストール方法: brew install lcov (macOS) または apt-get install lcov (Ubuntu)"
    fi
    
    log_success "依存関係チェック完了"
}

# プロジェクトクリーンアップ
clean_project() {
    log_info "プロジェクトをクリーンアップ中..."
    
    flutter clean
    flutter pub get
    
    # テスト用ディレクトリを作成
    mkdir -p coverage
    mkdir -p test_reports
    
    log_success "クリーンアップ完了"
}

# モッククラス生成
generate_mocks() {
    log_info "モッククラスを生成中..."
    
    if [[ -f "pubspec.yaml" ]] && grep -q "build_runner" pubspec.yaml; then
        dart run build_runner build --delete-conflicting-outputs
        log_success "モッククラス生成完了"
    else
        log_warning "build_runnerが設定されていません。モック生成をスキップします。"
    fi
}

# Firebase初期化のチェック
check_firebase_setup() {
    log_info "Firebase設定をチェック中..."
    
    # テスト設定ファイルの存在確認
    if [[ ! -f "test/flutter_test_config.dart" ]]; then
        log_error "test/flutter_test_config.dart が見つかりません。"
        log_info "Firebase モック設定が必要です。"
        exit 1
    fi
    
    log_success "Firebase設定確認完了"
}

# 単体テスト実行
run_unit_tests() {
    log_info "単体テストを実行中..."
    
    local test_args=""
    if [[ "$COVERAGE" == "true" ]]; then
        test_args="--coverage"
    fi
    
    # テストディレクトリが存在するかチェック
    if [[ ! -d "test" ]]; then
        log_warning "testディレクトリが見つかりません。単体テストをスキップします。"
        return 0
    fi
    
    # 特定のテストファイルから実行（依存関係順）
    local test_files=(
        "test/services/auth_service_test.dart"
        "test/models/pet_model_test.dart"
        "test/models/care_record_model_test.dart"
        "test/models/weight_record_model_test.dart"
        "test/providers/auth_provider_test.dart"
        "test/providers/pet_provider_test.dart"
    )
    
    local failed_tests=()
    local passed_tests=()
    
    for test_file in "${test_files[@]}"; do
        if [[ -f "$test_file" ]]; then
            log_info "実行中: $test_file"
            if flutter test "$test_file" $test_args; then
                passed_tests+=("$test_file")
                log_success "✓ $test_file"
            else
                failed_tests+=("$test_file")
                log_error "✗ $test_file"
            fi
        else
            log_warning "テストファイルが見つかりません: $test_file"
        fi
    done
    
    # 残りのテストファイルを実行
    log_info "その他の単体テストを実行中..."
    if ! flutter test test/ --exclude-tags=integration $test_args; then
        log_error "一部の単体テストが失敗しました"
        return 1
    fi
    
    # 結果サマリー
    echo ""
    log_info "=== 単体テスト結果サマリー ==="
    log_success "成功したテスト: ${#passed_tests[@]}"
    log_error "失敗したテスト: ${#failed_tests[@]}"
    
    if [[ ${#failed_tests[@]} -gt 0 ]]; then
        echo "失敗したテストファイル:"
        for failed_test in "${failed_tests[@]}"; do
            echo "  - $failed_test"
        done
        return 1
    fi
    
    log_success "すべての単体テストが成功しました"
}

# ウィジェットテスト実行
run_widget_tests() {
    log_info "ウィジェットテストを実行中..."
    
    local test_args=""
    if [[ "$COVERAGE" == "true" ]]; then
        test_args="--coverage"
    fi
    
    # ウィジェットテストファイルを検索
    local widget_tests=$(find test -name "*_test.dart" -path "*/screens/*" -o -path "*/widgets/*")
    
    if [[ -z "$widget_tests" ]]; then
        log_warning "ウィジェットテストが見つかりません。"
        return 0
    fi
    
    local failed_tests=()
    local passed_tests=()
    
    while IFS= read -r test_file; do
        if [[ -f "$test_file" ]]; then
            log_info "実行中: $test_file"
            if flutter test "$test_file" $test_args; then
                passed_tests+=("$test_file")
                log_success "✓ $test_file"
            else
                failed_tests+=("$test_file")
                log_error "✗ $test_file"
            fi
        fi
    done <<< "$widget_tests"
    
    # 結果サマリー
    echo ""
    log_info "=== ウィジェットテスト結果サマリー ==="
    log_success "成功したテスト: ${#passed_tests[@]}"
    log_error "失敗したテスト: ${#failed_tests[@]}"
    
    if [[ ${#failed_tests[@]} -gt 0 ]]; then
        return 1
    fi
    
    log_success "すべてのウィジェットテストが成功しました"
}

# 統合テスト実行
run_integration_tests() {
    log_info "統合テストを実行中..."
    
    if [[ ! -d "integration_test" ]]; then
        log_warning "integration_testディレクトリが見つかりません。統合テストをスキップします。"
        return 0
    fi
    
    # 統合テストの実行（実機またはシミュレータが必要）
    log_warning "統合テストには実機またはシミュレータが必要です。"
    log_info "手動で以下のコマンドを実行してください:"
    echo "  flutter test integration_test/auth_complete_flow_test.dart"
    echo "  flutter test integration_test/social_auth_manual_test.dart"
    
    # 自動化可能な統合テストがあれば実行
    local auto_integration_tests=$(find integration_test -name "*_test.dart" ! -name "*manual*")
    
    if [[ -n "$auto_integration_tests" ]]; then
        log_info "自動化された統合テストを実行中..."
        while IFS= read -r test_file; do
            log_info "実行中: $test_file"
            if flutter test "$test_file"; then
                log_success "✓ $test_file"
            else
                log_error "✗ $test_file"
                return 1
            fi
        done <<< "$auto_integration_tests"
    fi
    
    log_success "統合テスト確認完了"
}

# カバレッジレポート生成
generate_coverage_report() {
    if [[ "$COVERAGE" != "true" ]]; then
        return 0
    fi
    
    log_info "カバレッジレポートを生成中..."
    
    if [[ ! -f "coverage/lcov.info" ]]; then
        log_warning "カバレッジデータが見つかりません。"
        return 0
    fi
    
    # 不要なファイルを除外
    lcov --remove coverage/lcov.info \
        '*/generated/*' \
        '*/l10n/*' \
        '*/test/*' \
        '*/mocks/*' \
        '*/.dart_tool/*' \
        -o coverage/lcov_filtered.info 2>/dev/null || true
    
    # HTMLレポート生成
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov_filtered.info -o coverage/html_report 2>/dev/null || true
        log_success "HTMLカバレッジレポートを生成しました: coverage/html_report/index.html"
    fi
    
    # カバレッジサマリー表示
    if command -v lcov &> /dev/null; then
        echo ""
        log_info "=== カバレッジサマリー ==="
        lcov --summary coverage/lcov_filtered.info 2>/dev/null || lcov --summary coverage/lcov.info 2>/dev/null || true
    fi
}

# メイン処理
main() {
    log_info "認証テスト実行スクリプトを開始..."
    
    # デフォルト設定
    RUN_ALL=false
    RUN_UNIT=false
    RUN_WIDGET=false
    RUN_INTEGRATION=false
    COVERAGE=false
    CLEAN=false
    
    # 引数解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                RUN_ALL=true
                shift
                ;;
            --unit)
                RUN_UNIT=true
                shift
                ;;
            --widget)
                RUN_WIDGET=true
                shift
                ;;
            --integration)
                RUN_INTEGRATION=true
                shift
                ;;
            --coverage)
                COVERAGE=true
                shift
                ;;
            --clean)
                CLEAN=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "不明なオプション: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # デフォルトで全てのテストを実行
    if [[ "$RUN_ALL" == "false" && "$RUN_UNIT" == "false" && "$RUN_WIDGET" == "false" && "$RUN_INTEGRATION" == "false" ]]; then
        RUN_ALL=true
    fi
    
    # 全てのテストを実行する場合
    if [[ "$RUN_ALL" == "true" ]]; then
        RUN_UNIT=true
        RUN_WIDGET=true
        RUN_INTEGRATION=true
    fi
    
    # 依存関係チェック
    check_dependencies
    
    # クリーンアップ
    if [[ "$CLEAN" == "true" ]]; then
        clean_project
    fi
    
    # Firebase設定チェック
    check_firebase_setup
    
    # モッククラス生成
    generate_mocks
    
    log_success "プロジェクト準備完了"
    
    # テスト実行
    local test_failed=false
    
    if [[ "$RUN_UNIT" == "true" ]]; then
        if ! run_unit_tests; then
            test_failed=true
        fi
    fi
    
    if [[ "$RUN_WIDGET" == "true" ]]; then
        if ! run_widget_tests; then
            test_failed=true
        fi
    fi
    
    if [[ "$RUN_INTEGRATION" == "true" ]]; then
        if ! run_integration_tests; then
            test_failed=true
        fi
    fi
    
    # カバレッジレポート生成
    generate_coverage_report
    
    # 最終結果
    echo ""
    echo "========================================"
    if [[ "$test_failed" == "true" ]]; then
        log_error "一部のテストが失敗しました"
        echo "========================================"
        exit 1
    else
        log_success "すべてのテストが成功しました！"
        echo "========================================"
        exit 0
    fi
}

# スクリプト実行
main "$@"