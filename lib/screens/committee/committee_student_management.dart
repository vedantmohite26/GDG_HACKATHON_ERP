import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';
import '../../services/export_service.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/user_deletion_service.dart';
import '../common/student_details_view_screen.dart';

class CommitteeStudentManagement extends StatefulWidget {
  final bool showAppBar;
  const CommitteeStudentManagement({super.key, this.showAppBar = true});

  @override
  State<CommitteeStudentManagement> createState() =>
      _CommitteeStudentManagementState();
}

class _CommitteeStudentManagementState
    extends State<CommitteeStudentManagement> {
  final TextEditingController _searchController = TextEditingController();
  final ExportService _exportService = ExportService();
  String _searchQuery = '';
  List<Map<String, dynamic>> _currentFilteredList = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportList(BuildContext context) async {
    if (_currentFilteredList.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No students to export')));
      return;
    }

    try {
      final path = await _exportService.generateStudentListCsv(
        _currentFilteredList,
      );
      if (context.mounted) {
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(path)], text: 'Student List Export');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'Search by name, ID, or branch...',
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
                                color: PremiumTheme.textSecondary,
                                size: 18),
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
                  style: GoogleFonts.inter(
                    color: PremiumTheme.textPrimary,
                    fontSize: 15,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _exportList(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: PremiumTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: PremiumTheme.primary.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.file_download_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Student List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(Collections.studentProfiles)
                .snapshots(),
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
                    'Error: ${snapshot.error}',
                    style: GoogleFonts.inter(color: PremiumTheme.textPrimary),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              // Filtering
              _currentFilteredList = docs
                  .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    data['id'] = doc.id;
                    return data;
                  })
                  .where((data) {
                    final name = (data['name'] ?? '')
                        .toString()
                        .toLowerCase();
                    final id = (data['studentUID'] ?? '')
                        .toString()
                        .toLowerCase();
                    final branch = (data['branch'] ?? '')
                        .toString()
                        .toLowerCase();

                    if (_searchQuery.isEmpty) return true;

                    return name.contains(_searchQuery) ||
                        id.contains(_searchQuery) ||
                        branch.contains(_searchQuery);
                  })
                  .toList();

              // Count header
              return Column(
                children: [
                  // Result count
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: PremiumTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_currentFilteredList.length} ${_currentFilteredList.length == 1 ? 'student' : 'students'}',
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
                    child: _currentFilteredList.isEmpty
                        ? Center(
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
                                    Icons.person_search_rounded,
                                    size: 48,
                                    color: PremiumTheme.textSecondary
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No students found'
                                      : 'No matching students',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: PremiumTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Students will appear here once registered.'
                                      : 'Try a different search query.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: PremiumTheme.textSecondary
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              await Future.delayed(const Duration(seconds: 1));
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              itemCount: _currentFilteredList.length,
                              itemBuilder: (context, index) {
                                final data = _currentFilteredList[index];
                                return _StudentListTile(
                                        data: data, index: index);
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
    );

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: PremiumTheme.background,
        appBar: AppBar(
          title: Text(
            'Student Management',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: PremiumTheme.textPrimary,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: PremiumTheme.textPrimary),
        ),
        body: body,
      );
    }
    return Scaffold(
      backgroundColor: PremiumTheme.background,
      body: body,
    );
  }
}

class _StudentListTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;

  const _StudentListTile({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? 'Unknown').toString();
    final course = (data['course'] ?? '').toString();
    final year = data['year']?.toString() ?? '';

    // Generate consistent color based on name
    final colors = [
      PremiumTheme.primary,
      PremiumTheme.secondary,
      PremiumTheme.tertiary,
      PremiumTheme.success,
      const Color(0xFF9C27B0),
    ];
    final avatarColor = colors[name.hashCode.abs() % colors.length];

    return NeoGlassCard(
      onTap: () => _showStudentDetails(context, data),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  avatarColor.withValues(alpha: 0.8),
                  avatarColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: avatarColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
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
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: PremiumTheme.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (data['studentUID'] != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: PremiumTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${data['studentUID']}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: PremiumTheme.primaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        '${course.isNotEmpty ? course : ""}${course.isNotEmpty && year.isNotEmpty ? " • " : ""}${year.isNotEmpty ? "Year $year" : ""}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: PremiumTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              color: PremiumTheme.textSecondary.withValues(alpha: 0.4),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: PremiumTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: PremiumTheme.primary.withValues(alpha: 0.06),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: PremiumTheme.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: PremiumTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: PremiumTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (data['name'] ?? 'U')
                          .toString()
                          .substring(0, 1)
                          .toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unknown',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: PremiumTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data['email'] ?? '',
                        style: GoogleFonts.inter(
                          color: PremiumTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PremiumTheme.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: PremiumTheme.primary.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                children: [
                  _DetailItem(
                      icon: Icons.badge_rounded,
                      label: 'Student ID',
                      value: data['studentUID']),
                  _DetailItem(
                      icon: Icons.school_rounded,
                      label: 'Course',
                      value: data['course']),
                  _DetailItem(
                      icon: Icons.calendar_today_rounded,
                      label: 'Year',
                      value: data['year'] != null ? 'Year ${data['year']}' : 'N/A'),
                  _DetailItem(
                      icon: Icons.phone_rounded,
                      label: 'Phone',
                      value: data['phone']),
                  _DetailItem(
                      icon: Icons.event_rounded,
                      label: 'Passout',
                      value: data['passoutYear'],
                      isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // View Full Profile Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentDetailsViewScreen(
                        studentUID: data['studentUID'] ?? '',
                        studentName: data['name'],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.person_search_rounded, size: 18),
                label: Text(
                  'View Full Profile',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumTheme.primary.withValues(alpha: 0.1),
                  foregroundColor: PremiumTheme.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: PremiumTheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Delete Student Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _confirmDeleteStudent(context, data);
                },
                icon: const Icon(Icons.delete_forever_rounded, size: 18),
                label: Text(
                  'Delete Student',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumTheme.error.withValues(alpha: 0.08),
                  foregroundColor: PremiumTheme.error,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: PremiumTheme.error.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStudent(
      BuildContext sheetContext, Map<String, dynamic> data) {
    final studentName = data['name'] ?? 'Unknown';
    final studentId = data['studentUID'] ?? data['id'];
    final userId = data['userId'];

    showDialog(
      context: sheetContext,
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
                'Delete Student',
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
              'Are you sure you want to permanently delete this student?',
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
                    studentName,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: PremiumTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  if (studentId != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'ID: $studentId',
                      style: GoogleFonts.inter(
                        color: PremiumTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This will delete their account, profile, applications, documents, grievances, and academic records.',
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
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(sheetContext); // Close bottom sheet

              final messenger = ScaffoldMessenger.of(sheetContext);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Deleting $studentName...',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  backgroundColor: PremiumTheme.error,
                  duration: const Duration(seconds: 10),
                ),
              );

              try {
                await UserDeletionService().deleteStudent(
                  uid: userId,
                  studentId: studentId,
                );
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      '$studentName has been deleted successfully.',
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
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;
  final bool isLast;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: PremiumTheme.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              color: PremiumTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value?.toString() ?? 'N/A',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: PremiumTheme.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
