import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Quick script to seed test grievances with faculty assignments
/// Run this AFTER seeding students and faculty
class GrievanceSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedTestGrievances() async {
    debugPrint('🌱 Starting to seed test grievances...');

    try {
      // Get a student UID (first student from the collection)
      final studentDocs = await _firestore
          .collection('student_profiles')
          .limit(1)
          .get();

      if (studentDocs.docs.isEmpty) {
        debugPrint('❌ No students found. Please seed students first.');
        return;
      }

      final studentProfile = studentDocs.docs.first.data();
      final studentUserId = studentProfile['userId'] as String;
      final studentUID = studentProfile['studentId'] as String;

      // Get a faculty UID
      final facultyDocs = await _firestore
          .collection('faculty_profiles')
          .limit(1)
          .get();

      if (facultyDocs.docs.isEmpty) {
        debugPrint('❌ No faculty found. Please seed faculty first.');
        return;
      }

      final facultyId = facultyDocs.docs.first.id; // This is the Firebase UID

      // Create 3 test grievances - 2 assigned, 1 unassigned
      final grievances = [
        {
          'userId': studentUserId,
          'studentUID': studentUID,
          'category': 'Academic',
          'description': 'Need help with course material for Data Structures',
          'proofUrls': [],
          'isAnonymous': false,
          'priorityScore': 75, // High priority
          'status': 'assigned',
          'assignedTo': facultyId, // ASSIGNED to faculty
          'submittedAt': Timestamp.now(),
          'slaDeadline': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 5)),
          ),
        },
        {
          'userId': studentUserId,
          'studentUID': studentUID,
          'category': 'Hostel',
          'description': 'Room maintenance required - broken window',
          'proofUrls': [],
          'isAnonymous': false,
          'priorityScore': 85, // High priority
          'status': 'assigned',
          'assignedTo': facultyId, // ASSIGNED to faculty
          'submittedAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 2)),
          ),
          'slaDeadline': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 3)),
          ),
        },
        {
          'userId': studentUserId,
          'studentUID': studentUID,
          'category': 'Library',
          'description': 'Cannot access digital library resources',
          'proofUrls': [],
          'isAnonymous': true,
          'priorityScore': 40, // Normal priority
          'status': 'pending',
          'assignedTo': null, // UNASSIGNED
          'submittedAt': Timestamp.now(),
          'slaDeadline': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 7)),
          ),
        },
      ];

      for (int i = 0; i < grievances.length; i++) {
        await _firestore.collection('grievances').add(grievances[i]);
        final status = grievances[i]['assignedTo'] != null
            ? 'ASSIGNED'
            : 'UNASSIGNED';
        debugPrint('✅ Created grievance ${i + 1}/3 - $status');
      }

      debugPrint(
        '🎉 Successfully seeded ${grievances.length} test grievances!',
      );
      debugPrint('   - 2 assigned to faculty member');
      debugPrint('   - 1 unassigned (pending)');
    } catch (e) {
      debugPrint('❌ Error seeding grievances: $e');
    }
  }
}
