import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import 'package:flutter/foundation.dart';

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit scholarship application
  Future<String> submitApplication({
    required String studentUID,
    required String scholarshipId,
    required List<String> documentIds, // Document IDs from documents collection
  }) async {
    // Check if already applied
    final existing = await _firestore
        .collection(Collections.applications)
        .where('studentUID', isEqualTo: studentUID)
        .where('scholarshipId', isEqualTo: scholarshipId)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('You have already applied for this scholarship');
    }

    // Create application
    final docRef = await _firestore.collection(Collections.applications).add({
      'studentUID': studentUID,
      'scholarshipId': scholarshipId,
      'documents': documentIds,
      'status': ApplicationStatus.pending,
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
      'reviewedBy': null,
      'remarks': '',
    });

    // Increment applicant count on scholarship
    await _firestore
        .collection(Collections.scholarships)
        .doc(scholarshipId)
        .update({'applicants': FieldValue.increment(1)});

    return docRef.id;
  }

  // Get student's applications
  Future<List<Map<String, dynamic>>> getStudentApplications(
    String studentUID,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(Collections.applications)
          .where('studentUID', isEqualTo: studentUID)
          .orderBy('submittedAt', descending: true)
          .get();

      final applications = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        // Fetch scholarship details
        final scholarshipDoc = await _firestore
            .collection(Collections.scholarships)
            .doc(data['scholarshipId'])
            .get();

        if (scholarshipDoc.exists) {
          data['scholarship'] = scholarshipDoc.data();
        }

        applications.add(data);
      }

      return applications;
    } catch (e) {
      debugPrint('Error getting applications: $e');
      return [];
    }
  }

  // Get all applications (Admin/Committee)
  Future<List<Map<String, dynamic>>> getAllApplications({
    String? status,
  }) async {
    try {
      Query query = _firestore.collection(Collections.applications);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.orderBy('submittedAt', descending: true).get();

      final applications = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Fetch student and scholarship details
        final studentDoc = await _firestore
            .collection(Collections.studentProfiles)
            .doc(data['studentUID'])
            .get();

        final scholarshipDoc = await _firestore
            .collection(Collections.scholarships)
            .doc(data['scholarshipId'])
            .get();

        if (studentDoc.exists) {
          data['student'] = studentDoc.data();
        }

        if (scholarshipDoc.exists) {
          data['scholarship'] = scholarshipDoc.data();
        }

        applications.add(data);
      }

      return applications;
    } catch (e) {
      debugPrint('Error getting all applications: $e');
      return [];
    }
  }

  // Update application status (Admin/Committee only)
  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status, // approved/rejected
    required String reviewedBy,
    String? remarks,
  }) async {
    await _firestore
        .collection(Collections.applications)
        .doc(applicationId)
        .update({
          'status': status,
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': reviewedBy,
          'remarks': remarks ?? '',
        });
  }

  // Check if student has applied for scholarship
  Future<bool> hasApplied(String studentUID, String scholarshipId) async {
    try {
      final snapshot = await _firestore
          .collection(Collections.applications)
          .where('studentUID', isEqualTo: studentUID)
          .where('scholarshipId', isEqualTo: scholarshipId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get application by ID
  Future<Map<String, dynamic>?> getApplication(String applicationId) async {
    try {
      final doc = await _firestore
          .collection(Collections.applications)
          .doc(applicationId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      debugPrint('Error getting application: $e');
      return null;
    }
  }

  // Stream applications for realtime updates
  Stream<List<Map<String, dynamic>>> applicationsStream(String studentUID) {
    return _firestore
        .collection(Collections.applications)
        .where('studentUID', isEqualTo: studentUID)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final applications = <Map<String, dynamic>>[];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            data['id'] = doc.id;

            // Fetch scholarship details
            final scholarshipDoc = await _firestore
                .collection(Collections.scholarships)
                .doc(data['scholarshipId'])
                .get();

            if (scholarshipDoc.exists) {
              data['scholarship'] = scholarshipDoc.data();
            }

            applications.add(data);
          }

          return applications;
        });
  }
}
