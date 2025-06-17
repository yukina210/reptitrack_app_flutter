// lib/services/settings_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  japanese('ja', '日本語'),
  english('en', 'English');

  const AppLanguage(this.code, this.displayName);
  final String code;
  final String displayName;
}

class SettingsService extends ChangeNotifier {
  static const String _languageKey = 'app_language';

  AppLanguage _currentLanguage = AppLanguage.japanese;
  SharedPreferences? _prefs;

  SettingsService() {
    _loadSettings();
  }

  AppLanguage get currentLanguage => _currentLanguage;
  String get currentLanguageCode => _currentLanguage.code;

  String getCurrentLanguageDisplay() => _currentLanguage.displayName;

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    final languageCode = _prefs?.getString(_languageKey) ?? 'ja';

    _currentLanguage = AppLanguage.values.firstWhere(
      (lang) => lang.code == languageCode,
      orElse: () => AppLanguage.japanese,
    );

    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;
    await _prefs?.setString(_languageKey, language.code);
    notifyListeners();
  }

  // 多言語対応テキスト取得
  String getText(String key, String fallback) {
    final texts =
        _currentLanguage == AppLanguage.japanese
            ? _japaneseTexts
            : _englishTexts;
    return texts[key] ?? fallback;
  }

  // プレースホルダーを置換するヘルパーメソッド
  String getTextWithPlaceholder(
    String key,
    String fallback,
    String placeholder,
    String value,
  ) {
    final text = getText(key, fallback);
    return text.replaceAll(placeholder, value);
  }

  // 日本語テキスト
  static const Map<String, String> _japaneseTexts = {
    // Navigation
    'pets': 'ペット',
    'dashboard': 'ダッシュボード',
    'settings': '設定',

    // Common
    'my_pets': 'マイペット',
    'add_pet': 'ペット追加',
    'register_pet': 'ペット登録',
    'edit': '編集',
    'delete': '削除',
    'cancel': 'キャンセル',
    'error': 'エラー',
    'login': 'ログイン',
    'sign_out': 'ログアウト',
    'please_login': 'ログインしてください',
    'error_occurred': 'エラーが発生しました',
    'no_pets_registered': 'ペットが登録されていません',
    'birthday': '誕生日',
    'age': '年齢',
    'current_pet': '現在のペット',
    'care_calendar': 'お世話カレンダー',
    'weight_chart': '体重グラフ',
    'calendar_subtitle': '記録のある日をタップして詳細を確認、記録のない日をタップして新規追加',
    'add_weight_to_show_chart': '体重記録を追加してグラフを表示',
    'data_load_failed': 'データの読み込みに失敗しました',
    'delete_pet': 'ペット削除',
    'delete_pet_confirmation': 'PET_NAMEを削除してもよろしいですか？この操作は元に戻せません。',
    'pet_deleted_successfully': 'PET_NAMEを削除しました',
    'delete_error': '削除中にエラーが発生しました',

    // Settings Screen
    'unknown_user': '不明なユーザー',
    'app_settings': 'アプリ設定',
    'language': '言語',
    'language_subtitle': 'お好みの言語を選択してください',
    'notifications': '通知',
    'notification_subtitle': '通知設定を管理',
    'account': 'アカウント',
    'account_settings': 'アカウント設定',
    'account_subtitle': 'アカウント情報を管理',
    'security': 'セキュリティ',
    'security_subtitle': 'パスワードとセキュリティ設定',
    'legal': '法的事項',
    'terms_of_service': '利用規約',
    'terms_subtitle': '利用規約を確認',
    'privacy_policy': 'プライバシーポリシー',
    'privacy_subtitle': 'プライバシーポリシーを確認',
    'data_management': 'データ管理',
    'export_data': 'データのエクスポート',
    'export_subtitle': 'データをダウンロード',
    'delete_account': 'アカウントの削除',
    'delete_subtitle': 'アカウントを完全に削除',
    'confirm_sign_out': 'ログアウト確認',
    'sign_out_message': 'ログアウトしてもよろしいですか？',
    'coming_soon': '近日公開予定',

    // Authentication providers
    'email_auth': 'メール認証',
    'google_auth': 'Google認証',
    'apple_auth': 'Apple認証',

    // Delete account
    'delete_warning': 'この操作は元に戻せません。すべてのデータが完全に削除されます。',
    'delete_consequences': '以下が削除されます：',
    'pets_data': 'すべてのペット情報',
    'care_records': 'お世話記録',
    'weight_records': '体重記録',
    'account_info': 'アカウント情報',

    // Language Settings
    'select_language': '言語を選択',
    'restart_required': 'アプリの再起動が必要です',
    'language_changed': '言語が変更されました',

    // Account Settings
    'profile': 'プロフィール',
    'email': 'メールアドレス',
    'password': 'パスワード',
    'change_email': 'メールアドレス変更',
    'change_password': 'パスワード変更',
    'current_password': '現在のパスワード',
    'new_password': '新しいパスワード',
    'confirm_password': 'パスワード確認',
    'updated_successfully': '正常に更新されました',
    'current_password_required': '現在のパスワードが必要です',
    'password_mismatch': 'パスワードが一致しません',
    'password_too_short': 'パスワードは6文字以上にしてください',
    'email_updated': 'メールアドレスが更新されました',
    'password_updated': 'パスワードが更新されました',
    'verification_email_sent': '確認メールが送信されました',

    // Privacy Policy & Terms
    'last_updated': '最終更新日',
    'effective_date': '有効日',
    'contact_us': 'お問い合わせ',

    // Data Export
    'export_description': 'すべてのデータをJSONファイルとしてエクスポートできます。',
    'export_includes': 'エクスポートに含まれるもの：',
    'export_pets': 'ペット情報',
    'export_care': 'お世話記録',
    'export_weight': '体重記録',
    'export_button': 'データをエクスポート',
    'exporting': 'エクスポート中...',
    'export_success': 'データのエクスポートが完了しました',
    'export_error': 'エクスポートに失敗しました',
    'no_data': 'エクスポートするデータがありません',
    'share_data': 'データを共有',
    'share_error': '共有に失敗しました',
    'total_pets': '総ペット数',
    'total_care_records': '総お世話記録数',
    'total_weight_records': '総体重記録数',
    'export_date': 'エクスポート日',
    'export_preview': 'エクスポートプレビュー',
    'export_info':
        'エクスポートされたファイルにはすべてのデータがJSON形式で含まれます。このファイルはデータのバックアップや他のアプリケーションへのインポートに使用できます。',

    // Additional settings
    'danger_zone': '危険ゾーン',
    'delete_confirmation': '削除の確認',
    'delete_confirmation_error': '"DELETE"と入力してください',
    'auth_methods': '認証方法',
    'password_subtitle': '強力なパスワードでアカウントを安全に保ちます',
    'new_email': '新しいメールアドレス',
    'email_required': 'メールアドレスが必要です',
    'invalid_email': '無効なメールアドレス形式です',
    'password_required': 'パスワードが必要です',
    'account_created': 'アカウント作成日',
    'last_sign_in': '最終ログイン',
    'account_deleted': 'アカウントが削除されました',
    'user_not_logged_in': 'ユーザーがログインしていません',

    // Notifications
    'active': 'アクティブ',
    'scheduled': 'スケジュール',
    'reminders': 'リマインダー',
    'add_reminder': 'リマインダー追加',
    'edit_reminder': 'リマインダー編集',
    'delete_reminder': 'リマインダー削除',
    'delete_reminder_confirmation': 'このリマインダーを削除してもよろしいですか？',
    'reminder_deleted': 'リマインダーを削除しました',
    'reminder_created': 'リマインダーを作成しました',
    'reminder_updated': 'リマインダーを更新しました',
    'no_active_notifications': 'アクティブな通知はありません',
    'notifications_will_appear_here': '通知がトリガーされるとここに表示されます',
    'no_scheduled_reminders': 'スケジュールされたリマインダーはありません',
    'tap_add_to_create_reminder': '+ボタンをタップして最初のリマインダーを作成',
    'clear_completed': '完了済みをクリア',
    'complete': '完了',
    'completed': '完了しました！',

    // Notification form
    'select_pet': 'ペットを選択',
    'please_select_pet': 'ペットを選択してください',
    'notification_type': '通知タイプ',
    'title': 'タイトル',
    'title_required': 'タイトルは必須です',
    'description': '説明',
    'optional': '任意',
    'reminder_title_hint': 'リマインダーのタイトルを入力',
    'additional_notes': '追加のメモや指示',
    'schedule': 'スケジュール',
    'repeat': '繰り返し',
    'save': '保存',
    'update': '更新',

    // Notification types
    'feeding_reminder': 'ごはんリマインダー',
    'bathing_reminder': '温浴リマインダー',
    'cleaning_reminder': 'お部屋清掃リマインダー',
    'heat_lamp_reminder': 'ヒートランプ交換リマインダー',
    'uv_light_reminder': '紫外線ライト交換リマインダー',
    'medicine_reminder': 'お薬リマインダー',
    'hospital_reminder': '病院リマインダー',
    'health_check_reminder': '健康診断リマインダー',
    'custom_reminder': 'カスタムリマインダー',
    'notification_settings': '通知設定',
    'notification_sound': '通知音',
    'notification_priority': '通知優先度',
    'notification_style': '通知スタイル',
    'quiet_hours': 'サイレント時間',
    'physical_alerts': '物理的アラート',
    'snooze_settings': 'スヌーズ設定',
    'test_notification': 'テスト通知',

    'reset_defaults': 'デフォルトに戻す',
    'priority_description': '高い優先度の通知はより目立って表示されます',
    'style_description': '通知に表示する情報量を選択してください',
    'quiet_hours_description': '指定した時間帯は通知を無効にします',
    'test_description': 'テスト通知を送信して設定をプレビューできます',

    'enable_quiet_hours': 'サイレント時間を有効にする',
    'start_time': '開始時間',
    'end_time': '終了時間',
    'enable_vibration': 'バイブレーションを有効にする',
    'vibration_description': '通知が届いたときに振動します',
    'enable_led': 'LEDライトを有効にする',
    'led_description': '通知用のLEDライトを点滅させます（Androidのみ）',

    'snooze_interval': 'スヌーズ間隔',
    'minutes': '分',
    'select_snooze_interval': 'スヌーズ間隔を選択',
    'send_test': 'テスト通知を送信',
    'test_sent': 'テスト通知を送信しました',

    'reset_to_defaults': 'デフォルトに戻す',
    'reset_confirmation': 'すべての通知設定をデフォルトに戻してもよろしいですか？',
    'reset': 'リセット',
    'settings_reset': '設定をデフォルトに戻しました',

    // Time expressions
    'today': '今日',
    'tomorrow': '明日',
    'overdue': '期限切れ',
    'triggered_at': 'トリガー時間',
    'close': '閉じる',

    // Pet notification section
    'no_reminders_set': 'このペットにはリマインダーが設定されていません',
    'create_reminder': 'リマインダーを作成',
    'add_another_reminder': '別のリマインダーを追加',
    'no_pets_for_reminder': 'リマインダーを作成するには、まずペットを登録してください',

    // Smart suggestions
    'smart_suggestions': 'スマート提案',
    'suggested_reminders': '提案されたリマインダー',
    'based_on_care_pattern': 'お世話パターンに基づく提案',

    // Additional missing keys for Pet model
    'pet': 'ペット',
  };

  // English texts
  static const Map<String, String> _englishTexts = {
    // Navigation
    'pets': 'Pets',
    'dashboard': 'Dashboard',
    'settings': 'Settings',

    // Common
    'my_pets': 'My Pets',
    'add_pet': 'Add Pet',
    'register_pet': 'Register Pet',
    'edit': 'Edit',
    'delete': 'Delete',
    'cancel': 'Cancel',
    'error': 'Error',
    'login': 'Login',
    'sign_out': 'Sign Out',
    'please_login': 'Please login',
    'error_occurred': 'An error occurred',
    'no_pets_registered': 'No pets registered',
    'birthday': 'Birthday',
    'age': 'Age',
    'current_pet': 'Current Pet',
    'care_calendar': 'Care Calendar',
    'weight_chart': 'Weight Chart',
    'calendar_subtitle':
        'Tap days with records for details, tap empty days to add new records',
    'add_weight_to_show_chart': 'Add weight records to display chart',
    'data_load_failed': 'Failed to load data',
    'delete_pet': 'Delete Pet',
    'delete_pet_confirmation':
        'Are you sure you want to delete PET_NAME? This action cannot be undone.',
    'pet_deleted_successfully': 'PET_NAME has been deleted',
    'delete_error': 'An error occurred while deleting',

    // Settings Screen
    'unknown_user': 'Unknown User',
    'app_settings': 'App Settings',
    'language': 'Language',
    'language_subtitle': 'Choose your preferred language',
    'notifications': 'Notifications',
    'notification_subtitle': 'Manage notification preferences',
    'account': 'Account',
    'account_settings': 'Account Settings',
    'account_subtitle': 'Manage your account information',
    'security': 'Security',
    'security_subtitle': 'Password and security settings',
    'legal': 'Legal',
    'terms_of_service': 'Terms of Service',
    'terms_subtitle': 'Read our terms of service',
    'privacy_policy': 'Privacy Policy',
    'privacy_subtitle': 'Read our privacy policy',
    'data_management': 'Data Management',
    'export_data': 'Export Data',
    'export_subtitle': 'Download your data',
    'delete_account': 'Delete Account',
    'delete_subtitle': 'Permanently delete your account',
    'confirm_sign_out': 'Confirm Sign Out',
    'sign_out_message': 'Are you sure you want to sign out?',
    'coming_soon': 'Coming Soon',

    // Authentication providers
    'email_auth': 'Email Authentication',
    'google_auth': 'Google Authentication',
    'apple_auth': 'Apple Authentication',

    // Delete account
    'delete_warning':
        'This action cannot be undone. All your data will be permanently deleted.',
    'delete_consequences': 'This includes:',
    'pets_data': 'All pet information',
    'care_records': 'Care records',
    'weight_records': 'Weight records',
    'account_info': 'Account information',

    // Language Settings
    'select_language': 'Select Language',
    'restart_required': 'App restart required',
    'language_changed': 'Language changed',

    // Account Settings
    'profile': 'Profile',
    'email': 'Email',
    'password': 'Password',
    'change_email': 'Change Email',
    'change_password': 'Change Password',
    'current_password': 'Current Password',
    'new_password': 'New Password',
    'confirm_password': 'Confirm Password',
    'update': 'Update',
    'updated_successfully': 'Updated successfully',
    'current_password_required': 'Current password is required',
    'password_mismatch': 'Passwords do not match',
    'password_too_short': 'Password must be at least 6 characters',
    'email_updated': 'Email updated successfully',
    'password_updated': 'Password updated successfully',
    'verification_email_sent': 'Verification email sent',

    // Privacy Policy & Terms
    'last_updated': 'Last Updated',
    'effective_date': 'Effective Date',
    'contact_us': 'Contact Us',

    // Data Export
    'export_description': 'You can export all your data as a JSON file.',
    'export_includes': 'Export includes:',
    'export_pets': 'Pet information',
    'export_care': 'Care records',
    'export_weight': 'Weight records',
    'export_button': 'Export Data',
    'exporting': 'Exporting...',
    'export_success': 'Data export completed successfully',
    'export_error': 'Export failed',
    'no_data': 'No data to export',
    'share_data': 'Share Data',
    'share_error': 'Share failed',
    'total_pets': 'Total Pets',
    'total_care_records': 'Total Care Records',
    'total_weight_records': 'Total Weight Records',
    'export_date': 'Export Date',
    'export_preview': 'Export Preview',
    'export_info':
        'The exported file will contain all your data in JSON format. You can use this file to backup your data or import it into other applications.',

    // Additional settings
    'danger_zone': 'Danger Zone',
    'delete_confirmation': 'Type "DELETE" to confirm:',
    'delete_confirmation_error': 'Please type "DELETE"',
    'auth_methods': 'Authentication Methods',
    'password_subtitle': 'Keep your account secure with a strong password',
    'new_email': 'New Email',
    'email_required': 'Email is required',
    'invalid_email': 'Invalid email format',
    'password_required': 'Password is required',
    'account_created': 'Account Created',
    'last_sign_in': 'Last Sign In',
    'account_deleted': 'Account deleted successfully',
    'user_not_logged_in': 'User not logged in',

    // Notifications
    'active': 'Active',
    'scheduled': 'Scheduled',
    'reminders': 'Reminders',
    'add_reminder': 'Add Reminder',
    'edit_reminder': 'Edit Reminder',
    'delete_reminder': 'Delete Reminder',
    'delete_reminder_confirmation':
        'Are you sure you want to delete this reminder?',
    'reminder_deleted': 'Reminder deleted',
    'reminder_created': 'Reminder created',
    'reminder_updated': 'Reminder updated',
    'no_active_notifications': 'No active notifications',
    'notifications_will_appear_here':
        'Notifications will appear here when triggered',
    'no_scheduled_reminders': 'No scheduled reminders',
    'tap_add_to_create_reminder':
        'Tap the + button to create your first reminder',
    'clear_completed': 'Clear Completed',
    'complete': 'Complete',
    'completed': 'Completed!',

    // Notification form
    'select_pet': 'Select Pet',
    'please_select_pet': 'Please select a pet',
    'notification_type': 'Notification Type',
    'title': 'Title',
    'title_required': 'Title is required',
    'description': 'Description',
    'optional': 'Optional',
    'reminder_title_hint': 'Enter reminder title',
    'additional_notes': 'Additional notes or instructions',
    'schedule': 'Schedule',
    'repeat': 'Repeat',
    'save': 'Save',

    // Notification types
    'feeding_reminder': 'Feeding Reminder',
    'bathing_reminder': 'Bathing Reminder',
    'cleaning_reminder': 'Cleaning Reminder',
    'heat_lamp_reminder': 'Heat Lamp Reminder',
    'uv_light_reminder': 'UV Light Reminder',
    'medicine_reminder': 'Medicine Reminder',
    'hospital_reminder': 'Hospital Reminder',
    'health_check_reminder': 'Health Check Reminder',
    'custom_reminder': 'Custom Reminder',
    'notification_settings': 'Notification Settings',
    'notification_sound': 'Notification Sound',
    'notification_priority': 'Notification Priority',
    'notification_style': 'Notification Style',
    'quiet_hours': 'Quiet Hours',
    'physical_alerts': 'Physical Alerts',
    'snooze_settings': 'Snooze Settings',
    'test_notification': 'Test Notification',

    'reset_defaults': 'Reset to Defaults',
    'priority_description':
        'Higher priority notifications appear more prominently',
    'style_description': 'Choose how much information to show in notifications',
    'quiet_hours_description': 'Disable notifications during specific hours',
    'test_description': 'Send a test notification to preview your settings',

    'enable_quiet_hours': 'Enable Quiet Hours',
    'start_time': 'Start Time',
    'end_time': 'End Time',
    'enable_vibration': 'Enable Vibration',
    'vibration_description': 'Vibrate when notifications arrive',
    'enable_led': 'Enable LED Light',
    'led_description': 'Flash LED light for notifications (Android only)',

    'snooze_interval': 'Snooze Interval',
    'minutes': 'minutes',
    'select_snooze_interval': 'Select Snooze Interval',
    'send_test': 'Send Test Notification',
    'test_sent': 'Test notification sent',

    'reset_to_defaults': 'Reset to Defaults',
    'reset_confirmation':
        'Are you sure you want to reset all notification settings to defaults?',
    'reset': 'Reset',
    'settings_reset': 'Settings reset to defaults',

    // Time expressions
    'today': 'Today',
    'tomorrow': 'Tomorrow',
    'overdue': 'Overdue',
    'triggered_at': 'Triggered At',
    'close': 'Close',

    // Pet notification section
    'no_reminders_set': 'No reminders set for this pet',
    'create_reminder': 'Create Reminder',
    'add_another_reminder': 'Add Another Reminder',
    'no_pets_for_reminder': 'Please register a pet first to create reminders',

    // Smart suggestions
    'smart_suggestions': 'Smart Suggestions',
    'suggested_reminders': 'Suggested Reminders',
    'based_on_care_pattern': 'Based on care patterns',

    // Additional missing keys for Pet model
    'pet': 'Pet',
  };
}
