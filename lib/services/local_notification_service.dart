// lib/services/local_notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/notification_reminder.dart' as reminder_models;
import '../models/pet.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Initialize the local notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();

    _isInitialized = true;
  }

  // Request notification permissions
  Future<bool> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      return status == PermissionStatus.granted;
    }
    return true;
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Navigate to appropriate screen based on payload
  }

  // Schedule a notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reptitrack_reminders',
          'ReptiTrack Reminders',
          channelDescription: 'Reminders for pet care activities',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTZ,
      notificationDetails,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Schedule repeating notification
  Future<void> scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required reminder_models.RepeatInterval interval,
    required DateTime firstScheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reptitrack_reminders',
          'ReptiTrack Reminders',
          channelDescription: 'Reminders for pet care activities',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(
      firstScheduledDate,
      tz.local,
    );

    // Convert RepeatInterval to DateTimeComponents
    DateTimeComponents? dateTimeComponents;
    switch (interval) {
      case reminder_models.RepeatInterval.daily:
        dateTimeComponents = DateTimeComponents.time;
        break;
      case reminder_models.RepeatInterval.weekly:
        dateTimeComponents = DateTimeComponents.dayOfWeekAndTime;
        break;
      case reminder_models.RepeatInterval.monthly:
        dateTimeComponents = DateTimeComponents.dayOfMonthAndTime;
        break;
      case reminder_models.RepeatInterval.yearly:
        dateTimeComponents = DateTimeComponents.dateAndTime;
        break;
      case reminder_models.RepeatInterval.once:
        // For one-time notifications, use the regular schedule method
        await scheduleNotification(
          id: id,
          title: title,
          body: body,
          scheduledDate: firstScheduledDate,
          payload: payload,
        );
        return;
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTZ,
      notificationDetails,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: dateTimeComponents,
    );
  }

  // Cancel a notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Show immediate notification
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reptitrack_immediate',
          'ReptiTrack Immediate',
          channelDescription: 'Immediate notifications from ReptiTrack',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Helper method to generate notification ID from reminder ID
  static int generateNotificationId(String reminderId) {
    return reminderId.hashCode;
  }

  // Generate notification content for reminder
  static Map<String, String> generateNotificationContent(
    reminder_models.NotificationReminder reminder,
    Pet pet, {
    bool isJapanese = true,
  }) {
    final petName = pet.name;
    String title;
    String body;

    if (isJapanese) {
      if (reminder.type == reminder_models.NotificationType.custom) {
        title = reminder.title;
        body = '$petNameの${reminder.title}の時間です！';
      } else {
        final typeText = reminder_models.NotificationReminder.getTypeText(
          reminder.type,
          isJapanese: true,
        );
        title = '$petNameの$typeText';
        body = '$typeTextの時間です！';
      }

      if (reminder.description?.isNotEmpty == true) {
        body += '\n${reminder.description}';
      }
    } else {
      if (reminder.type == reminder_models.NotificationType.custom) {
        title = reminder.title;
        body = 'Time for $petName\'s ${reminder.title}!';
      } else {
        final typeText = reminder_models.NotificationReminder.getTypeText(
          reminder.type,
          isJapanese: false,
        );
        title = '$petName $typeText';
        body = 'Time for ${typeText.toLowerCase()}!';
      }

      if (reminder.description?.isNotEmpty == true) {
        body += '\n${reminder.description}';
      }
    }

    return {'title': title, 'body': body};
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status == PermissionStatus.granted;
  }

  // Open app settings for notification permissions
  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }
}
