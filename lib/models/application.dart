// Scholarship application model

import 'package:cloud_firestore/cloud_firestore.dart';

class Application {
  final String id;
  final String studentUID;
  final String scholarshipId;
  final String status; // pending, approved, rejected
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy; // Admin UID
  final String? adminNotes;

  final String? assignedFacultyId;
  final String? facultyRecommendation; // 'recommended', 'not_recommended'
  final String? facultyComments;

  // New fields for enhanced application
  final String? caste; // General, OBC, SC, ST, EWS
  final double? familyIncome;
  final List<String>? uploadedDocuments; // URLs to Firebase Storage
  final Map<String, String>? documentTypes; // filename → type mapping
  final String
  notificationStatus; // 'none', 'acknowledged', 'approved', 'rejected'

  Application({
    required this.id,
    required this.studentUID,
    required this.scholarshipId,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.adminNotes,
    this.assignedFacultyId,
    this.facultyRecommendation,
    this.facultyComments,
    this.caste,
    this.familyIncome,
    this.uploadedDocuments,
    this.documentTypes,
    this.notificationStatus = 'none',
  });

  // Create from Firestore document
  factory Application.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Application(
      id: doc.id,
      studentUID: data['studentUID'] ?? '',
      scholarshipId: data['scholarshipId'] ?? '',
      status: data['status'] ?? 'pending',
      submittedAt:
          (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'],
      adminNotes: data['adminNotes'],
      assignedFacultyId: data['assignedFacultyId'],
      facultyRecommendation: data['facultyRecommendation'],
      facultyComments: data['facultyComments'],
      caste: data['caste'],
      familyIncome: data['familyIncome']?.toDouble(),
      uploadedDocuments: data['uploadedDocuments'] != null
          ? List<String>.from(data['uploadedDocuments'])
          : null,
      documentTypes: data['documentTypes'] != null
          ? Map<String, String>.from(data['documentTypes'])
          : null,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'studentUID': studentUID,
      'scholarshipId': scholarshipId,
      'status': status,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'adminNotes': adminNotes,
      'assignedFacultyId': assignedFacultyId,
      'facultyRecommendation': facultyRecommendation,
      'facultyComments': facultyComments,
      'caste': caste,
      'familyIncome': familyIncome,
      'uploadedDocuments': uploadedDocuments,
      'documentTypes': documentTypes,
    };
  }

  // From JSON
  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] ?? '',
      studentUID: json['studentUID'] ?? '',
      scholarshipId: json['scholarshipId'] ?? '',
      status: json['status'] ?? 'pending',
      submittedAt: json['submittedAt'] is Timestamp
          ? (json['submittedAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['submittedAt'] ?? DateTime.now().toIso8601String(),
            ),
      reviewedAt: json['reviewedAt'] != null
          ? (json['reviewedAt'] is Timestamp
                ? (json['reviewedAt'] as Timestamp).toDate()
                : DateTime.parse(json['reviewedAt']))
          : null,
      reviewedBy: json['reviewedBy'],
      adminNotes: json['adminNotes'],
      assignedFacultyId: json['assignedFacultyId'],
      facultyRecommendation: json['facultyRecommendation'],
      facultyComments: json['facultyComments'],
      caste: json['caste'],
      familyIncome: json['familyIncome'] != null
          ? (json['familyIncome'] as num).toDouble()
          : null,
      uploadedDocuments: json['uploadedDocuments'] != null
          ? List<String>.from(json['uploadedDocuments'])
          : null,
      documentTypes: json['documentTypes'] != null
          ? Map<String, String>.from(json['documentTypes'])
          : null,
      notificationStatus: json['notificationStatus'] ?? 'none',
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentUID': studentUID,
      'scholarshipId': scholarshipId,
      'status': status,
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'adminNotes': adminNotes,
      'assignedFacultyId': assignedFacultyId,
      'facultyRecommendation': facultyRecommendation,
      'facultyComments': facultyComments,
      'caste': caste,
      'familyIncome': familyIncome,
      'uploadedDocuments': uploadedDocuments,
      'documentTypes': documentTypes,
      'notificationStatus': notificationStatus,
    };
  }

  // Copy with
  Application copyWith({
    String? id,
    String? studentUID,
    String? scholarshipId,
    String? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? adminNotes,
    String? assignedFacultyId,
    String? facultyRecommendation,
    String? facultyComments,
    String? caste,
    double? familyIncome,
    List<String>? uploadedDocuments,
    Map<String, String>? documentTypes,
    String? notificationStatus,
  }) {
    return Application(
      id: id ?? this.id,
      studentUID: studentUID ?? this.studentUID,
      scholarshipId: scholarshipId ?? this.scholarshipId,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      adminNotes: adminNotes ?? this.adminNotes,
      assignedFacultyId: assignedFacultyId ?? this.assignedFacultyId,
      facultyRecommendation:
          facultyRecommendation ?? this.facultyRecommendation,
      facultyComments: facultyComments ?? this.facultyComments,
      caste: caste ?? this.caste,
      familyIncome: familyIncome ?? this.familyIncome,
      uploadedDocuments: uploadedDocuments ?? this.uploadedDocuments,
      documentTypes: documentTypes ?? this.documentTypes,
      notificationStatus: notificationStatus ?? this.notificationStatus,
    );
  }

  // Status check helpers
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isReverted => status == 'reverted';
}
