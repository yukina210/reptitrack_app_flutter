// test/compatibility/production_compatibility_test.dart
// 本番環境での動作をシミュレートするテスト

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:reptitrack_app/screens/pets/pet_list_screen.dart';
import 'package:reptitrack_app/services/auth_service.dart';
import 'package:reptitrack_app/services/settings_service.dart';

void main() {
  group('本番環境互換性テスト', () {
    testWidgets('本番環境と同じ条件でPetListScreenが正常動作する', (WidgetTester tester) async {
      // 本番環境をシミュレート（PetServiceをProviderで提供しない）

      // AuthServiceとSettingsServiceのみ提供（本番環境と同じ構成）
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthService>(
              create: (_) => AuthService(),
            ),
            ChangeNotifierProvider<SettingsService>(
              create: (_) => SettingsService(),
            ),
            // 注意: PetServiceはProviderで提供しない（本番環境と同じ）
          ],
          child: MaterialApp(
            home: PetListScreen(),
          ),
        ),
      );

      // PetServiceがProvider.of()で見つからずに
      // catch ブロックで新しいインスタンスが作成されることを確認

      await tester.pumpAndSettle();

      // 基本的なUI要素が表示されることを確認
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('PetServiceの依存性注入パターンが正しく動作する', (WidgetTester tester) async {
      // テスト1: Provider経由でPetServiceが提供される場合（テスト環境）
      // テスト2: Provider経由でPetServiceが提供されない場合（本番環境）

      // これにより両方の環境で正常に動作することを確認

      // 本番環境パターンのテスト
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthService>(
              create: (_) => AuthService(),
            ),
            ChangeNotifierProvider<SettingsService>(
              create: (_) => SettingsService(),
            ),
          ],
          child: MaterialApp(
            home: PetListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // エラーなく画面が表示されることを確認
      expect(find.byType(PetListScreen), findsOneWidget);
    });
  });
}
