import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service to delete student and faculty accounts from Firestore.
/// Performs cascade deletion across all related collections.
/// 
/// Note: Firebase Auth accounts cannot be deleted from the client SDK
/// (only the user themselves can delete their own Auth account).
/// The Firestore data deletion effectively disables the account since
/// the app requires a valid 'users' document to function.
class UserDeletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Delete a faculty member's Firestore data completely.
  /// Deletes from: users, faculty_profiles
  /// Unassigns from: applications, grievances
  Future<String> deleteFaculty(String uid) async {
    try {
      final batch = _firestore.batch();

      // 1. Delete faculty profile
      batch.delete(_firestore.collection('faculty_profiles').doc(uid));

      // 2. Delete user record
      batch.delete(_firestore.collection('users').doc(uid));

      // 3. Unassign from applications
      final apps = await _firestore
          .collection('applications')
          .where('assignedFacultyId', isEqualTo: uid)
          .get();
      for (var doc in apps.docs) {
        batch.update(doc.reference, {
          'assignedFacultyId': null,
          'facultyComments': 'Faculty member removed',
        });
      }

      // 4. Unassign from grievances
      final grievances = await _firestore
          .collection('grievances')
          .where('assignedTo', isEqualTo: uid)
          .get();
      for (var doc in grievances.docs) {
        batch.update(doc.reference, {
          'assignedTo': null,
          'status': 'pending',
          'internalNotes': 'Reassign - previous faculty removed',
        });
      }

      await batch.commit();
      debugPrint('✅ Faculty $uid deleted from Firestore');
      return 'Faculty member deleted successfully.';
    } catch (e) {
      debugPrint('❌ Faculty deletion error: $e');
      rethrow;
    }
  }

  /// Delete a student's Firestore data completely.
  /// Provide either [uid] (Firebase Auth UID) or [studentId] (enrollment ID).
  /// Deletes from: users, student_profiles, academic_info,
  ///               applications, documents_meta, grievances
  Future<String> deleteStudent({String? uid, String? studentId}) async {
    try {
      String? authUid = uid;
      String? enrollmentId = studentId;

      // Resolve missing identifiers
      if (enrollmentId != null && (authUid == null || authUid.isEmpty)) {
        final profileDoc = await _firestore
            .collection('student_profiles')
            .doc(enrollmentId)
            .get();
        if (profileDoc.exists) {
          authUid = profileDoc.data()?['userId'] as String?;
        }
      }

      if (authUid != null && authUid.isNotEmpty && (enrollmentId == null || enrollmentId.isEmpty)) {
        final userDoc =
            await _firestore.collection('users').doc(authUid).get();
        if (userDoc.exists) {
          enrollmentId = userDoc.data()?['studentUID'] as String?;
        }
      }

      final batch = _firestore.batch();

      // 1. Delete user record
      if (authUid != null && authUid.isNotEmpty) {
        batch.delete(_firestore.collection('users').doc(authUid));
      }

      // 2. Delete student profile
      if (enrollmentId != null && enrollmentId.isNotEmpty) {
        batch.delete(
            _firestore.collection('student_profiles').doc(enrollmentId));

        // 3. Delete academic info
        batch.delete(
            _firestore.collection('academic_info').doc(enrollmentId));

        // 4. Delete applications
        final apps = await _firestore
            .collection('applications')
            .where('studentUID', isEqualTo: enrollmentId)
            .get();
        for (var doc in apps.docs) {
          batch.delete(doc.reference);
        }

        // 5. Delete documents meta
        final docs = await _firestore
            .collection('documents_meta')
            .where('studentUID', isEqualTo: enrollmentId)
            .get();
        for (var doc in docs.docs) {
          batch.delete(doc.reference);
        }
      }

      // 6. Delete grievances (tied to auth UID)
      if (authUid != null && authUid.isNotEmpty) {
        final grievances = await _firestore
            .collection('grievances')
            .where('userId', isEqualTo: authUid)
            .get();
        for (var doc in grievances.docs) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();

      final name = enrollmentId ?? authUid ?? 'Unknown';
      debugPrint('✅ Student $name deleted from Firestore');
      return 'Student $name deleted successfully.';
    } catch (e) {
      debugPrint('❌ Student deletion error: $e');
      rethrow;
    }
  }
}
