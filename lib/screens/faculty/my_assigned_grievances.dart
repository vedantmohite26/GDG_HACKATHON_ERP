import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/grievance.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';
import 'faculty_grievance_details_screen.dart';

/// Faculty screen showing only grievances assigned to them
/// Cannot see all grievances or assign to others
class MyAssignedGrievances extends StatelessWidget {
  final bool showAppBar;
  const MyAssignedGrievances({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    final uid = authService.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text('Please login to view grievances.'));
    }

    return Scaffold(
      backgroundColor: PremiumTheme.background,
      appBar: showAppBar
          ? AppBar(
              title: Text(
                'Assigned Tasks',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: PremiumTheme.textPrimary,
                  fontSize: 20,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: PremiumTheme.textPrimary),
            )
          : null,
      body: StreamBuilder<List<Grievance>>(
        stream: firestoreService.getAssignedGrievancesStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: PremiumTheme.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: PremiumTheme.error),
              ),
            );
          }

          final grievances = snapshot.data ?? [];

          if (grievances.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: PremiumTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.assignment_turned_in_rounded,
                      size: 64,
                      color: PremiumTheme.primary.withValues(alpha: 0.5),
                    ),
                  ).animate().scale(delay: 200.ms).fadeIn(),
                  const SizedBox(height: 24),
                  Text(
                    'No tasks assigned yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: PremiumTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Any grievances assigned by the committee\nwill appear here for your review.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: PremiumTheme.textSecondary,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: grievances.length,
            itemBuilder: (context, index) {
              final grievance = grievances[index];
              return _buildGrievanceCard(context, grievance, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildGrievanceCard(
    BuildContext context,
    Grievance grievance,
    int index,
  ) {
    final daysLeft = grievance.slaDeadline.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0;

    return NeoGlassCard(
      padding: const EdgeInsets.all(20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              FacultyGrievanceDetailsScreen(grievance: grievance),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                Row(
                  children: [
                    _buildModernStatusBadge(grievance.status),
                    const Spacer(),
                    _buildModernPriorityBadge(grievance.priorityScore),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  grievance.category.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: PremiumTheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  grievance.description,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: PremiumTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: PremiumTheme.background,
                        shape: BoxShape.circle,
                        border: Border.all(color: PremiumTheme.primary.withValues(alpha: 0.05)),
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: isOverdue
                            ? PremiumTheme.error
                            : PremiumTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatDeadlineText(daysLeft),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isOverdue
                            ? PremiumTheme.error
                            : PremiumTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: PremiumTheme.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        DateFormat('MMM dd').format(grievance.submittedAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: PremiumTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
  }

  String _formatDeadlineText(int daysLeft) {
    if (daysLeft < 0) return 'OVERDUE';
    if (daysLeft == 0) return 'DUE TODAY';
    return '$daysLeft DAYS REMAINING';
  }

  Widget _buildModernStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPriorityBadge(int score) {
    String label;
    Color color;
    if (score >= 70) {
      label = 'P3';
      color = PremiumTheme.error;
    } else if (score >= 40) {
      label = 'P2';
      color = Colors.orange;
    } else {
      label = 'P1';
      color = PremiumTheme.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'resolved') return PremiumTheme.success;
    if (status == 'pending') return Colors.orange;
    return PremiumTheme.primary;
  }
}
