import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../utils/result_utils.dart';

class ResultService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Publish results for a batch of students
  Future<void> publishResults({
    required String course,
    required String semester, // e.g., "Semester 3"
    required String subjectName,
    required int subjectCredits,
    required List<Map<String, dynamic>> studentResults, // {id, grade, isPassed}
  }) async {
    for (var result in studentResults) {
      final studentId = result['id'];
      final grade = result['sgpa']; // SGPA string

      if (studentId == null) continue;

      // We update individually for now
      await _updateStudentResult(
        studentId,
        semester,
        subjectName,
        subjectCredits,
        grade,
      );
    }
  }

  Future<void> _updateStudentResult(
    String studentId,
    String semesterName,
    String subjectName,
    int credits,
    String grade,
  ) async {
    final docRef = _firestore
        .collection(Collections.academicInfo)
        .doc(studentId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      // Read profile doc to verify existence before updating
      final profileRef = _firestore
          .collection(Collections.studentProfiles)
          .doc(studentId);
      final profileSnapshot = await transaction.get(profileRef);

      if (!snapshot.exists) {
        // Create new record with enhanced tracking
        transaction.set(docRef, {
          'studentUID': studentId,
          'currentCGPA': 0.0,
          'overallAttendance': 0.0,
          'totalCreditsEarned': 0, // NEW: Track earned credits
          'requiredCredits': 0, // NEW: Will be calculated based on year
          'failedSubjects': [], // NEW: Track failed/pending subjects
          'academicStatus': 'active', // NEW: active/detained/promoted
          'currentYear': '1st Year', // NEW: Track academic year
          'semesters': [
            {
              'semesterName': semesterName,
              'subjects': [
                {'name': subjectName, 'credits': credits, 'sgpa': grade},
              ],
              'cgpa': 0.0,
              'attendance': 0.0,
            },
          ],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;

      // Ensure new fields exist (migration support)
      List<dynamic> failedSubjects = List.from(data['failedSubjects'] ?? []);
      int totalCreditsEarned = (data['totalCreditsEarned'] as int?) ?? 0;
      String academicStatus = data['academicStatus'] as String? ?? 'active';

      List<dynamic> semesters = List.from(data['semesters'] ?? []);

      // Find or Create Semester
      int semIndex = semesters.indexWhere(
        (s) => s['semesterName'] == semesterName,
      );
      Map<String, dynamic> semesterData;

      if (semIndex == -1) {
        semesterData = {
          'semesterName': semesterName,
          'subjects': [],
          'cgpa': 0.0,
          'attendance': 0.0,
        };
        semesters.add(semesterData);
        semIndex = semesters.length - 1;
      } else {
        semesterData = Map<String, dynamic>.from(semesters[semIndex]);
      }

      // Update Subject in Semester
      List<dynamic> subjects = List.from(semesterData['subjects'] ?? []);
      int subIndex = subjects.indexWhere((s) => s['name'] == subjectName);

      // Check if this was a previously failed subject (ATKT scenario)
      String? previousGrade;
      if (subIndex != -1) {
        previousGrade = (subjects[subIndex]['sgpa'] ?? subjects[subIndex]['grade']) as String?;

        // ACADEMIC INTEGRITY RULE: Prevent grade changes once student has passed
        bool wasPassing = ResultUtils.isPassing(previousGrade);

        if (wasPassing) {
          throw Exception(
            'Cannot modify grade for "$subjectName". Student has already passed with grade "$previousGrade". '
            'Grade modification is only allowed for failed subjects (ATKT).',
          );
        }
      }

      final subjectEntry = {
        'name': subjectName,
        'credits': credits,
        'sgpa': grade,
      };

      if (subIndex == -1) {
        subjects.add(subjectEntry);
      } else {
        subjects[subIndex] = subjectEntry;
      }

      semesterData['subjects'] = subjects;

      // ATKT Logic: Handle credit accumulation
      bool isPassing = ResultUtils.isPassing(grade);
      bool wasFailing = previousGrade != null && !ResultUtils.isPassing(previousGrade);

      if (isPassing && (previousGrade == null || wasFailing)) {
        // First time passing OR clearing ATKT - add credits
        totalCreditsEarned += credits;

        // If clearing ATKT, update failed subjects list
        if (wasFailing) {
          failedSubjects = failedSubjects
              .where((f) => f['subjectName'] != subjectName)
              .toList();
        }
      } else if (!isPassing && (previousGrade == null || !wasFailing)) {
        // New failure - add to failed subjects
        final failedEntry = {
          'subjectName': subjectName,
          'credits': credits,
          'semester': semesterName,
          'originalGrade': grade,
          'attempts': 1,
          'status': 'pending',
        };

        // Check if not already in failed list
        bool exists = failedSubjects.any(
          (f) => f['subjectName'] == subjectName,
        );
        if (!exists) {
          failedSubjects.add(failedEntry);
        }
      }

      // Recalculate SGPA for this semester
      double sgpa = _calculateSGPA(subjects);
      semesterData['cgpa'] = sgpa;

      // Determine Pass/Fail Status based on SGPA < 4.0 rule
      semesterData['sgpaStatus'] = sgpa < 4.0 ? 'Fail' : 'Pass';
      semesterData['isEligibleForReExam'] = sgpa < 4.0;

      semesters[semIndex] = semesterData;

      // Recalculate Overall CGPA
      double overallCGPA = _calculateOverallCGPA(semesters);

      // Academic Standing Logic: Check for detentions
      int pendingATKTs = failedSubjects
          .where((f) => f['status'] == 'pending')
          .length;
      if (pendingATKTs >= 5) {
        academicStatus = 'detained';
      } else if (pendingATKTs == 0 && academicStatus == 'detained') {
        academicStatus = 'active';
      }

      transaction.update(docRef, {
        'semesters': semesters,
        'currentCGPA': overallCGPA,
        'totalCreditsEarned': totalCreditsEarned,
        'failedSubjects': failedSubjects,
        'academicStatus': academicStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Sync CGPA to StudentProfile if it exists
      if (profileSnapshot.exists) {
        transaction.update(profileRef, {
          'cgpa': overallCGPA,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  double _calculateSGPA(List<dynamic> subjects) {
    double totalPoints = 0;
    int totalCredits = 0;

    for (var sub in subjects) {
      int credits = sub['credits'] as int? ?? 0;
      String grade = (sub['sgpa'] ?? sub['grade']) as String? ?? 'F';
      double gradePoint = ResultUtils.getGradePoint(grade);

      // SGPA calculation must include ALL attempted credits in the denominator
      // but only points if the grade point is non-zero
      totalPoints += (gradePoint * credits);
      totalCredits += credits;
    }

    if (totalCredits == 0) return 0.0;
    return double.parse((totalPoints / totalCredits).toStringAsFixed(2));
  }

  double _calculateOverallCGPA(List<dynamic> semesters) {
    if (semesters.isEmpty) return 0.0;

    double totalSGPA = 0;
    int count = 0;

    for (var sem in semesters) {
      totalSGPA += (sem['cgpa'] as num).toDouble();
      count++;
    }

    if (count == 0) return 0.0;
    return double.parse((totalSGPA / count).toStringAsFixed(2));
  }
}
