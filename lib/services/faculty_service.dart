import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/faculty_profile.dart';

class FacultyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collection = 'faculty_profiles';

  // Create or Update Faculty Profile
  Future<void> saveProfile(FacultyProfile profile) async {
    try {
      await _firestore
          .collection(collection)
          .doc(profile.id)
          .set(profile.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving faculty profile: $e');
      rethrow;
    }
  }

  // Get Faculty Profile
  Future<FacultyProfile?> getProfile(String uid) async {
    try {
      final doc = await _firestore.collection(collection).doc(uid).get();
      if (doc.exists) {
        return FacultyProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching faculty profile: $e');
      return null;
    }
  }

  // Stream Faculty Profile
  Stream<FacultyProfile?> streamProfile(String uid) {
    return _firestore.collection(collection).doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return FacultyProfile.fromFirestore(doc);
      }
      return null;
    });
  }

  // Get All Faculty (For Admin)
  Stream<List<FacultyProfile>> streamAllFaculty() {
    return _firestore.collection(collection).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FacultyProfile.fromFirestore(doc))
          .toList();
    });
  }

  // Get only users with the 'faculty' role
  Stream<List<FacultyProfile>> streamFacultyOnly() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'faculty')
        .snapshots()
        .asyncMap((userSnapshot) async {
          final facultyProfiles = <FacultyProfile>[];
          for (var userDoc in userSnapshot.docs) {
            final profileDoc = await _firestore
                .collection(collection)
                .doc(userDoc.id)
                .get();
            if (profileDoc.exists) {
              facultyProfiles.add(FacultyProfile.fromFirestore(profileDoc));
            }
          }
          return facultyProfiles;
        });
  }

  // Delete Faculty - Removes all Firestore data
  // Note: Firebase Auth user will remain but cannot login (no user doc)
  // Use cleanup_auth_users.py script periodically to remove Auth users
  Future<void> deleteFaculty(String uid) async {
    try {
      final batch = _firestore.batch();

      // 1. Delete Faculty Profile
      batch.delete(_firestore.collection(collection).doc(uid));

      // 2. Delete User Record (Auth mirror)
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

      // Commit all changes in one transaction
      await batch.commit();

      debugPrint('✅ Faculty deleted from Firestore: $uid');
      debugPrint('ℹ️ Auth user remains - run cleanup script to remove');
    } catch (e) {
      debugPrint('Error deleting faculty: $e');
      rethrow;
    }
  }

  // Update specific profile fields (Committee/Admin action)
  Future<void> updateProfileDetails({
    required String uid,
    required String name,
    required String phone,
    required String department,
    required String designation,
  }) async {
    try {
      await _firestore.collection(collection).doc(uid).set({
        'name': name,
        'phone': phone,
        'department': department,
        'designation': designation,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating faculty profile: $e');
      rethrow;
    }
  }

  // Verify Faculty (Admin only)
  Future<void> verifyFaculty(String uid, bool isVerified) async {
    await _firestore.collection(collection).doc(uid).update({
      'isVerified': isVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
