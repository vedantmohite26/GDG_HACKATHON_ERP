import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'cache_service.dart';
import '../utils/constants.dart';

class ScholarshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = CacheService();

  // Get all scholarships
  Future<List<Map<String, dynamic>>> getScholarships({
    String? type, // 'merit' or 'need-based'
    bool? featured,
  }) async {
    try {
      // Check cache (simplified for "all scholarships" for now)
      if (type == null && featured == null) {
        final cached = _cacheService.getCachedScholarships();
        if (cached != null) {
          // Only refresh if cache is older than 10 minutes
          if (_cacheService.shouldRefresh(CacheService.scholarshipsBoxName, 'all_scholarships')) {
            _refreshScholarshipsInBackground();
          }
          return cached.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }

      Query<Map<String, dynamic>> query = _firestore.collection(Collections.scholarships);

      // Filter by type if provided
      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }

      // Filter by featured if provided
      if (featured != null && featured) {
        query = query.where('featured', isEqualTo: true);
      }

      // Only active scholarships
      query = query.where('status', isEqualTo: 'active');

      final snapshot = await query.get();

      final docs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort in memory by createdAt descending
      docs.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      if (type == null && featured == null) {
        _cacheService.cacheScholarships(docs);
      }
      return docs;
    } catch (e) {
      debugPrint('Error getting scholarships: $e');
      return [];
    }
  }

  // Get scholarship by ID
  Future<Map<String, dynamic>?> getScholarship(String scholarshipId) async {
    try {
      final doc = await _firestore
          .collection(Collections.scholarships)
          .doc(scholarshipId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      debugPrint('Error getting scholarship: $e');
      return null;
    }
  }

  // Create scholarship (Admin/Committee only)
  Future<String> createScholarship({
    required String title,
    required String description,
    required String organization,
    required String eligibility,
    required DateTime deadline,
    required double amount,
    required String type, // 'merit' or 'need-based'
    bool featured = false,
  }) async {
    final docRef = await _firestore.collection(Collections.scholarships).add({
      'title': title,
      'description': description,
      'organization': organization,
      'eligibility': eligibility,
      'deadline': Timestamp.fromDate(deadline),
      'amount': amount,
      'type': type,
      'status': 'active',
      'featured': featured,
      'applicants': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // Update scholarship
  Future<void> updateScholarship(
    String scholarshipId,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection(Collections.scholarships)
        .doc(scholarshipId)
        .update(data);
  }

  // Delete scholarship
  Future<void> deleteScholarship(String scholarshipId) async {
    await _firestore
        .collection(Collections.scholarships)
        .doc(scholarshipId)
        .delete();
  }

  // Stream scholarships for real-time updates
  Stream<List<Map<String, dynamic>>> scholarshipsStream({String? type}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(Collections.scholarships)
        .where('status', isEqualTo: 'active');

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    return query.snapshots().map((snapshot) {
      final docs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort in memory by createdAt descending
      docs.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return docs;
    });
  }

  // Background refresh helper
  void _refreshScholarshipsInBackground() async {
    try {
      final snapshot = await _firestore
          .collection(Collections.scholarships)
          .where('status', isEqualTo: 'active')
          .get();
          
      final docs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      _cacheService.cacheScholarships(docs);
    } catch (e) {
      debugPrint('ScholarshipService: Background refresh failed: $e');
    }
  }

  // Check if deadline is approaching (within 7 days)
  bool isDeadlineApproaching(Timestamp deadline) {
    final now = DateTime.now();
    final deadlineDate = deadline.toDate();
    final difference = deadlineDate.difference(now);

    return difference.inDays <= 7 && difference.inDays >= 0;
  }

  // Get days left until deadline
  int getDaysLeft(Timestamp deadline) {
    final now = DateTime.now();
    final deadlineDate = deadline.toDate();
    final difference = deadlineDate.difference(now);

    return difference.inDays;
  }

  // Format deadline string
  String formatDeadline(Timestamp deadline) {
    final daysLeft = getDaysLeft(deadline);

    if (daysLeft < 0) {
      return 'Expired';
    } else if (daysLeft == 0) {
      return 'Today';
    } else if (daysLeft == 1) {
      return 'Tomorrow';
    } else if (daysLeft <= 7) {
      return '$daysLeft Days Left';
    } else {
      final deadlineDate = deadline.toDate();
      return '${deadlineDate.day}/${deadlineDate.month}/${deadlineDate.year}';
    }
  }
}
