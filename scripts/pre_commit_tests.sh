#!/bin/bash
# プリコミットフック用の軽量テスト

echo "🔍 プリコミットテストを実行中..."

# コード解析
echo "📊 コード解析..."
flutter analyze --fatal-infos

if [ $? -ne 0 ]; then
    echo "❌ コード解析でエラーが見つかりました"
    exit 1
fi

# 認証関連のファイルが変更された場合のみテスト実行
CHANGED_FILES=$(git diff --cached --name-only)
AUTH_FILES_CHANGED=false

for file in $CHANGED_FILES; do
    if [[ $file == *"auth"* ]] || [[ $file == *"Auth"* ]]; then
        AUTH_FILES_CHANGED=true
        break
    fi
done

if [ "$AUTH_FILES_CHANGED" = true ]; then
    echo "🧪 認証関連ファイルの変更を検出。テストを実行..."

    # 単体テストのみ実行（高速）
    flutter test test/services/auth_service_test.dart

    if [ $? -ne 0 ]; then
        echo "❌ 認証テストが失敗しました"
        exit 1
    fi

    echo "✅ 認証テスト完了"
else
    echo "ℹ️ 認証関連ファイルの変更なし。テストスキップ"
fi

echo "✅ プリコミットテスト完了"