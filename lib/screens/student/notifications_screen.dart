import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../utils/date_helpers.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../models/notice.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsScreen extends StatelessWidget {
  final String? filterType;
  const NotificationsScreen({super.key, this.filterType});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final notificationService = context.read<NotificationService>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          filterType == 'resources' ? 'Course Resources' : 'Notifications',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              notificationService.markAllAsRead(user.uid);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Rx.combineLatest2(
          notificationService.getUserNotifications(user.uid),
          notificationService.getBroadcastNotices(),
          (QuerySnapshot userSnaps, QuerySnapshot broadcastSnaps) {
            final userNotes = userSnaps.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                ...data,
                'id': doc.id,
                'source': 'personal',
                'timestamp': data['createdAt'] as Timestamp?,
              };
            }).toList();

            final notices = broadcastSnaps.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                ...data,
                'id': doc.id,
                'source': 'broadcast',
                'title': data['title'],
                'message': data['content'], // Map content to message
                'type': data['type'] ?? 'announcement',
                'isRead': true, // Notices are always "read" effectively
                'isPinned': data['isPinned'],
                'postedBy': data['postedByName'] ?? data['postedBy'],
                'timestamp': data['postedAt'] as Timestamp?,
                'externalLink': data['externalLink'],
                'course': data['course'],
                'year': data['year'],
                'semester': data['semester'],
              };
            }).toList();

            final combined = [...userNotes, ...notices];

            // Apply filter
            var filtered = combined;
            if (filterType == 'resources') {
              filtered = combined.where((item) {
                final type = item['type'];
                return type == NoticeType.courseMaterial ||
                    type == NoticeType.examResult;
              }).toList();
            } else {
              // Regular notifications: Hide course materials
              filtered = combined.where((item) {
                final type = item['type'];
                return type != NoticeType.courseMaterial; // Hide explicitly
              }).toList();
            }

            // Sort: Pinned first, then by date descending
            filtered.sort((a, b) {
              final bool aPinned = a['isPinned'] ?? false;
              final bool bPinned = b['isPinned'] ?? false;
              if (aPinned != bPinned) return bPinned ? 1 : -1;

              final DateTime? dateA = (a['timestamp'] as Timestamp?)?.toDate();
              final DateTime? dateB = (b['timestamp'] as Timestamp?)?.toDate();

              if (dateA == null && dateB == null) return 0;
              if (dateA == null) return -1; // Treat as newest
              if (dateB == null) return 1;

              return dateB.compareTo(dateA);
            });

            return filtered;
          },
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading notifications...');
          }

          if (snapshot.hasError) {
            debugPrint('Error loading notifications: ${snapshot.error}');
            return const Center(child: Text('Error loading updates'));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const EmptyStateWidget(
              message: 'No notifications or notices.',
              icon: Icons.notifications_off_outlined,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            cacheExtent: 1000,
            itemBuilder: (context, index) {
              final data = items[index];
              final isRead = data['isRead'] ?? false;
              final type = data['type'] ?? 'info';
              final createdAt = (data['timestamp'] as Timestamp?)?.toDate();
              final isBroadcast = data['source'] == 'broadcast';

              return Dismissible(
                key: Key(data['id']),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: isBroadcast
                    ? DismissDirection.none
                    : DismissDirection.endToStart,
                onDismissed: (direction) {
                  if (!isBroadcast) {
                    // Delete logic here (not implemented in service yet, but UI allows swipe)
                  }
                },
                child: Card(
                  elevation: isRead ? 0 : 2,
                  color: isRead
                      ? Theme.of(context).cardTheme.color
                      : Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isRead
                          ? Theme.of(context).dividerColor
                          : Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (!isRead && !isBroadcast) {
                        notificationService.markAsRead(data['id']);
                      }
                      // Could show full notice content in a dialog if truncated
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIcon(
                            type,
                            context,
                            isPinned: data['isPinned'] ?? false,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          if (data['isPinned'] == true)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 6.0,
                                              ),
                                              child: Icon(
                                                Icons.push_pin,
                                                size: 14,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          Expanded(
                                            child: Text(
                                              data['title'] ?? 'Notification',
                                              style: GoogleFonts.inter(
                                                fontWeight: isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.bold,
                                                fontSize: 15,
                                                color: isRead
                                                    ? Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color
                                                    : Theme.of(
                                                        context,
                                                      ).primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (createdAt != null)
                                      Text(
                                        DateHelpers.formatDate(createdAt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['message'] ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isRead
                                        ? Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color
                                        : Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                if (isBroadcast && data['postedBy'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      'Posted by: ${data['postedBy']}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                if (data['externalLink'] != null &&
                                    data['externalLink'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final url = Uri.parse(
                                          data['externalLink'].toString(),
                                        );
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(
                                            url,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.open_in_new,
                                        size: 16,
                                      ),
                                      label: Text(
                                        data['type'] == NoticeType.examResult
                                            ? 'View Results'
                                            : 'Open Resource',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!isRead && !isBroadcast)
                            Container(
                              margin: const EdgeInsets.only(left: 8, top: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIcon(
    String type,
    BuildContext context, {
    bool isPinned = false,
  }) {
    IconData icon;
    Color color;

    if (isPinned) {
      icon = Icons.campaign_rounded;
      color = Colors.purple;
    } else {
      switch (type) {
        case 'success':
          icon = Icons.check_circle;
          color = Colors.green;
          break;
        case 'error':
        case 'rejected':
          icon = Icons.cancel;
          color = Colors.red;
          break;
        case 'warning':
          icon = Icons.warning;
          color = Colors.orange;
          break;
        case 'announcement':
          icon = Icons.campaign;
          color = Colors.blue;
          break;
        case NoticeType.courseMaterial:
          icon = Icons.menu_book_rounded;
          color = Colors.green;
          break;
        case NoticeType.examResult:
          icon = Icons.emoji_events_rounded;
          color = Colors.orange;
          break;
        default:
          icon = Icons.info;
          color = Theme.of(context).primaryColor;
      }
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
