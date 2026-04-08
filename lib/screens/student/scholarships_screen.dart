// Scholarships Screen - List all scholarships with eligibility indicators

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/eligibility_service.dart';
import '../../services/academic_record_service.dart';
import '../../models/scholarship.dart';
import '../../models/student_profile.dart';
import '../../models/application.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';
import 'scholarship_detail_screen.dart';

class ScholarshipsScreen extends StatefulWidget {
  final bool showBackButton;

  const ScholarshipsScreen({super.key, this.showBackButton = true});

  @override
  State<ScholarshipsScreen> createState() => _ScholarshipsScreenState();
}

class _ScholarshipsScreenState extends State<ScholarshipsScreen> {
  bool _isLoading = false;
  List<Scholarship> _scholarships = [];
  List<Application> _applications = [];
  StudentProfile? _profile;
  String _filter = 'all'; // all, eligible, not_eligible
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // ... rest of loadData is unchanged
    try {
      final authService = context.read<AuthService>();
      final firestoreService = context.read<FirestoreService>();

      final currentUser = authService.currentUser;
      if (currentUser == null) return;

      final userData = await authService.getUserData(currentUser.uid);
      if (userData == null) return;

      // Load profile, scholarships, applications, AND academic records in parallel
      final applicationsFuture = firestoreService
          .getStudentApplications(userData.studentUID)
          .first;

      if (!mounted) return;
      final academicRecordService = context.read<AcademicRecordService>();

      final results = await Future.wait([
        firestoreService.getStudentProfile(userData.studentUID),
        firestoreService.getAllScholarships(),
        applicationsFuture,
        // New: Fetch academic records for real-time dashboard sync
        academicRecordService.getAcademicRecords(userData.studentUID),
      ]);

      if (mounted) {
        setState(() {
          var fetchedProfile = results[0] as StudentProfile?;
          _scholarships = results[1] as List<Scholarship>;
          _applications = results[2] as List<Application>;
          final academicRecords = results[3] as Map<String, dynamic>?;

          // Sync Profile with Dashboard Data (CGPA/Attendance)
          if (fetchedProfile != null && academicRecords != null) {
            _profile = fetchedProfile.copyWith(
              cgpa: (academicRecords['currentCGPA'] ?? 0.0).toDouble(),
              attendance: (academicRecords['overallAttendance'] ?? 0.0)
                  .toDouble(),
            );
          } else {
            _profile = fetchedProfile;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Scholarship> _getFilteredScholarships() {
    if (_profile == null) return _scholarships;

    return _scholarships.where((scholarship) {
      // Search filter
      if (_searchQuery.isNotEmpty &&
          !scholarship.title.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          )) {
        return false;
      }

      final isEligible = EligibilityService.checkEligibility(
        _profile!,
        scholarship,
      );

      if (_filter == 'eligible') {
        return isEligible;
      } else if (_filter == 'not_eligible') {
        return !isEligible;
      }
      return true; // all
    }).toList();
  }

  Application? _getApplicationForScholarship(String scholarshipId) {
    try {
      return _applications.firstWhere(
        (app) => app.scholarshipId == scholarshipId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'Building ScholarshipsScreen. SearchQuery: $_searchQuery, Profile: ${_profile?.name}',
    );
    final filteredScholarships = _getFilteredScholarships();

    return Scaffold(
      appBar: AppBar(
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        automaticallyImplyLeading: false,
        title: Text(
          'Scholarships',
          style: Theme.of(context).appBarTheme.titleTextStyle ?? const TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Refresh Scholarships',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading scholarships...')
          : _profile == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Complete your profile first',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Profile needed for eligibility checking'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Go to Profile',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: PremiumTheme.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: PremiumTheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(
                        color: PremiumTheme.textPrimary,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search scholarships...',
                        hintStyle: GoogleFonts.inter(
                          color: PremiumTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: PremiumTheme.primary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                // Filter Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      _buildFilterButton('All', 'all', _scholarships.length),
                      const SizedBox(width: 12),
                      _buildFilterButton(
                        'Eligible',
                        'eligible',
                        _profile != null
                            ? _scholarships
                                  .where(
                                    (s) => EligibilityService.checkEligibility(
                                      _profile!,
                                      s,
                                    ),
                                  )
                                  .length
                            : 0,
                      ),
                      const SizedBox(width: 12),
                      _buildFilterButton(
                        'Not Eligible',
                        'not_eligible',
                        _profile != null
                            ? _scholarships
                                  .where(
                                    (s) => !EligibilityService.checkEligibility(
                                      _profile!,
                                      s,
                                    ),
                                  )
                                  .length
                            : 0,
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: filteredScholarships.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.school,
                          message: _searchQuery.isNotEmpty
                              ? 'No scholarships found matching "$_searchQuery"'
                              : _filter == 'all'
                              ? 'No scholarships available yet'
                              : 'No ${_filter.replaceAll('_', ' ')} scholarships found',
                          actionLabel:
                              _filter != 'all' || _searchQuery.isNotEmpty
                              ? 'Clear Filters'
                              : null,
                          onAction: _filter != 'all' || _searchQuery.isNotEmpty
                              ? () {
                                  setState(() {
                                    _filter = 'all';
                                    _searchController.clear();
                                  });
                                }
                              : null,
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredScholarships.length,
                            cacheExtent: 1000, // Smooth scrolling on 120Hz displays
                            itemBuilder: (context, index) {
                              final scholarship = filteredScholarships[index];
                              return _buildScholarshipCard(scholarship);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterButton(String label, String value, int count) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? PremiumTheme.primary : PremiumTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? PremiumTheme.primary
                : PremiumTheme.primary.withValues(alpha: 0.1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: PremiumTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : PremiumTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : PremiumTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : PremiumTheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScholarshipCard(Scholarship scholarship) {
    final isEligible = _profile != null
        ? EligibilityService.checkEligibility(_profile!, scholarship)
        : false;

    final matchScore = _profile != null
        ? EligibilityService.calculateMatchScore(_profile!, scholarship)
        : 0;

    final daysUntilDeadline = scholarship.deadline
        .difference(DateTime.now())
        .inDays;
    final isUrgent = daysUntilDeadline <= 7 && daysUntilDeadline > 0;

    final application = _getApplicationForScholarship(scholarship.id);
    final isReverted = application?.status == 'reverted';

    return NeoGlassCard(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScholarshipDetailScreen(
                scholarship: scholarship,
                profile: _profile,
                application: application,
              ),
            ),
          ).then((_) => _loadData());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scholarship.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: PremiumTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scholarship.organization,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: PremiumTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (application != null)
                  _buildApplicationStatusBadge(application)
                else if (_profile != null)
                  _buildEligibilityBadge(isEligible),
              ],
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),

            if (isReverted && application?.facultyComments != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PremiumTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: PremiumTheme.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: PremiumTheme.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Correction Needed: ${application!.facultyComments}',
                        style: GoogleFonts.inter(
                          color: PremiumTheme.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Info Grid
            Row(
              children: [
                _buildInfoBadge(
                  Icons.payments_rounded,
                  '₹${scholarship.amount.toStringAsFixed(0)}',
                  PremiumTheme.success,
                ),
                const SizedBox(width: 8),
                _buildInfoBadge(
                  Icons.event_rounded,
                  '${daysUntilDeadline}d left',
                  isUrgent ? PremiumTheme.error : PremiumTheme.primary,
                ),
                if (isEligible) ...[
                  const SizedBox(width: 8),
                  _buildInfoBadge(
                    Icons.star_rounded,
                    '$matchScore%',
                    Colors.amber,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            Text(
              scholarship.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: PremiumTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityBadge(bool isEligible) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isEligible ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEligible ? Icons.check_circle : Icons.info,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isEligible ? 'Eligible' : 'Not Eligible',
            style: const TextStyle(
              color: Color.fromARGB(255, 0, 0, 0),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationStatusBadge(Application application) {
    Color color;
    IconData icon;
    String text;

    switch (application.status) {
      case 'reverted':
        color = Colors.orange;
        icon = Icons.priority_high;
        text = 'Reverted';
        break;
      case 'approved':
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        text = 'Rejected';
        break;
      default:
        color = Colors.blue;
        icon = Icons.access_time;
        text = 'Applied';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
