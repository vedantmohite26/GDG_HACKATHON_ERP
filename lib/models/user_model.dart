// User model for authentication data

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // student, admin, committee
  final String studentUID; // Enrollment number
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.studentUID,
    required this.createdAt,
  });

  // Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      studentUID: data['studentUID'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create UserModel from Map (Hive)
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      studentUID: data['studentUID'] ?? '',
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt']
          : data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
                DateTime.now(),
    );
  }

  // Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role,
      'studentUID': studentUID,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      studentUID: json['studentUID'] ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['createdAt'] ?? DateTime.now().toIso8601String(),
            ),
    );
  }

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'studentUID': studentUID,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Copy with method for immutability
  UserModel copyWith({
    String? uid,
    String? email,
    String? role,
    String? studentUID,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      studentUID: studentUID ?? this.studentUID,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
