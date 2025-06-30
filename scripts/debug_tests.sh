#!/bin/bash

# scripts/debug_tests.sh - テストデバッグ用スクリプト

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info "認証テストの詳細デバッグを開始..."

# 1. まず依存関係を確認
log_info "=== 依存関係の確認 ==="
flutter pub get

# 2. モッククラスを生成
log_info "=== モッククラス生成 ==="
dart run build_runner build --delete-conflicting-outputs

# 3. 個別のテストファイルを詳細モードで実行
log_info "=== AuthService テストの詳細実行 ==="
if [[ -f "test/services/auth_service_test.dart" ]]; then
    echo "AuthServiceテストを詳細モードで実行中..."
    flutter test test/services/auth_service_test.dart --reporter=expanded
else
    log_error "test/services/auth_service_test.dart が見つかりません"
fi

# 4. その他の主要テストファイルも個別に確認
log_info "=== その他のテストファイル確認 ==="

test_files=(
    "test/models/pet_model_test.dart"
    "test/models/care_record_model_test.dart"
    "test/models/weight_record_model_test.dart"
    "test/providers/auth_provider_test.dart"
    "test/screens/auth_screen_test.dart"
)

for test_file in "${test_files[@]}"; do
    if [[ -f "$test_file" ]]; then
        log_info "実行中: $test_file"
        if flutter test "$test_file" --reporter=expanded; then
            log_success "✓ $test_file 成功"
        else
            log_error "✗ $test_file 失敗"
        fi
        echo "----------------------------------------"
    else
        echo "スキップ: $test_file (ファイルが存在しません)"
    fi
done

# 5. テストディレクトリ全体の状況を確認
log_info "=== テストディレクトリ構造確認 ==="
find test -name "*.dart" -type f | head -20

echo "=========================================="
log_info "デバッグ完了"