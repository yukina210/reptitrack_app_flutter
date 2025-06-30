#!/bin/bash

# scripts/test_runner_fixed.sh - 修正版テスト実行スクリプト

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

# 使用方法を表示
show_usage() {
    echo "使用方法: ./scripts/test_runner_fixed.sh [オプション]"
    echo ""
    echo "オプション:"
    echo "  --unit         単体テストのみ実行"
    echo "  --coverage     カバレッジレポートを生成"
    echo "  --help         このヘルプを表示"
}

# 依存関係チェック
check_dependencies() {
    log_info "依存関係をチェック中..."
    
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter SDKが見つかりません。"
        exit 1
    fi
    
    if [[ "$COVERAGE" == "true" ]] && ! command -v lcov &> /dev/null; then
        log_warning "lcovが見つかりません。カバレッジレポートHTMLは生成されません。"
        log_info "インストール方法: brew install lcov (macOS)"
    fi
    
    log_success "依存関係チェック完了"
}

# モッククラス生成
generate_mocks() {
    log_info "モッククラスを生成中..."
    
    if [[ -f "pubspec.yaml" ]] && grep -q "build_runner" pubspec.yaml; then
        dart run build_runner build --delete-conflicting-outputs
        log_success "モッククラス生成完了"
    fi
}

# 単体テスト実行
run_unit_tests() {
    log_info "単体テストを実行中..."
    
    local test_args=""
    if [[ "$COVERAGE" == "true" ]]; then
        test_args="--coverage"
    fi
    
    local failed_tests=()
    local passed_tests=()
    
    # 実行するテストファイルのリスト（存在するもののみ）
    local test_files=(
        "test/services/auth_service_test.dart"
        "test/screens/auth_screen_test.dart"
        "test/widget_test.dart"
    )
    
    # 各テストファイルを個別に実行
    for test_file in "${test_files[@]}"; do
        if [[ -f "$test_file" ]]; then
            log_info "実行中: $test_file"
            if flutter test "$test_file" $test_args --reporter=compact; then
                passed_tests+=("$test_file")
                log_success "✓ $test_file"
            else
                failed_tests+=("$test_file")
                log_error "✗ $test_file"
            fi
            echo "----------------------------------------"
        else
            log_warning "スキップ: $test_file (ファイルが存在しません)"
        fi
    done
    
    # 存在しない推奨テストファイルの警告
    local missing_files=(
        "test/models/pet_model_test.dart"
        "test/models/care_record_model_test.dart"
        "test/models/weight_record_model_test.dart"
        "test/providers/auth_provider_test.dart"
        "test/providers/pet_provider_test.dart"
    )
    
    for missing_file in "${missing_files[@]}"; do
        if [[ ! -f "$missing_file" ]]; then
            log_warning "推奨テストファイルが見つかりません: $missing_file"
        fi
    done
    
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
    
    # HTMLレポート生成
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html_report 2>/dev/null || true
        log_success "HTMLカバレッジレポートを生成しました: coverage/html_report/index.html"
    fi
    
    # カバレッジサマリー表示
    if command -v lcov &> /dev/null; then
        echo ""
        log_info "=== カバレッジサマリー ==="
        lcov --summary coverage/lcov.info 2>/dev/null || true
    fi
}

# メイン処理
main() {
    log_info "ReptiTrack テスト実行スクリプトを開始..."
    
    # デフォルト設定
    RUN_UNIT=false
    COVERAGE=false
    
    # 引数解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            --unit)
                RUN_UNIT=true
                shift
                ;;
            --coverage)
                COVERAGE=true
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
    
    # デフォルトで単体テストを実行
    if [[ "$RUN_UNIT" == "false" ]]; then
        RUN_UNIT=true
    fi
    
    # 依存関係チェック
    check_dependencies
    
    # プロジェクト準備
    flutter pub get
    
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