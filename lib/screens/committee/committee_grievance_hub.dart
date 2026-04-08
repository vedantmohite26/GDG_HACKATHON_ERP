import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/grievance.dart';
import '../../theme/premium_theme.dart';
import '../../services/faculty_service.dart';
import '../../models/faculty_profile.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CommitteeGrievanceHub extends StatefulWidget {
  final bool showAppBar;
  const CommitteeGrievanceHub({super.key, this.showAppBar = true});

  @override
  State<CommitteeGrievanceHub> createState() => _CommitteeGrievanceHubState();
}

class _CommitteeGrievanceHubState extends State<CommitteeGrievanceHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: PremiumTheme.lightTheme,
      child: Scaffold(
        backgroundColor: PremiumTheme.background,
        appBar: widget.showAppBar
            ? AppBar(
                title: Text(
                  'Grievance Hub',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: PremiumTheme.textPrimary,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: PremiumTheme.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
        body: Column(
          children: [
            _buildStatsHeader(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PremiumTheme.primary.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: PremiumTheme.primary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: PremiumTheme.textSecondary,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  gradient: PremiumTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: PremiumTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                tabs: const [
                  Tab(text: 'Unassigned'),
                  Tab(text: 'Priority'),
                  Tab(text: 'Resolved'),
                ],
              ),
            ).animate().fadeIn(delay: 100.milliseconds).slideY(begin: -0.1),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _GrievanceList(filter: 'unassigned'),
                  _GrievanceList(filter: 'high_priority'),
                  _GrievanceList(filter: 'resolved'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return StreamBuilder<List<Grievance>>(
      stream: context.read<FirestoreService>().getAllGrievances(),
      builder: (context, snapshot) {
        final grievances = snapshot.data ?? [];
        final unassigned = grievances
            .where((g) =>
                g.status == 'pending' &&
                (g.assignedTo == null || g.assignedTo!.isEmpty))
            .length;
        final highPriority = grievances
            .where((g) => g.priorityScore >= 70 && g.status != 'resolved')
            .length;
        final resolved =
            grievances.where((g) => g.status == 'resolved').length;

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              _MiniStat(
                icon: Icons.pending_actions_rounded,
                label: 'Pending',
                value: '$unassigned',
                color: PremiumTheme.secondary,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                icon: Icons.priority_high_rounded,
                label: 'Critical',
                value: '$highPriority',
                color: PremiumTheme.error,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                icon: Icons.check_circle_outline_rounded,
                label: 'Solved',
                value: '$resolved',
                color: PremiumTheme.success,
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: -0.1);
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: PremiumTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: PremiumTheme.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrievanceList extends StatelessWidget {
  final String filter;

  const _GrievanceList({required this.filter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Grievance>>(
      stream: context.read<FirestoreService>().getAllGrievances(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: 'Loading grievances...');
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allGrievances = snapshot.data ?? [];

        final grievances = allGrievances.where((g) {
          if (filter == 'unassigned') {
            return g.status == 'pending' &&
                (g.assignedTo == null || g.assignedTo!.isEmpty);
          } else if (filter == 'high_priority') {
            return g.priorityScore >= 70 && g.status != 'resolved';
          } else if (filter == 'resolved') {
            return g.status == 'resolved';
          }
          return false;
        }).toList();

        if (grievances.isEmpty) {
          return EmptyStateWidget(
            message: filter == 'resolved'
                ? 'No resolved cases.'
                : 'All clear here!',
            icon: Icons.done_all_rounded,
          );
        }

        return RefreshIndicator(
          color: PremiumTheme.primary,
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: grievances.length,
            itemBuilder: (context, index) {
              return _GrievanceCard(grievance: grievances[index], index: index);
            },
          ),
        );
      },
    );
  }
}

class _GrievanceCard extends StatelessWidget {
  final Grievance grievance;
  final int index;

  const _GrievanceCard({required this.grievance, required this.index});

  @override
  Widget build(BuildContext context) {
    bool isHighPriority = grievance.priorityScore >= 70;
    final daysLeft = grievance.slaDeadline.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriorityBadge(isHighPriority),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 12, color: PremiumTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(grievance.submittedAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: PremiumTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _buildTimeBadge(daysLeft, isOverdue),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: grievance.priorityScore / 100,
                    backgroundColor: PremiumTheme.primary.withValues(alpha: 0.05),
                    color: isHighPriority ? PremiumTheme.error : PremiumTheme.primary,
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'PRIORITY SCORE: ${grievance.priorityScore}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isHighPriority ? PremiumTheme.error : PremiumTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                grievance.category.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: PremiumTheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
              if (!grievance.isAnonymous)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: PremiumTheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge_outlined, size: 12, color: PremiumTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        grievance.studentUID ?? 'N/A',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: PremiumTheme.primary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility_off_outlined, size: 12, color: PremiumTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'ANONYMOUS',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: PremiumTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
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
          ),
          if (grievance.proofUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'ATTACHMENTS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: PremiumTheme.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: grievance.proofUrls.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () => _openAttachment(entry.value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.attach_file_rounded, size: 14, color: PremiumTheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'File ${entry.key + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: PremiumTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (grievance.assignedTo != null && grievance.assignedTo!.isNotEmpty)
            _buildAssignedFaculty(context, grievance.assignedTo!)
          else
            _buildAssignButton(context),
        ],
      ),
    ).animate().fadeIn(delay: (index * 80).milliseconds).slideY(begin: 0.1);
  }

  Widget _buildTimeBadge(int daysLeft, bool isOverdue) {
    final color = isOverdue ? PremiumTheme.error : PremiumTheme.textSecondary;
    return Row(
      children: [
        Icon(isOverdue ? Icons.warning_amber_rounded : Icons.schedule_rounded, 
             size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          isOverdue ? '${-daysLeft}d late' : '${daysLeft}d left',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBadge(bool isHigh) {
    final color = isHigh ? PremiumTheme.error : PremiumTheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        isHigh ? 'CRITICAL' : 'STANDARD',
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAssignedFaculty(BuildContext context, String facultyId) {
    return FutureBuilder<FacultyProfile?>(
      future: FacultyService().getProfile(facultyId),
      builder: (context, snapshot) {
        final facultyName = snapshot.data?.name ?? 'Loading...';
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PremiumTheme.success.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PremiumTheme.success.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 16, color: PremiumTheme.success),
              const SizedBox(width: 8),
              Text(
                'Assigned to: ',
                style: GoogleFonts.inter(fontSize: 12, color: PremiumTheme.textSecondary),
              ),
              Text(
                facultyName,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: PremiumTheme.success),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showAssignDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: PremiumTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text('Assign for Review', 
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _openAttachment(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAssignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'Assign Faculty',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: PremiumTheme.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<FacultyProfile>>(
            stream: FacultyService().streamFacultyOnly(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final list = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (context, idx) {
                  final f = list[idx];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: PremiumTheme.primary.withValues(alpha: 0.1),
                      child: Text(f.name[0], style: const TextStyle(color: PremiumTheme.primary)),
                    ),
                    title: Text(f.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    subtitle: Text(f.department, style: GoogleFonts.inter(fontSize: 12)),
                    onTap: () async {
                      await context.read<FirestoreService>().assignGrievance(grievance.id, f.id);
                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
