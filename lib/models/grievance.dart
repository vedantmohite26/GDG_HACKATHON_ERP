// Grievance model

import 'package:cloud_firestore/cloud_firestore.dart';

class Grievance {
  final String id;
  final String userId; // Firebase Auth UID (New)
  final String? studentUID; // Enrollment number
  final String category;
  final String description;
  final List<String> proofUrls;
  final bool isAnonymous;
  final int priorityScore;
  final String status;
  final String? assignedTo;
  final DateTime submittedAt;
  final DateTime slaDeadline;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? internalNotes;

  Grievance({
    required this.id,
    required this.userId, // Required
    this.studentUID,
    required this.category,
    required this.description,
    this.proofUrls = const [],
    required this.isAnonymous,
    required this.priorityScore,
    required this.status,
    this.assignedTo,
    required this.submittedAt,
    required this.slaDeadline,
    this.resolvedAt,
    this.resolvedBy,
    this.internalNotes,
  });

  // Create from Firestore document
  factory Grievance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Grievance(
      id: doc.id,
      userId: data['userId'] ?? '', // Handle migration
      studentUID: data['studentUID'],
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      proofUrls: List<String>.from(data['proofUrls'] ?? []),
      isAnonymous: data['isAnonymous'] ?? false,
      priorityScore: data['priorityScore'] ?? 0,
      status: data['status'] ?? 'pending',
      assignedTo: data['assignedTo'],
      submittedAt:
          (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      slaDeadline:
          (data['slaDeadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      resolvedBy: data['resolvedBy'],
      internalNotes: data['internalNotes'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'studentUID': studentUID,
      'category': category,
      'description': description,
      'proofUrls': proofUrls,
      'isAnonymous': isAnonymous,
      'priorityScore': priorityScore,
      'status': status,
      'assignedTo': assignedTo,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'slaDeadline': Timestamp.fromDate(slaDeadline),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
      'internalNotes': internalNotes,
    };
  }

  // From JSON
  factory Grievance.fromJson(Map<String, dynamic> json) {
    return Grievance(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      studentUID: json['studentUID'],
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      proofUrls: List<String>.from(json['proofUrls'] ?? []),
      isAnonymous: json['isAnonymous'] ?? false,
      priorityScore: json['priorityScore'] ?? 0,
      status: json['status'] ?? 'pending',
      assignedTo: json['assignedTo'],
      submittedAt: json['submittedAt'] is Timestamp
          ? (json['submittedAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['submittedAt'] ?? DateTime.now().toIso8601String(),
            ),
      slaDeadline: json['slaDeadline'] is Timestamp
          ? (json['slaDeadline'] as Timestamp).toDate()
          : DateTime.parse(
              json['slaDeadline'] ?? DateTime.now().toIso8601String(),
            ),
      resolvedAt: json['resolvedAt'] != null
          ? (json['resolvedAt'] is Timestamp
                ? (json['resolvedAt'] as Timestamp).toDate()
                : DateTime.parse(json['resolvedAt']))
          : null,
      internalNotes: json['internalNotes'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'studentUID': studentUID,
      'category': category,
      'description': description,
      'proofUrls': proofUrls,
      'isAnonymous': isAnonymous,
      'priorityScore': priorityScore,
      'status': status,
      'assignedTo': assignedTo,
      'submittedAt': submittedAt.toIso8601String(),
      'slaDeadline': slaDeadline.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'internalNotes': internalNotes,
    };
  }

  // Copy with
  Grievance copyWith({
    String? id,
    String? userId,
    String? studentUID,
    String? category,
    String? description,
    List<String>? proofUrls,
    bool? isAnonymous,
    int? priorityScore,
    String? status,
    String? assignedTo,
    DateTime? submittedAt,
    DateTime? slaDeadline,
    DateTime? resolvedAt,
    String? internalNotes,
  }) {
    return Grievance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      studentUID: studentUID ?? this.studentUID,
      category: category ?? this.category,
      description: description ?? this.description,
      proofUrls: proofUrls ?? this.proofUrls,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      priorityScore: priorityScore ?? this.priorityScore,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      submittedAt: submittedAt ?? this.submittedAt,
      slaDeadline: slaDeadline ?? this.slaDeadline,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      internalNotes: internalNotes ?? this.internalNotes,
    );
  }

  // Status check helpers
  bool get isPending => status == 'pending';
  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in-progress';
  bool get isResolved => status == 'resolved';

  // SLA check
  bool get isSLABreached => DateTime.now().isAfter(slaDeadline) && !isResolved;

  // Get SLA status
  String get slaStatus {
    if (isResolved) return 'completed';

    final now = DateTime.now();
    final difference = slaDeadline.difference(now);

    if (difference.isNegative) {
      return 'breached';
    } else if (difference.inHours < 6) {
      return 'critical';
    } else if (difference.inHours < 24) {
      return 'warning';
    } else {
      return 'normal';
    }
  }
}
