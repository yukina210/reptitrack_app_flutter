// lib/models/care_record.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum FoodStatus { completed, leftover, refused }

enum MatingStatus { success, rejected }

class CareRecord {
  final String? id;
  final DateTime date;
  final TimeOfDay? time;
  final FoodStatus? foodStatus;
  final String? foodType;
  final bool excretion;
  final bool shedding;
  final bool vomiting;
  final bool bathing;
  final bool cleaning;
  final MatingStatus? matingStatus;
  final bool layingEggs;
  final String? otherNote;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  CareRecord({
    this.id,
    required this.date,
    this.time,
    this.foodStatus,
    this.foodType,
    this.excretion = false,
    this.shedding = false,
    this.vomiting = false,
    this.bathing = false,
    this.cleaning = false,
    this.matingStatus,
    this.layingEggs = false,
    this.otherNote,
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'time':
          time != null ? {'hour': time!.hour, 'minute': time!.minute} : null,
      'foodStatus': foodStatus?.toString().split('.').last,
      'foodType': foodType,
      'excretion': excretion,
      'shedding': shedding,
      'vomiting': vomiting,
      'bathing': bathing,
      'cleaning': cleaning,
      'matingStatus': matingStatus?.toString().split('.').last,
      'layingEggs': layingEggs,
      'otherNote': otherNote,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory CareRecord.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CareRecord(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      time:
          data['time'] != null
              ? TimeOfDay(
                hour: data['time']['hour'],
                minute: data['time']['minute'],
              )
              : null,
      foodStatus: _foodStatusFromString(data['foodStatus']),
      foodType: data['foodType'],
      excretion: data['excretion'] ?? false,
      shedding: data['shedding'] ?? false,
      vomiting: data['vomiting'] ?? false,
      bathing: data['bathing'] ?? false,
      cleaning: data['cleaning'] ?? false,
      matingStatus: _matingStatusFromString(data['matingStatus']),
      layingEggs: data['layingEggs'] ?? false,
      otherNote: data['otherNote'],
      tags: List<String>.from(data['tags'] ?? []),
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
  CareRecord copyWith({
    String? id,
    DateTime? date,
    TimeOfDay? time,
    bool clearTime = false,
    FoodStatus? foodStatus,
    bool clearFoodStatus = false,
    String? foodType,
    bool clearFoodType = false,
    bool? excretion,
    bool? shedding,
    bool? vomiting,
    bool? bathing,
    bool? cleaning,
    MatingStatus? matingStatus,
    bool clearMatingStatus = false,
    bool? layingEggs,
    String? otherNote,
    bool clearOtherNote = false,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CareRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      time: clearTime ? null : (time ?? this.time),
      foodStatus: clearFoodStatus ? null : (foodStatus ?? this.foodStatus),
      foodType: clearFoodType ? null : (foodType ?? this.foodType),
      excretion: excretion ?? this.excretion,
      shedding: shedding ?? this.shedding,
      vomiting: vomiting ?? this.vomiting,
      bathing: bathing ?? this.bathing,
      cleaning: cleaning ?? this.cleaning,
      matingStatus:
          clearMatingStatus ? null : (matingStatus ?? this.matingStatus),
      layingEggs: layingEggs ?? this.layingEggs,
      otherNote: clearOtherNote ? null : (otherNote ?? this.otherNote),
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper methods
  static FoodStatus? _foodStatusFromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'completed':
        return FoodStatus.completed;
      case 'leftover':
        return FoodStatus.leftover;
      case 'refused':
        return FoodStatus.refused;
      default:
        return null;
    }
  }

  static MatingStatus? _matingStatusFromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'success':
        return MatingStatus.success;
      case 'rejected':
        return MatingStatus.rejected;
      default:
        return null;
    }
  }

  // Localized text methods
  static String getFoodStatusText(FoodStatus status, {bool isJapanese = true}) {
    if (isJapanese) {
      switch (status) {
        case FoodStatus.completed:
          return '完食';
        case FoodStatus.leftover:
          return '食べ残し';
        case FoodStatus.refused:
          return '拒食';
      }
    } else {
      switch (status) {
        case FoodStatus.completed:
          return 'Completed';
        case FoodStatus.leftover:
          return 'Leftover';
        case FoodStatus.refused:
          return 'Refused';
      }
    }
  }

  static String getMatingStatusText(
    MatingStatus status, {
    bool isJapanese = true,
  }) {
    if (isJapanese) {
      switch (status) {
        case MatingStatus.success:
          return '成功';
        case MatingStatus.rejected:
          return '拒絶';
      }
    } else {
      switch (status) {
        case MatingStatus.success:
          return 'Success';
        case MatingStatus.rejected:
          return 'Rejected';
      }
    }
  }

  // Check if record has any care items
  bool get hasAnyCareItems {
    return foodStatus != null ||
        excretion ||
        shedding ||
        vomiting ||
        bathing ||
        cleaning ||
        matingStatus != null ||
        layingEggs ||
        (otherNote?.isNotEmpty ?? false);
  }

  // Get care items as icons for display
  List<String> get careIcons {
    List<String> icons = [];

    if (foodStatus != null) {
      if (foodStatus == FoodStatus.refused) {
        icons.add('assets/icons/food_refusal.png');
      } else {
        icons.add('assets/icons/feeding.png');
      }
    }

    if (vomiting) icons.add('assets/icons/regurgitation.png');
    if (excretion) icons.add('assets/icons/excretion.png');
    if (shedding) icons.add('assets/icons/shedding.png');
    if (bathing) icons.add('assets/icons/bathing.png');
    if (cleaning) icons.add('assets/icons/habitat_cleaning.png');
    if (matingStatus != null) icons.add('assets/icons/mating.png');
    if (layingEggs) icons.add('assets/icons/egg_laying.png');
    if (otherNote?.isNotEmpty ?? false) icons.add('assets/icons/note.png');

    return icons;
  }
}
