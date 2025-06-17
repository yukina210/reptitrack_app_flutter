// lib/screens/settings/terms_of_service_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/settings_service.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          settingsService.getText('terms_of_service', 'Terms of Service'),
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
              settingsService.getText('terms_of_service', 'Terms of Service'),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '${settingsService.getText('effective_date', 'Effective Date')}: 2025年6月2日',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),

            // Agreement to Terms
            _buildSection(
              settingsService.getText(
                'agreement_to_terms',
                'Agreement to Terms',
              ),
              settingsService.currentLanguage == AppLanguage.japanese
                  ? _getJapaneseAgreement()
                  : _getEnglishAgreement(),
            ),

            // Use License
            _buildSection(
              settingsService.getText('use_license', 'Use License'),
              settingsService.currentLanguage == AppLanguage.japanese
                  ? _getJapaneseLicense()
                  : _getEnglishLicense(),
            ),

            // User Account
            _buildSection(
              settingsService.getText('user_account', 'User Account'),
              settingsService.currentLanguage == AppLanguage.japanese
                  ? _getJapaneseAccount()
                  : _getEnglishAccount(),
            ),

            // Prohibited Uses
            _buildSection(
              settingsService.getText('prohibited_uses', 'Prohibited Uses'),
              settingsService.currentLanguage == AppLanguage.japanese
                  ? _getJapaneseProhibited()
                  : _getEnglishProhibited(),
            ),

            // Content
            _buildSection(
              settingsService.getText('content', 'Content'),
              settingsService.currentLanguage == AppLanguage.japanese
                  ? _getJapaneseContent()
                  : _getEnglishContent(),
            ),

            // Privacy Policy
            _buildSection(
              settingsService.getText('privacy', 'Privacy'),
              settingsService.currentLanguage == AppLanguage.japanese
                  ? _getJapanesePrivacy()
                  : _getEnglishPrivacy(),
            ),

            // Termination
            _buildSection(
              settingsService.getText('termination', 'Termination'),
              settingsService.currentLanguage == AppLanguage.japanese
                  ? _getJapaneseTermination()
                  : _getEnglishTermination(),
            ),

            // Disclaimer
            _buildSection(
              settingsService.getText('disclaimer', 'Disclaimer'),
              settingsService.currentLanguage == AppLanguage.japanese
                  ? _getJapaneseDisclaimer()
                  : _getEnglishDisclaimer(),
            ),

            // Limitation of Liability
            _buildSection(
              settingsService.getText(
                'limitation_of_liability',
                'Limitation of Liability',
              ),
              settingsService.currentLanguage == AppLanguage.japanese
                  ? _getJapaneseLimitation()
                  : _getEnglishLimitation(),
            ),

            // Changes to Terms
            _buildSection(
              settingsService.getText('changes_to_terms', 'Changes to Terms'),
              settingsService.currentLanguage == AppLanguage.japanese
                  ? _getJapaneseChanges()
                  : _getEnglishChanges(),
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

  String _getJapaneseAgreement() {
    return '''ReptiTrack（以下「本アプリ」）にアクセスし、これを使用することにより、お客様は本利用規約に同意し、拘束されることに同意したものとみなされます。

本利用規約のいずれかの条項に同意いただけない場合は、本アプリの使用を停止してください。''';
  }

  String _getEnglishAgreement() {
    return '''By accessing and using ReptiTrack (the "App"), you accept and agree to be bound by the terms and provision of this agreement.

If you do not agree to abide by the above, please do not use this App.''';
  }

  String _getJapaneseLicense() {
    return '''本利用規約の条項に従って、ReptiTrackは本アプリを使用するための個人的、非独占的、譲渡不可能で制限付きライセンスを付与します。

このライセンスは以下の目的でのみ使用することができます：
• 個人的な爬虫類の飼育管理
• 非商用目的での使用
• 本利用規約に準拠した使用''';
  }

  String _getEnglishLicense() {
    return '''Subject to the terms of this agreement, ReptiTrack grants you a personal, non-exclusive, non-transferable, limited license to use this App.

This license is for the following purposes only:
• Personal reptile care management
• Non-commercial use
• Use in compliance with these terms''';
  }

  String _getJapaneseAccount() {
    return '''本アプリを使用するためには、アカウントを作成する必要があります。アカウント作成時には、正確で完全な情報を提供することに同意します。

お客様は以下について責任を負います：
• アカウント情報の機密性の維持
• アカウントで発生するすべての活動
• パスワードの安全な管理
• 不正使用の疑いがある場合の即座の通知''';
  }

  String _getEnglishAccount() {
    return '''To use this App, you must create an account. When creating an account, you agree to provide accurate and complete information.

You are responsible for:
• Maintaining the confidentiality of your account information
• All activities that occur under your account
• Safeguarding your password
• Immediately notifying us of any suspected unauthorized use''';
  }

  String _getJapaneseProhibited() {
    return '''本アプリの使用にあたり、以下の行為は禁止されています：

• 違法な目的での使用
• 他のユーザーの権利やプライバシーの侵害
• ウイルスやマルウェアの送信
• システムやセキュリティ機能の迂回または無効化
• 逆エンジニアリング、逆コンパイル、または逆アセンブル
• 商用目的での使用（明示的に許可された場合を除く）
• 虚偽または誤解を招く情報の提供''';
  }

  String _getEnglishProhibited() {
    return '''You are prohibited from using the App for:

• Any unlawful purpose
• Violating the rights or privacy of other users
• Transmitting viruses or malicious code
• Circumventing or disabling security features
• Reverse engineering, decompiling, or disassembling
• Commercial purposes (unless explicitly permitted)
• Providing false or misleading information''';
  }

  String _getJapaneseContent() {
    return '''本アプリでは、ユーザーがペット情報、写真、記録などのコンテンツを投稿できます。

ユーザーの責任：
• 投稿するコンテンツの正確性と適法性
• 他者の知的財産権の尊重
• 不適切なコンテンツの投稿禁止

ReptiTrackの権利：
• 不適切なコンテンツの削除
• 利用規約違反時のアカウント停止
• サービス改善のためのデータ分析''';
  }

  String _getEnglishContent() {
    return '''The App allows users to post content including pet information, photos, and records.

User Responsibilities:
• Accuracy and legality of posted content
• Respecting others' intellectual property rights
• Prohibiting inappropriate content

ReptiTrack Rights:
• Removing inappropriate content
• Suspending accounts for terms violations
• Analyzing data for service improvement''';
  }

  String _getJapanesePrivacy() {
    return '''お客様のプライバシーは当社にとって重要です。個人情報の収集、使用、開示については、別途プライバシーポリシーに詳細を記載しています。

本アプリを使用することにより、プライバシーポリシーに同意したものとみなされます。''';
  }

  String _getEnglishPrivacy() {
    return '''Your privacy is important to us. Our collection, use, and disclosure of personal information is detailed in our separate Privacy Policy.

By using this App, you agree to our Privacy Policy.''';
  }

  String _getJapaneseTermination() {
    return '''ReptiTrackは、以下の場合にアカウントを停止または終了する権利を留保します：

• 本利用規約への違反
• 不正または不適切な使用
• 法的要求または規制上の義務
• サービスの廃止

アカウント終了時には、関連するデータが削除される場合があります。''';
  }

  String _getEnglishTermination() {
    return '''ReptiTrack reserves the right to suspend or terminate accounts in the following cases:

• Violation of these terms
• Fraudulent or inappropriate use
• Legal requirements or regulatory obligations
• Service discontinuation

Upon account termination, associated data may be deleted.''';
  }

  String _getJapaneseDisclaimer() {
    return '''本アプリは「現状のまま」提供され、明示的または暗示的な保証はありません。

ReptiTrackは以下について保証しません：
• サービスの継続性や可用性
• エラーやバグの不存在
• データの完全性や正確性
• 特定目的への適合性

ペットの健康に関する重要な決定は、必ず獣医師に相談してください。''';
  }

  String _getEnglishDisclaimer() {
    return '''The App is provided "as is" without any express or implied warranties.

ReptiTrack does not warrant:
• Service continuity or availability
• Absence of errors or bugs
• Data completeness or accuracy
• Fitness for a particular purpose

Always consult with a veterinarian for important decisions regarding your pet's health.''';
  }

  String _getJapaneseLimitation() {
    return '''適用法で許可される最大限の範囲で、ReptiTrackは以下について責任を負いません：

• 間接的、偶発的、特別、結果的損害
• データの損失や破損
• 利益の損失
• サービスの中断
• 第三者によるアクセスや使用

当社の責任は、サービス料金相当額に限定されます。''';
  }

  String _getEnglishLimitation() {
    return '''To the maximum extent permitted by applicable law, ReptiTrack shall not be liable for:

• Indirect, incidental, special, or consequential damages
• Data loss or corruption
• Loss of profits
• Service interruptions
• Third-party access or use

Our liability is limited to the amount of service fees paid.''';
  }

  String _getJapaneseChanges() {
    return '''ReptiTrackは、本利用規約をいつでも変更する権利を留保します。変更は本アプリまたはウェブサイトに掲載することにより有効となります。

重要な変更については、可能な限り事前にユーザーに通知いたします。変更後も本アプリを継続使用することで、変更に同意したものとみなされます。''';
  }

  String _getEnglishChanges() {
    return '''ReptiTrack reserves the right to modify these terms at any time. Changes become effective when posted in the App or on our website.

We will notify users of significant changes whenever possible. Continued use of the App after changes constitutes acceptance of the modified terms.''';
  }
}
