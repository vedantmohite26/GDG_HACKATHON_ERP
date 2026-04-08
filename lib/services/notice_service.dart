import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'cache_service.dart';
import '../utils/constants.dart';

class NoticeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = CacheService();

  // Get recent notices (for dashboard)
  Future<List<Map<String, dynamic>>> getRecentNotices({int limit = 3}) async {
    try {
      // Check cache first
      final cached = _cacheService.getCachedNotices();
      if (cached != null) {
        // Only refresh if cache is older than 10 minutes
        if (_cacheService.shouldRefresh(CacheService.noticesBoxName, 'all_notices')) {
          _refreshNoticesInBackground();
        }
        return cached.take(limit).map((e) => Map<String, dynamic>.from(e)).toList();
      }

      Query<Map<String, dynamic>> query = _firestore
          .collection(Collections.notices)
          .where('expiresAt', isGreaterThan: Timestamp.now());

      final snapshot = await query.get();

      final docs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort in memory: Pinned first, then createdAt desc
      docs.sort((a, b) {
        final bool aPinned = a['isPinned'] ?? false;
        final bool bPinned = b['isPinned'] ?? false;
        if (aPinned != bPinned) return bPinned ? 1 : -1;

        final aCreated = a['createdAt'] as Timestamp?;
        final bCreated = b['createdAt'] as Timestamp?;

        if (aCreated == null && bCreated == null) return 0;
        if (aCreated == null) return -1; // New (unsynced) first
        if (bCreated == null) return 1;

        return bCreated.compareTo(aCreated);
      });

      final result = docs.take(limit).toList();
      _cacheService.cacheNotices(docs); // Cache full list
      return result;
    } catch (e) {
      // If no notices or error, return empty list
      debugPrint('Error getting notices: $e');
      return [];
    }
  }

  // Get all notices
  Future<List<Map<String, dynamic>>> getAllNotices() async {
    try {
      // Check cache first
      final cached = _cacheService.getCachedNotices();
      if (cached != null) {
        // Only refresh if cache is older than 10 minutes
        if (_cacheService.shouldRefresh(CacheService.noticesBoxName, 'all_notices')) {
          _refreshNoticesInBackground();
        }
        return cached.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      final snapshot = await _firestore
          .collection(Collections.notices)
          .orderBy('createdAt', descending: true)
          .get();

      final docs = snapshot.docs.map((doc) {
        final data = doc.data(); 
        data['id'] = doc.id;
        return data;
      }).toList();
      
      _cacheService.cacheNotices(docs);
      return docs;
    } catch (e) {
      debugPrint('Error getting all notices: $e');
      return [];
    }
  }

  // Create notice (Admin/Committee only)
  Future<void> createNotice({
    required String title,
    required String description,
    required String category,
    String priority = 'medium',
    String icon = 'notifications',
    DateTime? expiresAt,
  }) async {
    await _firestore.collection(Collections.notices).add({
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'icon': icon,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt != null
          ? Timestamp.fromDate(expiresAt)
          : Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
    });
  }

  // Stream for real-time notice updates
  Stream<List<Map<String, dynamic>>> noticesStream() {
    return _firestore
        .collection(Collections.notices)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Background refresh helper
  void _refreshNoticesInBackground() async {
    try {
      final snapshot = await _firestore
          .collection(Collections.notices)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
          
      final docs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      _cacheService.cacheNotices(docs);
    } catch (e) {
      debugPrint('NoticeService: Background refresh failed: $e');
    }
  }

  // Get time ago string
  String getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
