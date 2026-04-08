import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../models/student_profile.dart';
import '../../services/firestore_service.dart';
import '../../theme/premium_theme.dart';
import 'documents_screen.dart';
import 'my_grievances_screen.dart';
import 'student_id_card_screen.dart';
import 'academic_overview_screen.dart';
import 'profile_screen.dart';
import 'scholarships_screen.dart';
import 'submit_grievance_screen.dart';
import 'student_attendance_screen.dart';
import '../../services/attendance_service.dart';
import '../../services/academic_record_service.dart';
import 'calendar_screen.dart';
import 'notifications_screen.dart';
import '../../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/skeleton_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/result_utils.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  DateTime? _lastPressedAt;

  final List<Widget> _screens = [
    const _StudentHome(),
    const ScholarshipsScreen(showBackButton: false),
    const _GrievanceWrapper(),
    const ProfileScreen(showBackButton: false),
  ];

  @override
  void initState() {
    super.initState();
    _ensureProfile();
  }

  Future<void> _ensureProfile() async {
    final authService = context.read<AuthService>();
    
    // Performance Optimization: Check cache FIRST for zero-wait transition
    if (authService.currentUser != null) {
      final userData = authService.getCachedRole();
      if (userData != null) {
        // We have the user, let's check for the student profile specifically
        final profile = authService.getCachedProfile(); 
        if (profile != null) {
          debugPrint('Dashboard: Profile found in cache, skipping long await');
          if (mounted) setState(() => _isLoading = false);
          // Still call ensureProfileExists in background to handle auto-repair/updates
          scheduleMicrotask(() => authService.ensureProfileExists());
          return;
        }
      }
    }

    await authService.ensureProfileExists();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: PremiumTheme.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SkeletonCard(
                        width: 50, height: 50, borderRadius: 25,
                        margin: EdgeInsets.zero),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonCard(width: 100, height: 14,
                            margin: EdgeInsets.only(bottom: 8)),
                        SkeletonCard(width: 150, height: 20,
                            margin: EdgeInsets.zero),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const SkeletonCard(width: double.infinity, height: 140),
                const SizedBox(height: 32),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: List.generate(4, (i) =>
                        const SkeletonCard(height: 100, margin: EdgeInsets.zero)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

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
      child: StreamProvider<StudentProfile?>(
        create: (_) => firestore.getStudentProfileStream(user.uid),
        initialData: null,
        catchError: (context, error) => null,
        child: Scaffold(
          backgroundColor: PremiumTheme.background,
          floatingActionButton: _buildFAB(context),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: _buildBottomNav(context),
          body: IndexedStack(index: _selectedIndex, children: _screens),
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: PremiumTheme.orangeGradient,
        boxShadow: [
          BoxShadow(
            color: PremiumTheme.secondary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'dashboard_fab',
        onPressed: () => _showQuickActions(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PremiumTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Quick Actions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: PremiumTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickActionItem(
                  icon: Icons.school_rounded,
                  label: 'Scholarships',
                  color: PremiumTheme.primary,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const ScholarshipsScreen()));
                  },
                ),
                _QuickActionItem(
                  icon: Icons.report_problem_rounded,
                  label: 'Grievance',
                  color: PremiumTheme.secondary,
                  onTap: () {
                    final profile = context.read<StudentProfile?>();
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) =>
                            SubmitGrievanceScreen(profile: profile)));
                  },
                ),
                _QuickActionItem(
                  icon: Icons.upload_file_rounded,
                  label: 'Documents',
                  color: PremiumTheme.tertiary,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const DocumentsScreen()));
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PremiumTheme.surface,
        boxShadow: [
          BoxShadow(
            color: PremiumTheme.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.school_outlined, 'Scholarships'),
              const SizedBox(width: 56), // FAB space
              _buildNavItem(2, Icons.record_voice_over_rounded, 'Grievances'),
              _buildNavItem(3, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? PremiumTheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? PremiumTheme.primary : PremiumTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isSelected
                    ? PremiumTheme.primary
                    : PremiumTheme.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              color: PremiumTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Student Home Tab — Full Academic Vitality Redesign
// ─────────────────────────────────────────────────────────
class _StudentHome extends StatefulWidget {
  const _StudentHome();

  @override
  State<_StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<_StudentHome>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  double _overallAttendance = 0.0;
  final bool _isLoadingAttendance = false;
  final AttendanceService _attendanceService = AttendanceService();
  final AcademicRecordService _academicService = AcademicRecordService();
  String? _fetchedForStudentId;

  Future<void> _fetchOverallAttendance(StudentProfile profile) async {
    if (_fetchedForStudentId == profile.id && !_isLoadingAttendance) return;
    _fetchedForStudentId = profile.id;

    try {
      final report = await _attendanceService.getStudentAttendanceReport(
        studentId: profile.id,
        branch: profile.course,
        year: profile.year.toString(),
      );

      int totalClasses = 0;
      int totalPresent = 0;

      for (var stats in report.values) {
        totalClasses += (stats['total'] as int? ?? 0);
        totalPresent += (stats['present'] as int? ?? 0);
      }

      if (totalClasses > 0 && mounted) {
        setState(() {
          _overallAttendance = (totalPresent / totalClasses) * 100;
        });
      }
    } catch (e) {
      debugPrint('Error fetching overall attendance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final profile = context.watch<StudentProfile?>();

    // Load attendance from cache or fetch if stale
    if (profile != null && (_fetchedForStudentId != profile.id || _overallAttendance == 0.0)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchOverallAttendance(profile);
      });
    }

    final name = profile?.name ?? 'Student';
    final cgpa = profile?.cgpa ?? 0.0;
    final attendance = _overallAttendance;
    final greeting = PremiumTheme.getGreeting();

    return RefreshIndicator(
      color: PremiumTheme.primary,
      onRefresh: () async {
        final authService = context.read<AuthService>();
        await authService.ensureProfileExists();
        if (profile != null) {
          _fetchedForStudentId = null;
          await _fetchOverallAttendance(profile);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Blue Hero Header ───
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 24,
              ),
              decoration: const BoxDecoration(
                gradient: PremiumTheme.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: RepaintBoundary(
                child: Column(
                  children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 46,
                        height: 46,
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
                                  width: 46,
                                  height: 46,
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
                                  errorWidget: (context, url, error) => Center(
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
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
                          ],
                        ),
                      ),
                      // Notifications
                      _buildHeaderActions(context),
                    ],
                  ).animate().fadeIn().slideY(begin: -0.1),

                  const SizedBox(height: 20),

                  // ─── Stats Row ───
                  StreamBuilder<Map<String, dynamic>?>(
                    stream: profile != null
                        ? _academicService.academicRecordsStream(profile.id)
                        : const Stream.empty(),
                    builder: (context, snapshot) {
                      int totalCreditsEarned = 0;
                      String academicStatus = 'active';

                      if (snapshot.hasData && snapshot.data != null) {
                        totalCreditsEarned =
                            (snapshot.data!['totalCreditsEarned'] as int?) ?? 0;
                        academicStatus =
                            snapshot.data!['academicStatus'] as String? ?? 'active';

                        if (profile != null) {
                          context.read<AuthService>().cacheDashboardStats(
                              profile.id, snapshot.data!);
                        }
                      } else if (profile != null) {
                        final cached = context
                            .read<AuthService>()
                            .getCachedDashboardStats(profile.id);
                        if (cached != null) {
                          totalCreditsEarned =
                              (cached['totalCreditsEarned'] as int?) ?? 0;
                          academicStatus =
                              cached['academicStatus'] as String? ?? 'active';
                        }
                      }

                      return RepaintBoundary(
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'CGPA',
                                value: ResultUtils.formatSGPA(cgpa),
                                suffix: '/10',
                                icon: Icons.school_rounded,
                                bgColor: Colors.white.withValues(alpha: 0.15),
                                textColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (profile != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            StudentAttendanceScreen(
                                                profile: profile),
                                      ),
                                    );
                                  }
                                },
                                child: _StatCard(
                                  label: 'ATTENDANCE',
                                  value: '${attendance.toInt()}',
                                  suffix: '%',
                                  icon: Icons.calendar_today_rounded,
                                  bgColor: Colors.white.withValues(alpha: 0.15),
                                  textColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'CREDITS',
                                value: '$totalCreditsEarned',
                                suffix: '',
                                icon: Icons.auto_awesome_rounded,
                                bgColor: academicStatus == 'detained'
                                    ? Colors.red.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.15),
                                textColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
                    },
                  ),
                ],
              ),
            ),
          ),

            const SizedBox(height: 24),

            // ─── Services Section ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Services',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PremiumTheme.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          '',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: PremiumTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.1,
                    children: [
                      _ServiceCard(
                        title: 'Academic Calendar',
                        subtitle: 'View Schedule',
                        icon: Icons.event_note_rounded,
                        color: PremiumTheme.secondary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CalendarScreen()),
                        ),
                      ),
                      _ServiceCard(
                        title: 'Document Vault',
                        subtitle: 'Secure Files',
                        icon: Icons.folder_special_rounded,
                        color: PremiumTheme.tertiary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DocumentsScreen()),
                        ),
                      ),
                      _ServiceCard(
                        title: 'Student ID Card',
                        subtitle: 'View Card',
                        icon: Icons.badge_rounded,
                        color: const Color(0xFFE91E63),
                        onTap: () {
                          if (profile != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    StudentIDCardScreen(profile: profile),
                              ),
                            );
                          }
                        },
                      ),
                      _ServiceCard(
                        title: 'Academic Overview',
                        subtitle: 'View Results',
                        icon: Icons.analytics_rounded,
                        color: const Color(0xFF7C3AED),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AcademicOverviewScreen(profile: profile),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08),

                  const SizedBox(height: 24),

                  // ─── Notifications Teaser ───
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            PremiumTheme.primary.withValues(alpha: 0.12),
                            PremiumTheme.primaryLight.withValues(alpha: 0.06),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: PremiumTheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: PremiumTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: PremiumTheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notices & Updates',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: PremiumTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'View all campus announcements',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: PremiumTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: PremiumTheme.primary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 450.ms),

                  const SizedBox(height: 100), // Bottom nav padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    const NotificationsScreen(filterType: 'resources')),
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.library_books_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: context
                .read<NotificationService>()
                .getUserNotifications(
                    context.read<AuthService>().currentUser!.uid),
            builder: (context, snapshot) {
              final hasUnread = snapshot.data?.docs.any(
                    (doc) =>
                        !(doc.data() as Map<String, dynamic>)['isRead'],
                  ) ??
                  false;
              return Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: PremiumTheme.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: PremiumTheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Stat Card inside blue header
// ─────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final IconData icon;
  final Color bgColor;
  final Color textColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor.withValues(alpha: 0.85), size: 18),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                TextSpan(
                  text: suffix,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: textColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Service Card — Light white card with color icon circle
// ─────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PremiumTheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PremiumTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: PremiumTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Grievance wrapper
// ─────────────────────────────────────────────────────────
class _GrievanceWrapper extends StatelessWidget {
  const _GrievanceWrapper();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<StudentProfile?>();

    if (profile == null) {
      return const Scaffold(
        backgroundColor: PremiumTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: PremiumTheme.primary),
        ),
      );
    }

    return MyGrievancesScreen(profile: profile, showBackButton: false);
  }
}
