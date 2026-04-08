import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Key _refreshKey = UniqueKey();

  void _refresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final isDark = PremiumTheme.isDark(context);

    return Scaffold(
      backgroundColor: isDark ? PremiumTheme.darkBackground : PremiumTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? PremiumTheme.darkText : PremiumTheme.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? PremiumTheme.darkText : PremiumTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: isDark ? PremiumTheme.darkText : PremiumTheme.textPrimary),
            onPressed: _refresh,
            tooltip: 'Refresh Notifications',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        key: _refreshKey,
        stream: firestoreService.getNotices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<Map<String, dynamic>> notices = snapshot.data ?? [];
          
          notices.sort((a, b) {
            final bool aPinned = a['isPinned'] ?? false;
            final bool bPinned = b['isPinned'] ?? false;
            if (aPinned != bPinned) return bPinned ? 1 : -1;

            final DateTime? dateA = (a['postedAt'] as dynamic)?.toDate();
            final DateTime? dateB = (b['postedAt'] as dynamic)?.toDate();

            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return -1;
            if (dateB == null) return 1;

            return dateB.compareTo(dateA);
          });

          if (notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No new notifications',
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark ? PremiumTheme.darkTextSecondary : PremiumTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              final date = (notice['postedAt'] as dynamic)?.toDate();
              final timeAgo = _getTimeAgo(date);
              final isPinned = notice['isPinned'] ?? false;
              final priority = notice['priority'] ?? 'Low'; // Low, Medium, High

              Color badgeColor = PremiumTheme.primary;
              if (priority == 'High') badgeColor = PremiumTheme.error;
              if (priority == 'Medium') badgeColor = Colors.orange;

              return NeoGlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPinned ? Icons.push_pin : Icons.notifications,
                        color: badgeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notice['title'] ?? 'Notice',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: isDark ? PremiumTheme.darkText : PremiumTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (timeAgo != null)
                                Text(
                                  timeAgo,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? PremiumTheme.darkTextSecondary : PremiumTheme.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notice['content'] ?? '',
                            style: GoogleFonts.inter(
                              color: isDark ? PremiumTheme.darkText.withValues(alpha: 0.7) : PremiumTheme.textSecondary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isPinned)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PINNED',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1);
            },
          );
        },
      ),
    );
  }

  String? _getTimeAgo(DateTime? date) {
    if (date == null) return null;
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return DateFormat('MMM d').format(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
