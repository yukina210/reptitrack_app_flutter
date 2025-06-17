// lib/screens/settings/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/settings_service.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          settingsService.getText('privacy_policy', 'Privacy Policy'),
        ),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              settingsService.getText('privacy_policy', 'Privacy Policy'),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '${settingsService.getText('last_updated', 'Last Updated')}: 2025年6月2日',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),

            // Introduction
            _buildSection(
              settingsService.getText('introduction', 'Introduction'),
              settingsService.currentLanguage == AppLanguage.japanese
                  ? _getJapaneseIntroduction()
                  : _getEnglishIntroduction(),
            ),

            // Information We Collect
            _buildSection(
              settingsService.getText(
                'info_we_collect',
                'Information We Collect',
              ),
              settingsService.currentLanguage == AppLanguage.japanese
                  ? _getJapaneseInfoCollection()
                  : _getEnglishInfoCollection(),
            ),

            // How We Use Information
            _buildSection(
              settingsService.getText(
                'how_we_use_info',
                'How We Use Your Information',
              ),
              settingsService.currentLanguage == AppLanguage.japanese
                  ? _getJapaneseInfoUsage()
                  : _getEnglishInfoUsage(),
            ),

            // Data Security
            _buildSection(
              settingsService.getText('data_security', 'Data Security'),
              settingsService.currentLanguage == AppLanguage.japanese
                  ? _getJapaneseDataSecurity()
                  : _getEnglishDataSecurity(),
            ),

            // Third Party Services
            _buildSection(
              settingsService.getText(
                'third_party_services',
                'Third-Party Services',
              ),
              settingsService.currentLanguage == AppLanguage.japanese
                  ? _getJapaneseThirdParty()
                  : _getEnglishThirdParty(),
            ),

            // Your Rights
            _buildSection(
              settingsService.getText('your_rights', 'Your Rights'),
              settingsService.currentLanguage == AppLanguage.japanese
                  ? _getJapaneseUserRights()
                  : _getEnglishUserRights(),
            ),

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        SizedBox(height: 12),
        Text(content, style: TextStyle(fontSize: 16, height: 1.6)),
        SizedBox(height: 24),
      ],
    );
  }

  String _getJapaneseIntroduction() {
    return '''ReptiTrack（以下「本アプリ」）は、爬虫類の飼育管理を支援するアプリケーションです。本プライバシーポリシーは、本アプリをご利用いただく際の個人情報の取り扱いについて説明します。

本アプリをご利用いただくことで、本プライバシーポリシーに同意いただいたものとみなします。''';
  }

  String _getEnglishIntroduction() {
    return '''ReptiTrack (the "App") is an application designed to help manage reptile care. This Privacy Policy explains how we handle personal information when you use our App.

By using our App, you agree to the collection and use of information in accordance with this policy.''';
  }

  String _getJapaneseInfoCollection() {
    return '''本アプリでは、以下の情報を収集します：

• アカウント情報：メールアドレス、パスワード（暗号化済み）
• プロフィール情報：Google/Appleアカウント連携時の基本情報
• ペット情報：ペットの名前、性別、誕生日、種類、写真など
• 飼育記録：お世話記録、体重記録、その他のメモ
• 利用状況：アプリの使用パターン、エラーログ

これらの情報は、サービス提供のために必要な範囲でのみ収集されます。''';
  }

  String _getEnglishInfoCollection() {
    return '''We collect the following types of information:

• Account Information: Email address, encrypted password
• Profile Information: Basic information when linking Google/Apple accounts
• Pet Information: Pet names, gender, birthdate, species, photos, etc.
• Care Records: Care logs, weight records, and other notes
• Usage Data: App usage patterns, error logs

This information is collected only to the extent necessary to provide our services.''';
  }

  String _getJapaneseInfoUsage() {
    return '''収集した情報は以下の目的で使用されます：

• アプリのサービス提供・運営
• ユーザーサポートの提供
• アプリの改善・新機能の開発
• 技術的な問題の解決
• 法的義務の履行

お客様の明示的な同意なしに、上記以外の目的で個人情報を使用することはありません。''';
  }

  String _getEnglishInfoUsage() {
    return '''We use the collected information for the following purposes:

• Providing and operating our App services
• Providing user support
• Improving the App and developing new features
• Resolving technical issues
• Complying with legal obligations

We will not use personal information for purposes other than those listed above without your explicit consent.''';
  }

  String _getJapaneseDataSecurity() {
    return '''お客様の個人情報の安全性は、当社にとって最重要事項です：

• データの暗号化：すべてのデータは暗号化して保存
• Firebase Security：Google Firebaseの高度なセキュリティ機能を利用
• アクセス制御：権限のある担当者のみがデータにアクセス可能
• 定期的な監査：セキュリティ体制の定期的な見直し

ただし、インターネット上の完全なセキュリティは保証できないことをご理解ください。''';
  }

  String _getEnglishDataSecurity() {
    return '''The security of your personal information is of utmost importance to us:

• Data Encryption: All data is stored with encryption
• Firebase Security: Utilizing Google Firebase's advanced security features
• Access Control: Only authorized personnel can access data
• Regular Audits: Regular review of security measures

However, please understand that no method of transmission over the Internet is 100% secure.''';
  }

  String _getJapaneseThirdParty() {
    return '''本アプリでは以下のサードパーティサービスを使用しています：

• Firebase（Google）：データベース、認証、ストレージ
• Google Sign-In：Googleアカウント認証
• Sign in with Apple：Appleアカウント認証

これらのサービスには独自のプライバシーポリシーがあります。詳細は各サービスのプライバシーポリシーをご確認ください。''';
  }

  String _getEnglishThirdParty() {
    return '''Our App uses the following third-party services:

• Firebase (Google): Database, authentication, storage
• Google Sign-In: Google account authentication
• Sign in with Apple: Apple account authentication

These services have their own privacy policies. Please review their privacy policies for more information.''';
  }

  String _getJapaneseUserRights() {
    return '''お客様には以下の権利があります：

• アクセス権：保存されている個人情報の確認
• 修正権：不正確な個人情報の修正
• 削除権：個人情報の削除（アカウント削除）
• データポータビリティ権：データのエクスポート
• 同意撤回権：いつでも同意を撤回可能

これらの権利を行使される場合は、アプリ内の設定よりアカウント削除またはデータエクスポートを行ってください。''';
  }

  String _getEnglishUserRights() {
    return '''You have the following rights:

• Access: View your stored personal information
• Rectification: Correct inaccurate personal information
• Erasure: Delete your personal information (account deletion)
• Data Portability: Export your data
• Withdrawal of Consent: Withdraw consent at any time

To exercise these rights, please use the account deletion or data export features in the app settings.''';
  }
}
