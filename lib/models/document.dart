// Document metadata model

import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String id;
  final String studentUID;
  final String fileName;
  final String fileType; // pdf, jpg, png
  final int fileSize; // in bytes
  final String storageURL; // Firebase Storage download URL
  final DateTime uploadedAt;
  final String status; // pending, verified, rejected
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? rejectionReason;

  DocumentModel({
    required this.id,
    required this.studentUID,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.storageURL,
    required this.uploadedAt,
    this.status = 'pending',
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionReason,
  });

  // Create from Firestore document
  factory DocumentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DocumentModel(
      id: doc.id,
      studentUID: data['studentUID'] ?? '',
      fileName: data['fileName'] ?? '',
      fileType: data['fileType'] ?? '',
      fileSize: data['fileSize'] ?? 0,
      storageURL: data['storageURL'] ?? '',
      uploadedAt:
          (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      verifiedBy: data['verifiedBy'],
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'studentUID': studentUID,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'storageURL': storageURL,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'status': status,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }

  // From JSON
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] ?? '',
      studentUID: json['studentUID'] ?? '',
      fileName: json['fileName'] ?? '',
      fileType: json['fileType'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      storageURL: json['storageURL'] ?? '',
      uploadedAt: json['uploadedAt'] is Timestamp
          ? (json['uploadedAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['uploadedAt'] ?? DateTime.now().toIso8601String(),
            ),
      status: json['status'] ?? 'pending',
      verifiedBy: json['verifiedBy'],
      verifiedAt: json['verifiedAt'] != null
          ? (json['verifiedAt'] is Timestamp
                ? (json['verifiedAt'] as Timestamp).toDate()
                : DateTime.parse(json['verifiedAt']))
          : null,
      rejectionReason: json['rejectionReason'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentUID': studentUID,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'storageURL': storageURL,
      'uploadedAt': uploadedAt.toIso8601String(),
      'status': status,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  // Copy with
  DocumentModel copyWith({
    String? id,
    String? studentUID,
    String? fileName,
    String? fileType,
    int? fileSize,
    String? storageURL,
    DateTime? uploadedAt,
    String? status,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? rejectionReason,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      studentUID: studentUID ?? this.studentUID,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      storageURL: storageURL ?? this.storageURL,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      status: status ?? this.status,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  // Get file size in human-readable format
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  // Get file icon based on type
  String get fileIcon {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return '🖼️';
      default:
        return '📁';
    }
  }
}
