import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/grievance.dart';
import '../../services/firestore_service.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';

class FacultyGrievanceDetailsScreen extends StatelessWidget {
  final Grievance grievance;

  const FacultyGrievanceDetailsScreen({super.key, required this.grievance});

  @override
  Widget build(BuildContext context) {
    // Recalculate days left
    final daysLeft = grievance.slaDeadline.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0;

    return Scaffold(
      backgroundColor: PremiumTheme.background,
      appBar: AppBar(
        title: Text(
          'Grievance Details',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: PremiumTheme.textPrimary,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: PremiumTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Priority Row
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildModernStatusBadge(grievance.status),
                _buildModernPriorityBadge(grievance.priorityScore),
              ],
            ).animate().fadeIn().slideX(),
            const SizedBox(height: 24),

            // Main Info Sections
            _buildInfoCard(
              title: 'Description',
              icon: Icons.description_outlined,
              color: PremiumTheme.primary,
              child: Text(
                grievance.description,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.6,
                  color: PremiumTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),

            _buildInfoCard(
              title: 'Timeline',
              icon: Icons.history_toggle_off_rounded,
              color: Colors.orange,
              child: Row(
                children: [
                  Expanded(
                    child: _buildTimelineItem(
                      'Submitted',
                      DateFormat('MMM dd, yyyy').format(grievance.submittedAt),
                      Icons.event_available_rounded,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: PremiumTheme.primary.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: _buildTimelineItem(
                      'Target Resolution',
                      _formatDeadline(daysLeft),
                      Icons.timer_outlined,
                      valueColor: isOverdue ? PremiumTheme.error : null,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),

            _buildInfoCard(
              title: 'Grievant Identity',
              icon: Icons.person_outline_rounded,
              color: Colors.teal,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      grievance.isAnonymous
                          ? Icons.visibility_off
                          : Icons.person,
                      color: Colors.teal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          grievance.isAnonymous
                              ? 'Anonymous Request'
                              : 'Standard Identity',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: PremiumTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          grievance.isAnonymous
                              ? 'Identity hidden from faculty'
                              : 'UID: ${grievance.studentUID ?? "Not Provided"}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: PremiumTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

            // Attached Images/Proof
            if (grievance.proofUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Attached Evidence',
                icon: Icons.image_outlined,
                color: Colors.purple,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${grievance.proofUrls.length} ${grievance.proofUrls.length == 1 ? 'image' : 'images'} attached',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: PremiumTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: grievance.proofUrls.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _showFullImage(
                              context,
                              grievance.proofUrls[index],
                            ),
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[900],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  grievance.proofUrls[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey[600],
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                            color: PremiumTheme.primary,
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: PremiumTheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: PremiumTheme.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          child: FutureButton(
            onPressed: grievance.status == 'resolved'
                ? null
                : () => _showUpdateStatusDialog(context, grievance),
            text: grievance.status == 'resolved'
                ? 'RESOLVED'
                : 'MARK AS RESOLVED',
            icon: Icons.check_circle_outline_rounded,
            isLoading: false,
          ),
        ),
      ),
    );
  }

  Widget _buildModernStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1,
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
      label = 'CRITICAL P3';
      color = PremiumTheme.error;
    } else if (score >= 40) {
      label = 'MODERATE P2';
      color = Colors.orange;
    } else {
      label = 'ROUTINE P1';
      color = PremiumTheme.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return NeoGlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: PremiumTheme.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: PremiumTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? PremiumTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatDeadline(int daysLeft) {
    if (daysLeft < 0) return 'Overdue by ${daysLeft.abs()} days';
    if (daysLeft == 0) return 'Due Today';
    return '$daysLeft days remaining';
  }

  Color _getStatusColor(String status) {
    if (status == 'resolved') return Colors.green;
    if (status == 'pending') return Colors.orange;
    return Colors.blue;
  }

  IconData _getStatusIcon(String status) {
    if (status == 'resolved') return Icons.check_circle;
    if (status == 'pending') return Icons.pending;
    return Icons.work;
  }

  void _showUpdateStatusDialog(BuildContext context, Grievance grievance) {
    final commentsController = TextEditingController();
    final firestoreService = context.read<FirestoreService>();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: PremiumTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resolve Grievance',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: PremiumTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide resolution details for the student.',
                style: GoogleFonts.inter(color: const Color.fromARGB(255, 0, 0, 0), fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: commentsController,
                maxLines: 4,
                style: GoogleFonts.inter(
                  color: PremiumTheme.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter resolution notes...',
                  hintStyle: GoogleFonts.inter(color: PremiumTheme.textSecondary),
                  filled: true,
                  fillColor: PremiumTheme.primary.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: PremiumTheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (commentsController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please add resolution notes')),
                        );
                        return;
                      }

                      try {
                        await firestoreService.updateGrievanceStatus(
                          grievanceId: grievance.id,
                          status: 'resolved',
                          internalNotes: 'Resolved by Faculty: ${commentsController.text}',
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Grievance marked as resolved'),
                              backgroundColor: PremiumTheme.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumTheme.success,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: PremiumTheme.success.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Confirm Resolution',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: PremiumTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: PremiumTheme.primary,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: GoogleFonts.inter(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
