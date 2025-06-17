// lib/models/weight_record.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class WeightRecord {
  final String? id;
  final DateTime date;
  final double weightValue;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  WeightRecord({
    this.id,
    required this.date,
    required this.weightValue,
    this.memo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'weightValue': weightValue,
      'memo': memo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory WeightRecord.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeightRecord(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      weightValue: (data['weightValue'] as num).toDouble(),
      memo: data['memo'],
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
  WeightRecord copyWith({
    String? id,
    DateTime? date,
    double? weightValue,
    String? memo,
    bool clearMemo = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeightRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      weightValue: weightValue ?? this.weightValue,
      memo: clearMemo ? null : (memo ?? this.memo),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
