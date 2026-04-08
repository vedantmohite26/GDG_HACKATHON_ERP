import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _notifications =>
      _firestore.collection('notifications');

  // Send a notification to a specific user (student)
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type, // 'info', 'success', 'warning', 'error'
    String? relatedId, // e.g., application ID
  }) async {
    try {
      await _notifications.add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'relatedId': relatedId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
      rethrow;
    }
  }

  // Stream of notifications for a user, ordered by date
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        // .orderBy('createdAt', descending: true) // Removed to avoid composite index requirement
        .snapshots();
  }

  // Stream of public notices (Broadcasts by Faculty/Admin)
  Stream<QuerySnapshot> getBroadcastNotices() {
    return _firestore
        .collection('notices')
        .orderBy('postedAt', descending: true)
        .limit(20)
        .snapshots();
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notifications.doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final unreadDocs = await _notifications
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }
}
