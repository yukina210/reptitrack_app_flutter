// lib/services/notification_customization_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_notification_service.dart';

enum NotificationSound {
  defaultSound,
  bell,
  chime,
  ding,
  chirp,
  gentle,
  custom,
}

enum NotificationPriority { low, medium, high, urgent }

enum NotificationStyle { simple, detailed, minimal, rich }

class NotificationCustomizationService {
  static const String _soundPreferenceKey = 'notification_sound';
  static const String _priorityPreferenceKey = 'notification_priority';
  static const String _stylePreferenceKey = 'notification_style';
  static const String _quietHoursStartKey = 'quiet_hours_start';
  static const String _quietHoursEndKey = 'quiet_hours_end';
  static const String _enableQuietHoursKey = 'enable_quiet_hours';
  static const String _enableVibrationKey = 'enable_vibration';
  static const String _enableLedKey = 'enable_led';
  static const String _snoozeIntervalKey = 'snooze_interval';

  late SharedPreferences _prefs;

  // Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Notification Sound Settings
  NotificationSound get notificationSound {
    final soundIndex = _prefs.getInt(_soundPreferenceKey) ?? 0;
    return NotificationSound.values[soundIndex];
  }

  Future<void> setNotificationSound(NotificationSound sound) async {
    await _prefs.setInt(_soundPreferenceKey, sound.index);
  }

  // Notification Priority Settings
  NotificationPriority get notificationPriority {
    final priorityIndex =
        _prefs.getInt(_priorityPreferenceKey) ?? 2; // Default to high
    return NotificationPriority.values[priorityIndex];
  }

  Future<void> setNotificationPriority(NotificationPriority priority) async {
    await _prefs.setInt(_priorityPreferenceKey, priority.index);
  }

  // Notification Style Settings
  NotificationStyle get notificationStyle {
    final styleIndex =
        _prefs.getInt(_stylePreferenceKey) ?? 1; // Default to detailed
    return NotificationStyle.values[styleIndex];
  }

  Future<void> setNotificationStyle(NotificationStyle style) async {
    await _prefs.setInt(_stylePreferenceKey, style.index);
  }

  // Quiet Hours Settings
  bool get isQuietHoursEnabled {
    return _prefs.getBool(_enableQuietHoursKey) ?? false;
  }

  Future<void> setQuietHoursEnabled(bool enabled) async {
    await _prefs.setBool(_enableQuietHoursKey, enabled);
  }

  TimeOfDay get quietHoursStart {
    final hour = _prefs.getInt('${_quietHoursStartKey}_hour') ?? 22;
    final minute = _prefs.getInt('${_quietHoursStartKey}_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setQuietHoursStart(TimeOfDay time) async {
    await _prefs.setInt('${_quietHoursStartKey}_hour', time.hour);
    await _prefs.setInt('${_quietHoursStartKey}_minute', time.minute);
  }

  TimeOfDay get quietHoursEnd {
    final hour = _prefs.getInt('${_quietHoursEndKey}_hour') ?? 8;
    final minute = _prefs.getInt('${_quietHoursEndKey}_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setQuietHoursEnd(TimeOfDay time) async {
    await _prefs.setInt('${_quietHoursEndKey}_hour', time.hour);
    await _prefs.setInt('${_quietHoursEndKey}_minute', time.minute);
  }

  // Vibration Settings
  bool get isVibrationEnabled {
    return _prefs.getBool(_enableVibrationKey) ?? true;
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    await _prefs.setBool(_enableVibrationKey, enabled);
  }

  // LED Settings (Android)
  bool get isLedEnabled {
    return _prefs.getBool(_enableLedKey) ?? true;
  }

  Future<void> setLedEnabled(bool enabled) async {
    await _prefs.setBool(_enableLedKey, enabled);
  }

  // Snooze Interval Settings
  int get snoozeInterval {
    return _prefs.getInt(_snoozeIntervalKey) ?? 10; // Default 10 minutes
  }

  Future<void> setSnoozeInterval(int minutes) async {
    await _prefs.setInt(_snoozeIntervalKey, minutes);
  }

  // Check if current time is in quiet hours
  bool isInQuietHours() {
    if (!isQuietHoursEnabled) return false;

    final now = TimeOfDay.now();
    final start = quietHoursStart;
    final end = quietHoursEnd;

    // Handle overnight quiet hours (e.g., 22:00 to 08:00)
    if (start.hour > end.hour) {
      return (now.hour >= start.hour) ||
          (now.hour < end.hour) ||
          (now.hour == start.hour && now.minute >= start.minute) ||
          (now.hour == end.hour && now.minute < end.minute);
    } else {
      // Same day quiet hours (e.g., 12:00 to 14:00)
      final nowMinutes = now.hour * 60 + now.minute;
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }
  }

  // Get notification content based on style
  Map<String, String> getStyledNotificationContent(
    String title,
    String body,
    String petName,
    String reminderType,
  ) {
    switch (notificationStyle) {
      case NotificationStyle.simple:
        return {'title': title, 'body': body};

      case NotificationStyle.detailed:
        return {
          'title': title,
          'body': '$body\n\n🐢 ペット: $petName\n⏰ 種類: $reminderType',
        };

      case NotificationStyle.minimal:
        return {'title': petName, 'body': reminderType};

      case NotificationStyle.rich:
        final icon = _getReminderIcon(reminderType);
        return {
          'title': '$icon $title',
          'body': '🐢 $petName\n⏰ $reminderType\n\n$body',
        };
    }
  }

  String _getReminderIcon(String reminderType) {
    switch (reminderType.toLowerCase()) {
      case 'ごはん':
      case 'feeding':
        return '🍖';
      case '温浴':
      case 'bathing':
        return '🛁';
      case 'お部屋清掃':
      case 'cleaning':
        return '🧹';
      case 'ヒートランプ交換':
      case 'heat lamp':
        return '💡';
      case '紫外線ライト交換':
      case 'uv light':
        return '☀️';
      case 'お薬':
      case 'medicine':
        return '💊';
      case '病院':
      case 'hospital':
        return '🏥';
      case '健康診断':
      case 'health check':
        return '⚕️';
      default:
        return '🔔';
    }
  }

  // Get sound file name based on selection
  String? getSoundFileName() {
    switch (notificationSound) {
      case NotificationSound.defaultSound:
        return null; // Use system default
      case NotificationSound.bell:
        return 'notification_bell.mp3';
      case NotificationSound.chime:
        return 'notification_chime.mp3';
      case NotificationSound.ding:
        return 'notification_ding.mp3';
      case NotificationSound.chirp:
        return 'notification_chirp.mp3';
      case NotificationSound.gentle:
        return 'notification_gentle.mp3';
      case NotificationSound.custom:
        return _prefs.getString('custom_sound_path');
    }
  }

  // Get text for notification settings
  static String getSoundText(
    NotificationSound sound, {
    bool isJapanese = true,
  }) {
    if (isJapanese) {
      switch (sound) {
        case NotificationSound.defaultSound:
          return 'デフォルト';
        case NotificationSound.bell:
          return 'ベル';
        case NotificationSound.chime:
          return 'チャイム';
        case NotificationSound.ding:
          return 'ディン';
        case NotificationSound.chirp:
          return 'チャープ';
        case NotificationSound.gentle:
          return 'やさしい音';
        case NotificationSound.custom:
          return 'カスタム';
      }
    } else {
      switch (sound) {
        case NotificationSound.defaultSound:
          return 'Default';
        case NotificationSound.bell:
          return 'Bell';
        case NotificationSound.chime:
          return 'Chime';
        case NotificationSound.ding:
          return 'Ding';
        case NotificationSound.chirp:
          return 'Chirp';
        case NotificationSound.gentle:
          return 'Gentle';
        case NotificationSound.custom:
          return 'Custom';
      }
    }
  }

  static String getPriorityText(
    NotificationPriority priority, {
    bool isJapanese = true,
  }) {
    if (isJapanese) {
      switch (priority) {
        case NotificationPriority.low:
          return '低';
        case NotificationPriority.medium:
          return '中';
        case NotificationPriority.high:
          return '高';
        case NotificationPriority.urgent:
          return '緊急';
      }
    } else {
      switch (priority) {
        case NotificationPriority.low:
          return 'Low';
        case NotificationPriority.medium:
          return 'Medium';
        case NotificationPriority.high:
          return 'High';
        case NotificationPriority.urgent:
          return 'Urgent';
      }
    }
  }

  static String getStyleText(
    NotificationStyle style, {
    bool isJapanese = true,
  }) {
    if (isJapanese) {
      switch (style) {
        case NotificationStyle.simple:
          return 'シンプル';
        case NotificationStyle.detailed:
          return '詳細';
        case NotificationStyle.minimal:
          return 'ミニマル';
        case NotificationStyle.rich:
          return 'リッチ';
      }
    } else {
      switch (style) {
        case NotificationStyle.simple:
          return 'Simple';
        case NotificationStyle.detailed:
          return 'Detailed';
        case NotificationStyle.minimal:
          return 'Minimal';
        case NotificationStyle.rich:
          return 'Rich';
      }
    }
  }

  // Test notification
  Future<void> sendTestNotification() async {
    final localNotificationService = LocalNotificationService();

    final content = getStyledNotificationContent(
      'テスト通知',
      'これはテスト通知です。設定が正しく適用されているか確認してください。',
      'テストペット',
      'ごはん',
    );

    await localNotificationService.showImmediateNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: content['title']!,
      body: content['body']!,
      payload: 'test_notification',
    );
  }

  // Apply customization to notification
  Future<Map<String, dynamic>> getCustomizedNotificationDetails({
    required String title,
    required String body,
    required String petName,
    required String reminderType,
  }) async {
    // Check quiet hours
    if (isInQuietHours()) {
      return {'shouldSkip': true, 'reason': 'quiet_hours'};
    }

    final content = getStyledNotificationContent(
      title,
      body,
      petName,
      reminderType,
    );

    return {
      'shouldSkip': false,
      'title': content['title']!,
      'body': content['body']!,
      'sound': getSoundFileName(),
      'vibration': isVibrationEnabled,
      'led': isLedEnabled,
      'priority': notificationPriority,
      'style': notificationStyle,
    };
  }

  // Reset all settings to default
  Future<void> resetToDefaults() async {
    await _prefs.remove(_soundPreferenceKey);
    await _prefs.remove(_priorityPreferenceKey);
    await _prefs.remove(_stylePreferenceKey);
    await _prefs.remove(_quietHoursStartKey);
    await _prefs.remove(_quietHoursEndKey);
    await _prefs.remove(_enableQuietHoursKey);
    await _prefs.remove(_enableVibrationKey);
    await _prefs.remove(_enableLedKey);
    await _prefs.remove(_snoozeIntervalKey);
  }
}
