import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../models/application.dart';
import '../../models/student_profile.dart';
import '../../models/scholarship.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/premium_widgets.dart';
import '../../theme/premium_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReviewApplicationsFaculty extends StatefulWidget {
  final bool showAppBar;
  const ReviewApplicationsFaculty({super.key, this.showAppBar = true});

  @override
  State<ReviewApplicationsFaculty> createState() =>
      _ReviewApplicationsFacultyState();
}

class _ReviewApplicationsFacultyState extends State<ReviewApplicationsFaculty> {
  Key _refreshKey = UniqueKey();

  void _refresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in first'));
    }

    return Scaffold(
      backgroundColor: PremiumTheme.background,
      appBar: widget.showAppBar
          ? AppBar(
              automaticallyImplyLeading: true,
              backgroundColor: PremiumTheme.background,
              elevation: 0,
              iconTheme: const IconThemeData(color: PremiumTheme.textPrimary),
              title: Text(
                'Review Applications',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: PremiumTheme.textPrimary,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: PremiumTheme.textPrimary),
                  onPressed: _refresh,
                  tooltip: 'Refresh List',
                ),
              ],
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4361EE).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4361EE).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Color(0xFF4361EE), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can review and recommend applications.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: PremiumTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder<List<Application>>(
              key: _refreshKey,
              // Use pending applications stream to ensure faculty sees something
              stream: context
                  .read<FirestoreService>()
                  .getPendingApplicationsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget(
                    message: 'Loading applications...',
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final applications = snapshot.data ?? [];

                if (applications.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'No pending applications found.',
                    icon: Icons.assignment_turned_in,
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    return _ApplicationCard(app: applications[index])
                        .animate()
                        .fadeIn(delay: (index * 100).ms)
                        .slideX(begin: 0.1, end: 0);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatefulWidget {
  final Application app;

  const _ApplicationCard({required this.app});

  @override
  State<_ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<_ApplicationCard> {
  StudentProfile? _studentProfile;
  Scholarship? _scholarship;
  bool _showAllDocuments = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final firestore = context.read<FirestoreService>();
    try {
      final student = await firestore.getStudentProfile(widget.app.studentUID);
      final scholarship = await firestore.getScholarship(
        widget.app.scholarshipId,
      );

      if (mounted) {
        setState(() {
          _studentProfile = student;
          _scholarship = scholarship;
        });
      }
    } catch (e) {
      debugPrint('Error fetching details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isReviewed = widget.app.facultyRecommendation != null;
    final studentProfile = _studentProfile;

    return NeoGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1),
                child: Text(
                  _studentProfile?.name.isNotEmpty == true
                      ? _studentProfile!.name[0].toUpperCase()
                      : 'S',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _studentProfile?.name ?? 'Loading Name...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: PremiumTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'UID: ${widget.app.studentUID.substring(0, 8)}...',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: PremiumTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(isReviewed),
            ],
          ),

          const Divider(height: 24),

          if (_scholarship != null) ...[
            Text(
              _scholarship!.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: PremiumTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 14, color: PremiumTheme.tertiary),
                const SizedBox(width: 6),
                Text(
                  'Amount: ₹${_scholarship!.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PremiumTheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _scholarship!.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12, 
                color: PremiumTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDetailBadge(
                Icons.school_outlined,
                'Year: ${_studentProfile?.year ?? '-'}',
                PremiumTheme.primary,
              ),
              _buildDetailBadge(
                Icons.category_outlined,
                widget.app.caste ?? studentProfile?.category ?? '-',
                PremiumTheme.secondary,
              ),
              _buildDetailBadge(
                Icons.account_balance_wallet_outlined,
                'Income: ₹${widget.app.familyIncome?.toStringAsFixed(0) ?? studentProfile?.familyIncome.toStringAsFixed(0) ?? '-'}',
                PremiumTheme.tertiary,
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (widget.app.uploadedDocuments != null &&
              widget.app.uploadedDocuments!.isNotEmpty) ...[
            Text(
              'Submitted Documents:',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: PremiumTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: PremiumTheme.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: PremiumTheme.primary.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: widget.app.uploadedDocuments!.map((url) {
                  final type = widget.app.documentTypes?[url] ?? 'Document';
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.description,
                      size: 18,
                      color: Colors.blueAccent,
                    ),
                    title: Text(
                      type,
                      style: GoogleFonts.inter(
                        fontSize: 13, 
                        color: PremiumTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: PremiumTheme.textSecondary,
                    ),
                    onTap: () async {
                      try {
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(
                            Uri.parse(url),
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open document'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error opening: $e')),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          InkWell(
            onTap: () => setState(() => _showAllDocuments = !_showAllDocuments),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    _showAllDocuments
                        ? 'Hide Student Details'
                        : 'View Student Details',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Icon(
                    _showAllDocuments
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_showAllDocuments)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  _buildProfileRow(
                    Icons.school,
                    'Course',
                    _studentProfile?.course ?? 'N/A',
                  ),
                  const Divider(height: 16),
                  _buildProfileRow(
                    Icons.grade,
                    'CGPA',
                    _studentProfile?.cgpa.toStringAsFixed(2) ?? 'N/A',
                  ),
                  const Divider(height: 16),
                  _buildProfileRow(
                    Icons.percent,
                    'Attendance',
                    '${_studentProfile?.attendance.toStringAsFixed(1) ?? '0'}%',
                  ),
                  const Divider(height: 16),
                  _buildProfileRow(
                    Icons.phone,
                    'Contact',
                    _studentProfile?.contactNumber ?? 'N/A',
                  ),
                  const Divider(height: 16),
                  _buildProfileRow(
                    Icons.contact_phone,
                    'Parent Contact',
                    _studentProfile?.parentContactNumber ?? 'N/A',
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          if (!isReviewed)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _updateRecommendation(context, 'not_recommended'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Reject', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRevertDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                    child: const Text('Revert', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _updateRecommendation(context, 'recommended'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                    child: const Text('Accept', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    (widget.app.facultyRecommendation == 'recommended'
                            ? Colors.green
                            : Colors.orange)
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Recommendation submitted: ${widget.app.facultyRecommendation?.toUpperCase()}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.app.facultyRecommendation == 'recommended'
                      ? Colors.green[800]
                      : Colors.orange[800],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isReviewed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isReviewed
            ? (widget.app.facultyRecommendation == 'recommended'
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1))
            : Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isReviewed
            ? (widget.app.facultyRecommendation == 'recommended'
                  ? 'Recommended'
                  : 'Not Recommended')
            : 'Pending Review',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isReviewed
              ? (widget.app.facultyRecommendation == 'recommended'
                    ? Colors.green
                    : Colors.orange)
              : Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  void _updateRecommendation(BuildContext context, String recommendation) {
    TextEditingController commentsController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          recommendation == 'recommended'
              ? 'Recommend Application?'
              : 'Decline Recommendation?',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add comments for the admin:'),
            const SizedBox(height: 8),
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                hintText: 'Enter comments...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context
                    .read<FirestoreService>()
                    .submitFacultyRecommendation(
                      applicationId: widget.app.id,
                      recommendation: recommendation,
                      comments: commentsController.text,
                    );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showRevertDialog(BuildContext context) {
    TextEditingController commentsController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revert Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request corrections from the student. The application status will be changed to "Reverted".',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reason for Revert:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                hintText: 'e.g., Upload clearer income certificate...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentsController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason.')),
                );
                return;
              }

              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(dialogContext);
              final notificationService = context.read<NotificationService>();
              final firestoreService = context.read<FirestoreService>();

              try {
                // 1. Update Application Status to 'reverted'
                await firestoreService.revertApplication(
                  applicationId: widget.app.id,
                  comments: commentsController.text,
                );

                // 2. Send Notification to Student
                await notificationService.sendNotification(
                  userId: widget.app.studentUID,
                  title: 'Action Required: Application Reverted',
                  message:
                      'Faculty has requested changes: ${commentsController.text}',
                  type: 'warning',
                  relatedId: widget.app.id,
                );

                if (navigator.mounted) {
                  navigator.pop();
                }

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Application reverted & Student notified'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Revert Application'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
