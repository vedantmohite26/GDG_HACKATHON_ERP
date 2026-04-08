import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import 'dart:math';

/// Service to seed test data for development/testing
class TestDataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _random = Random();

  final _firstNames = [
    'Alex',
    'Jordan',
    'Taylor',
    'Morgan',
    'Casey',
    'Riley',
    'Avery',
    'Quinn',
    'Parker',
    'Cameron',
    'Skyler',
    'Blake',
    'Drew',
    'Reese',
    'Dakota',
    'Sage',
    'River',
    'Phoenix',
    'Rowan',
    'Charlie',
    'Sam',
    'Jamie',
    'Hayden',
    'Peyton',
    'Emerson',
  ];

  final _lastNames = [
    'Smith',
    'Johnson',
    'Williams',
    'Brown',
    'Jones',
    'Garcia',
    'Miller',
    'Davis',
    'Rodriguez',
    'Martinez',
    'Hernandez',
    'Lopez',
    'Gonzalez',
    'Wilson',
    'Anderson',
    'Thomas',
    'Taylor',
    'Moore',
    'Jackson',
    'Martin',
    'Lee',
    'Thompson',
    'White',
    'Harris',
    'Clark',
  ];

  final _branches = Courses.all;

  /// Create 25 test students with randomized data
  Future<void> seedStudents() async {
    debugPrint('🌱 Starting to seed 25 test students...');

    for (int i = 1; i <= 25; i++) {
      try {
        final firstName = _firstNames[_random.nextInt(_firstNames.length)];
        final lastName = _lastNames[_random.nextInt(_lastNames.length)];
        final name = '$firstName $lastName';

        final studentId =
            '2024${_getBranchCode(i)}${i.toString().padLeft(4, '0')}';
        final email =
            '${firstName.toLowerCase()}.${lastName.toLowerCase()}$i@university.edu';
        final password = 'Test@123'; // Default password for all test users

        // Create Firebase Auth user
        UserCredential userCredential;
        try {
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } catch (e) {
          debugPrint('⚠️  User $email already exists, skipping auth creation');
          continue;
        }

        final userId = userCredential.user!.uid;

        // Create user document
        await _firestore.collection(Collections.users).doc(userId).set({
          'email': email,
          'role': UserRole.student,
          'studentUID': studentId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Create student profile
        final branch = _branches[i % _branches.length];
        final year = (i % 4) + 1; // 1-4
        final passoutYear = 2024 + (4 - year);

        await _firestore
            .collection(Collections.studentProfiles)
            .doc(studentId)
            .set({
              'userId': userId,
              'name': name,
              'studentId': studentId,
              'email': email,
              'branch': branch,
              'currentYear': '$year${_getYearSuffix(year)} Year',
              'passoutYear': passoutYear.toString(),
              'phone':
                  '+1 (555) ${_random.nextInt(900) + 100}-${_random.nextInt(9000) + 1000}',
              'profilePhoto': '',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        // Create academic records
        final cgpa = 2.5 + (_random.nextDouble() * 1.5); // 2.5-4.0
        final attendance = 70 + (_random.nextInt(30)); // 70-100%

        await _firestore
            .collection(Collections.academicInfo)
            .doc(studentId)
            .set({
              'studentUID': studentId,
              'currentCGPA': double.parse(cgpa.toStringAsFixed(2)),
              'overallAttendance': attendance.toDouble(),
              'semesters': _generateSemesters(year),
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        debugPrint('✅ Created student $i/25: $name ($email)');
      } catch (e) {
        debugPrint('❌ Error creating student $i: $e');
      }
    }

    debugPrint('🎉 Finished seeding 25 students!');
    debugPrint('📝 Default password for all: Test@123');
  }

  /// Create sample scholarships
  Future<void> seedScholarships() async {
    debugPrint('🌱 Seeding scholarships...');

    final scholarships = [
      {
        'title': 'Global Future Leaders Scholarship 2024',
        'description':
            'Full funding for talented students pursuing Masters in technology.',
        'organization': 'Tech Innovation Foundation',
        'eligibility': 'AI & DS Students',
        'deadline': DateTime(2024, 12, 15),
        'amount': 50000.0,
        'type': 'merit',
        'featured': true,
      },
      {
        'title': 'Tech Innovators Grant',
        'description':
            'Grant for students excelling in computer science and innovation.',
        'organization': 'Foundation for Digital Progress',
        'eligibility': 'All Engineering',
        'deadline': DateTime(2024, 10, 15),
        'amount': 25000.0,
        'type': 'merit',
        'featured': false,
      },
      {
        'title': 'Diversity in STEM Fellowship',
        'description': 'Supporting diversity in STEM fields.',
        'organization': 'Global Tech Alliance',
        'eligibility': 'All Engineering',
        'deadline': DateTime(2024, 11, 20),
        'amount': 30000.0,
        'type': 'need-based',
        'featured': false,
      },
      {
        'title': 'Merit Achievement Award',
        'description': 'For students with CGPA above 3.5.',
        'organization': 'Academic Council',
        'eligibility': 'Top 5% CGPA',
        'deadline': DateTime(2024, 11, 13),
        'amount': 15000.0,
        'type': 'merit',
        'featured': false,
      },
      {
        'title': 'Rural Support Program',
        'description': 'Financial aid for students from rural areas.',
        'organization': 'National Welfare Trust',
        'eligibility': 'Domicile Restricted',
        'deadline': DateTime(2024, 12, 1),
        'amount': 20000.0,
        'type': 'need-based',
        'featured': false,
      },
    ];

    for (final scholarship in scholarships) {
      await _firestore.collection(Collections.scholarships).add({
        ...scholarship,
        'deadline': Timestamp.fromDate(scholarship['deadline'] as DateTime),
        'status': 'active',
        'applicants': _random.nextInt(100),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    debugPrint('✅ Created ${scholarships.length} scholarships');
  }

  /// Create sample notices
  Future<void> seedNotices() async {
    debugPrint('🌱 Seeding notices...');

    final notices = [
      {
        'title': 'Tuition Deadline',
        'description':
            'Semester fees deadline is now October 31st. Please pay before the deadline.',
        'category': 'deadline',
        'priority': 'high',
        'icon': 'access_time',
        'expiresAt': DateTime.now().add(const Duration(days: 7)),
      },
      {
        'title': 'Holiday Alert',
        'description':
            'Campus closed Friday for public holiday. Emergency services available.',
        'category': 'holiday',
        'priority': 'medium',
        'icon': 'celebration',
        'expiresAt': DateTime.now().add(const Duration(days: 14)),
      },
      {
        'title': 'Library Policy',
        'description':
            'New digital borrowing rules apply from next week. Check library portal.',
        'category': 'policy',
        'priority': 'low',
        'icon': 'description',
        'expiresAt': DateTime.now().add(const Duration(days: 30)),
      },
    ];

    for (final notice in notices) {
      await _firestore.collection(Collections.notices).add({
        ...notice,
        'expiresAt': Timestamp.fromDate(notice['expiresAt'] as DateTime),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    debugPrint('✅ Created ${notices.length} notices');
  }

  /// Create test Faculty user
  Future<void> seedFaculty() async {
    debugPrint('🌱 Seeding Faculty user...');
    try {
      const email = 'faculty.member@university.edu';
      const password = 'Test@123';

      UserCredential userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        debugPrint('⚠️ Faculty user already exists');
        return;
      }

      await _firestore
          .collection(Collections.users)
          .doc(userCredential.user!.uid)
          .set({
            'email': email,
            'role': UserRole.faculty, // Changed from admin to faculty
            'name': 'Dr. Faculty Member',
            'department': 'Computer Science',
            'createdAt': FieldValue.serverTimestamp(),
          });

      debugPrint('✅ Created Faculty user: $email');
    } catch (e) {
      debugPrint('❌ Error creating Faculty: $e');
    }
  }

  /// Create test Committee user
  Future<void> seedCommittee() async {
    debugPrint('🌱 Seeding Committee user...');
    try {
      const email = 'committee.head@university.edu';
      const password = 'Test@123';

      UserCredential userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        debugPrint('⚠️ Committee user already exists');
        return;
      }

      await _firestore
          .collection(Collections.users)
          .doc(userCredential.user!.uid)
          .set({
            'email': email,
            'role': UserRole.committee,
            'name': 'Head of Committee',
            'createdAt': FieldValue.serverTimestamp(),
          });

      debugPrint('✅ Created Committee user: $email');
    } catch (e) {
      debugPrint('❌ Error creating Committee: $e');
    }
  }

  // Helper methods
  String _getBranchCode(int index) {
    final codes = ['CS', 'DS', 'EC', 'ME', 'CE', 'EE'];
    return codes[index % codes.length];
  }

  String _getYearSuffix(int year) {
    switch (year) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  List<Map<String, dynamic>> _generateSemesters(int currentYear) {
    final semesters = <Map<String, dynamic>>[];
    final semesterNames = [
      'Fall 2023',
      'Spring 2024',
      'Fall 2024',
      'Spring 2025',
      'Fall 2025',
    ];

    for (int i = 0; i < currentYear * 2; i++) {
      final cgpa = 2.5 + (_random.nextDouble() * 1.5);
      final attendance = 70 + (_random.nextInt(30));

      semesters.add({
        'semesterName': semesterNames[i],
        'cgpa': double.parse(cgpa.toStringAsFixed(2)),
        'attendance': attendance.toDouble(),
        'subjects': _generateSubjects(),
      });
    }

    return semesters;
  }

  List<Map<String, dynamic>> _generateSubjects() {
    final subjects = [
      {
        'name': 'Mathematics IV',
        'code': 'MTH-401',
        'credits': 4,
        'sgpa': '8.5',
        'attendance': 95,
      },
      {
        'name': 'Database Systems',
        'code': 'CS-302',
        'credits': 3,
        'sgpa': '7.0',
        'attendance': 78,
      },
      {
        'name': 'Software Engineering',
        'code': 'SE-201',
        'credits': 3,
        'sgpa': '9.0',
        'attendance': 88,
      },
    ];

    final numericSgpas = ['9.5', '8.0', '7.5', '6.0', '8.5', '9.0'];

    return subjects.map((s) {
      return {
        ...s,
        'sgpa': numericSgpas[_random.nextInt(numericSgpas.length)],
        'attendance': 70 + _random.nextInt(30),
      };
    }).toList();
  }

  /// Seed everything
  Future<void> seedAll() async {
    debugPrint('\n🚀 Starting full database seed...\n');
    await seedStudents();
    await seedScholarships();
    await seedNotices();
    await seedFaculty();
    await seedCommittee();
    debugPrint('\n✅ Database seeding complete! Signing out...\n');
    await _auth.signOut();
  }
}
