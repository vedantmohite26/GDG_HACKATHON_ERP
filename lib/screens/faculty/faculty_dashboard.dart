import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/faculty_service.dart';
import '../../services/firestore_service.dart';
import '../../models/faculty_profile.dart';
import 'review_applications_faculty.dart';
import 'my_assigned_grievances.dart';
import 'verify_documents.dart';
import 'faculty_profile_screen.dart';
import 'mark_attendance_screen.dart';
import 'faculty_documents_viewer.dart';
import 'manage_results_screen.dart';
import 'manage_calendar_screen.dart';
import '../common/create_notice_screen.dart';
import '../common/upload_resource_screen.dart';
import '../common/student_search_screen.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/grievance.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';
import 'faculty_grievance_details_screen.dart';

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().ensureProfileExists();
    });
  }

  List<Widget> _screens(void Function(int) onTapped) => [
    _DashboardHome(onNavigate: onTapped),
    const ReviewApplicationsFaculty(showAppBar: false),
    const MyAssignedGrievances(showAppBar: false),
    const FacultyDocumentsViewer(showAppBar: false),
    const VerifyDocuments(showAppBar: false),
    const MarkAttendanceScreen(showAppBar: false),
    const ManageResultsScreen(showAppBar: false),
    const ManageCalendarScreen(showAppBar: false),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return;
        }

        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Press back again to exit',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: PremiumTheme.primary,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: PremiumTheme.background,
        appBar: _buildAppBar(),
        drawer: _buildDrawer(),
        body: IndexedStack(index: _selectedIndex, children: _screens(_onItemTapped)),
        floatingActionButton: _selectedIndex == 0
            ? FloatingActionButton.extended(
                heroTag: 'faculty_fab',
                backgroundColor: PremiumTheme.secondary,
                foregroundColor: Colors.white,
                elevation: 8,
                shape: const StadiumBorder(),
                icon: const Icon(Icons.add_rounded, size: 24),
                label: Text(
                  'New Notice',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontSize: 16,
                  ),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateNoticeScreen()),
                ),
              )
            : null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: const BoxDecoration(
          gradient: PremiumTheme.primaryGradient,
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: Text(
            _getTitle(_selectedIndex),
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          actions: [
            StreamBuilder<FacultyProfile?>(
              stream: context.read<FacultyService>().streamProfile(
                context.read<AuthService>().currentUser?.uid ?? ''
              ),
              builder: (context, snapshot) {
                final profile = snapshot.data;
                return PopupMenuButton<String>(
                  icon: (profile?.profilePhoto != null && profile!.profilePhoto.isNotEmpty)
                      ? CircleAvatar(
                          radius: 14,
                          backgroundImage: CachedNetworkImageProvider(profile.profilePhoto),
                        )
                      : const Icon(Icons.account_circle_outlined, color: Colors.white),
              onSelected: (result) {
                switch (result) {
                  case 'edit_profile':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FacultyProfileScreen()),
                    );
                    break;
                  case 'logout':
                    context.read<AuthService>().signOut();
                    break;
                }
              },
              color: PremiumTheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit_profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          color: PremiumTheme.primary, size: 18),
                      const SizedBox(width: 12),
                      Text('Edit Profile',
                          style: GoogleFonts.inter(
                              color: PremiumTheme.textPrimary)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded,
                          color: PremiumTheme.error, size: 18),
                      const SizedBox(width: 12),
                      Text('Logout',
                          style: GoogleFonts.inter(
                              color: PremiumTheme.error)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: PremiumTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: PremiumTheme.heroGradient,
              borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<FacultyProfile?>(
                  stream: context.read<FacultyService>().streamProfile(
                    context.read<AuthService>().currentUser?.uid ?? ''
                  ),
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    final name = profile?.name ?? 'Faculty';
                    final dept = profile?.department ?? 'Department';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4), width: 2),
                          ),
                          child: (profile?.profilePhoto != null && profile!.profilePhoto.isNotEmpty)
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: profile.profilePhoto,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => const Icon(
                                      Icons.account_circle_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.co_present_rounded,
                                      color: Colors.white, size: 32),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          dept,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.home_rounded,
                  label: 'Dashboard',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onItemTapped(0),
                ),
                _DrawerItem(
                  icon: Icons.assignment_rounded,
                  label: 'Review Applications',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onItemTapped(1),
                ),
                _DrawerItem(
                  icon: Icons.messenger_outline_rounded,
                  label: 'Assigned Grievances',
                  isSelected: _selectedIndex == 2,
                  onTap: () => _onItemTapped(2),
                ),
                _DrawerItem(
                  icon: Icons.folder_open_rounded,
                  label: 'View Student Documents',
                  isSelected: _selectedIndex == 3,
                  onTap: () => _onItemTapped(3),
                ),
                _DrawerItem(
                  icon: Icons.verified_user_rounded,
                  label: 'Verify Documents',
                  isSelected: _selectedIndex == 4,
                  onTap: () => _onItemTapped(4),
                ),
                _DrawerItem(
                  icon: Icons.how_to_reg_rounded,
                  label: 'Mark Attendance',
                  isSelected: _selectedIndex == 5,
                  onTap: () => _onItemTapped(5),
                ),
                _DrawerItem(
                  icon: Icons.grade_rounded,
                  label: 'Manage Results',
                  isSelected: _selectedIndex == 6,
                  onTap: () => _onItemTapped(6),
                ),
                _DrawerItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Manage Calendar',
                  isSelected: _selectedIndex == 7,
                  onTap: () => _onItemTapped(7),
                ),
                const Divider(height: 24),
                _DrawerItem(
                  icon: Icons.campaign_rounded,
                  label: 'Post Notice',
                  color: PremiumTheme.secondary,
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateNoticeScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.upload_file_rounded,
                  label: 'Upload Resource',
                  color: PremiumTheme.tertiary,
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const UploadResourceScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.search_rounded,
                  label: 'Search Student',
                  color: const Color(0xFF7C3AED),
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const StudentSearchScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          // Logout button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.read<AuthService>().signOut(),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text('Sign Out',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PremiumTheme.error,
                  side: BorderSide(
                      color: PremiumTheme.error.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(48)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Faculty Dashboard';
      case 1:
        return 'Review Applications';
      case 2:
        return 'Assigned Grievances';
      case 3:
        return 'Student Documents';
      case 4:
        return 'Verify Documents';
      case 5:
        return 'Mark Attendance';
      case 6:
        return 'Manage Results';
      case 7:
        return 'Manage Calendar';
      default:
        return 'Faculty Portal';
    }
  }
}

// ─────────────────────────────────────────────────────────
// Faculty Dashboard Home
// ─────────────────────────────────────────────────────────
class _DashboardHome extends StatelessWidget {
  final void Function(int) onNavigate;
  const _DashboardHome({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    final facultyService = context.read<FacultyService>();
    final userId = authService.currentUser?.uid ?? '';

    final dashboardStream = CombineLatestStream.combine2(
      firestoreService.getGlobalPlatformStatsStream(),
      firestoreService.getAssignedGrievancesStream(userId),
      (Map<String, dynamic> stats, List<Grievance> grievances) => {
        'stats': stats,
        'grievances': grievances,
      },
    );

    return StreamBuilder<FacultyProfile?>(
      stream: facultyService.streamProfile(userId),
      builder: (context, profileSnap) {
        final profile = profileSnap.data;
        final name = profile?.name ?? 'Faculty';
        final dept = profile?.department ?? '';
        final designation = profile?.designation ?? '';
        final greeting = PremiumTheme.getGreeting();

        return RefreshIndicator(
          color: PremiumTheme.primary,
          onRefresh: () async => authService.ensureProfileExists(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Hero Header ───
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  decoration: const BoxDecoration(
                    gradient: PremiumTheme.heroGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                          RepaintBoundary(
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        width: 2),
                                    image: (profile?.profilePhoto != null && profile!.profilePhoto.isNotEmpty)
                                        ? DecorationImage(
                                            image: CachedNetworkImageProvider(profile.profilePhoto),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: (profile?.profilePhoto == null || profile!.profilePhoto.isNotEmpty == false)
                                      ? Center(
                                          child: Text(
                                            name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : 'F',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(greeting,
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.white
                                                  .withValues(alpha: 0.8))),
                                      Text(name,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          )),
                                      if (dept.isNotEmpty)
                                        Text('$designation · $dept',
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.white
                                                    .withValues(alpha: 0.75))),
                                    ],
                                  ),
                                ),
                                // Faculty badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    'FACULTY',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(),
                          ),
                      const SizedBox(height: 24),

                      // ─── Stats Row ───
                      StreamBuilder<Map<String, dynamic>>(
                        stream: dashboardStream,
                        builder: (context, dashboardSnap) {
                          final data = dashboardSnap.data ?? {};
                          final stats = data['stats'] as Map<String, dynamic>? ?? {};
                          final grievances = data['grievances'] as List<Grievance>? ?? [];
                          
                          final pendingCount = stats['pendingApplications'] ?? 0;
                          final activeGrievances = grievances.where((g) => g.status != 'resolved').length;
                          final totalStudents = stats['totalStudents'] ?? 0;

                          return RepaintBoundary(
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 10,
                                    child: _FacStatCard(
                                      icon: Icons.assignment_late_rounded,
                                      label: 'Applications',
                                      value: '$pendingCount',
                                      color: PremiumTheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 11,
                                    child: _FacStatCard(
                                      icon: Icons.error_outline_rounded,
                                      label: 'Grievances',
                                      value: '$activeGrievances',
                                      color: PremiumTheme.error,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 10,
                                    child: _FacStatCard(
                                      icon: Icons.group_rounded,
                                      label: 'Students',
                                      value: '$totalStudents',
                                      color: PremiumTheme.primary,
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 100.ms),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),

                      // ─── Assigned Grievances Section ───
                      StreamBuilder<List<Grievance>>(
                        stream: firestoreService.getAssignedGrievancesStream(userId),
                        builder: (context, snap) {
                          final grievances = snap.data?.where((g) => g.status != 'resolved').toList() ?? [];
                          if (grievances.isEmpty) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Assigned Grievances',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: PremiumTheme.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => onNavigate(2),
                                    child: Text(
                                      'See All',
                                      style: GoogleFonts.inter(
                                        color: PremiumTheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...grievances.take(3).map((g) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _GrievanceDashboardCard(grievance: g),
                                  )),
                              const SizedBox(height: 16),
                            ],
                          ).animate().fadeIn(delay: 250.ms);
                        },
                      ),

                      // ─── Quick Actions ───
                      Text(
                        'Quick Actions',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PremiumTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.start,
                        children: [
                          _QAButton(
                            icon: Icons.how_to_reg_rounded,
                            label: 'Attendance',
                            color: PremiumTheme.primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const MarkAttendanceScreen(showAppBar: true)),
                            ),
                          ),
                          _QAButton(
                            icon: Icons.assignment_rounded,
                            label: 'Review Apps',
                            color: PremiumTheme.secondary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ReviewApplicationsFaculty(showAppBar: true)),
                            ),
                          ),
                          _QAButton(
                            icon: Icons.verified_user_rounded,
                            label: 'Verify Docs',
                            color: PremiumTheme.tertiary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const VerifyDocuments(showAppBar: true)),
                            ),
                          ),
                          _QAButton(
                            icon: Icons.campaign_rounded,
                            label: 'Notice',
                            color: const Color(0xFF7C3AED),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const CreateNoticeScreen()),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 28),

                      // ─── Tasks ───
                      Text(
                        'Today\'s Tasks',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PremiumTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _TaskCard(
                        title: 'Mark Today\'s Attendance',
                        subtitle: 'Update attendance records for all classes',
                        icon: Icons.how_to_reg_rounded,
                        accentColor: PremiumTheme.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const MarkAttendanceScreen(showAppBar: true)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _TaskCard(
                        title: 'Review Scholarship Applications',
                        subtitle: 'Pending student applications awaiting review',
                        icon: Icons.assignment_turned_in_rounded,
                        accentColor: PremiumTheme.secondary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ReviewApplicationsFaculty(showAppBar: true)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _TaskCard(
                        title: 'Verify Student Documents',
                        subtitle:
                            'Authenticate and verify uploaded student files',
                        icon: Icons.verified_rounded,
                        accentColor: PremiumTheme.tertiary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const VerifyDocuments(showAppBar: true)),
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ).animate().fadeIn(delay: 300.ms),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FacStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _FacStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: PremiumTheme.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: PremiumTheme.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _QAButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QAButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: PremiumTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _TaskCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeoGlassCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: PremiumTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: PremiumTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: PremiumTheme.textSecondary.withValues(alpha: 0.5),
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? PremiumTheme.primary;
    return Material(
      color: isSelected
          ? activeColor.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : PremiumTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? activeColor : PremiumTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrievanceDashboardCard extends StatelessWidget {
  final Grievance grievance;

  const _GrievanceDashboardCard({required this.grievance});

  @override
  Widget build(BuildContext context) {
    final isResolved = grievance.status == 'resolved';
    final daysLeft = grievance.slaDeadline.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0;

    return NeoGlassCard(
      padding: const EdgeInsets.all(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FacultyGrievanceDetailsScreen(grievance: grievance),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: grievance.priorityScore >= 70
                      ? PremiumTheme.error.withValues(alpha: 0.1)
                      : PremiumTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  grievance.priorityScore >= 70 ? 'URGENT' : 'ASSIGNED',
                  style: GoogleFonts.plusJakartaSans(
                    color: grievance.priorityScore >= 70
                        ? PremiumTheme.error
                        : PremiumTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              if (!isResolved)
                Text(
                  isOverdue ? 'Overdue' : 'Due in $daysLeft d',
                  style: GoogleFonts.inter(
                    color: isOverdue ? PremiumTheme.error : PremiumTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            grievance.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: PremiumTheme.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.category_outlined, size: 14, color: PremiumTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                grievance.category,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: PremiumTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: PremiumTheme.primary),
            ],
          ),
        ],
      ),
    );
  }
}
