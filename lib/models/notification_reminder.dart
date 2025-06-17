// lib/models/notification_reminder.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  feeding, // ごはん
  bathing, // 温浴
  cleaning, // お部屋清掃
  heatLamp, // ヒートランプ交換
  uvLight, // 紫外線ライト交換
  medicine, // お薬
  hospital, // 病院
  healthCheck, // 健康診断
  custom, // 自由テキスト
}

enum RepeatInterval {
  once, // 一回のみ
  daily, // 毎日
  weekly, // 毎週
  monthly, // 毎月
  yearly, // 毎年
}

class NotificationReminder {
  final String? id;
  final String petId;
  final NotificationType type;
  final String title;
  final String? description;
  final DateTime scheduledDateTime;
  final RepeatInterval repeatInterval;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationReminder({
    this.id,
    required this.petId,
    required this.type,
    required this.title,
    this.description,
    required this.scheduledDateTime,
    required this.repeatInterval,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
      'repeatInterval': repeatInterval.toString().split('.').last,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory NotificationReminder.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationReminder(
      id: doc.id,
      petId: data['petId'] ?? '',
      type: _typeFromString(data['type'] ?? 'custom'),
      title: data['title'] ?? '',
      description: data['description'],
      scheduledDateTime: (data['scheduledDateTime'] as Timestamp).toDate(),
      repeatInterval: _intervalFromString(data['repeatInterval'] ?? 'once'),
      isActive: data['isActive'] ?? true,
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  // Copy with method
  NotificationReminder copyWith({
    String? id,
    String? petId,
    NotificationType? type,
    String? title,
    String? description,
    bool clearDescription = false,
    DateTime? scheduledDateTime,
    RepeatInterval? repeatInterval,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationReminder(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper methods
  static NotificationType _typeFromString(String value) {
    switch (value) {
      case 'feeding':
        return NotificationType.feeding;
      case 'bathing':
        return NotificationType.bathing;
      case 'cleaning':
        return NotificationType.cleaning;
      case 'heatLamp':
        return NotificationType.heatLamp;
      case 'uvLight':
        return NotificationType.uvLight;
      case 'medicine':
        return NotificationType.medicine;
      case 'hospital':
        return NotificationType.hospital;
      case 'healthCheck':
        return NotificationType.healthCheck;
      default:
        return NotificationType.custom;
    }
  }

  static RepeatInterval _intervalFromString(String value) {
    switch (value) {
      case 'daily':
        return RepeatInterval.daily;
      case 'weekly':
        return RepeatInterval.weekly;
      case 'monthly':
        return RepeatInterval.monthly;
      case 'yearly':
        return RepeatInterval.yearly;
      default:
        return RepeatInterval.once;
    }
  }

  // Get next scheduled time for repeating notifications
  DateTime getNextScheduledTime() {
    if (repeatInterval == RepeatInterval.once) {
      return scheduledDateTime;
    }

    final now = DateTime.now();
    var nextTime = scheduledDateTime;

    // Find the next occurrence
    while (nextTime.isBefore(now)) {
      switch (repeatInterval) {
        case RepeatInterval.daily:
          nextTime = nextTime.add(Duration(days: 1));
          break;
        case RepeatInterval.weekly:
          nextTime = nextTime.add(Duration(days: 7));
          break;
        case RepeatInterval.monthly:
          nextTime = DateTime(
            nextTime.year,
            nextTime.month + 1,
            nextTime.day,
            nextTime.hour,
            nextTime.minute,
          );
          break;
        case RepeatInterval.yearly:
          nextTime = DateTime(
            nextTime.year + 1,
            nextTime.month,
            nextTime.day,
            nextTime.hour,
            nextTime.minute,
          );
          break;
        case RepeatInterval.once:
          break;
      }
    }

    return nextTime;
  }

  // Localized text methods
  static String getTypeText(NotificationType type, {bool isJapanese = true}) {
    if (isJapanese) {
      switch (type) {
        case NotificationType.feeding:
          return 'ごはん';
        case NotificationType.bathing:
          return '温浴';
        case NotificationType.cleaning:
          return 'お部屋清掃';
        case NotificationType.heatLamp:
          return 'ヒートランプ交換';
        case NotificationType.uvLight:
          return '紫外線ライト交換';
        case NotificationType.medicine:
          return 'お薬';
        case NotificationType.hospital:
          return '病院';
        case NotificationType.healthCheck:
          return '健康診断';
        case NotificationType.custom:
          return 'カスタム';
      }
    } else {
      switch (type) {
        case NotificationType.feeding:
          return 'Feeding';
        case NotificationType.bathing:
          return 'Bathing';
        case NotificationType.cleaning:
          return 'Cleaning';
        case NotificationType.heatLamp:
          return 'Heat Lamp';
        case NotificationType.uvLight:
          return 'UV Light';
        case NotificationType.medicine:
          return 'Medicine';
        case NotificationType.hospital:
          return 'Hospital';
        case NotificationType.healthCheck:
          return 'Health Check';
        case NotificationType.custom:
          return 'Custom';
      }
    }
  }

  static String getIntervalText(
    RepeatInterval interval, {
    bool isJapanese = true,
  }) {
    if (isJapanese) {
      switch (interval) {
        case RepeatInterval.once:
          return '一回のみ';
        case RepeatInterval.daily:
          return '毎日';
        case RepeatInterval.weekly:
          return '毎週';
        case RepeatInterval.monthly:
          return '毎月';
        case RepeatInterval.yearly:
          return '毎年';
      }
    } else {
      switch (interval) {
        case RepeatInterval.once:
          return 'Once';
        case RepeatInterval.daily:
          return 'Daily';
        case RepeatInterval.weekly:
          return 'Weekly';
        case RepeatInterval.monthly:
          return 'Monthly';
        case RepeatInterval.yearly:
          return 'Yearly';
      }
    }
  }

  // Get notification icon
  IconData getIcon() {
    switch (type) {
      case NotificationType.feeding:
        return Icons.restaurant;
      case NotificationType.bathing:
        return Icons.bathtub;
      case NotificationType.cleaning:
        return Icons.cleaning_services;
      case NotificationType.heatLamp:
        return Icons.wb_incandescent;
      case NotificationType.uvLight:
        return Icons.wb_sunny;
      case NotificationType.medicine:
        return Icons.medication;
      case NotificationType.hospital:
        return Icons.local_hospital;
      case NotificationType.healthCheck:
        return Icons.health_and_safety;
      case NotificationType.custom:
        return Icons.notifications;
    }
  }

  // Get notification color
  Color getColor() {
    switch (type) {
      case NotificationType.feeding:
        return Colors.orange;
      case NotificationType.bathing:
        return Colors.blue;
      case NotificationType.cleaning:
        return Colors.green;
      case NotificationType.heatLamp:
        return Colors.red;
      case NotificationType.uvLight:
        return Colors.yellow;
      case NotificationType.medicine:
        return Colors.purple;
      case NotificationType.hospital:
        return Colors.red;
      case NotificationType.healthCheck:
        return Colors.teal;
      case NotificationType.custom:
        return Colors.grey;
    }
  }

  // Static extension methods for NotificationType
  static IconData getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.feeding:
        return Icons.restaurant;
      case NotificationType.bathing:
        return Icons.bathtub;
      case NotificationType.cleaning:
        return Icons.cleaning_services;
      case NotificationType.heatLamp:
        return Icons.wb_incandescent;
      case NotificationType.uvLight:
        return Icons.wb_sunny;
      case NotificationType.medicine:
        return Icons.medication;
      case NotificationType.hospital:
        return Icons.local_hospital;
      case NotificationType.healthCheck:
        return Icons.health_and_safety;
      case NotificationType.custom:
        return Icons.notifications;
    }
  }

  static Color getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.feeding:
        return Colors.orange;
      case NotificationType.bathing:
        return Colors.blue;
      case NotificationType.cleaning:
        return Colors.green;
      case NotificationType.heatLamp:
        return Colors.red;
      case NotificationType.uvLight:
        return Colors.yellow;
      case NotificationType.medicine:
        return Colors.purple;
      case NotificationType.hospital:
        return Colors.red;
      case NotificationType.healthCheck:
        return Colors.teal;
      case NotificationType.custom:
        return Colors.grey;
    }
  }
}

// 通知履歴用のモデル
class NotificationHistory {
  final String? id;
  final String petId;
  final String reminderId;
  final NotificationType type;
  final String title;
  final String? description;
  final DateTime triggeredAt;
  final DateTime? completedAt;
  final bool isCompleted;

  NotificationHistory({
    this.id,
    required this.petId,
    required this.reminderId,
    required this.type,
    required this.title,
    this.description,
    required this.triggeredAt,
    this.completedAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'reminderId': reminderId,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'triggeredAt': Timestamp.fromDate(triggeredAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isCompleted': isCompleted,
    };
  }

  factory NotificationHistory.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationHistory(
      id: doc.id,
      petId: data['petId'] ?? '',
      reminderId: data['reminderId'] ?? '',
      type: NotificationReminder._typeFromString(data['type'] ?? 'custom'),
      title: data['title'] ?? '',
      description: data['description'],
      triggeredAt: (data['triggeredAt'] as Timestamp).toDate(),
      completedAt:
          data['completedAt'] != null
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
      isCompleted: data['isCompleted'] ?? false,
    );
  }
}
