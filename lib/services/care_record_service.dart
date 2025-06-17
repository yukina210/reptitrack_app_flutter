// lib/services/care_record_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/care_record.dart';

class CareRecordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  final String petId;

  CareRecordService({required this.userId, required this.petId});

  // Collection reference for care records
  CollectionReference get _careRecordsCollection => _firestore
      .collection('users')
      .doc(userId)
      .collection('pets')
      .doc(petId)
      .collection('care_records');

  // Get all care records for current pet
  Stream<List<CareRecord>> getCareRecords() {
    return _careRecordsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => CareRecord.fromDocument(doc)).toList(),
        );
  }

  // Get care records for a specific date
  Future<List<CareRecord>> getCareRecordsForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot =
          await _careRecordsCollection
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
              .orderBy('date')
              .get();

      return snapshot.docs.map((doc) => CareRecord.fromDocument(doc)).toList();
    } catch (e) {
      debugPrint('Error getting care records for date: $e');
      return [];
    }
  }

  // Get care records for a date range (for calendar)
  Future<Map<DateTime, List<CareRecord>>> getCareRecordsForRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot =
          await _careRecordsCollection
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
              .orderBy('date')
              .get();

      final Map<DateTime, List<CareRecord>> recordsMap = {};

      for (final doc in snapshot.docs) {
        final record = CareRecord.fromDocument(doc);
        final dateKey = DateTime(
          record.date.year,
          record.date.month,
          record.date.day,
        );

        if (recordsMap.containsKey(dateKey)) {
          recordsMap[dateKey]!.add(record);
        } else {
          recordsMap[dateKey] = [record];
        }
      }

      return recordsMap;
    } catch (e) {
      debugPrint('Error getting care records for range: $e');
      return {};
    }
  }

  // Get a specific care record
  Future<CareRecord?> getCareRecord(String recordId) async {
    try {
      DocumentSnapshot doc = await _careRecordsCollection.doc(recordId).get();
      if (doc.exists) {
        return CareRecord.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting care record: $e');
      return null;
    }
  }

  // Add a new care record
  Future<String?> addCareRecord(CareRecord record) async {
    try {
      DocumentReference docRef = await _careRecordsCollection.add(
        record.toMap(),
      );
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding care record: $e');
      return null;
    }
  }

  // Update an existing care record
  Future<bool> updateCareRecord(CareRecord record) async {
    try {
      if (record.id == null) return false;
      await _careRecordsCollection.doc(record.id).update(record.toMap());
      return true;
    } catch (e) {
      debugPrint('Error updating care record: $e');
      return false;
    }
  }

  // Delete a care record
  Future<bool> deleteCareRecord(String recordId) async {
    try {
      await _careRecordsCollection.doc(recordId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting care record: $e');
      return false;
    }
  }
}
