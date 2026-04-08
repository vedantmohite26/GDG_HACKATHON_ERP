// Academic information model

import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicEvent {
  final String type; // exam, holiday, result, other
  final String title;
  final DateTime date;
  final String description;

  AcademicEvent({
    required this.type,
    required this.title,
    required this.date,
    required this.description,
  });

  factory AcademicEvent.fromJson(Map<String, dynamic> json) {
    return AcademicEvent(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      date: json['date'] is Timestamp
          ? (json['date'] as Timestamp).toDate()
          : DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'date': Timestamp.fromDate(date),
      'description': description,
    };
  }
}

class AcademicInfo {
  final String id;
  final int year;
  final String course;
  final List<AcademicEvent> events;
  final String updatedBy; // Admin UID
  final DateTime updatedAt;

  AcademicInfo({
    required this.id,
    required this.year,
    required this.course,
    required this.events,
    required this.updatedBy,
    required this.updatedAt,
  });

  // Create from Firestore document
  factory AcademicInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final eventsList = data['events'] as List<dynamic>? ?? [];

    return AcademicInfo(
      id: doc.id,
      year: data['year'] ?? 1,
      course: data['course'] ?? '',
      events: eventsList
          .map((e) => AcademicEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedBy: data['updatedBy'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'year': year,
      'course': course,
      'events': events.map((e) => e.toJson()).toList(),
      'updatedBy': updatedBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // From JSON
  factory AcademicInfo.fromJson(Map<String, dynamic> json) {
    final eventsList = json['events'] as List<dynamic>? ?? [];

    return AcademicInfo(
      id: json['id'] ?? '',
      year: json['year'] ?? 1,
      course: json['course'] ?? '',
      events: eventsList
          .map((e) => AcademicEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedBy: json['updatedBy'] ?? '',
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
      'year': year,
      'course': course,
      'events': events.map((e) => e.toJson()).toList(),
      'updatedBy': updatedBy,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with
  AcademicInfo copyWith({
    String? id,
    int? year,
    String? course,
    List<AcademicEvent>? events,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return AcademicInfo(
      id: id ?? this.id,
      year: year ?? this.year,
      course: course ?? this.course,
      events: events ?? this.events,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get upcoming events
  List<AcademicEvent> get upcomingEvents {
    final now = DateTime.now();
    return events.where((event) => event.date.isAfter(now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // Get events by type
  List<AcademicEvent> getEventsByType(String type) {
    return events.where((event) => event.type == type).toList();
  }
}
