import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/student_profile.dart';
import '../../models/application.dart';
import '../../models/scholarship.dart';
import '../../models/grievance.dart';
import '../../models/document.dart';
import '../../services/firestore_service.dart';
import '../../services/attendance_service.dart';
import '../../services/academic_record_service.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';

class StudentDetailsViewScreen extends StatefulWidget {
  final String studentUID;
  final String? studentName; // Optional for better placeholder during loading

  const StudentDetailsViewScreen({
    super.key,
    required this.studentUID,
    this.studentName,
  });

  @override
  State<StudentDetailsViewScreen> createState() => _StudentDetailsViewScreenState();
}

class _StudentDetailsViewScreenState extends State<StudentDetailsViewScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AttendanceService _attendanceService = AttendanceService();
  final AcademicRecordService _academicRecordService = AcademicRecordService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StudentProfile?>(
      stream: _firestoreService.streamStudentProfile(widget.studentUID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: PremiumTheme.background,
            body: const Center(child: CircularProgressIndicator(color: PremiumTheme.primary)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            backgroundColor: PremiumTheme.background,
            appBar: AppBar(title: const Text('Student Details')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: PremiumTheme.error),
                  const SizedBox(height: 16),
                  Text('Profile not found', style: GoogleFonts.inter(fontSize: 16, color: PremiumTheme.textSecondary)),
                ],
              ),
            ),
          );
        }

        final profile = snapshot.data!;

        return Scaffold(
          backgroundColor: PremiumTheme.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  stretch: true,
                  backgroundColor: PremiumTheme.primary,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: PremiumTheme.primaryGradient,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Hero(
                            tag: 'student_avatar_${profile.studentUID}',
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: profile.profilePhoto.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: profile.profilePhoto,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(color: Colors.white10),
                                        errorWidget: (context, url, error) => _buildPlaceholder(profile.name),
                                      )
                                    : _buildPlaceholder(profile.name),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            profile.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${profile.studentUID}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<Map<String, dynamic>?>(
                            stream: _academicRecordService.academicRecordsStream(profile.studentUID),
                            builder: (context, academicSnap) {
                              final academicData = academicSnap.data;
                              final cgpa = (academicData?['currentCGPA'] ?? 0.0).toDouble();

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildHeaderBadge(profile.course, Icons.school_rounded),
                                      const SizedBox(width: 8),
                                      _buildHeaderBadge('Year ${profile.year}', Icons.calendar_today_rounded),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  StreamBuilder<double>(
                                    stream: _attendanceService.getStudentAttendancePercentageStream(
                                      profile.studentUID,
                                      profile.course,
                                      profile.year.toString(),
                                    ),
                                    builder: (context, attendanceSnap) {
                                      final attendance = attendanceSnap.data ?? 0.0;
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _buildHeaderBadge('${attendance.toStringAsFixed(1)}% Attd', Icons.fact_check_rounded),
                                          const SizedBox(width: 8),
                                          _buildHeaderBadge('${cgpa.toStringAsFixed(2)} CGPA', Icons.grade_rounded),
                                          const SizedBox(width: 8),
                                          _buildHeaderBadge('Till 31.07.${profile.passoutYear}', Icons.event_available_rounded),
                                        ],
                                      );
                                    }
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: PremiumTheme.primary,
                      unselectedLabelColor: PremiumTheme.textSecondary,
                      indicatorColor: PremiumTheme.primary,
                      indicatorWeight: 3,
                      labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                      unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
                      tabs: const [
                        Tab(text: 'General'),
                        Tab(text: 'Academics'),
                        Tab(text: 'Applications'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralTab(profile),
                _buildAcademicsTab(profile),
                _buildApplicationsTab(profile),
                _buildHistoryTab(profile),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(String name) {
    return Container(
      color: Colors.white24,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTab(StudentProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Personal Information'),
          _buildInfoGrid([
            _InfoItem(label: 'Gender', value: profile.gender, icon: Icons.person_rounded),
            _InfoItem(label: 'Blood Group', value: profile.bloodGroup, icon: Icons.bloodtype_rounded),
            _InfoItem(label: 'Date of Birth', value: profile.dateOfBirth, icon: Icons.cake_rounded),
            _InfoItem(label: 'Category', value: profile.category, icon: Icons.category_rounded),
            _InfoItem(label: 'Shift', value: profile.shift, icon: Icons.access_time_filled_rounded),
            _InfoItem(label: 'Passout Year', value: profile.passoutYear, icon: Icons.flag_rounded),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Contact Details'),
          _buildDetailCard([
            _DetailTile(icon: Icons.email_rounded, label: 'Email', value: 'Loading...', isEmail: true, studentUID: profile.userId),
            _DetailTile(icon: Icons.phone_android_rounded, label: 'Student Phone', value: profile.contactNumber),
            _DetailTile(icon: Icons.contact_phone_rounded, label: 'Parent Phone', value: profile.parentContactNumber),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Financial Status'),
          NeoGlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PremiumTheme.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: PremiumTheme.success, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Annual Family Income', style: GoogleFonts.inter(fontSize: 12, color: PremiumTheme.textSecondary, fontWeight: FontWeight.w500)),
                    Text(
                      '₹${profile.familyIncome.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: PremiumTheme.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAcademicsTab(StudentProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Academic Performance'),
          StreamBuilder<Map<String, dynamic>?>(
            stream: _academicRecordService.academicRecordsStream(profile.studentUID),
            builder: (context, academicSnap) {
                final academicData = academicSnap.data;
                final cgpa = (academicData?['currentCGPA'] ?? 0.0).toDouble();

                return Row(
                  children: [
                    Expanded(child: _buildMetricCard('CGPA', cgpa.toStringAsFixed(2), Icons.grade_rounded, PremiumTheme.primary)),
                    const SizedBox(width: 16),
                    StreamBuilder<double>(
                      stream: _attendanceService.getStudentAttendancePercentageStream(
                        profile.studentUID,
                        profile.course,
                        profile.year.toString(),
                      ),
                      builder: (context, attendanceSnap) {
                        final attendance = attendanceSnap.data ?? 0.0;
                        return Expanded(child: _buildMetricCard('Attendance', '${attendance.toStringAsFixed(1)}%', Icons.fact_check_rounded, PremiumTheme.secondary));
                      }
                    ),
                  ],
                );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Enrollment Details'),
          _buildDetailCard([
            _DetailTile(icon: Icons.badge_rounded, label: 'Enrollment No.', value: profile.studentUID),
            _DetailTile(icon: Icons.school_rounded, label: 'Course', value: profile.course),
            _DetailTile(icon: Icons.calendar_today_rounded, label: 'Current Year', value: '${profile.year}${_getOrdinal(profile.year)} Year'),
            _DetailTile(icon: Icons.event_available_rounded, label: 'Valid From', value: profile.validFrom),
            _DetailTile(icon: Icons.event_note_rounded, label: 'Valid Till', value: '31.07.${profile.passoutYear}'),
          ]),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildApplicationsTab(StudentProfile profile) {
    return StreamBuilder<List<Application>>(
      stream: _firestoreService.getStudentApplications(profile.studentUID),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final apps = snapshot.data!;
        if (apps.isEmpty) {
          return _buildEmptyState(Icons.assignment_rounded, 'No Applications Found', 'Student has not applied for any scholarships yet.');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final app = apps[index];
            return FutureBuilder<Scholarship?>(
              future: _firestoreService.getScholarship(app.scholarshipId),
              builder: (context, scholarshipSnapshot) {
                // Determine display values based on snapshot state
                String scholarshipName;
                String organization;
                bool isLoading = scholarshipSnapshot.connectionState == ConnectionState.waiting;

                if (isLoading) {
                  scholarshipName = 'Loading...';
                  organization = '...';
                } else if (scholarshipSnapshot.hasError || scholarshipSnapshot.data == null) {
                  scholarshipName = app.scholarshipId; // Fallback to ID if not found
                  organization = scholarshipSnapshot.hasError ? 'Error loading data' : 'Unknown Organization';
                } else {
                  final scholarship = scholarshipSnapshot.data!;
                  scholarshipName = scholarship.title;
                  organization = scholarship.organization;
                }

                return NeoGlassCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(app.status),
                          Text(
                            _formatDate(app.submittedAt),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: PremiumTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: PremiumTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.description_rounded,
                              color: PremiumTheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  scholarshipName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: PremiumTheme.textPrimary,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  organization,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: PremiumTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (app.facultyComments != null && app.facultyComments!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: PremiumTheme.surfaceVariant.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: PremiumTheme.primary.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 14, color: PremiumTheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Remarks: ${app.facultyComments}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: PremiumTheme.textPrimary.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab(StudentProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Grievance History'),
          StreamBuilder<List<Grievance>>(
            stream: _firestoreService.getStudentGrievances(profile.userId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
              final grievances = snapshot.data!;
              if (grievances.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(color: PremiumTheme.surfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
                  child: Text('No grievances recorded.', style: GoogleFonts.inter(color: PremiumTheme.textSecondary)),
                );
              }
              return Column(
                children: grievances.take(3).map((g) => _buildGrievanceMiniCard(g)).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Document Vault'),
          StreamBuilder<List<DocumentModel>>(
            stream: _firestoreService.getStudentDocuments(profile.studentUID),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
              final docs = snapshot.data!;
              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(color: PremiumTheme.surfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
                  child: Text('No documents uploaded.', style: GoogleFonts.inter(color: PremiumTheme.textSecondary)),
                );
              }
              return _buildDetailCard(docs.map((d) => _DetailTile(
                icon: Icons.file_present_rounded,
                label: d.fileType.toUpperCase(),
                value: d.fileName,
              )).toList());
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return NeoGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: PremiumTheme.textPrimary)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: PremiumTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildGrievanceMiniCard(Grievance g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PremiumTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PremiumTheme.primary.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          _getGrievanceStatusIcon(g.status),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.category, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(_formatDate(g.submittedAt), style: GoogleFonts.inter(fontSize: 11, color: PremiumTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: PremiumTheme.primary, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildInfoGrid(List<_InfoItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildInfoTile(items[index]),
    );
  }

  Widget _buildInfoTile(_InfoItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PremiumTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PremiumTheme.primary.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 18, color: PremiumTheme.primary.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.label, style: GoogleFonts.inter(fontSize: 10, color: PremiumTheme.textSecondary, fontWeight: FontWeight.w500)),
                Text(item.value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: PremiumTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(List<_DetailTile> tiles) {
    return NeoGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: List.generate(tiles.length, (index) {
          final tile = tiles[index];
          return Column(
            children: [
              tile,
              if (index < tiles.length - 1)
                Divider(height: 1, color: PremiumTheme.primary.withValues(alpha: 0.05), indent: 56),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved': color = PremiumTheme.success; break;
      case 'rejected': color = PremiumTheme.error; break;
      case 'reverted': color = PremiumTheme.warning; break;
      default: color = PremiumTheme.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: PremiumTheme.textSecondary.withValues(alpha: 0.2)),
            const SizedBox(height: 24),
            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: PremiumTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: PremiumTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _getGrievanceStatusIcon(String status) {
    IconData icon;
    Color color;
    switch (status) {
      case 'resolved': icon = Icons.check_circle_rounded; color = PremiumTheme.success; break;
      case 'in-progress': icon = Icons.pending_rounded; color = PremiumTheme.warning; break;
      default: icon = Icons.radio_button_checked_rounded; color = PremiumTheme.primary;
    }
    return Icon(icon, color: color, size: 18);
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) return 'th';
    switch (number % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: PremiumTheme.background,
      child: _tabBar,
    );
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _InfoItem {
  final String label;
  final String value;
  final IconData icon;
  _InfoItem({required this.label, required this.value, required this.icon});
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isEmail;
  final String? studentUID;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isEmail = false,
    this.studentUID,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: PremiumTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: PremiumTheme.primary),
      ),
      title: Text(label, style: GoogleFonts.inter(fontSize: 11, color: PremiumTheme.textSecondary, fontWeight: FontWeight.w500)),
      subtitle: isEmail && studentUID != null
          ? FutureBuilder<String>(
              future: FirebaseFirestore.instance.collection('users').doc(studentUID).get().then((doc) => doc.data()?['email'] ?? 'No email'),
              builder: (context, snap) => Text(snap.data ?? '...', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: PremiumTheme.textPrimary)),
            )
          : Text(
              value.isEmpty ? 'Not Provided' : value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: value.isEmpty ? PremiumTheme.textSecondary.withValues(alpha: 0.5) : PremiumTheme.textPrimary,
                fontStyle: value.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
    );
  }
}
