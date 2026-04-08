import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../models/application.dart';
import '../../models/student_profile.dart';
import '../../models/scholarship.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/premium_widgets.dart';
import '../../theme/premium_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CommitteeScholarshipApproval extends StatefulWidget {
  final bool showAppBar;
  const CommitteeScholarshipApproval({super.key, this.showAppBar = true});

  @override
  State<CommitteeScholarshipApproval> createState() =>
      _CommitteeScholarshipApprovalState();
}

class _CommitteeScholarshipApprovalState
    extends State<CommitteeScholarshipApproval> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.background,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                'Scholarship Oversight',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: PremiumTheme.textPrimary,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: PremiumTheme.textPrimary),
            )
          : null,
      body: StreamBuilder<List<Application>>(
        stream: context
            .read<FirestoreService>()
            .getCommitteePendingApplicationsStream(),
        builder: (context, snapshot) {
          // Debug: Print connection state
          debugPrint(
            'Committee Approval Screen - Connection State: ${snapshot.connectionState}',
          );

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading recommendations...');
          }

          if (snapshot.hasError) {
            // Show detailed error information
            debugPrint('Committee Approval Error: ${snapshot.error}');
            debugPrint('Error Stack Trace: ${snapshot.stackTrace}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: PremiumTheme.error.withValues(alpha: 0.6),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Applications',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: PremiumTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: PremiumTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        (context as Element).markNeedsBuild();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PremiumTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final applications = snapshot.data ?? [];

          // Debug: Print application count
          debugPrint(
            'Committee Approval Screen - Applications loaded: ${applications.length}',
          );

          if (applications.isEmpty) {
            return const EmptyStateWidget(
              message:
                  'No faculty-recommended applications.\n\n'
                  'Applications appear here after faculty members have reviewed and recommended them.',
              icon: Icons.check_circle_outline,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: applications.length,
              itemBuilder: (context, index) {
                return _ApprovalCard(app: applications[index])
                    .animate()
                    .fadeIn(delay: (index * 100).ms)
                    .slideY(begin: 0.1, end: 0);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ApprovalCard extends StatefulWidget {
  final Application app;

  const _ApprovalCard({required this.app});

  @override
  State<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<_ApprovalCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        firestoreService.getStudentProfile(widget.app.studentUID),
        firestoreService.getScholarship(widget.app.scholarshipId),
      ]).then((results) => {
            'profile': results[0] as StudentProfile?,
            'scholarship': results[1] as Scholarship?,
          }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const NeoGlassCard(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final profile = snapshot.data?['profile'] as StudentProfile?;
        final scholarship = snapshot.data?['scholarship'] as Scholarship?;

        // Fallback initials/name
        final String displayName = profile?.name ?? 'Unknown Student';
        final String firstInitial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

        return NeoGlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row (Avatar, Name/UID, Badge)
              Row(
                children: [
                   CircleAvatar(
                    radius: 24,
                    backgroundColor: PremiumTheme.primary.withValues(alpha: 0.1),
                    backgroundImage: (profile?.profilePhoto != null && profile!.profilePhoto.isNotEmpty)
                        ? NetworkImage(profile.profilePhoto)
                        : null,
                    child: (profile?.profilePhoto == null || profile!.profilePhoto.isEmpty)
                        ? Text(
                            firstInitial,
                            style: GoogleFonts.outfit(
                              color: PremiumTheme.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: PremiumTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'UID: ${widget.app.studentUID.substring(0, 8).toUpperCase()}...',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: PremiumTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Recommended',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFEEEEEE)),
              ),

              // Scholarship Info
              Text(
                scholarship?.title ?? 'Pending Scholarship Title',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 6),
                  Text(
                    'Amount: ₹${scholarship?.amount.toInt() ?? 'N/A'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                scholarship?.description ?? 'No information available for this scholarship...',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: PremiumTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 16),

              // Badge Row
              Row(
                children: [
                   _buildDetailBadge(
                    Icons.school_outlined,
                    'Year: ${profile?.year ?? 'N/A'}',
                    const Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 8),
                  _buildDetailBadge(
                    Icons.category_outlined,
                    widget.app.caste ?? 'OBC',
                    const Color(0xFFEF6C00),
                  ),
                  const SizedBox(width: 8),
                  _buildDetailBadge(
                    Icons.account_balance_wallet_outlined,
                    'Income: ₹${widget.app.familyIncome?.toInt() ?? 'N/A'}',
                    const Color(0xFF2E7D32),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              
              // Documents Section
              Text(
                'Submitted Documents:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: PremiumTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              if (widget.app.uploadedDocuments != null && widget.app.uploadedDocuments!.isNotEmpty)
                Column(
                  children: widget.app.uploadedDocuments!.map((url) {
                    final type = widget.app.documentTypes?[url] ?? 'Document';
                    return GestureDetector(
                      onTap: () async {
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F9FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE3F2FD)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.description_outlined, color: Color(0xFF1976D2), size: 20),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                type,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: PremiumTheme.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 12),

              // Student Details Dropdown
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'View Student Details',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: const Color(0xFF1565C0),
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF1565C0),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              if (_isExpanded && profile != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: PremiumTheme.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Course', profile.course),
                      _buildInfoRow('CGPA', profile.cgpa.toStringAsFixed(2)),
                      _buildInfoRow('Attendance', '${profile.attendance}%'),
                      _buildInfoRow('Contact', profile.contactNumber),
                      _buildInfoRow('Parent Contact', profile.parentContactNumber),
                    ],
                  ).animate().fadeIn(),
                ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleDecision(context, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE53935)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Reject',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFE53935),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleDecision(context, 'approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Approve',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _showRevertDialog(context),
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: const Text('Revert to Student'),
                  style: TextButton.styleFrom(
                    foregroundColor: PremiumTheme.secondary,
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: PremiumTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: PremiumTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _handleDecision(BuildContext context, String decision) {
    if (decision == 'approved') {
      _confirmApproval(context);
    } else {
      _requestRejectionReason(context);
    }
  }

  void _confirmApproval(BuildContext context) {
    // Capture the outer context before showing the dialog
    final outerContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: PremiumTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Confirm Approval',
          style: GoogleFonts.plusJakartaSans(
            color: PremiumTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to approve this scholarship application? This is a final decision.',
          style: GoogleFonts.inter(
            color: PremiumTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: PremiumTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _submitDecision(
                outerContext,
                'approved',
                'Approved by Committee',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumTheme.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirm Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRevertDialog(BuildContext context) async {
    final commentController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PremiumTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Revert Application',
          style: GoogleFonts.plusJakartaSans(
            color: PremiumTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Return this application to the student for corrections. They will be notified to resubmit.',
              style: GoogleFonts.inter(
                color: PremiumTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              style: GoogleFonts.inter(color: PremiumTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Reason for Revert',
                labelStyle: GoogleFonts.inter(color: PremiumTheme.textSecondary),
                hintText: 'e.g., Incorrect income certificate uploaded',
                hintStyle: GoogleFonts.inter(color: PremiumTheme.textSecondary.withValues(alpha: 0.5)),
                filled: true,
                fillColor: PremiumTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: PremiumTheme.primary.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: PremiumTheme.primary.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: PremiumTheme.primary, width: 1.5),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: PremiumTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              if (commentController.text.trim().isEmpty) {
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Please provide a reason.'),
                    backgroundColor: PremiumTheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                return;
              }

              Navigator.pop(context);

              final firestoreService = context.read<FirestoreService>();
              final notificationService = context.read<NotificationService>();

              try {
                await firestoreService.revertApplication(
                  applicationId: widget.app.id,
                  comments: commentController.text.trim(),
                );

                if (context.mounted) {
                  await notificationService.sendNotification(
                    userId: widget.app.studentUID,
                    title: 'Application Reverted by Committee',
                    message:
                        'Committee has requested changes: ${commentController.text.trim()}',
                    type: 'warning',
                    relatedId: widget.app.id,
                  );

                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Application reverted successfully'),
                      backgroundColor: PremiumTheme.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: PremiumTheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumTheme.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Revert Application'),
          ),
        ],
      ),
    );
  }

  void _requestRejectionReason(BuildContext context) {
    final controller = TextEditingController();
    final outerContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: PremiumTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Reject Application',
          style: GoogleFonts.plusJakartaSans(
            color: PremiumTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please provide a reason for rejection (required):',
              style: GoogleFonts.inter(
                color: PremiumTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: GoogleFonts.inter(color: PremiumTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                hintStyle: GoogleFonts.inter(color: PremiumTheme.textSecondary.withValues(alpha: 0.5)),
                filled: true,
                fillColor: PremiumTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: PremiumTheme.primary.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: PremiumTheme.primary.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: PremiumTheme.primary, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: PremiumTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  SnackBar(
                    content: const Text('Reason is required for rejection'),
                    backgroundColor: PremiumTheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext);
              await _submitDecision(
                outerContext,
                'rejected',
                controller.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitDecision(
    BuildContext context,
    String status,
    String notes,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null) return;

      final firestoreService = context.read<FirestoreService>();
      final notificationService = context.read<NotificationService>();

      await firestoreService.updateApplicationStatus(
        applicationId: widget.app.id,
        status: status,
        reviewedBy: user.uid,
        adminNotes: notes,
      );

      await notificationService.sendNotification(
        userId: widget.app.studentUID,
        title: status == 'approved'
            ? 'Scholarship Application Approved'
            : 'Application Status Update',
        message: status == 'approved'
            ? 'Congratulations! Your application has been approved by the committee.'
            : 'Your application has been reviewed and marked as rejected. Reason: $notes',
        type: status == 'approved' ? 'success' : 'error',
        relatedId: widget.app.id,
      );

      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Application ${status == "approved" ? "Approved" : "Rejected"}',
            ),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildDetailBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
