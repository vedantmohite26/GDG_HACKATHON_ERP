// Notice/Announcement model

import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String id;
  final String title;
  final String content;
  final String
  type; // 'general', 'holiday', 'urgent', 'courseMaterial', 'examResult'
  final String postedBy; // User UID
  final String postedByName; // User name for display
  final DateTime postedAt;
  final DateTime? expiresAt; // Optional expiry date
  final bool isPinned; // Pin to top
  final String? externalLink; // Optional link for resources/results
  final String? course; // Optional target course
  final String? year; // Optional target year
  final String? semester; // Optional target semester

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.postedBy,
    required this.postedByName,
    required this.postedAt,
    this.expiresAt,
    this.isPinned = false,
    this.externalLink,
    this.course,
    this.year,
    this.semester,
  });

  // Create from Firestore document
  factory Notice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Notice(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? 'general',
      postedBy: data['postedBy'] ?? '',
      postedByName: data['postedByName'] ?? '',
      postedAt: (data['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      isPinned: data['isPinned'] ?? false,
      externalLink: data['externalLink'],
      course: data['course'],
      year: data['year'],
      semester: data['semester'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'type': type,
      'postedBy': postedBy,
      'postedByName': postedByName,
      'postedAt': Timestamp.fromDate(postedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isPinned': isPinned,
      'externalLink': externalLink,
      'course': course,
      'year': year,
      'semester': semester,
    };
  }

  // From JSON
  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'general',
      postedBy: json['postedBy'] ?? '',
      postedByName: json['postedByName'] ?? '',
      postedAt: json['postedAt'] is Timestamp
          ? (json['postedAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['postedAt'] ?? DateTime.now().toIso8601String(),
            ),
      expiresAt: json['expiresAt'] != null
          ? (json['expiresAt'] is Timestamp
                ? (json['expiresAt'] as Timestamp).toDate()
                : DateTime.parse(json['expiresAt']))
          : null,
      isPinned: json['isPinned'] ?? false,
      externalLink: json['externalLink'],
      course: json['course'],
      year: json['year'],
      semester: json['semester'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'postedBy': postedBy,
      'postedByName': postedByName,
      'postedAt': postedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isPinned': isPinned,
      'externalLink': externalLink,
      'course': course,
      'year': year,
      'semester': semester,
    };
  }

  // Copy with
  Notice copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    String? postedBy,
    String? postedByName,
    DateTime? postedAt,
    DateTime? expiresAt,
    bool? isPinned,
    String? externalLink,
    String? course,
    String? year,
    String? semester,
  }) {
    return Notice(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      postedBy: postedBy ?? this.postedBy,
      postedByName: postedByName ?? this.postedByName,
      postedAt: postedAt ?? this.postedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isPinned: isPinned ?? this.isPinned,
      externalLink: externalLink ?? this.externalLink,
      course: course ?? this.course,
      year: year ?? this.year,
      semester: semester ?? this.semester,
    );
  }

  // Check if notice is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Check if notice is active
  bool get isActive {
    return !isExpired;
  }
}

// Notice types
class NoticeType {
  static const String general = 'general';
  static const String holiday = 'holiday';
  static const String urgent = 'urgent';
  static const String courseMaterial = 'courseMaterial';
  static const String examResult = 'examResult';

  static const List<String> all = [
    general,
    holiday,
    urgent,
    courseMaterial,
    examResult,
  ];
}
