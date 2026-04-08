import 'package:cloud_firestore/cloud_firestore.dart';

class FacultyProfile {
  final String id; // Auth UID
  final String employeeId;
  final String name;
  final String email;
  final String department;
  final String designation;
  final String phone;
  final String qualification;
  final String specialization;
  final DateTime joiningDate;
  final String profilePhoto;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  FacultyProfile({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.department,
    required this.designation,
    required this.phone,
    required this.qualification,
    required this.specialization,
    required this.joiningDate,
    required this.profilePhoto,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FacultyProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FacultyProfile(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      department: data['department'] ?? '',
      designation: data['designation'] ?? '',
      phone: data['phone'] ?? '',
      qualification: data['qualification'] ?? '',
      specialization: data['specialization'] ?? '',
      joiningDate:
          (data['joiningDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profilePhoto: data['profilePhoto'] ?? '',
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'name': name,
      'email': email,
      'department': department,
      'designation': designation,
      'phone': phone,
      'qualification': qualification,
      'specialization': specialization,
      'joiningDate': Timestamp.fromDate(joiningDate),
      'profilePhoto': profilePhoto,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
