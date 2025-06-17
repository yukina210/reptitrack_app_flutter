// lib/models/notification_reminder_extensions.dart
import 'package:flutter/material.dart';
import 'notification_reminder.dart';

extension NotificationTypeExtensions on NotificationType {
  IconData getIcon() {
    switch (this) {
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

  Color getColor() {
    switch (this) {
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
