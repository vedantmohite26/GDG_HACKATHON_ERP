import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';
import 'student_details_view_screen.dart';

// import '../student/profile_screen.dart'; // Reuse existing profile screen

class StudentSearchScreen extends StatefulWidget {
  const StudentSearchScreen({super.key});

  @override
  State<StudentSearchScreen> createState() => _StudentSearchScreenState();
}

class _StudentSearchScreenState extends State<StudentSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PremiumTheme.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? PremiumTheme.darkBackground : PremiumTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? PremiumTheme.darkText : PremiumTheme.textPrimary,
              size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Container(
          height: 46,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: isDark 
                ? PremiumTheme.darkSurfaceVariant.withValues(alpha: 0.5)
                : PremiumTheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : PremiumTheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: GoogleFonts.inter(
              color: isDark ? PremiumTheme.darkText : PremiumTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search by name or ID...',
              hintStyle: GoogleFonts.inter(
                color: isDark ? PremiumTheme.darkTextSecondary : Colors.grey[500],
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : const Icon(Icons.search, color: Colors.grey, size: 20),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.toLowerCase();
              });
            },
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(Collections.studentProfiles)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          // Client-side filtering
          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final id = (data['studentUID'] ?? '').toString().toLowerCase();
            final uid = doc.id.toLowerCase();

            if (_searchQuery.isEmpty) return true;

            return name.contains(_searchQuery) ||
                id.contains(_searchQuery) ||
                uid.contains(_searchQuery);
          }).toList();

          if (filteredDocs.isEmpty) {
            return Center(
              child: Text(
                'No students found',
                style: GoogleFonts.plusJakartaSans(
                  color: isDark ? PremiumTheme.darkTextSecondary : PremiumTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _StudentListTile(data: data, docId: doc.id);
            },
          );
        },
      ),
    );
  }
}

class _StudentListTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _StudentListTile({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final isDark = PremiumTheme.isDark(context);
    return NeoGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: PremiumTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            (data['name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              color: PremiumTheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ),
        title: Text(
          data['name'] ?? 'Unknown',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: isDark ? PremiumTheme.darkText : PremiumTheme.textPrimary,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: PremiumTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: PremiumTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'ID: ${data['studentUID'] ?? 'N/A'}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: PremiumTheme.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${data['course'] ?? ''} • Year ${data['year'] ?? ''}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? PremiumTheme.darkTextSecondary.withValues(alpha: 0.7) : Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () {
          _showStudentDetails(context, data);
        },
      ),
    );
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> data) {
    final isDark = PremiumTheme.isDark(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? PremiumTheme.darkSurface : PremiumTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    (data['name'] ?? 'U')
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
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
                          color: isDark ? PremiumTheme.darkText : PremiumTheme.textPrimary,
                        ),
                      ),
                      Text(
                        data['email'] ?? '',
                        style: GoogleFonts.inter(
                          color: isDark ? PremiumTheme.darkTextSecondary : PremiumTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _DetailItem(label: 'Student ID', value: data['studentUID']),
            _DetailItem(label: 'Course', value: data['course']),
            _DetailItem(label: 'Year', value: data['year'] != null ? 'Year ${data['year']}' : 'N/A'),
            _DetailItem(label: 'Phone', value: data['phone']),
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final dynamic value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: PremiumTheme.isDark(context) ? PremiumTheme.darkTextSecondary : PremiumTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: PremiumTheme.isDark(context) ? PremiumTheme.darkText : PremiumTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
