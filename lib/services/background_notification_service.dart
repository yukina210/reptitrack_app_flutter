// lib/services/background_notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import 'local_notification_service.dart';
import 'notification_service.dart';

class BackgroundNotificationService {
  static const String _taskIdentifier =
      'com.example.reptitrack-app.notification-check';
  static Timer? _backgroundTimer;
  static bool _isInitialized = false;

  // Initialize background service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register background task handler
      await _registerBackgroundTaskHandler();

      // Schedule periodic notification check
      _schedulePeriodicCheck();

      _isInitialized = true;
      debugPrint('Background notification service initialized');
    } catch (e) {
      debugPrint('Error initializing background service: $e');
    }
  }

  // Register background task handler for iOS
  static Future<void> _registerBackgroundTaskHandler() async {
    // iOS specific background task registration
    if (Theme.of(WidgetsBinding.instance.rootElement!).platform ==
        TargetPlatform.iOS) {
      try {
        const MethodChannel channel = MethodChannel('background_tasks');
        await channel.invokeMethod('registerBackgroundTask', {
          'identifier': _taskIdentifier,
          'handler': 'checkNotifications',
        });
      } catch (e) {
        debugPrint('Failed to register background task: $e');
      }
    }
  }

  // Schedule periodic notification check
  static void _schedulePeriodicCheck() {
    // Check every 5 minutes when app is active
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      checkDueNotifications(); // パブリックメソッドを呼び出し
    });
  }

  // Check for due notifications - パブリックメソッドとして公開
  static Future<void> checkDueNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notificationService = NotificationService(userId: user.uid);
      await notificationService.checkDueNotifications();

      debugPrint('Background notification check completed');
    } catch (e) {
      debugPrint('Error checking notifications in background: $e');
    }
  }

  // Smart notification scheduling
  static Future<void> scheduleSmartNotifications(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Get all pets for the user
      final petsSnapshot =
          await firestore
              .collection('users')
              .doc(userId)
              .collection('pets')
              .get();

      for (final petDoc in petsSnapshot.docs) {
        final pet = Pet.fromDocument(petDoc);
        await _analyzeAndScheduleForPet(userId, pet);
      }
    } catch (e) {
      debugPrint('Error scheduling smart notifications: $e');
    }
  }

  // Analyze pet care patterns and suggest notifications
  static Future<void> _analyzeAndScheduleForPet(String userId, Pet pet) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(Duration(days: 7));

      // Analyze feeding patterns
      final feedingRecords =
          await firestore
              .collection('users')
              .doc(userId)
              .collection('pets')
              .doc(pet.id!)
              .collection('care_records')
              .where('food_status', isNotEqualTo: null)
              .where('date', isGreaterThan: Timestamp.fromDate(oneWeekAgo))
              .orderBy('date', descending: true)
              .get();

      if (feedingRecords.docs.isNotEmpty) {
        await _suggestFeedingReminder(userId, pet, feedingRecords.docs);
      }

      // Analyze weight recording patterns
      final weightRecords =
          await firestore
              .collection('users')
              .doc(userId)
              .collection('pets')
              .doc(pet.id!)
              .collection('weight_records')
              .where('date', isGreaterThan: Timestamp.fromDate(oneWeekAgo))
              .orderBy('date', descending: true)
              .get();

      if (weightRecords.docs.isEmpty) {
        await _suggestWeightCheckReminder(userId, pet);
      }
    } catch (e) {
      debugPrint('Error analyzing pet care patterns: $e');
    }
  }

  // Suggest feeding reminder based on patterns
  static Future<void> _suggestFeedingReminder(
    String userId,
    Pet pet,
    List<QueryDocumentSnapshot> feedingRecords,
  ) async {
    try {
      final lastFeeding =
          (feedingRecords.first.data() as Map<String, dynamic>)['date']
              as Timestamp;
      final lastFeedingDate = lastFeeding.toDate();
      final hoursSinceFeeding =
          DateTime.now().difference(lastFeedingDate).inHours;

      // Get recommended feeding interval based on pet category
      final recommendedInterval = _getRecommendedFeedingInterval(pet.category);

      if (hoursSinceFeeding > recommendedInterval) {
        // Trigger immediate feeding reminder
        final localNotificationService = LocalNotificationService();
        await localNotificationService.showImmediateNotification(
          id: DateTime.now().millisecondsSinceEpoch,
          title: '${pet.name}のごはん時間です',
          body: '最後の食事から$hoursSinceFeeding時間経過しています。',
          payload: 'smart_feeding|${pet.id}',
        );
      }
    } catch (e) {
      debugPrint('Error suggesting feeding reminder: $e');
    }
  }

  // Suggest weight check reminder
  static Future<void> _suggestWeightCheckReminder(
    String userId,
    Pet pet,
  ) async {
    try {
      final localNotificationService = LocalNotificationService();
      await localNotificationService.showImmediateNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: '${pet.name}の体重測定',
        body: '最近体重を測定していません。健康管理のため体重を記録しませんか？',
        payload: 'smart_weight|${pet.id}',
      );
    } catch (e) {
      debugPrint('Error suggesting weight check reminder: $e');
    }
  }

  // Get recommended feeding interval in hours
  static int _getRecommendedFeedingInterval(Category category) {
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

  // Handle notification actions (from notification center)
  static Future<void> handleNotificationAction(String payload) async {
    try {
      final parts = payload.split('|');
      if (parts.length < 2) return;

      final actionType = parts[0];
      final petId = parts[1];

      switch (actionType) {
        case 'smart_feeding':
          await _handleFeedingAction(petId);
          break;
        case 'smart_weight':
          await _handleWeightAction(petId);
          break;
        case 'reminder_complete':
          await _handleReminderComplete(parts[2]); // reminder ID
          break;
      }
    } catch (e) {
      debugPrint('Error handling notification action: $e');
    }
  }

  static Future<void> _handleFeedingAction(String petId) async {
    // Navigate to feeding record screen or mark as fed
    debugPrint('Handling feeding action for pet: $petId');
  }

  static Future<void> _handleWeightAction(String petId) async {
    // Navigate to weight recording screen
    debugPrint('Handling weight action for pet: $petId');
  }

  static Future<void> _handleReminderComplete(String reminderId) async {
    // Mark reminder as completed
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notificationService = NotificationService(userId: user.uid);
      await notificationService.completeNotification(reminderId);
    } catch (e) {
      debugPrint('Error completing reminder: $e');
    }
  }

  // Clean up resources
  static void dispose() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    _isInitialized = false;
  }

  // Enable/disable background notifications
  static Future<void> setBackgroundNotificationsEnabled(bool enabled) async {
    try {
      if (enabled) {
        await initialize();
      } else {
        dispose();
      }
    } catch (e) {
      debugPrint('Error setting background notifications: $e');
    }
  }

  // Check if background notifications are supported
  static Future<bool> isBackgroundNotificationSupported() async {
    try {
      const MethodChannel channel = MethodChannel('background_tasks');
      final result = await channel.invokeMethod<bool>('isSupported') ?? false;
      return result;
    } catch (e) {
      debugPrint('Error checking background support: $e');
      return false;
    }
  }
}
