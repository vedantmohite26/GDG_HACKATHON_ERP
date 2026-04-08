// Student profile model

import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfile {
  final String id;
  final String userId; // Firebase Auth UID
  final String studentUID; // Enrollment number
  final String name;
  final String gender; // New field
  final String course;
  final int year;
  final String passoutYear; // Added field
  final String category; // General, OBC, SC, ST, EWS
  final double familyIncome;
  final double cgpa;
  final double attendance;
  final String contactNumber;
  final String parentContactNumber; // Parent's contact number
  final String profilePhoto; // Added profile photo URL
  final String bloodGroup; // New field
  final String dateOfBirth; // New field
  final String shift; // New field (e.g., FIRST, SECOND)
  final String validFrom; // New field (e.g., 14.08.2023)
  final String? photoPublicId; // NEW: Cloudinary Public ID for deletion

  final DateTime createdAt;
  final DateTime updatedAt;

  StudentProfile({
    required this.id,
    required this.userId,
    required this.studentUID,
    required this.name,
    this.gender = 'Male', // Default to Male if not specified
    required this.course,
    required this.year,
    this.passoutYear = '', // Added field
    required this.category,
    required this.familyIncome,
    this.cgpa = 0.0, // Default
    this.attendance = 0.0, // Default
    required this.contactNumber,
    required this.parentContactNumber,
    this.profilePhoto = '', // Added profile photo URL
    this.bloodGroup = 'Not Specified',
    this.dateOfBirth = '',
    this.shift = 'FIRST',
    this.validFrom = '',
    this.photoPublicId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Firestore document
  factory StudentProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentProfile(
      id: doc.id,
      userId: data['userId'] ?? '',
      studentUID: (data['studentUID'] as String?)?.isNotEmpty == true ? data['studentUID'] : doc.id,
      name: data['name'] ?? '',
      gender: data['gender'] ?? 'Male',
      course: data['course'] ?? data['branch'] ?? '',
      year: data['year'] ?? data['currentYear'] ?? 1,
      passoutYear: data['passoutYear'] ?? '',
      category: data['category'] ?? '',
      familyIncome: (data['familyIncome'] ?? 0).toDouble(),
      cgpa: (data['cgpa'] ?? 0.0).toDouble(),
      attendance: (data['attendance'] ?? 0.0).toDouble(),
      contactNumber: data['contactNumber'] ?? '',
      parentContactNumber: data['parentContactNumber'] ?? '',
      profilePhoto: data['profilePhoto'] ?? '',
      bloodGroup: data['bloodGroup'] ?? 'Not Specified',
      dateOfBirth: data['dateOfBirth'] ?? '',
      shift: data['shift'] ?? 'FIRST',
      validFrom: data['validFrom'] ?? '',
      photoPublicId: data['photoPublicId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create from Map (Hive)
  factory StudentProfile.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic d) {
      if (d is DateTime) return d;
      if (d is Timestamp) return d.toDate();
      return DateTime.tryParse(d?.toString() ?? '') ?? DateTime.now();
    }

    return StudentProfile(
      id: id,
      userId: data['userId'] ?? '',
      studentUID: data['studentUID'] ?? '',
      name: data['name'] ?? '',
      gender: data['gender'] ?? 'Male',
      course: data['course'] ?? '',
      year: data['year'] ?? 1,
      passoutYear: data['passoutYear'] ?? '',
      category: data['category'] ?? '',
      familyIncome: (data['familyIncome'] ?? 0).toDouble(),
      cgpa: (data['cgpa'] ?? 0.0).toDouble(),
      attendance: (data['attendance'] ?? 0.0).toDouble(),
      contactNumber: data['contactNumber'] ?? '',
      parentContactNumber: data['parentContactNumber'] ?? '',
      profilePhoto: data['profilePhoto'] ?? '',
      bloodGroup: data['bloodGroup'] ?? 'Not Specified',
      dateOfBirth: data['dateOfBirth'] ?? '',
      shift: data['shift'] ?? 'FIRST',
      validFrom: data['validFrom'] ?? '',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'studentUID': studentUID,
      'name': name,
      'gender': gender,
      'course': course,
      'year': year,
      'passoutYear': passoutYear,
      'category': category,
      'familyIncome': familyIncome,
      'cgpa': cgpa,
      'attendance': attendance,
      'contactNumber': contactNumber,
      'parentContactNumber': parentContactNumber,
      'profilePhoto': profilePhoto,
      'bloodGroup': bloodGroup,
      'dateOfBirth': dateOfBirth,
      'shift': shift,
      'validFrom': validFrom,
      'photoPublicId': photoPublicId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // From JSON
  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      studentUID: json['studentUID'] ?? '',
      name: json['name'] ?? '',
      gender: json['gender'] ?? 'Male',
      course: json['course'] ?? '',
      year: json['year'] ?? 1,
      passoutYear: json['passoutYear'] ?? '',
      category: json['category'] ?? '',
      familyIncome: (json['familyIncome'] ?? 0).toDouble(),
      cgpa: (json['cgpa'] ?? 0.0).toDouble(),
      attendance: (json['attendance'] ?? 0.0).toDouble(),
      contactNumber: json['contactNumber'] ?? '',
      parentContactNumber: json['parentContactNumber'] ?? '',
      profilePhoto: json['profilePhoto'] ?? '',
      bloodGroup: json['bloodGroup'] ?? 'Not Specified',
      dateOfBirth: json['dateOfBirth'] ?? '',
      shift: json['shift'] ?? 'FIRST',
      validFrom: json['validFrom'] ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['createdAt'] ?? DateTime.now().toIso8601String(),
            ),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['updatedAt'] ?? DateTime.now().toIso8601String(),
            ),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'studentUID': studentUID,
      'name': name,
      'gender': gender,
      'course': course,
      'year': year,
      'passoutYear': passoutYear,
      'category': category,
      'familyIncome': familyIncome,
      'cgpa': cgpa,
      'attendance': attendance,
      'contactNumber': contactNumber,
      'parentContactNumber': parentContactNumber,
      'profilePhoto': profilePhoto,
      'bloodGroup': bloodGroup,
      'dateOfBirth': dateOfBirth,
      'shift': shift,
      'validFrom': validFrom,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with
  StudentProfile copyWith({
    String? id,
    String? userId,
    String? studentUID,
    String? name,
    String? gender,
    String? course,
    int? year,
    String? passoutYear,
    String? category,
    double? familyIncome,
    double? cgpa,
    double? attendance,
    String? contactNumber,
    String? parentContactNumber,
    String? profilePhoto,
    String? bloodGroup,
    String? dateOfBirth,
    String? shift,
    String? validFrom,
    String? photoPublicId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      studentUID: studentUID ?? this.studentUID,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      course: course ?? this.course,
      year: year ?? this.year,
      passoutYear: passoutYear ?? this.passoutYear,
      category: category ?? this.category,
      familyIncome: familyIncome ?? this.familyIncome,
      cgpa: cgpa ?? this.cgpa,
      attendance: attendance ?? this.attendance,
      contactNumber: contactNumber ?? this.contactNumber,
      parentContactNumber: parentContactNumber ?? this.parentContactNumber,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      shift: shift ?? this.shift,
      validFrom: validFrom ?? this.validFrom,
      photoPublicId: photoPublicId ?? this.photoPublicId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if profile is complete
  bool get isComplete {
    return studentUID.isNotEmpty &&
        name.isNotEmpty &&
        course.isNotEmpty &&
        year > 0 &&
        category.isNotEmpty &&
        familyIncome >= 0 &&
        contactNumber.isNotEmpty;
  }

  // Getters for compatibility
  String get rollNumber => studentUID;
  // removed cgpa getter

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
