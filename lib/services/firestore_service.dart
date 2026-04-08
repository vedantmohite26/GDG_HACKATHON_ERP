// Firestore Service for database operations

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../models/student_profile.dart';
import '../models/scholarship.dart';
import '../models/application.dart';
import '../models/grievance.dart';
import '../models/document.dart';
import '../models/academic_info.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =================================
  // STUDENT PROFILES
  // =================================

  // Helper to get committee members
  Stream<List<Map<String, dynamic>>> getCommitteeMembers() {
    return _firestore
        .collection(Collections.users)
        .where('role', isEqualTo: 'committee')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();
        });
  }

  // Create student profile
  Future<void> createStudentProfile(StudentProfile profile) async {
    try {
      await _firestore
          .collection(Collections.studentProfiles)
          .doc(profile.id)
          .set(profile.toFirestore());
    } catch (e) {
      throw Exception('Failed to create profile: $e');
    }
  }

  // Get student profile by UID
  Future<StudentProfile?> getStudentProfile(String studentUID) async {
    try {
      final querySnapshot = await _firestore
          .collection(Collections.studentProfiles)
          .where('studentUID', isEqualTo: studentUID)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return StudentProfile.fromFirestore(querySnapshot.docs.first);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  // Stream student profile by UID
  Stream<StudentProfile?> streamStudentProfile(String studentUID) {
    return _firestore
        .collection(Collections.studentProfiles)
        .where('studentUID', isEqualTo: studentUID)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return StudentProfile.fromFirestore(snapshot.docs.first);
          }
          return null;
        });
  }

  // Get student profile by Firebase UID (fallback when studentUID is not available)
  Future<StudentProfile?> getStudentProfileByFirebaseUID(
    String firebaseUID,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(Collections.studentProfiles)
          .where('userId', isEqualTo: firebaseUID)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return StudentProfile.fromFirestore(querySnapshot.docs.first);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch profile by Firebase UID: $e');
    }
  }

  // Stream student profile by Firebase UID (fallback when studentUID is not available)
  Stream<StudentProfile?> streamStudentProfileByFirebaseUID(
    String firebaseUID,
  ) {
    return _firestore
        .collection(Collections.studentProfiles)
        .where('userId', isEqualTo: firebaseUID)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return StudentProfile.fromFirestore(snapshot.docs.first);
          }
          return null;
        });
  }

  // Combined stream for student profile (handles both studentUID and Firebase UID)
  Stream<StudentProfile?> getStudentProfileStream(String firebaseUID) {
    return _firestore
        .collection(Collections.users)
        .doc(firebaseUID)
        .snapshots()
        .switchMap((userDoc) {
          if (!userDoc.exists) return Stream.value(null);

          // Always prefer querying by userId (Auth UID) which is secure
          // Fallback to direct doc access if needed, but the ByFirebaseUID stream handles the query
          return streamStudentProfileByFirebaseUID(firebaseUID);
        });
  }

  // Update student profile
  Future<void> updateStudentProfile(StudentProfile profile) async {
    try {
      await _firestore
          .collection(Collections.studentProfiles)
          .doc(profile.id)
          .update(profile.toFirestore());
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get all students (for admin/faculty)
  Future<List<StudentProfile>> getAllStudents() async {
    try {
      final snapshot = await _firestore
          .collection(Collections.studentProfiles)
          .get();

      return snapshot.docs
          .map((doc) => StudentProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch students: $e');
    }
  }

  // =================================
  // SCHOLARSHIPS
  // =================================

  // Create scholarship
  Future<String> createScholarship(Scholarship scholarship) async {
    try {
      final docRef = await _firestore
          .collection(Collections.scholarships)
          .add(scholarship.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create scholarship: $e');
    }
  }

  // Get all scholarships (Future)
  Future<List<Scholarship>> getAllScholarships() async {
    try {
      final snapshot = await _firestore
          .collection(Collections.scholarships)
          .orderBy('deadline', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Scholarship.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch scholarships: $e');
    }
  }

  // Get all scholarships (Stream)
  Stream<List<Scholarship>> getScholarships() {
    return _firestore
        .collection(Collections.scholarships)
        .orderBy('deadline', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Scholarship.fromFirestore(doc))
              .toList(),
        );
  }

  // Get scholarship by ID
  Future<Scholarship?> getScholarship(String id) async {
    try {
      final doc = await _firestore
          .collection(Collections.scholarships)
          .doc(id)
          .get();

      if (doc.exists) {
        return Scholarship.fromFirestore(doc);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch scholarship: $e');
    }
  }

  // Update scholarship
  Future<void> updateScholarship(Scholarship scholarship) async {
    try {
      await _firestore
          .collection(Collections.scholarships)
          .doc(scholarship.id)
          .update(scholarship.toFirestore());
    } catch (e) {
      throw Exception('Failed to update scholarship: $e');
    }
  }

  // Delete scholarship
  Future<void> deleteScholarship(String id) async {
    try {
      await _firestore.collection(Collections.scholarships).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete scholarship: $e');
    }
  }

  // =================================
  // APPLICATIONS
  // =================================

  // Create application
  Future<String> createApplication(Application application) async {
    try {
      final docRef = await _firestore
          .collection(Collections.applications)
          .add(application.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create application: $e');
    }
  }

  // Submit application (Alias for createApplication)
  Future<String> submitApplication(Application application) {
    return createApplication(application);
  }

  // Get applications by student UID
  Stream<List<Application>> getStudentApplications(String studentUID) {
    return _firestore
        .collection(Collections.applications)
        .where('studentUID', isEqualTo: studentUID)
        .snapshots()
        .map((snapshot) {
          final apps = snapshot.docs
              .map((doc) => Application.fromFirestore(doc))
              .toList();
          apps.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return apps;
        });
  }

  // Get all applications (for admin)
  Stream<List<Application>> getAllApplications() {
    return _firestore.collection(Collections.applications).snapshots().map((
      snapshot,
    ) {
      final apps = snapshot.docs
          .map((doc) => Application.fromFirestore(doc))
          .toList();
      apps.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return apps;
    });
  }

  // Get faculty-recommended applications for committee approval
  // Only shows applications that faculty have reviewed and recommended
  Stream<List<Application>> getCommitteePendingApplicationsStream() {
    return _firestore
        .collection(Collections.applications)
        .where('facultyRecommendation', isEqualTo: 'recommended')
        .where(
          'status',
          whereIn: ['pending', 'assigned'],
        ) // Applications pending final committee decision
        .snapshots()
        .handleError((error) {
          // Log any Firestore errors
          debugPrint('ERROR in getCommitteePendingApplicationsStream: $error');
          return Stream<QuerySnapshot>.empty();
        })
        .map((snapshot) {
          // Debug: Log the number of documents returned
          debugPrint(
            'Committee Applications Query: Found ${snapshot.docs.length} faculty-recommended applications',
          );

          // Debug: Log details of each application
          for (var doc in snapshot.docs) {
            final data = doc.data();
            debugPrint(
              'App ID: ${doc.id}, Status: ${data['status']}, FacultyRec: ${data['facultyRecommendation']}, StudentUID: ${data['studentUID']}',
            );
          }

          try {
            final apps = snapshot.docs
                .map((doc) => Application.fromFirestore(doc))
                .toList();
            // Sort by submission date (newest first)
            apps.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
            debugPrint('Successfully parsed ${apps.length} applications');
            return apps;
          } catch (e) {
            debugPrint('Error parsing applications: $e');
            return <Application>[];
          }
        });
  }

  // Update application status
  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
    required String reviewedBy,
    String? adminNotes,
  }) async {
    try {
      await _firestore
          .collection(Collections.applications)
          .doc(applicationId)
          .update({
            'status': status,
            'reviewedAt': Timestamp.now(),
            'reviewedBy': reviewedBy,
            if (adminNotes != null) 'adminNotes': adminNotes,
          });
    } catch (e) {
      throw Exception('Failed to update application: $e');
    }
  }

  // Check if student has already applied for scholarship
  Future<bool> hasApplied(String studentUID, String scholarshipId) async {
    try {
      final querySnapshot = await _firestore
          .collection(Collections.applications)
          .where('studentUID', isEqualTo: studentUID)
          .where('scholarshipId', isEqualTo: scholarshipId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check application status: $e');
    }
  }

  // Get specific application for student and scholarship
  Future<Application?> getApplication(
    String studentUID,
    String scholarshipId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(Collections.applications)
          .where('studentUID', isEqualTo: studentUID)
          .where('scholarshipId', isEqualTo: scholarshipId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Application.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get application: $e');
    }
  }

  // Helper to get faculty members
  Stream<List<Map<String, dynamic>>> getFacultyMembers() {
    return _firestore
        .collection(Collections.users)
        .where('role', isEqualTo: 'faculty')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();
        });
  }

  // Assign application to faculty
  Future<void> assignApplication(String applicationId, String facultyId) async {
    try {
      await _firestore
          .collection(Collections.applications)
          .doc(applicationId)
          .update({'assignedFacultyId': facultyId, 'status': 'assigned'});
    } catch (e) {
      throw Exception('Failed to assign application: $e');
    }
  }

  // Submit faculty recommendation
  Future<void> submitFacultyRecommendation({
    required String applicationId,
    required String recommendation,
    required String comments,
  }) async {
    try {
      await _firestore
          .collection(Collections.applications)
          .doc(applicationId)
          .update({
            'facultyRecommendation': recommendation,
            'facultyComments': comments,
          });
    } catch (e) {
      throw Exception('Failed to submit recommendation: $e');
    }
  }

  // Revert application with required corrections
  Future<void> revertApplication({
    required String applicationId,
    required String comments,
  }) async {
    try {
      await _firestore
          .collection(Collections.applications)
          .doc(applicationId)
          .update({
            'status': 'reverted',
            'facultyRecommendation': null, // Clear recommendation
            'facultyComments': comments,
            'reviewedAt': Timestamp.now(),
          });
    } catch (e) {
      throw Exception('Failed to revert application: $e');
    }
  }

  // Get assigned applications for faculty
  Stream<List<Application>> getAssignedApplications(String facultyId) {
    return _firestore
        .collection(Collections.applications)
        .where('assignedFacultyId', isEqualTo: facultyId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Application.fromFirestore(doc))
              .toList();
        });
  }

  // Get all pending applications (for faculty pool view)
  Stream<List<Application>> getPendingApplicationsStream() {
    return _firestore
        .collection(Collections.applications)
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Application.fromFirestore(doc))
              .toList();
        });
  }

  // =================================
  // GRIEVANCES
  // =================================

  // Create grievance
  Future<String> createGrievance(Grievance grievance) async {
    try {
      final docRef = await _firestore
          .collection(Collections.grievances)
          .add(grievance.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create grievance: $e');
    }
  }

  // Get grievances by userId (Auth UID)
  Stream<List<Grievance>> getStudentGrievances(String userId) {
    return _firestore
        .collection(Collections.grievances)
        .where('userId', isEqualTo: userId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Grievance.fromFirestore(doc))
              .toList();
        });
  }

  // Get all grievances (for admin)
  Stream<List<Grievance>> getAllGrievances() {
    return _firestore
        .collection(Collections.grievances)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .handleError((e) => debugPrint('❌ Error in getAllGrievances: $e'))
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Grievance.fromFirestore(doc))
              .toList();
        });
  }

  // Get assigned grievances (for committee)
  Stream<List<Grievance>> getAssignedGrievances(String committeeUID) {
    return _firestore
        .collection(Collections.grievances)
        .where('assignedTo', isEqualTo: committeeUID)
        .orderBy('slaDeadline', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Grievance.fromFirestore(doc))
              .toList();
        });
  }

  // Update grievance
  Future<void> updateGrievance(Grievance grievance) async {
    try {
      await _firestore
          .collection(Collections.grievances)
          .doc(grievance.id)
          .update(grievance.toFirestore());
    } catch (e) {
      throw Exception('Failed to update grievance: $e');
    }
  }

  // Assign grievance to committee member
  Future<void> assignGrievance(String grievanceId, String committeeUID) async {
    try {
      await _firestore
          .collection(Collections.grievances)
          .doc(grievanceId)
          .update({'assignedTo': committeeUID, 'status': 'assigned'});
    } catch (e) {
      throw Exception('Failed to assign grievance: $e');
    }
  }

  // Update grievance status with details
  Future<void> updateGrievanceStatus({
    required String grievanceId,
    required String status,
    String? assignedTo,
    String? internalNotes,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (assignedTo != null) data['assignedTo'] = assignedTo;
      if (internalNotes != null) data['internalNotes'] = internalNotes;
      if (status == 'resolved') {
        data['resolvedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection(Collections.grievances)
          .doc(grievanceId)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update grievance status: $e');
    }
  }

  // =================================
  // DOCUMENTS
  // =================================

  // Create document metadata
  Future<String> createDocumentMeta(DocumentModel document) async {
    try {
      final docRef = await _firestore
          .collection(Collections.documentsMeta)
          .add(document.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create document metadata: $e');
    }
  }

  // Get documents by student UID
  Stream<List<DocumentModel>> getStudentDocuments(String studentUID) {
    return _firestore
        .collection(Collections.documentsMeta)
        .where('studentUID', isEqualTo: studentUID)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => DocumentModel.fromFirestore(doc))
              .toList();
          docs.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
          return docs;
        });
  }

  // Delete document metadata
  Future<void> deleteDocumentMeta(String docId) async {
    try {
      await _firestore
          .collection(Collections.documentsMeta)
          .doc(docId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete document metadata: $e');
    }
  }

  // =================================
  // ACADEMIC INFO
  // =================================

  // Create academic info
  Future<String> createAcademicInfo(AcademicInfo info) async {
    try {
      final docRef = await _firestore
          .collection(Collections.academicInfo)
          .add(info.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create academic info: $e');
    }
  }

  // Get academic info by course and year
  Stream<List<AcademicInfo>> getAcademicInfo(String course, int year) {
    return _firestore
        .collection(Collections.academicInfo)
        .where('course', isEqualTo: course)
        .where('year', isEqualTo: year)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AcademicInfo.fromFirestore(doc))
              .toList(),
        );
  }

  // Update academic info
  Future<void> updateAcademicInfo(AcademicInfo info) async {
    try {
      await _firestore
          .collection(Collections.academicInfo)
          .doc(info.id)
          .update(info.toFirestore());
    } catch (e) {
      throw Exception('Failed to update academic info: $e');
    }
  }

  // Delete academic info
  Future<void> deleteAcademicInfo(String id) async {
    try {
      await _firestore.collection(Collections.academicInfo).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete academic info: $e');
    }
  }

  // =================================
  // STATISTICS (for dashboards)
  // =================================

  // Get total count of documents in a collection
  Future<int> getCollectionCount(String collectionName) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Get pending applications count
  Future<int> getPendingApplicationsCount() async {
    try {
      final snapshot = await _firestore
          .collection(Collections.applications)
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Get unresolved grievances count
  Future<int> getUnresolvedGrievancesCount() async {
    try {
      final snapshot = await _firestore
          .collection(Collections.grievances)
          .where('status', whereIn: ['pending', 'assigned', 'in-progress'])
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Get pending applications count stream
  Stream<int> getPendingApplicationsCountStream() {
    return _firestore
        .collection(Collections.applications)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get unresolved grievances count stream
  // Get unresolved grievances count stream
  Stream<int> getUnresolvedGrievancesCountStream() {
    return _firestore
        .collection(Collections.grievances)
        .where('status', whereIn: ['pending', 'assigned', 'in-progress'])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get urgent/high-priority grievances count stream
  Stream<int> getUrgentGrievancesCountStream() {
    return _firestore
        .collection(Collections.grievances)
        .where('status', whereIn: ['pending', 'assigned', 'in-progress'])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            final data = doc.data();
            return (data['priorityScore'] ?? 0) >= 70;
          }).length;
        });
  }

  // Get faculty workload stats stream
  Stream<Map<String, int>> getFacultyWorkloadStatsStream(String facultyId) {
    final appsStream = _firestore
        .collection(Collections.applications)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    final grievancesStream = _firestore
        .collection(Collections.grievances)
        .where('assignedTo', isEqualTo: facultyId)
        .where('status', isEqualTo: 'assigned')
        .snapshots();

    return Rx.combineLatest2<QuerySnapshot, QuerySnapshot, Map<String, int>>(
      appsStream,
      grievancesStream,
      (apps, grievances) {
        return {
          'pendingReviews': apps.docs.length,
          'assignedGrievances': grievances.docs.length,
        };
      },
    );
  }

  // Get global platform stats stream
  Stream<Map<String, int>> getGlobalPlatformStatsStream() {
    // Count from student_profiles (actual students with profiles)
    // instead of users collection (which may have orphaned records)
    final studentsStream = _firestore
        .collection(Collections.studentProfiles)
        .snapshots();
    final facultyStream = _firestore
        .collection(Collections.users)
        .where('role', isEqualTo: 'faculty')
        .snapshots();
    final appsStream = _firestore
        .collection(Collections.applications)
        .snapshots();
    final grievancesStream = _firestore
        .collection(Collections.grievances)
        .snapshots();

    return Rx.combineLatest4<
      QuerySnapshot<Map<String, dynamic>>,
      QuerySnapshot<Map<String, dynamic>>,
      QuerySnapshot<Map<String, dynamic>>,
      QuerySnapshot<Map<String, dynamic>>,
      Map<String, int>
    >(
      studentsStream
          .handleError((e) => debugPrint('❌ Students Error: $e'))
          .onErrorReturnWith((e, s) => _EmptyQuerySnapshot()),
      facultyStream
          .handleError((e) => debugPrint('❌ Faculty Error: $e'))
          .onErrorReturnWith((e, s) => _EmptyQuerySnapshot()),
      appsStream
          .handleError((e) => debugPrint('❌ Apps Error: $e'))
          .onErrorReturnWith((e, s) => _EmptyQuerySnapshot()),
      grievancesStream
          .handleError((e) => debugPrint('❌ Grievances Error: $e'))
          .onErrorReturnWith((e, s) => _EmptyQuerySnapshot()),
      (students, faculty, apps, grievances) {
        final gDocs = grievances.docs;
        final aDocs = apps.docs;

        debugPrint(
          '📊 Stats Sync: S:${students.docs.length} F:${faculty.docs.length} A:${aDocs.length} G:${gDocs.length}',
        );

        return {
          'totalStudents': students.docs.length,
          'totalFaculty': faculty.docs.length,
          'totalApplications': aDocs.length,
          'totalGrievances': gDocs.length,
          'pendingApplications': aDocs.where((d) {
            final s = d.data();
            final status = s['status']?.toString().toLowerCase();
            return status == 'pending' || status == 'assigned';
          }).length,
          'committeePendingApplications': aDocs.where((d) {
            final data = d.data();
            final status = data['status']?.toString().toLowerCase();
            return data['facultyRecommendation'] == 'recommended' &&
                (status == 'pending' || status == 'assigned');
          }).length,
          'unresolvedGrievances': gDocs.where((d) {
            final status = d.data()['status']?.toString().toLowerCase();
            return ['pending', 'assigned', 'in-progress'].contains(status);
          }).length,
          'unassignedGrievances': gDocs.where((d) {
            final data = d.data();
            final status = data['status']?.toString().toLowerCase();
            final assignedTo = data['assignedTo'];
            return status == 'pending' &&
                (assignedTo == null || assignedTo.toString().isEmpty);
          }).length,
        };
      },
    );
  }

  // Get grievances assigned to a specific faculty member
  Stream<List<Grievance>> getAssignedGrievancesStream(String facultyId) {
    return _firestore
        .collection(Collections.grievances)
        .where('assignedTo', isEqualTo: facultyId)
        .snapshots()
        .map((snapshot) {
          final grievances = snapshot.docs
              .map((doc) => Grievance.fromFirestore(doc))
              .toList();
          // Client-side sorting by date
          grievances.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return grievances;
        });
  }

  // =================================
  // EVENTS & CALENDAR
  // =================================

  Stream<List<Map<String, dynamic>>> getCalendarEvents() {
    return _firestore
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Create a new calendar event
  Future<void> createCalendarEvent(Map<String, dynamic> eventData) async {
    try {
      await _firestore.collection('events').add(eventData);
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  // Delete a calendar event
  Future<void> deleteCalendarEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  // =================================
  // NOTIFICATIONS (NOTICES)
  // =================================

  Stream<List<Map<String, dynamic>>> getNotices() {
    return _firestore
        .collection('notices')
        .orderBy('postedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Post a new notice
  Future<void> createNotice({
    required String title,
    required String content,
    required String postedBy,
    required String postedByName,
    String type = 'general',
    bool isPinned = false,
    String priority = 'Low',
    String? externalLink,
    String? course,
    String? year,
    String? semester,
  }) async {
    try {
      await _firestore.collection('notices').add({
        'title': title,
        'content': content,
        'postedBy': postedBy,
        'postedByName': postedByName,
        'postedAt': FieldValue.serverTimestamp(),
        'type': type,
        'isPinned': isPinned,
        'priority': priority,
        'externalLink': externalLink,
        'course': course,
        'year': year,
        'semester': semester,
      });
    } catch (e) {
      throw Exception('Failed to post notice: $e');
    }
  }

  // Delete a notice
  Future<void> deleteNotice(String noticeId) async {
    try {
      await _firestore.collection('notices').doc(noticeId).delete();
    } catch (e) {
      throw Exception('Failed to delete notice: $e');
    }
  }
}

// Dummy class to satisfy Rx.combineLatest when a stream errors
class _EmptyQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => [];
  @override
  List<DocumentChange<Map<String, dynamic>>> get docChanges => [];
  @override
  SnapshotMetadata get metadata => throw UnimplementedError();
  @override
  int get size => 0;
}
