import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/student_profile.dart';
import '../../models/application.dart';
import 'scholarships_screen.dart';
import 'academic_overview_screen.dart';

import '../../theme/premium_theme.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBackButton;

  const ProfileScreen({super.key, this.showBackButton = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _studentUID;
  bool _isLoadingID = true;

  Map<String, String> _scholarshipNames = {};

  @override
  void initState() {
    super.initState();
    _fetchStudentUID();
    _fetchScholarships();
  }

  Future<void> _fetchScholarships() async {
    try {
      final scholarships = await _firestoreService.getAllScholarships();
      if (mounted) {
        setState(() {
          _scholarshipNames = {for (var s in scholarships) s.id: s.title};
        });
      }
    } catch (e) {
      debugPrint('Error fetching scholarships: $e');
    }
  }

  Future<void> _fetchStudentUID() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    // Debug: ProfileScreen: Fetching student UID
    // Debug: Current user UID logged

    if (user != null) {
      try {
        final userData = await authService.getUserData(user.uid);
        // Debug: User data fetched
        // Debug: Student UID logged

        if (mounted && userData != null) {
          setState(() {
            _studentUID = userData.studentUID;
            debugPrint('ProfileScreen: _studentUID set to: $_studentUID');
            _isLoadingID = false;
          });
          // Debug: Student UID set successfully
        } else {
          // Debug: User data is null or widget unmounted
          if (mounted) setState(() => _isLoadingID = false);
        }
      } catch (e) {
        // Debug: Error fetching student UID: $e
        if (mounted) setState(() => _isLoadingID = false);
      }
    } else {
      // Debug: No current user
      if (mounted) setState(() => _isLoadingID = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: PremiumTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.showBackButton
            ? Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _fetchStudentUID(),
            tooltip: 'Refresh Profile',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () {
              if (_studentUID != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return FutureBuilder<StudentProfile?>(
                        future: _firestoreService.getStudentProfile(
                          _studentUID!,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return EditProfileScreen(profile: snapshot.data!);
                          }
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        },
                      );
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoadingID
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<StudentProfile?>(
              // Use studentUID if available, otherwise fall back to Firebase UID
              stream: _studentUID != null && _studentUID!.isNotEmpty
                  ? _firestoreService.streamStudentProfile(_studentUID!)
                  : currentUser != null
                  ? _firestoreService.streamStudentProfileByFirebaseUID(
                      currentUser.uid,
                    )
                  : const Stream.empty(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  // Debug: Profile stream error
                  return _buildErrorState(
                    'Error loading profile: ${snapshot.error}',
                  );
                }

                final profile = snapshot.data;
                if (profile == null) {
                  return _buildErrorState(
                    'Profile not found. Please contact admin.',
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: PremiumTheme.primaryGradient,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: PremiumTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 60,
                          bottom: 40,
                        ),
                        child: Column(
                          children: [
                            // Profile Photo with Edit Button
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: const Color(0xFF2C3E50),
                                  child: profile.profilePhoto.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            profile.profilePhoto,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Text(
                                                profile.name.isNotEmpty
                                                    ? profile.name[0].toUpperCase()
                                                    : '?',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 40,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            },
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white70,
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : Text(
                                          profile.name.isNotEmpty
                                              ? profile.name[0].toUpperCase()
                                              : '?',
                                          style: GoogleFonts.outfit(
                                            fontSize: 40,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF5B5FEF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Name
                            Text(
                              profile.name,
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Student ID
                            Text(
                              'ID: ${profile.studentUID}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white70,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Branch and Year Badges
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildBadge(
                                  icon: Icons.school,
                                  text: profile.course,
                                  color: const Color(0xFF5B5FEF),
                                ),
                                _buildBadge(
                                  icon: Icons.calendar_today,
                                  text: 'Year ${profile.year}',
                                  color: const Color(0xFF9C27B0),
                                ),
                                _buildBadge(
                                  icon: Icons.person,
                                  text: profile.gender.isNotEmpty
                                      ? profile.gender
                                      : 'Male',
                                  color: Colors.blue,
                                ),
                                if (profile.passoutYear.isNotEmpty)
                                  _buildBadge(
                                    icon: Icons.flag,
                                    text: 'Class of ${profile.passoutYear}',
                                    color: const Color(0xFFE53935),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      const SizedBox(height: 24),

                      // PINNED APPLICATIONS (New)
                      if (_studentUID != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: StreamBuilder<List<Application>>(
                            stream: _firestoreService.getStudentApplications(
                              _studentUID!,
                            ),
                            builder: (context, snapshot) {
                              debugPrint(
                                'PinnedApplications Stream: ConnectionState: ${snapshot.connectionState}, HasData: ${snapshot.hasData}',
                              );
                              if (snapshot.hasError) {
                                debugPrint(
                                  'PinnedApplications Stream Error: ${snapshot.error}',
                                );
                              }

                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                debugPrint(
                                  'PinnedApplications: No data or empty list',
                                );
                                return const SizedBox.shrink();
                              }

                              final apps = snapshot.data!;
                              debugPrint(
                                'PinnedApplications: Total apps found: ${apps.length}',
                              );

                              // Filter for relevant statuses (Applied/Pending, Approved, Reverted)
                              final pinnedApps = apps.where((app) {
                                return [
                                  'pending',
                                  'approved',
                                  'reverted',
                                ].contains(app.status);
                              }).toList();

                              debugPrint(
                                'PinnedApplications: Pinned apps count: ${pinnedApps.length}',
                              );

                              if (pinnedApps.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MY APPLICATIONS',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[500],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...pinnedApps.map(
                                    (app) => _buildPinnedApplicationCard(app),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              );
                            },
                          ),
                        ),

                      // Academics & Grants Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACADEMICS & GRANTS',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[500],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),

                            _buildMenuCard(
                              icon: Icons.description,
                              iconColor: const Color(0xFF5B5FEF),
                              iconBg: const Color(
                                0xFF5B5FEF,
                              ).withValues(alpha: 0.1),
                              title: 'Academic Records',
                              subtitle: 'Grades, Attendance, Schedule',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AcademicOverviewScreen(),
                                ),
                              ),
                            ),

                            _buildMenuCard(
                              icon: Icons.monetization_on,
                              iconColor: const Color(0xFF00C853),
                              iconBg: const Color(
                                0xFF00C853,
                              ).withValues(alpha: 0.1),
                              title: 'Scholarships',
                              subtitle: 'Merit-Based Active',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ScholarshipsScreen(),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Contact Info Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'CONTACT INFO',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[500],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Edit',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF5B5FEF),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            _buildContactCard(
                              icon: Icons.email,
                              iconColor: const Color(0xFF9C27B0),
                              iconBg: const Color(
                                0xFF9C27B0,
                              ).withValues(alpha: 0.1),
                              label: 'Email',
                              value: currentUser?.email ?? 'No email',
                            ),

                            _buildContactCard(
                              icon: Icons.phone,
                              iconColor: const Color(0xFFFF9800),
                              iconBg: const Color(
                                0xFFFF9800,
                              ).withValues(alpha: 0.1),
                              label: 'Phone',
                              value: profile.contactNumber.isNotEmpty
                                  ? profile.contactNumber
                                  : 'Not set',
                            ),

                            _buildContactCard(
                              icon: Icons.contact_phone,
                              iconColor: const Color(0xFF4CAF50),
                              iconBg: const Color(
                                0xFF4CAF50,
                              ).withValues(alpha: 0.1),
                              label: "Parent's Phone",
                              value: profile.parentContactNumber.isNotEmpty
                                  ? profile.parentContactNumber
                                  : 'Not set',
                            ),

                            const SizedBox(height: 24),

                            // Support Section
                            Text(
                              'SUPPORT',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[500],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),

                            _buildMenuCard(
                              icon: Icons.warning,
                              iconColor: const Color(0xFFE53935),
                              iconBg: const Color(
                                0xFFE53935,
                              ).withValues(alpha: 0.1),
                              title: 'Grievances',
                              subtitle: 'Track Tickets',
                              onTap: () {},
                            ),

                            _buildMenuCard(
                              icon: Icons.logout,
                              iconColor: const Color(0xFFE53935),
                              iconBg: const Color(
                                0xFFE53935,
                              ).withValues(alpha: 0.1),
                              title: 'Log Out',
                              subtitle: '',
                              onTap: () => authService.signOut(),
                              hideArrow: true,
                            ),

                            const SizedBox(height: 32),

                            // App Version
                            Center(
                              child: Text(
                                'APP VERSION 2.4.1',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),

                            const SizedBox(height: 100),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.inter(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _fetchStudentUID(),
            child: const Text('Retry'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.read<AuthService>().signOut(),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool hideArrow = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PremiumTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (!hideArrow)
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedApplicationCard(Application app) {
    Color color;
    IconData icon;
    String statusText;
    String message;

    switch (app.status) {
      case 'approved':
        color = Colors.green;
        icon = Icons.check_circle;
        statusText = 'Approved';
        message = 'Scholarship Approved';
        break;
      case 'reverted':
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        statusText = 'Action Required';
        message = app.facultyComments ?? 'Please review remarks';
        break;
      case 'pending':
      default:
        color = Colors.blue;
        icon = Icons.access_time_filled;
        statusText = 'Applied';
        message = 'Under Review';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PremiumTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _scholarshipNames[app.scholarshipId] ?? 'Scholarship',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PremiumTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
