#!/bin/bash

# scripts/run_tests.sh - テスト実行スクリプト

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

# ヘルプ表示
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          このヘルプを表示"
    echo "  -u, --unit          単体テストのみ実行"
    echo "  -w, --widget        ウィジェットテストのみ実行"
    echo "  -i, --integration   統合テストのみ実行"
    echo "  -c, --coverage      カバレッジレポート生成"
    echo "  -v, --verbose       詳細ログ出力"
    echo "  --clean             事前にクリーンアップ実行"
    echo "  --generate-mocks    モック生成"
    echo ""
    echo "Examples:"
    echo "  $0                  全テストを実行"
    echo "  $0 -u -c            単体テストとカバレッジ生成"
    echo "  $0 --clean -w       クリーンアップ後にウィジェットテスト"
}

# デフォルト設定
RUN_UNIT=false
RUN_WIDGET=false
RUN_INTEGRATION=false
RUN_ALL=true
GENERATE_COVERAGE=false
VERBOSE=false
CLEAN=false
GENERATE_MOCKS=false

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -u|--unit)
            RUN_UNIT=true
            RUN_ALL=false
            shift
            ;;
        -w|--widget)
            RUN_WIDGET=true
            RUN_ALL=false
            shift
            ;;
        -i|--integration)
            RUN_INTEGRATION=true
            RUN_ALL=false
            shift
            ;;
        -c|--coverage)
            GENERATE_COVERAGE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --generate-mocks)
            GENERATE_MOCKS=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# プロジェクトルートディレクトリの確認
if [ ! -f "pubspec.yaml" ]; then
    log_error "pubspec.yaml が見つかりません。プロジェクトルートで実行してください。"
    exit 1
fi

log_info "ReptiTrack アプリのテスト実行を開始します..."

# クリーンアップ
if [ "$CLEAN" = true ]; then
    log_info "プロジェクトをクリーンアップ中..."
    flutter clean
    flutter pub get
    log_success "クリーンアップ完了"
fi

# 依存関係の確認
log_info "依存関係を確認中..."
flutter pub get

# モック生成
if [ "$GENERATE_MOCKS" = true ]; then
    log_info "モッククラスを生成中..."
    flutter packages pub run build_runner build --delete-conflicting-outputs
    log_success "モッククラス生成完了"
fi

# テスト実行関数
run_tests() {
    local test_type=$1
    local test_path=$2
    local description=$3
    
    log_info "$description を実行中..."
    
    if [ "$VERBOSE" = true ]; then
        if [ "$GENERATE_COVERAGE" = true ]; then
            flutter test "$test_path" --coverage --verbose
        else
            flutter test "$test_path" --verbose
        fi
    else
        if [ "$GENERATE_COVERAGE" = true ]; then
            flutter test "$test_path" --coverage
        else
            flutter test "$test_path"
        fi
    fi
    
    if [ $? -eq 0 ]; then
        log_success "$description 完了"
    else
        log_error "$description 失敗"
        exit 1
    fi
}

# テスト実行
if [ "$RUN_ALL" = true ]; then
    log_info "全テストを実行します..."
    if [ "$GENERATE_COVERAGE" = true ]; then
        flutter test --coverage
    else
        flutter test
    fi
    
    if [ $? -eq 0 ]; then
        log_success "全テスト完了"
    else
        log_error "テスト失敗"
        exit 1
    fi
else
    # 個別テスト実行
    if [ "$RUN_UNIT" = true ]; then
        run_tests "unit" "test/services/ test/models/" "単体テスト"
    fi
    
    if [ "$RUN_WIDGET" = true ]; then
        run_tests "widget" "test/screens/ test/widgets/" "ウィジェットテスト"
    fi
    
    if [ "$RUN_INTEGRATION" = true ]; then
        run_tests "integration" "integration_test/" "統合テスト"
    fi
fi

# カバレッジレポート生成
if [ "$GENERATE_COVERAGE" = true ]; then
    log_info "カバレッジレポートを生成中..."
    
    # lcov がインストールされているか確認
    if command -v genhtml &> /dev/null; then
        mkdir -p coverage/html
        genhtml coverage/lcov.info -o coverage/html
        log_success "カバレッジレポートを coverage/html に生成しました"
        
        # ブラウザでレポートを開く（オプション）
        if command -v open &> /dev/null; then
            open coverage/html/index.html
        elif command -v xdg-open &> /dev/null; then
            xdg-open coverage/html/index.html
        fi
    else
        log_warning "genhtml がインストールされていません。lcov ファイルのみ生成されました。"
    fi
    
    # カバレッジサマリー表示
    if [ -f "coverage/lcov.info" ]; then
        log_info "カバレッジサマリー:"
        lcov --summary coverage/lcov.info
    fi
fi

# テスト結果の後処理
log_info "テスト結果を確認中..."

# 失敗したテストがあるかチェック
if [ -f "test_results.json" ]; then
    log_info "詳細なテスト結果は test_results.json で確認できます"
fi

log_success "すべてのテストプロセスが完了しました！"

# 次のステップの提案
echo ""
log_info "次のステップ:"
echo "  • カバレッジを向上させるためのテストを追加"
echo "  • CI/CD パイプラインへの統合"
echo "  • パフォーマンステストの実装"
echo "  • E2E テストの追加"