// Scholarship model

import 'package:cloud_firestore/cloud_firestore.dart';

class EligibilityCriteria {
  final double minIncome;
  final double maxIncome;
  final double minCGPA;
  final double minAttendance;
  final List<String> categories; // Student categories eligible
  final List<String> courses; // Courses eligible
  final List<int> years; // Years eligible

  EligibilityCriteria({
    required this.minIncome,
    required this.maxIncome,
    this.minCGPA = 0.0,
    this.minAttendance = 0.0,
    required this.categories,
    required this.courses,
    required this.years,
  });

  factory EligibilityCriteria.fromJson(Map<String, dynamic> json) {
    return EligibilityCriteria(
      minIncome: (json['minIncome'] ?? 0).toDouble(),
      maxIncome: (json['maxIncome'] ?? double.infinity).toDouble(),
      minCGPA: (json['minCGPA'] ?? 0.0).toDouble(),
      minAttendance: (json['minAttendance'] ?? 0.0).toDouble(),
      categories: List<String>.from(json['categories'] ?? []),
      courses: List<String>.from(json['courses'] ?? []),
      years: List<int>.from(json['years'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minIncome': minIncome,
      'maxIncome': maxIncome,
      'minCGPA': minCGPA,
      'minAttendance': minAttendance,
      'categories': categories,
      'courses': courses,
      'years': years,
    };
  }
}

class Scholarship {
  final String id;
  final String title;
  final String organization;
  final String description;
  final double amount;
  final EligibilityCriteria eligibilityCriteria;
  final DateTime deadline;
  final String? applicationURL;
  final String createdBy; // Admin UID
  final DateTime createdAt;

  Scholarship({
    required this.id,
    required this.title,
    required this.organization,
    required this.description,
    required this.amount,
    required this.eligibilityCriteria,
    required this.deadline,
    this.applicationURL,
    required this.createdBy,
    required this.createdAt,
  });

  // Create from Firestore document
  factory Scholarship.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Scholarship(
      id: doc.id,
      title: data['title'] ?? data['name'] ?? '',
      organization: data['organization'] ?? 'Various',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      eligibilityCriteria: EligibilityCriteria.fromJson(
        data['eligibilityCriteria'] ?? {},
      ),
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      applicationURL: data['applicationURL'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'organization': organization,
      'description': description,
      'amount': amount,
      'eligibilityCriteria': eligibilityCriteria.toJson(),
      'deadline': Timestamp.fromDate(deadline),
      'applicationURL': applicationURL,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // From JSON
  factory Scholarship.fromJson(Map<String, dynamic> json) {
    return Scholarship(
      id: json['id'] ?? '',
      title: json['title'] ?? json['name'] ?? '',
      organization: json['organization'] ?? 'Various',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      eligibilityCriteria: EligibilityCriteria.fromJson(
        json['eligibilityCriteria'] ?? {},
      ),
      deadline: json['deadline'] is Timestamp
          ? (json['deadline'] as Timestamp).toDate()
          : DateTime.parse(
              json['deadline'] ?? DateTime.now().toIso8601String(),
            ),
      applicationURL: json['applicationURL'],
      createdBy: json['createdBy'] ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['createdAt'] ?? DateTime.now().toIso8601String(),
            ),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'organization': organization,
      'description': description,
      'amount': amount,
      'eligibilityCriteria': eligibilityCriteria.toJson(),
      'deadline': deadline.toIso8601String(),
      'applicationURL': applicationURL,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Copy with
  Scholarship copyWith({
    String? id,
    String? title,
    String? organization,
    String? description,
    double? amount,
    EligibilityCriteria? eligibilityCriteria,
    DateTime? deadline,
    String? applicationURL,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Scholarship(
      id: id ?? this.id,
      title: title ?? this.title,
      organization: organization ?? this.organization,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      eligibilityCriteria: eligibilityCriteria ?? this.eligibilityCriteria,
      deadline: deadline ?? this.deadline,
      applicationURL: applicationURL ?? this.applicationURL,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Check if deadline has passed
  bool get isExpired {
    return DateTime.now().isAfter(deadline);
  }

  // Check if deadline is approaching (within 7 days)
  bool get isDeadlineApproaching {
    final daysRemaining = deadline.difference(DateTime.now()).inDays;
    return daysRemaining >= 0 && daysRemaining <= 7;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Scholarship && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
