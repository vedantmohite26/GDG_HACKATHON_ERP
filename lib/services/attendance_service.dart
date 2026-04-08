import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'cache_service.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = CacheService();
  static const String collection = 'attendance_logs';

  // Check if attendance already exists for the given criteria
  Future<Map<String, dynamic>?> checkExistingAttendance({
    required String subject,
    required String branch,
    required String year,
    required DateTime date,
  }) async {
    try {
      // Normalize date to start of day for accurate comparison
      final startOfDay = DateTime(date.year, date.month, date.day);
      final nextDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(collection)
          .where('subject', isEqualTo: subject)
          .where('branch', isEqualTo: branch)
          .where('year', isEqualTo: year)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(nextDay))
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Error checking existing attendance: $e');
      return null;
    }
  }

  // Mark Attendance Function
  Future<void> submitAttendance({
    required String facultyId,
    required String subject,
    required String branch,
    required String year,
    required DateTime date,
    required Map<String, String>
    studentStatuses, // studentUID -> 'Present'/'Absent'/'Holiday'
  }) async {
    try {
      // Create a batch commit for efficiency (although singular document usually better for session)
      // Storing as one document per session is better.

      final sessionData = {
        'facultyId': facultyId,
        'subject': subject,
        'branch': branch,
        'year': year,
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
        'totalStudents': studentStatuses.length,
        'presentCount': studentStatuses.values
            .where((s) => s == 'Present')
            .length,
        'absentCount': studentStatuses.values
            .where((s) => s == 'Absent')
            .length,
        'holidayCount': studentStatuses.values
            .where((s) => s == 'Holiday')
            .length,
        'records': studentStatuses, // { "uid1": "Present", "uid2": "Absent" }
      };

      await _firestore.collection(collection).add(sessionData);

      // Optional: Logic to update aggregate attendance in academic_info could go here.
      // But that's complex as academic_info is by semester.
      // We will leave that for future implementation or assume a cloud function handles it.
    } catch (e) {
      debugPrint('Error submitting attendance: $e');
      rethrow;
    }
  }

  // Get Recent Attendance Sessions (for Faculty history)
  Future<List<Map<String, dynamic>>> getRecentSessions(String facultyId) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where('facultyId', isEqualTo: facultyId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting sessions: $e');
      return [];
    }
  }

  // Get Student Attendance Report
  Future<Map<String, Map<String, dynamic>>> getStudentAttendanceReport({
    required String studentId,
    required String branch,
    required String year,
  }) async {
    try {
      // 1. Check Cache First
      final cachedData = _cacheService.getCachedAttendanceReport(studentId);
      if (cachedData != null) {
        debugPrint('Returning cached attendance report for $studentId');
        // Only refresh if cache is older than 10 minutes
        if (_cacheService.shouldRefresh(CacheService.attendanceBoxName, studentId)) {
          _refreshAttendanceInBackground(studentId, branch, year);
        }
        return Map<String, Map<String, dynamic>>.from(
          cachedData.map((key, value) {
            final Map<String, dynamic> subjectData = Map<String, dynamic>.from(value);
            if (subjectData.containsKey('history')) {
              final rawHistory = subjectData['history'] as Map;
              subjectData['history'] = rawHistory.map((hKey, hValue) => 
                MapEntry(hKey.toString(), List<DateTime>.from(hValue))
              );
            }
            return MapEntry(key.toString(), subjectData);
          })
        );
      }

      return await _fetchAttendanceFromFirestore(studentId, branch, year);
    } catch (e) {
      debugPrint('Error generating student report: $e');
      return {};
    }
  }

  Future<Map<String, Map<String, dynamic>>> _fetchAttendanceFromFirestore(
    String studentId,
    String branch,
    String year,
  ) async {
    // Original aggregation logic preserved
    String queryYear = year;
    if (year == '1') { queryYear = '1st Year'; }
    else if (year == '2') { queryYear = '2nd Year'; }
    else if (year == '3') { queryYear = '3rd Year'; }
    else if (year == '4') { queryYear = '4th Year'; }

    final query = _firestore
        .collection(collection)
        .where('branch', isEqualTo: branch)
        .where('year', isEqualTo: queryYear);

    final snapshot = await query.get();
    final Map<String, Map<String, dynamic>> subjectStats = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final subject = data['subject'] as String;
      final timestamp = data['date'] as Timestamp;
      final date = timestamp.toDate();
      final records = data['records'] as Map<String, dynamic>?;

      if (records != null && records.containsKey(studentId)) {
        if (!subjectStats.containsKey(subject)) {
          subjectStats[subject] = {
            'total': 0, 'present': 0, 'absent': 0, 'holiday': 0,
            'history': {'Present': <DateTime>[], 'Absent': <DateTime>[], 'Holiday': <DateTime>[]},
          };
        }

        final status = records[studentId];
        subjectStats[subject]!['total'] = (subjectStats[subject]!['total'] as int) + 1;

        if (status == 'Present') {
          subjectStats[subject]!['present'] = (subjectStats[subject]!['present'] as int) + 1;
          (subjectStats[subject]!['history']['Present'] as List<DateTime>).add(date);
        } else if (status == 'Absent') {
          subjectStats[subject]!['absent'] = (subjectStats[subject]!['absent'] as int) + 1;
          (subjectStats[subject]!['history']['Absent'] as List<DateTime>).add(date);
        } else if (status == 'Holiday') {
          subjectStats[subject]!['holiday'] = (subjectStats[subject]!['holiday'] as int) + 1;
          (subjectStats[subject]!['history']['Holiday'] as List<DateTime>).add(date);
        }
      }
    }

    // Sort history
    for (var subject in subjectStats.keys) {
      final history = subjectStats[subject]!['history'] as Map<String, List<DateTime>>;
      for (var status in history.keys) {
        history[status]!.sort((a, b) => b.compareTo(a));
      }
    }

    // Cache the result
    await _cacheService.cacheAttendanceReport(studentId, subjectStats);
    return subjectStats;
  }

  void _refreshAttendanceInBackground(String studentId, String branch, String year) {
    debugPrint('Scheduling background attendance refresh for $studentId');
    _fetchAttendanceFromFirestore(studentId, branch, year).then((_) {
      debugPrint('Background attendance refresh complete for $studentId');
    }).catchError((e) {
      debugPrint('Background attendance refresh failed: $e');
      return null;
    });
  }

  // Get live overall attendance percentage from logs
  Stream<double> getStudentAttendancePercentageStream(String studentId, String branch, String year) {
    String queryYear = year;
    if (year == '1') { queryYear = '1st Year'; }
    else if (year == '2') { queryYear = '2nd Year'; }
    else if (year == '3') { queryYear = '3rd Year'; }
    else if (year == '4') { queryYear = '4th Year'; }

    return _firestore
        .collection(collection)
        .where('branch', isEqualTo: branch)
        .where('year', isEqualTo: queryYear)
        .snapshots()
        .map((snapshot) {
          int present = 0;
          int total = 0;

          // debug log to identify why attendance might be 0.0
          debugPrint('AttendanceStream: Processing ${snapshot.docs.length} sessions for student $studentId');

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final records = data['records'] as Map<String, dynamic>?;

            if (records != null && records.containsKey(studentId)) {
              final status = records[studentId];
              // Robust check: accept both full words and initials
              if (status == 'Present' || status == 'P' || status == 'Absent' || status == 'A') {
                total++;
                if (status == 'Present' || status == 'P') {
                  present++;
                }
              }
            }
          }
          
          if (total == 0) {
            debugPrint('AttendanceStream: No participation records found in sessions.');
            return 0.0;
          }
          final percentage = (present / total) * 100.0;
          return double.parse(percentage.toStringAsFixed(1));
        });
  }
}
