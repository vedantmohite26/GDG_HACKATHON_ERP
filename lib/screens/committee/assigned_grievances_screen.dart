import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/grievance.dart';
import '../../utils/date_helpers.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../theme/premium_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class AssignedGrievancesScreen extends StatefulWidget {
  const AssignedGrievancesScreen({super.key});

  @override
  State<AssignedGrievancesScreen> createState() =>
      _AssignedGrievancesScreenState();
}

class _AssignedGrievancesScreenState extends State<AssignedGrievancesScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    return Theme(
      data: PremiumTheme.lightTheme,
      child: Scaffold(
        backgroundColor: PremiumTheme.background,
        appBar: AppBar(
          title: Text(
            'My Assigned Grievances',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: PremiumTheme.textPrimary,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: PremiumTheme.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: StreamBuilder<List<Grievance>>(
          stream: context.read<FirestoreService>().getAssignedGrievances(
            currentUser.uid,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget(
                message: 'Loading assigned grievances...',
              );
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final grievances = snapshot.data ?? [];

            if (grievances.isEmpty) {
              return const EmptyStateWidget(
                message: 'No grievances assigned to you.',
                icon: Icons.assignment_turned_in_outlined,
              );
            }

            return RefreshIndicator(
              color: PremiumTheme.primary,
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: grievances.length,
                itemBuilder: (context, index) {
                  final grievance = grievances[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: PremiumTheme.primary.withValues(alpha: 0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: PremiumTheme.primary.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatusBadge(grievance.status),
                            Text(
                              DateHelpers.formatDate(grievance.submittedAt),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: PremiumTheme.textSecondary,
                              ),
                            ),
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
                        const SizedBox(height: 8),
                        Text(
                          grievance.description,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: PremiumTheme.textPrimary,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 14, color: PremiumTheme.secondary),
                            const SizedBox(width: 8),
                            Text(
                              'Due: ${DateHelpers.formatDate(grievance.slaDeadline)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: PremiumTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () => _showResolveDialog(context, grievance),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PremiumTheme.primary.withValues(alpha: 0.08),
                                foregroundColor: PremiumTheme.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Update', 
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: (index * 100).milliseconds).slideX(begin: 0.1, end: 0);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case GrievanceStatus.pending:
        return Colors.orange;
      case GrievanceStatus.assigned:
        return PremiumTheme.primary;
      case GrievanceStatus.inProgress:
        return PremiumTheme.secondary;
      case GrievanceStatus.resolved:
        return PremiumTheme.success;
      default:
        return Colors.grey;
    }
  }

  void _showResolveDialog(BuildContext context, Grievance grievance) {
    final notesController = TextEditingController();
    String selectedStatus = grievance.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PremiumTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.update_rounded, color: PremiumTheme.primary, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                'Update Grievance',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: PremiumTheme.textPrimary,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHANGE STATUS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: PremiumTheme.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                dropdownColor: Colors.white,
                style: GoogleFonts.inter(
                  color: PremiumTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _inputDecoration(''),
                items: [
                  GrievanceStatus.assigned,
                  GrievanceStatus.inProgress,
                  GrievanceStatus.resolved,
                ].map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s),
                    )).toList(),
                onChanged: (val) => setState(() => selectedStatus = val!),
              ),
              const SizedBox(height: 20),
              Text(
                'RESOLUTION NOTES',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: PremiumTheme.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: notesController,
                style: GoogleFonts.inter(
                  color: PremiumTheme.textPrimary,
                  fontSize: 14,
                ),
                decoration: _inputDecoration('Provide details on the resolution...'),
                maxLines: 4,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: PremiumTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final currentUser = context.read<AuthService>().currentUser;
                  final updatedGrievance = Grievance(
                    id: grievance.id,
                    userId: grievance.userId,
                    studentUID: grievance.studentUID,
                    category: grievance.category,
                    description: grievance.description,
                    isAnonymous: grievance.isAnonymous,
                    proofUrls: grievance.proofUrls,
                    status: selectedStatus,
                    priorityScore: grievance.priorityScore,
                    submittedAt: grievance.submittedAt,
                    slaDeadline: grievance.slaDeadline,
                    assignedTo: grievance.assignedTo,
                    resolvedBy: currentUser?.uid,
                    resolvedAt: selectedStatus == GrievanceStatus.resolved
                        ? DateTime.now()
                        : null,
                    internalNotes: notesController.text,
                  );

                  await context.read<FirestoreService>().updateGrievance(updatedGrievance);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Update successful!'),
                        backgroundColor: PremiumTheme.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
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
                backgroundColor: PremiumTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: PremiumTheme.primary.withValues(alpha: 0.3),
              ),
              child: Text('Update Status', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
      filled: true,
      fillColor: PremiumTheme.primary.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: PremiumTheme.primary.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: PremiumTheme.primary.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: PremiumTheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
