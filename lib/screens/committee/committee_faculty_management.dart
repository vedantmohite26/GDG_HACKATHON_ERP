import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/faculty_profile.dart';
import '../../services/faculty_service.dart';
import '../../services/user_deletion_service.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';

class CommitteeFacultyManagement extends StatefulWidget {
  final bool showAppBar;
  const CommitteeFacultyManagement({super.key, this.showAppBar = true});

  @override
  State<CommitteeFacultyManagement> createState() =>
      _CommitteeFacultyManagementState();
}

class _CommitteeFacultyManagementState
    extends State<CommitteeFacultyManagement> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.background,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                'Faculty Management',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: PremiumTheme.textPrimary,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: PremiumTheme.textPrimary),
            )
          : null,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(color: PremiumTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by name, ID, department, or email...',
                hintStyle: GoogleFonts.inter(
                  color: PremiumTheme.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: PremiumTheme.primary.withValues(alpha: 0.6),
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: PremiumTheme.textSecondary, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: PremiumTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: PremiumTheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: PremiumTheme.primary.withValues(alpha: 0.05),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: PremiumTheme.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Faculty List
          Expanded(
            child: StreamBuilder<List<FacultyProfile>>(
              stream: FacultyService().streamFacultyOnly(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: PremiumTheme.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading faculty',
                      style: GoogleFonts.inter(color: PremiumTheme.textPrimary),
                    ),
                  );
                }

                final allFaculty = snapshot.data ?? [];
                final filteredFaculty = allFaculty.where((faculty) {
                  if (_searchQuery.isEmpty) return true;
                  return faculty.name.toLowerCase().contains(_searchQuery) ||
                      faculty.email.toLowerCase().contains(_searchQuery) ||
                      faculty.employeeId.toLowerCase().contains(_searchQuery) ||
                      faculty.department.toLowerCase().contains(_searchQuery) ||
                      faculty.designation.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredFaculty.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: PremiumTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            Icons.people_outline_rounded,
                            size: 48,
                            color: PremiumTheme.textSecondary
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No Faculty Members'
                              : 'No matching faculty found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: PremiumTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Faculty members will appear here.'
                              : 'Try a different search query.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: PremiumTheme.textSecondary
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Result count header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color:
                                  PremiumTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${filteredFaculty.length} ${filteredFaculty.length == 1 ? 'member' : 'members'}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: PremiumTheme.primaryLight,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (_searchQuery.isNotEmpty)
                            Text(
                              'Filtered results',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: PremiumTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await Future.delayed(const Duration(seconds: 1));
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredFaculty.length,
                          itemBuilder: (context, index) {
                            final faculty = filteredFaculty[index];
                            return _buildFacultyCard(faculty, index);
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: PremiumTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: PremiumTheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddFacultyDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          label: Text(
            'ADD FACULTY',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
              fontSize: 12,
            ),
          ),
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      PremiumTheme.primary,
      PremiumTheme.secondary,
      PremiumTheme.tertiary,
      PremiumTheme.success,
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
      const Color(0xFFFF5722),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  Widget _buildFacultyCard(FacultyProfile faculty, int index) {
    return NeoGlassCard(
      onTap: () => _showFacultyDetails(faculty),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getAvatarColor(faculty.name).withValues(alpha: 0.8),
                  _getAvatarColor(faculty.name),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _getAvatarColor(faculty.name).withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                faculty.name.isNotEmpty ? faculty.name[0].toUpperCase() : 'F',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        faculty.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: PremiumTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (faculty.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: PremiumTheme.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: PremiumTheme.success.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 12,
                              color: PremiumTheme.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'VERIFIED',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                color: PremiumTheme.success,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: PremiumTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        faculty.employeeId,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: PremiumTheme.primaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        faculty.email,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: PremiumTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.work_outline_rounded,
                      size: 14,
                      color: PremiumTheme.primary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      faculty.designation,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: PremiumTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '•',
                        style: TextStyle(
                            color: PremiumTheme.textSecondary.withValues(
                                alpha: 0.3)),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        faculty.department,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: PremiumTheme.primary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: PremiumTheme.textSecondary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  void _showFacultyDetails(FacultyProfile faculty) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PremiumTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        title: Row(
          children: [
            Expanded(
              child: Text(
                faculty.name,
                style: GoogleFonts.plusJakartaSans(
                  color: PremiumTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ),
            if (faculty.isVerified)
              const Icon(Icons.verified_rounded,
                  color: PremiumTheme.success, size: 24),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.badge, 'Employee ID', faculty.employeeId),
              _buildDetailRow(Icons.email, 'Email', faculty.email),
              _buildDetailRow(Icons.phone, 'Phone', faculty.phone),
              _buildDetailRow(Icons.business, 'Department', faculty.department),
              _buildDetailRow(Icons.work, 'Designation', faculty.designation),
              _buildDetailRow(
                Icons.school,
                'Qualification',
                faculty.qualification,
              ),
              _buildDetailRow(
                Icons.stars,
                'Specialization',
                faculty.specialization,
              ),
              _buildDetailRow(
                Icons.calendar_today,
                'Joining Date',
                '${faculty.joiningDate.day}/${faculty.joiningDate.month}/${faculty.joiningDate.year}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(
                color: PremiumTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteFaculty(faculty);
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            label: Text(
              'Delete',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumTheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFaculty(FacultyProfile faculty) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: PremiumTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PremiumTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: PremiumTheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Faculty',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: PremiumTheme.textPrimary,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete this faculty member?',
              style: GoogleFonts.inter(
                color: PremiumTheme.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: PremiumTheme.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: PremiumTheme.error.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faculty.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: PremiumTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    faculty.email,
                    style: GoogleFonts.inter(
                      color: PremiumTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${faculty.designation} • ${faculty.department}',
                    style: GoogleFonts.inter(
                      color: PremiumTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This will delete their account, profile, and unassign them from all applications and grievances.',
              style: GoogleFonts.inter(
                color: PremiumTheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: PremiumTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Deleting ${faculty.name}...',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  backgroundColor: PremiumTheme.error,
                  duration: const Duration(seconds: 10),
                ),
              );

              try {
                await UserDeletionService().deleteFaculty(faculty.id);
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      '${faculty.name} has been deleted successfully.',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    backgroundColor: PremiumTheme.success,
                  ),
                );
              } catch (e) {
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error: $e',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    backgroundColor: PremiumTheme.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete Permanently',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: PremiumTheme.textSecondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: PremiumTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFacultyDialog(BuildContext context) {
    final facultyIdController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: PremiumTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Add New Faculty',
            style: GoogleFonts.plusJakartaSans(
              color: PremiumTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: facultyIdController,
                style: GoogleFonts.inter(color: PremiumTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Faculty ID',
                  labelStyle:
                      GoogleFonts.inter(color: PremiumTheme.textSecondary),
                  prefixIcon: Icon(Icons.badge_rounded,
                      color: PremiumTheme.primary.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: PremiumTheme.surfaceVariant.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: PremiumTheme.primary.withValues(alpha: 0.1)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                style: GoogleFonts.inter(color: PremiumTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle:
                      GoogleFonts.inter(color: PremiumTheme.textSecondary),
                  prefixIcon: Icon(Icons.email_rounded,
                      color: PremiumTheme.primary.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: PremiumTheme.surfaceVariant.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: PremiumTheme.primary.withValues(alpha: 0.1)),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                style: GoogleFonts.inter(color: PremiumTheme.textPrimary),
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle:
                      GoogleFonts.inter(color: PremiumTheme.textSecondary),
                  prefixIcon: Icon(Icons.lock_rounded,
                      color: PremiumTheme.primary.withValues(alpha: 0.6)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: PremiumTheme.textSecondary,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: PremiumTheme.surfaceVariant.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: PremiumTheme.primary.withValues(alpha: 0.1)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final facultyId = facultyIdController.text.trim();
                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();

                      if (facultyId.isEmpty ||
                          email.isEmpty ||
                          password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please fill in all fields',
                              style: GoogleFonts.inter(),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        // Import Firebase Auth and Firestore
                        final auth = FirebaseAuth.instance;
                        final firestore = FirebaseFirestore.instance;

                        // Create Firebase Auth user
                        final userCredential = await auth
                            .createUserWithEmailAndPassword(
                              email: email,
                              password: password,
                            );

                        final uid = userCredential.user!.uid;

                        // Create user document
                        await firestore.collection('users').doc(uid).set({
                          'email': email,
                          'role': 'faculty',
                          'facultyId': facultyId,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Faculty account created successfully!',
                                style: GoogleFonts.inter(),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: ${e.toString()}',
                                style: GoogleFonts.inter(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumTheme.primary,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Add Faculty',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
