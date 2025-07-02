#!/bin/bash

# scripts/generate_mocks.sh - モッククラス生成確認スクリプト

echo "🔄 モッククラスを生成中..."

# 依存関係を更新
flutter pub get

# build_runner でモッククラスを生成
dart run build_runner build --delete-conflicting-outputs

# 生成されたファイルを確認
echo "📁 生成されたモックファイル:"
find . -name "*.mocks.dart" -type f

# テストファイルの構文チェック
echo "🔍 テストファイルの構文チェック:"
dart analyze test/screens/pets/pet_form_screen_test.dart

echo "✅ モック生成完了！"