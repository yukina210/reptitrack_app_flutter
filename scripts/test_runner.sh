#!/bin/bash

# test_runner.sh - 認証テスト実行スクリプト

set -e

# 色付きログ用の定数
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

# ヘルプメッセージ
show_help() {
    echo "認証テスト実行スクリプト"
    echo
    echo "使用方法:"
    echo "  $0 [オプション]"
    echo
    echo "オプション:"
    echo "  --unit          単体テストのみ実行"
    echo "  --widget        ウィジェットテストのみ実行"  
    echo "  --integration   統合テストのみ実行"
    echo "  --all           すべてのテストを実行（デフォルト）"
    echo "  --coverage      カバレッジレポートを生成"
    echo "  --device        統合テスト用のデバイスID指定"
    echo "  --help          このヘルプメッセージを表示"
    echo
    echo "例:"
    echo "  $0 --unit --coverage"
    echo "  $0 --integration --device emulator-5554"
    echo "  $0 --all"
}

# デフォルト値
RUN_UNIT=false
RUN_WIDGET=false
RUN_INTEGRATION=false
RUN_ALL=true
GENERATE_COVERAGE=false
DEVICE_ID=""

# コマンドライン引数の解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --unit)
            RUN_UNIT=true
            RUN_ALL=false
            shift
            ;;
        --widget)
            RUN_WIDGET=true
            RUN_ALL=false
            shift
            ;;
        --integration)
            RUN_INTEGRATION=true
            RUN_ALL=false
            shift
            ;;
        --all)
            RUN_ALL=true
            shift
            ;;
        --coverage)
            GENERATE_COVERAGE=true
            shift
            ;;
        --device)
            DEVICE_ID="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log_error "不明なオプション: $1"
            show_help
            exit 1
            ;;
    esac
done

# 必要な依存関係をチェック
check_dependencies() {
    log_info "依存関係をチェック中..."
    
    if ! command -v flutter &> /dev/null; then
        log_error "Flutterがインストールされていません"
        exit 1
    fi
    
    if ! flutter doctor --android-licenses &> /dev/null; then
        log_warning "Android licensesが未承認の可能性があります"
    fi
    
    log_success "依存関係チェック完了"
}

# プロジェクトのクリーンとビルド
clean_and_build() {
    log_info "プロジェクトをクリーンアップ中..."
    flutter clean
    flutter pub get
    
    log_info "モッククラスを生成中..."
    flutter packages pub run build_runner build --delete-conflicting-outputs
    
    log_success "プロジェクト準備完了"
}

# 単体テスト実行
run_unit_tests() {
    log_info "単体テストを実行中..."
    
    if [ "$GENERATE_COVERAGE" = true ]; then
        flutter test test/services/auth_service_test.dart --coverage
        log_success "単体テスト完了（カバレッジ付き）"
    else
        flutter test test/services/auth_service_test.dart
        log_success "単体テスト完了"
    fi
}

# ウィジェットテスト実行
run_widget_tests() {
    log_info "ウィジェットテストを実行中..."
    
    if [ "$GENERATE_COVERAGE" = true ]; then
        flutter test test/screens/auth_screen_test.dart --coverage
        log_success "ウィジェットテスト完了（カバレッジ付き）"
    else
        flutter test test/screens/auth_screen_test.dart
        log_success "ウィジェットテスト完了"
    fi
}

# 統合テスト実行
run_integration_tests() {
    log_info "統合テストを実行中..."
    
    # デバイスの確認
    if [ -n "$DEVICE_ID" ]; then
        log_info "指定されたデバイスでテスト実行: $DEVICE_ID"
        flutter test integration_test/auth_complete_flow_test.dart -d "$DEVICE_ID"
    else
        # 利用可能なデバイスを確認
        DEVICES=$(flutter devices --machine | jq -r '.[] | select(.category == "mobile") | .id' | head -1)
        
        if [ -z "$DEVICES" ]; then
            log_error "利用可能なデバイスが見つかりません"
            log_info "以下のコマンドでデバイスを確認してください:"
            log_info "  flutter devices"
            exit 1
        fi
        
        log_info "デバイスで統合テストを実行: $DEVICES"
        flutter test integration_test/auth_complete_flow_test.dart -d "$DEVICES"
    fi
    
    log_success "統合テスト完了"
}

# カバレッジレポート生成
generate_coverage_report() {
    if [ "$GENERATE_COVERAGE" = true ]; then
        log_info "カバレッジレポートを生成中..."
        
        # lcovがインストールされているかチェック
        if command -v genhtml &> /dev/null; then
            genhtml coverage/lcov.info -o coverage/html
            log_success "カバレッジレポートが生成されました: coverage/html/index.html"
        else
            log_warning "genhtml が見つかりません。HTMLレポートはスキップされます"
            log_info "lcov をインストールしてください（macOS: brew install lcov）"
        fi
        
        # カバレッジ情報を表示
        if [ -f "coverage/lcov.info" ]; then
            COVERAGE_PERCENTAGE=$(lcov --summary coverage/lcov.info 2>/dev/null | grep "lines" | grep -o '[0-9.]*%' || echo "N/A")
            log_info "カバレッジ率: $COVERAGE_PERCENTAGE"
        fi
    fi
}

# テスト結果のサマリー生成
generate_test_summary() {
    log_info "テスト結果サマリーを生成中..."
    
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    SUMMARY_FILE="test_results_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$SUMMARY_FILE" << EOF
# 認証機能テスト結果サマリー

**実行日時**: $TIMESTAMP

## 実行されたテスト

EOF

    if [ "$RUN_UNIT" = true ] || [ "$RUN_ALL" = true ]; then
        echo "- [x] 単体テスト (AuthService)" >> "$SUMMARY_FILE"
    fi
    
    if [ "$RUN_WIDGET" = true ] || [ "$RUN_ALL" = true ]; then
        echo "- [x] ウィジェットテスト (AuthScreen)" >> "$SUMMARY_FILE"
    fi
    
    if [ "$RUN_INTEGRATION" = true ] || [ "$RUN_ALL" = true ]; then
        echo "- [x] 統合テスト (認証フロー)" >> "$SUMMARY_FILE"
    fi

    cat >> "$SUMMARY_FILE" << EOF

## 手動テスト項目（要実施）

### Google認証
- [ ] Google認証でのログイン
- [ ] Google認証キャンセル時の処理
- [ ] Google認証エラー時の処理

### Apple認証
- [ ] Apple認証でのログイン  
- [ ] Apple認証キャンセル時の処理
- [ ] Apple認証エラー時の処理

### その他
- [ ] 複数デバイスでの同時ログイン
- [ ] ネットワークエラー時の処理
- [ ] 長時間使用後のセッション確認

## 次のステップ

1. 手動テスト項目を実施
2. 見つかった問題の修正
3. 本番環境での動作確認

EOF

    log_success "テスト結果サマリーが生成されました: $SUMMARY_FILE"
}

# メイン実行関数
main() {
    log_info "認証テスト実行スクリプトを開始..."
    
    # 依存関係チェック
    check_dependencies
    
    # プロジェクト準備
    clean_and_build
    
    # テスト実行
    if [ "$RUN_ALL" = true ]; then
        run_unit_tests
        run_widget_tests
        run_integration_tests
    else
        if [ "$RUN_UNIT" = true ]; then
            run_unit_tests
        fi
        
        if [ "$RUN_WIDGET" = true ]; then
            run_widget_tests
        fi
        
        if [ "$RUN_INTEGRATION" = true ]; then
            run_integration_tests
        fi
    fi
    
    # カバレッジレポート生成
    generate_coverage_report
    
    # テスト結果サマリー生成
    generate_test_summary
    
    log_success "すべてのテストが完了しました！"
}

# スクリプト実行
main "$@"

---

# PowerShell版（Windows用）
# test_runner.ps1

param(
    [switch]$Unit,
    [switch]$Widget,
    [switch]$Integration,
    [switch]$All = $true,
    [switch]$Coverage,
    [string]$Device = "",
    [switch]$Help
)

# ヘルプメッセージ
function Show-Help {
    Write-Host "認証テスト実行スクリプト (PowerShell版)" -ForegroundColor Blue
    Write-Host ""
    Write-Host "使用方法:"
    Write-Host "  .\test_runner.ps1 [オプション]"
    Write-Host ""
    Write-Host "オプション:"
    Write-Host "  -Unit          単体テストのみ実行"
    Write-Host "  -Widget        ウィジェットテストのみ実行"
    Write-Host "  -Integration   統合テストのみ実行"
    Write-Host "  -All           すべてのテストを実行（デフォルト）"
    Write-Host "  -Coverage      カバレッジレポートを生成"
    Write-Host "  -Device        統合テスト用のデバイスID指定"
    Write-Host "  -Help          このヘルプメッセージを表示"
    Write-Host ""
    Write-Host "例:"
    Write-Host "  .\test_runner.ps1 -Unit -Coverage"
    Write-Host "  .\test_runner.ps1 -Integration -Device 'emulator-5554'"
    Write-Host "  .\test_runner.ps1 -All"
}

# ログ関数
function Write-Info($message) {
    Write-Host "[INFO] $message" -ForegroundColor Blue
}

function Write-Success($message) {
    Write-Host "[SUCCESS] $message" -ForegroundColor Green
}

function Write-Warning($message) {
    Write-Host "[WARNING] $message" -ForegroundColor Yellow
}

function Write-Error($message) {
    Write-Host "[ERROR] $message" -ForegroundColor Red
}

# ヘルプが要求された場合
if ($Help) {
    Show-Help
    exit 0
}

# パラメータの調整
if ($Unit -or $Widget -or $Integration) {
    $All = $false
}

# 依存関係チェック
function Test-Dependencies {
    Write-Info "依存関係をチェック中..."
    
    if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
        Write-Error "Flutterがインストールされていません"
        exit 1
    }
    
    Write-Success "依存関係チェック完了"
}

# プロジェクトのクリーンとビルド
function Initialize-Project {
    Write-Info "プロジェクトをクリーンアップ中..."
    flutter clean
    flutter pub get
    
    Write-Info "モッククラスを生成中..."
    flutter packages pub run build_runner build --delete-conflicting-outputs
    
    Write-Success "プロジェクト準備完了"
}

# 単体テスト実行
function Invoke-UnitTests {
    Write-Info "単体テストを実行中..."
    
    if ($Coverage) {
        flutter test test/services/auth_service_test.dart --coverage
        Write-Success "単体テスト完了（カバレッジ付き）"
    } else {
        flutter test test/services/auth_service_test.dart
        Write-Success "単体テスト完了"
    }
}

# ウィジェットテスト実行
function Invoke-WidgetTests {
    Write-Info "ウィジェットテストを実行中..."
    
    if ($Coverage) {
        flutter test test/screens/auth_screen_test.dart --coverage
        Write-Success "ウィジェットテスト完了（カバレッジ付き）"
    } else {
        flutter test test/screens/auth_screen_test.dart
        Write-Success "ウィジェットテスト完了"
    }
}

# 統合テスト実行
function Invoke-IntegrationTests {
    Write-Info "統合テストを実行中..."
    
    if ($Device) {
        Write-Info "指定されたデバイスでテスト実行: $Device"
        flutter test integration_test/auth_complete_flow_test.dart -d $Device
    } else {
        $availableDevices = flutter devices --machine | ConvertFrom-Json | Where-Object { $_.category -eq "mobile" }
        
        if ($availableDevices.Count -eq 0) {
            Write-Error "利用可能なデバイスが見つかりません"
            Write-Info "以下のコマンドでデバイスを確認してください:"
            Write-Info "  flutter devices"
            exit 1
        }
        
        $selectedDevice = $availableDevices[0].id
        Write-Info "デバイスで統合テストを実行: $selectedDevice"
        flutter test integration_test/auth_complete_flow_test.dart -d $selectedDevice
    }
    
    Write-Success "統合テスト完了"
}

# メイン実行
function Main {
    Write-Info "認証テスト実行スクリプトを開始..."
    
    Test-Dependencies
    Initialize-Project
    
    if ($All) {
        Invoke-UnitTests
        Invoke-WidgetTests
        Invoke-IntegrationTests
    } else {
        if ($Unit) { Invoke-UnitTests }
        if ($Widget) { Invoke-WidgetTests }
        if ($Integration) { Invoke-IntegrationTests }
    }
    
    if ($Coverage -and (Test-Path "coverage/lcov.info")) {
        Write-Info "カバレッジファイルが生成されました: coverage/lcov.info"
    }
    
    Write-Success "すべてのテストが完了しました！"
}

# スクリプト実行
Main