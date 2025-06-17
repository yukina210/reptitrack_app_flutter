// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/notification_reminder.dart';
import '../models/pet.dart';
import 'local_notification_service.dart';
import 'settings_service.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  final SettingsService? settingsService;

  List<NotificationHistory> _activeNotifications = [];
  List<NotificationReminder> _reminders = [];

  NotificationService({required this.userId, this.settingsService}) {
    _loadActiveNotifications();
    _loadReminders();
  }

  List<NotificationHistory> get activeNotifications => _activeNotifications;
  List<NotificationReminder> get reminders => _reminders;
  int get notificationCount =>
      _activeNotifications.where((n) => !n.isCompleted).length;

  // Collection references
  CollectionReference get _remindersCollection => _firestore
      .collection('users')
      .doc(userId)
      .collection('notification_reminders');

  CollectionReference get _historyCollection => _firestore
      .collection('users')
      .doc(userId)
      .collection('notification_history');

  // Load active notifications
  Future<void> _loadActiveNotifications() async {
    try {
      final snapshot =
          await _historyCollection
              .where('isCompleted', isEqualTo: false)
              .orderBy('triggeredAt', descending: true)
              .get();

      _activeNotifications =
          snapshot.docs
              .map((doc) => NotificationHistory.fromDocument(doc))
              .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading active notifications: $e');
    }
  }

  // Load reminders
  Future<void> _loadReminders() async {
    try {
      final snapshot =
          await _remindersCollection
              .where('isActive', isEqualTo: true)
              .orderBy('scheduledDateTime')
              .get();

      _reminders =
          snapshot.docs
              .map((doc) => NotificationReminder.fromDocument(doc))
              .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading reminders: $e');
    }
  }

  // Get reminders for a specific pet
  Stream<List<NotificationReminder>> getRemindersForPet(String petId) {
    return _remindersCollection
        .where('petId', isEqualTo: petId)
        .where('isActive', isEqualTo: true)
        .orderBy('scheduledDateTime')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => NotificationReminder.fromDocument(doc))
                  .toList(),
        );
  }

  // Add new reminder
  Future<String?> addReminder(NotificationReminder reminder) async {
    try {
      final docRef = await _remindersCollection.add(reminder.toMap());

      // Schedule local notification if needed
      await _scheduleLocalNotification(reminder.copyWith(id: docRef.id));

      await _loadReminders();
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding reminder: $e');
      return null;
    }
  }

  // Update reminder
  Future<bool> updateReminder(NotificationReminder reminder) async {
    try {
      if (reminder.id == null) return false;

      await _remindersCollection.doc(reminder.id).update(reminder.toMap());

      // Reschedule local notification
      await _scheduleLocalNotification(reminder);

      await _loadReminders();
      return true;
    } catch (e) {
      debugPrint('Error updating reminder: $e');
      return false;
    }
  }

  // Delete reminder
  Future<bool> deleteReminder(String reminderId) async {
    try {
      await _remindersCollection.doc(reminderId).delete();

      // Cancel local notification
      await _cancelLocalNotification(reminderId);

      await _loadReminders();
      return true;
    } catch (e) {
      debugPrint('Error deleting reminder: $e');
      return false;
    }
  }

  // Complete notification
  Future<bool> completeNotification(String notificationId) async {
    try {
      await _historyCollection.doc(notificationId).update({
        'isCompleted': true,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });

      await _loadActiveNotifications();
      return true;
    } catch (e) {
      debugPrint('Error completing notification: $e');
      return false;
    }
  }

  // Trigger notification (called by background service or manually)
  Future<String?> triggerNotification(
    NotificationReminder reminder,
    Pet pet,
  ) async {
    try {
      final notification = NotificationHistory(
        petId: reminder.petId,
        reminderId: reminder.id!,
        type: reminder.type,
        title: _generateNotificationTitle(reminder, pet),
        description: reminder.description,
        triggeredAt: DateTime.now(),
      );

      final docRef = await _historyCollection.add(notification.toMap());

      // Schedule next occurrence for repeating reminders
      if (reminder.repeatInterval != RepeatInterval.once) {
        final nextTime = reminder.getNextScheduledTime();
        final updatedReminder = reminder.copyWith(scheduledDateTime: nextTime);
        await updateReminder(updatedReminder);
      } else {
        // Deactivate one-time reminders
        await updateReminder(reminder.copyWith(isActive: false));
      }

      await _loadActiveNotifications();
      return docRef.id;
    } catch (e) {
      debugPrint('Error triggering notification: $e');
      return null;
    }
  }

  // Generate notification title
  String _generateNotificationTitle(NotificationReminder reminder, Pet pet) {
    final petName = pet.name;

    // settingsServiceがnullの場合はデフォルトで日本語を使用
    final isJapanese = settingsService?.currentLanguage == AppLanguage.japanese;

    if (reminder.type == NotificationType.custom) {
      return reminder.title;
    }

    final typeText = NotificationReminder.getTypeText(
      reminder.type,
      isJapanese: isJapanese,
    );

    if (isJapanese) {
      return '$petNameの$typeTextの時間です！';
    } else {
      return 'Time for $petName\'s ${typeText.toLowerCase()}!';
    }
  }

  // Check for due notifications (called periodically)
  Future<void> checkDueNotifications() async {
    final now = DateTime.now();

    for (final reminder in _reminders) {
      if (reminder.isActive && reminder.getNextScheduledTime().isBefore(now)) {
        // Get pet information
        try {
          final petDoc =
              await _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('pets')
                  .doc(reminder.petId)
                  .get();

          if (petDoc.exists) {
            final pet = Pet.fromDocument(petDoc);
            await triggerNotification(reminder, pet);
          }
        } catch (e) {
          debugPrint('Error checking due notification: $e');
        }
      }
    }
  }

  // Smart reminder suggestions based on care records
  Future<List<NotificationReminder>> generateSmartReminders(
    String petId,
    Pet pet,
  ) async {
    final suggestions = <NotificationReminder>[];

    // Check last feeding time
    final lastFeeding = await _getLastCareRecord(petId, 'feeding');
    if (lastFeeding != null) {
      final hoursSinceFeeding = DateTime.now().difference(lastFeeding).inHours;

      // Suggest feeding reminder based on pet type
      if (hoursSinceFeeding > _getRecommendedFeedingInterval(pet.category)) {
        // settingsServiceがnullの場合はデフォルトで日本語を使用
        final isJapanese =
            settingsService?.currentLanguage == AppLanguage.japanese;

        suggestions.add(
          NotificationReminder(
            petId: petId,
            type: NotificationType.feeding,
            title:
                isJapanese ? '${pet.name}のごはんタイム' : '${pet.name} Feeding Time',
            scheduledDateTime: DateTime.now().add(Duration(hours: 24)),
            repeatInterval: RepeatInterval.daily,
          ),
        );
      }
    }

    // Add more smart suggestions based on pet care patterns

    return suggestions;
  }

  // Helper methods
  Future<DateTime?> _getLastCareRecord(String petId, String type) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('pets')
              .doc(petId)
              .collection('care_records')
              .where('food_status', isNotEqualTo: null)
              .orderBy('date', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return (snapshot.docs.first.data()['date'] as Timestamp).toDate();
      }
    } catch (e) {
      debugPrint('Error getting last care record: $e');
    }
    return null;
  }

  int _getRecommendedFeedingInterval(Category category) {
    // Recommended feeding intervals in hours
    switch (category) {
      case Category.snake:
        return 168; // 1 week
      case Category.lizard:
        return 24; // daily
      case Category.gecko:
        return 48; // every 2 days
      case Category.turtle:
        return 24; // daily
      case Category.chameleon:
        return 24; // daily
      case Category.crocodile:
        return 72; // every 3 days
      default:
        return 48; // default 2 days
    }
  }

  // Local notification methods
  Future<void> _scheduleLocalNotification(NotificationReminder reminder) async {
    try {
      final localNotificationService = LocalNotificationService();

      // Get pet information for notification content
      final petDoc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('pets')
              .doc(reminder.petId)
              .get();

      if (!petDoc.exists) return;

      final pet = Pet.fromDocument(petDoc);

      // settingsServiceがnullの場合はデフォルトで日本語を使用
      final isJapanese =
          settingsService?.currentLanguage == AppLanguage.japanese;

      final notificationContent =
          LocalNotificationService.generateNotificationContent(
            reminder,
            pet,
            isJapanese: isJapanese,
          );

      final notificationId = LocalNotificationService.generateNotificationId(
        reminder.id!,
      );

      if (reminder.repeatInterval == RepeatInterval.once) {
        await localNotificationService.scheduleNotification(
          id: notificationId,
          title: notificationContent['title']!,
          body: notificationContent['body']!,
          scheduledDate: reminder.scheduledDateTime,
          payload: '${reminder.id}|${reminder.petId}',
        );
      } else {
        await localNotificationService.scheduleRepeatingNotification(
          id: notificationId,
          title: notificationContent['title']!,
          body: notificationContent['body']!,
          interval: reminder.repeatInterval,
          firstScheduledDate: reminder.scheduledDateTime,
          payload: '${reminder.id}|${reminder.petId}',
        );
      }

      debugPrint('Scheduled local notification for: ${reminder.title}');
    } catch (e) {
      debugPrint('Error scheduling local notification: $e');
    }
  }

  Future<void> _cancelLocalNotification(String reminderId) async {
    try {
      final localNotificationService = LocalNotificationService();
      final notificationId = LocalNotificationService.generateNotificationId(
        reminderId,
      );
      await localNotificationService.cancelNotification(notificationId);
      debugPrint('Cancelled local notification for: $reminderId');
    } catch (e) {
      debugPrint('Error cancelling local notification: $e');
    }
  }

  // Clear all completed notifications
  Future<void> clearCompletedNotifications() async {
    try {
      final completedDocs =
          await _historyCollection.where('isCompleted', isEqualTo: true).get();

      final batch = _firestore.batch();
      for (final doc in completedDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      await _loadActiveNotifications();
    } catch (e) {
      debugPrint('Error clearing completed notifications: $e');
    }
  }
}
