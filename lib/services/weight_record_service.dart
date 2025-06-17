// lib/services/weight_record_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/weight_record.dart';

class WeightRecordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  final String petId;

  WeightRecordService({required this.userId, required this.petId});

  // Collection reference for weight records
  CollectionReference get _weightRecordsCollection => _firestore
      .collection('users')
      .doc(userId)
      .collection('pets')
      .doc(petId)
      .collection('weight_records');

  // Get all weight records for current pet
  Stream<List<WeightRecord>> getWeightRecords() {
    return _weightRecordsCollection
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => WeightRecord.fromDocument(doc))
                  .toList(),
        );
  }

  // Get weight records for a date range
  Future<List<WeightRecord>> getWeightRecordsForRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot =
          await _weightRecordsCollection
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
              .orderBy('date')
              .get();

      return snapshot.docs
          .map((doc) => WeightRecord.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting weight records for range: $e');
      return [];
    }
  }

  // Get a specific weight record
  Future<WeightRecord?> getWeightRecord(String recordId) async {
    try {
      DocumentSnapshot doc = await _weightRecordsCollection.doc(recordId).get();
      if (doc.exists) {
        return WeightRecord.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting weight record: $e');
      return null;
    }
  }

  // Add a new weight record
  Future<String?> addWeightRecord(WeightRecord record) async {
    try {
      DocumentReference docRef = await _weightRecordsCollection.add(
        record.toMap(),
      );
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding weight record: $e');
      return null;
    }
  }

  // Update an existing weight record
  Future<bool> updateWeightRecord(WeightRecord record) async {
    try {
      if (record.id == null) return false;
      await _weightRecordsCollection.doc(record.id).update(record.toMap());
      return true;
    } catch (e) {
      debugPrint('Error updating weight record: $e');
      return false;
    }
  }

  // Delete a weight record
  Future<bool> deleteWeightRecord(String recordId) async {
    try {
      await _weightRecordsCollection.doc(recordId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting weight record: $e');
      return false;
    }
  }

  // Get latest weight record
  Future<WeightRecord?> getLatestWeightRecord() async {
    try {
      final snapshot =
          await _weightRecordsCollection
              .orderBy('date', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return WeightRecord.fromDocument(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting latest weight record: $e');
      return null;
    }
  }
}
