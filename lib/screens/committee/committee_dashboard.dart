import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/faculty_service.dart';
import '../../models/faculty_profile.dart';
import '../../theme/premium_theme.dart';

import 'committee_scholarship_approval.dart';
import 'committee_grievance_hub.dart';
import 'committee_student_management.dart';
import 'committee_faculty_management.dart';
import 'widgets/high_priority_alerts_widget.dart';

import '../common/create_notice_screen.dart';
import '../common/upload_resource_screen.dart';
import '../../widgets/edit_faculty_profile_dialog.dart';

class CommitteeDashboard extends StatefulWidget {
  const CommitteeDashboard({super.key});

  @override
  State<CommitteeDashboard> createState() => _CommitteeDashboardState();
}

class _CommitteeDashboardState extends State<CommitteeDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastPressedAt;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().ensureProfileExists();
    });

    _screens = [
      _DashboardHome(onNavigate: _setIndex),
      const CommitteeScholarshipApproval(showAppBar: false),
      const CommitteeGrievanceHub(showAppBar: false),
      const CommitteeStudentManagement(showAppBar: false),
      const CommitteeFacultyManagement(showAppBar: false),
    ];
  }

  void _setIndex(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onDrawerItemTapped(int index) {
    _setIndex(index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: PremiumTheme.lightTheme,
      child: PopScope(
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
          body: IndexedStack(index: _selectedIndex, children: _screens),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: PremiumTheme.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu_rounded,
                      color: PremiumTheme.primary),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _getTitle(_selectedIndex),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: PremiumTheme.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: PremiumTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: PremiumTheme.primary.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    'ADMIN',
                    style: GoogleFonts.inter(
                      color: PremiumTheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.logout_rounded,
                      color: PremiumTheme.textSecondary),
                  onPressed: () => context.read<AuthService>().signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 32,
              left: 28,
              right: 24,
              bottom: 32,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [PremiumTheme.primary, PremiumTheme.primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  'Committee Portal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Administrative Oversight',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _CommitteeDrawerItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onDrawerItemTapped(0),
                ),
                _CommitteeDrawerItem(
                  icon: Icons.verified_rounded,
                  label: 'Scholarship Approval',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onDrawerItemTapped(1),
                ),
                _CommitteeDrawerItem(
                  icon: Icons.report_problem_rounded,
                  label: 'Grievance Hub',
                  isSelected: _selectedIndex == 2,
                  onTap: () => _onDrawerItemTapped(2),
                ),
                _CommitteeDrawerItem(
                  icon: Icons.people_rounded,
                  label: 'Student Management',
                  isSelected: _selectedIndex == 3,
                  onTap: () => _onDrawerItemTapped(3),
                ),
                _CommitteeDrawerItem(
                  icon: Icons.co_present_rounded,
                  label: 'Faculty Management',
                  isSelected: _selectedIndex == 4,
                  onTap: () => _onDrawerItemTapped(4),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                      color: PremiumTheme.primary.withValues(alpha: 0.1), height: 1),
                ),
                _CommitteeDrawerItem(
                  icon: Icons.edit_note_rounded,
                  label: 'Edit My Profile',
                  color: PremiumTheme.secondary,
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    _showEditMyProfile(context);
                  },
                ),
                _CommitteeDrawerItem(
                  icon: Icons.campaign_rounded,
                  label: 'Post Notice',
                  color: PremiumTheme.secondary,
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateNoticeScreen()));
                  },
                ),
                _CommitteeDrawerItem(
                  icon: Icons.upload_file_rounded,
                  label: 'Upload Resource',
                  color: PremiumTheme.tertiary,
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UploadResourceScreen()));
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.read<AuthService>().signOut(),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text('Sign Out',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumTheme.error.withValues(alpha: 0.05),
                  foregroundColor: PremiumTheme.error,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: PremiumTheme.error.withValues(alpha: 0.1))),
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
        return 'Committee Dashboard';
      case 1:
        return 'Scholarship Approval';
      case 2:
        return 'Grievance Hub';
      case 3:
        return 'Student Management';
      case 4:
        return 'Faculty Management';
      default:
        return 'Committee';
    }
  }

  Future<void> _showEditMyProfile(BuildContext context) async {
    final authService = context.read<AuthService>();
    final uid = authService.currentUser?.uid;
    if (uid == null) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final profile = await FacultyService().getProfile(uid);
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => EditFacultyProfileDialog(
          uid: uid,
          initialProfile: profile ??
              FacultyProfile(
                id: uid,
                employeeId: '',
                email: authService.currentUser?.email ?? '',
                name: '',
                phone: '',
                department: '',
                designation: '',
                qualification: '',
                specialization: '',
                isVerified: false,
                joiningDate: DateTime.now(),
                profilePhoto: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

class _DashboardHome extends StatelessWidget {
  final Function(int) onNavigate;
  const _DashboardHome({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final greeting = PremiumTheme.getGreeting();

    return RefreshIndicator(
      color: PremiumTheme.primary,
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          color: PremiumTheme.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Hero Banner ───
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          PremiumTheme.primaryContainer,
                          Colors.white,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: PremiumTheme.primary.withValues(alpha: 0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _RibbonTag(
                                color: PremiumTheme.secondary, label: 'WELFARE'),
                            const SizedBox(width: 8),
                            _RibbonTag(
                                color: PremiumTheme.tertiary, label: 'EXCELLENCE'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    greeting,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: PremiumTheme.primary.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  Text(
                                    'Committee Portal',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: PremiumTheme.primary,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Academic Oversight & Student Welfare',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: PremiumTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: PremiumTheme.primary.withValues(alpha: 0.1),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: PremiumTheme.primary,
                                size: 40,
                              ).animate().scale(duration: 600.milliseconds, curve: Curves.easeOutBack),
                            ),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(),
                  ),
                  const Positioned(
                    right: 60,
                    top: 25,
                    child: Icon(Icons.star_rounded, color: PremiumTheme.secondaryLight, size: 24),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds),
                ],
              ),

              const SizedBox(height: 28),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: PremiumTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CommitteeQA(
                          icon: Icons.campaign_rounded,
                          label: 'Post Notice',
                          color: PremiumTheme.secondary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CreateNoticeScreen()),
                          ),
                        ),
                        _CommitteeQA(
                          icon: Icons.upload_file_rounded,
                          label: 'Resources',
                          color: PremiumTheme.primary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UploadResourceScreen()),
                          ),
                        ),
                        _CommitteeQA(
                          icon: Icons.verified_rounded,
                          label: 'Approvals',
                          color: PremiumTheme.tertiary,
                          onTap: () => onNavigate(1),
                        ),
                        _CommitteeQA(
                          icon: Icons.report_problem_rounded,
                          label: 'Grievances',
                          color: PremiumTheme.error,
                          onTap: () => onNavigate(2),
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.milliseconds),

                    const SizedBox(height: 32),

                    Text(
                      'Platform Overview',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: PremiumTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    StreamBuilder<Map<String, int>>(
                      stream: context
                          .read<FirestoreService>()
                          .getGlobalPlatformStatsStream(),
                      builder: (context, snapshot) {
                        final stats = snapshot.data ?? {};

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _CommitteeStatCard(
                                    title: 'Total Students',
                                    value: '${stats['totalStudents'] ?? 0}',
                                    icon: Icons.group_add_rounded,
                                    gradient: PremiumTheme.primaryGradient,
                                    onTap: () => onNavigate(3),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _CommitteeStatCard(
                                    title: 'Pending Approvals',
                                    value: '${stats['committeePendingApplications'] ?? 0}',
                                    icon: Icons.verified_user_rounded,
                                    gradient: PremiumTheme.orangeGradient,
                                    onTap: () => onNavigate(1),
                                    showStar: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _CommitteeStatCard(
                                    title: 'Unresolved Cases',
                                    value: '${stats['unassignedGrievances'] ?? 0}',
                                    icon: Icons.gavel_rounded,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () => onNavigate(2),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _CommitteeStatCard(
                                    title: 'Faculty Members',
                                    value: '${stats['totalFaculty'] ?? 0}',
                                    icon: Icons.person_pin_rounded,
                                    gradient: PremiumTheme.greenGradient,
                                    onTap: () => onNavigate(4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ).animate().fadeIn(delay: 200.milliseconds);
                      },
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'High Priority Alerts',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: PremiumTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const HighPriorityAlertsWidget(),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RibbonTag extends StatelessWidget {
  final Color color;
  final String label;

  const _RibbonTag({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _CommitteeQA extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CommitteeQA({
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: PremiumTheme.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CommitteeStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;
  final bool showStar;

  const _CommitteeStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    this.onTap,
    this.showStar = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PremiumTheme.primary.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: PremiumTheme.primary.withValues(alpha: 0.06),
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                if (showStar)
                  const Icon(Icons.star_rounded, color: PremiumTheme.secondary, size: 16),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: PremiumTheme.textPrimary,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: PremiumTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommitteeDrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _CommitteeDrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? PremiumTheme.primary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? activeColor.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isSelected ? activeColor : PremiumTheme.textSecondary,
          size: 24,
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? activeColor : PremiumTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
