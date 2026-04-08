import 'package:cloud_firestore/cloud_firestore.dart';
import 'cache_service.dart';
import '../utils/constants.dart';

import 'package:flutter/foundation.dart';

class AcademicRecordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = CacheService();

  // Get academic records for a student
  Future<Map<String, dynamic>?> getAcademicRecords(String studentUID) async {
    try {
      // Check cache first
      final cached = _cacheService.getCachedAcademicInfo(studentUID);
      if (cached != null) {
        // Only refresh if cache is older than 10 minutes
        if (_cacheService.shouldRefresh(CacheService.academicBoxName, studentUID)) {
          _refreshAcademicInfoInBackground(studentUID);
        }
        return Map<String, dynamic>.from(cached);
      }

      final doc = await _firestore
          .collection(Collections.academicInfo)
          .doc(studentUID)
          .get();
          
      if (doc.exists) {
        final data = doc.data()!;
        _cacheService.cacheAcademicInfo(studentUID, data);
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting academic records: $e');
      return null;
    }
  }

  // Create initial academic record
  Future<void> createAcademicRecord(String studentUID) async {
    await _firestore.collection(Collections.academicInfo).doc(studentUID).set({
      'studentUID': studentUID,
      'currentCGPA': 0.0,
      'overallAttendance': 0.0,
      'semesters': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update semester data
  Future<void> updateSemesterData({
    required String studentUID,
    required String semesterName,
    required double cgpa,
    required double attendance,
    required List<Map<String, dynamic>> subjects,
  }) async {
    final doc = await _firestore
        .collection(Collections.academicInfo)
        .doc(studentUID)
        .get();

    List<dynamic> semesters = doc.data()?['semesters'] ?? [];

    // Check if semester exists
    final existingIndex = semesters.indexWhere(
      (sem) => sem['semesterName'] == semesterName,
    );

    final semesterData = {
      'semesterName': semesterName,
      'cgpa': cgpa,
      'attendance': attendance,
      'subjects': subjects,
    };

    if (existingIndex >= 0) {
      semesters[existingIndex] = semesterData;
    } else {
      semesters.add(semesterData);
    }

    await _firestore
        .collection(Collections.academicInfo)
        .doc(studentUID)
        .update({
          'semesters': semesters,
          'currentCGPA': cgpa, // Update current CGPA to latest semester
          'overallAttendance': attendance,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  // Get subjects for a specific semester
  Future<List<Map<String, dynamic>>> getSubjects(
    String studentUID,
    String semesterName,
  ) async {
    try {
      final doc = await _firestore
          .collection(Collections.academicInfo)
          .doc(studentUID)
          .get();

      if (!doc.exists) return [];

      final semesters = doc.data()?['semesters'] as List<dynamic>? ?? [];
      final semester = semesters.firstWhere(
        (sem) => sem['semesterName'] == semesterName,
        orElse: () => null,
      );

      if (semester == null) return [];

      return List<Map<String, dynamic>>.from(semester['subjects'] ?? []);
    } catch (e) {
      debugPrint('Error getting subjects: $e');
      return [];
    }
  }

  // Stream for real-time academic updates
  Stream<Map<String, dynamic>?> academicRecordsStream(String studentUID) {
    return _firestore
        .collection(Collections.academicInfo)
        .doc(studentUID)
        .snapshots()
        .map((snapshot) => snapshot.exists ? snapshot.data() : null);
  }

  // Background refresh helper
  void _refreshAcademicInfoInBackground(String studentUID) async {
    try {
      final doc = await _firestore
          .collection(Collections.academicInfo)
          .doc(studentUID)
          .get();
      if (doc.exists) {
        _cacheService.cacheAcademicInfo(studentUID, doc.data()!);
      }
    } catch (e) {
      debugPrint('AcademicRecordService: Background refresh failed: $e');
    }
  }

  // Calculate average CGPA across all semesters
  double calculateAverageCGPA(List<dynamic> semesters) {
    if (semesters.isEmpty) return 0.0;

    double total = 0.0;
    for (var sem in semesters) {
      total += (sem['cgpa'] as num).toDouble();
    }

    return double.parse((total / semesters.length).toStringAsFixed(2));
  }

  // Calculate average attendance
  double calculateAverageAttendance(List<dynamic> semesters) {
    if (semesters.isEmpty) return 0.0;

    double total = 0.0;
    for (var sem in semesters) {
      total += (sem['attendance'] as num).toDouble();
    }

    return double.parse((total / semesters.length).toStringAsFixed(2));
  }

  /// ONE-TIME CLEANUP: Remove legacy semester entries from all student records
  Future<void> cleanupLegacySemesters() async {
    try {
      final legacyNames = {
        'Spring 2023',
        'Fall 2022',
        'Spring 2022',
        'Fall 2021',
      };

      final snapshot = await _firestore
          .collection(Collections.academicInfo)
          .get();

      final batch = _firestore.batch();
      int count = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        List<dynamic> semesters = List.from(data['semesters'] ?? []);

        semesters.removeWhere(
          (sem) => legacyNames.contains(sem['semesterName']),
        );

        if (semesters.length != (data['semesters'] as List).length) {
          batch.update(doc.reference, {
            'semesters': semesters,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          count++;
        }
      }

      if (count > 0) {
        await batch.commit();
        debugPrint(
          '🧹 Cleanup complete: Removed legacy semesters from $count students.',
        );
      } else {
        debugPrint('✨ No legacy semesters found to clean up.');
      }
    } catch (e) {
      debugPrint('❌ Error during legacy cleanup: $e');
    }
  }
}
