import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../services/student_profile_service.dart';
import '../../utils/constants.dart';
import '../../theme/premium_theme.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class MarkAttendanceScreen extends StatefulWidget {
  final bool showAppBar;
  const MarkAttendanceScreen({super.key, this.showAppBar = true});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final StudentProfileService _studentService = StudentProfileService();
  final AttendanceService _attendanceService = AttendanceService();

  // Selection State
  String _selectedCourse = 'Computer Engineering';
  String _selectedYear = '1st Year';
  String _selectedSemester = 'Semester 1'; // NEW: Semester selection
  String? _selectedSubject;
  DateTime _selectedDate = DateTime.now(); // Date State

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Data State
  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];
  final Map<String, String> _attendanceMap =
      {}; // uid -> Present/Absent/Holiday
  bool _hasFetched = false;
  bool _isAttendanceSaved = false;

  List<String> _courses = []; // Start empty

  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

  // Semester mapping based on year
  List<String> get _semesters {
    if (_selectedYear == '1st Year') return ['Semester 1', 'Semester 2'];
    if (_selectedYear == '2nd Year') return ['Semester 3', 'Semester 4'];
    if (_selectedYear == '3rd Year') return ['Semester 5', 'Semester 6'];
    if (_selectedYear == '4th Year') return ['Semester 7', 'Semester 8'];
    return ['Semester 1'];
  }

  @override
  void initState() {
    super.initState();
    _initializeCourses();
  }

  void _initializeCourses() {
    setState(() {
      _courses = Courses.all;

      // Ensure selected course is valid
      if (!_courses.contains(_selectedCourse)) {
        _selectedCourse = _courses.contains('Computer Engineering')
            ? 'Computer Engineering'
            : _courses.first;
      }
    });
  }

  Future<void> _fetchStudents() async {
    if (_selectedSubject == null) return;

    setState(() {
      _isLoading = true;
      _hasFetched = true;
      _isAttendanceSaved = false;
      _students = [];
      _attendanceMap.clear();
    });

    try {
      // 1. Check if attendance already exists for this session
      final existingSession = await _attendanceService.checkExistingAttendance(
        subject: _selectedSubject!,
        branch: _selectedCourse,
        year: _selectedYear,
        date: _selectedDate,
      );

      // 2. Fetch class list
      final students = await _studentService.getStudentsByFilter(
        branch: _selectedCourse,
        year: _selectedYear,
      );

      setState(() {
        _students = students;
        _isLoading = false;

        if (existingSession != null) {
          // Load existing records
          _isAttendanceSaved = true;
          final Map<String, dynamic> records = existingSession['records'] ?? {};
          for (var s in students) {
            _attendanceMap[s['id']] = records[s['id']] ?? 'Present';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance previously marked for this session.'),
              backgroundColor: Colors.blueGrey,
            ),
          );
        } else {
          // Default to Present for new session
          for (var s in students) {
            _attendanceMap[s['id']] = 'Present';
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
      }
    }
  }

  Future<void> _submitAttendance() async {
    if (_selectedSubject == null || _selectedSubject!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a subject')));
      return;
    }
    if (_students.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null) return;

      await _attendanceService.submitAttendance(
        facultyId: user.uid,
        subject: _selectedSubject!,
        branch: _selectedCourse,
        year: _selectedYear,
        date: _selectedDate,
        studentStatuses: _attendanceMap,
      );

      if (mounted) {
        setState(() {
          _isAttendanceSaved = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance submitted and locked!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting attendance: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateAndDownloadCSV() async {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendance data to download')),
      );
      return;
    }

    try {
      List<List<dynamic>> rows = [];
      // Header
      rows.add([
        'Student Name',
        'Student ID',
        'Status',
        'Date',
        'Subject',
        'Course',
        'Year',
        'Semester',
      ]);

      // Data
      final formattedDate = _formatDate(_selectedDate);
      for (var student in _students) {
        final id = student['id']; // Firebase UID for mapping
        final status = _attendanceMap[id] ?? 'Unknown';
        rows.add([
          student['name'] ?? 'Unknown',
          student['studentUID'] ?? student['studentId'] ?? '',
          status,
          formattedDate,
          _selectedSubject ?? '',
          _selectedCourse,
          _selectedYear,
          _selectedSemester,
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/attendance_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      await Share.shareXFiles([
        XFile(path),
      ], text: 'Attendance Report ($formattedDate)');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _markAll(String status) {
    setState(() {
      for (var key in _attendanceMap.keys) {
        _attendanceMap[key] = status;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: PremiumTheme.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: widget.showAppBar ? 60 : 0,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: PremiumTheme.primary,
              title: widget.showAppBar ? Text(
                'Mark Attendance',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ) : null,
              centerTitle: false,
              leading: widget.showAppBar 
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
              actions: [
                if (_students.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      onPressed: _generateAndDownloadCSV,
                      icon: const Icon(Icons.share_rounded, color: Colors.white),
                      tooltip: 'Share Report',
                    ),
                  ),
              ],
              ),
            ],
            body: _buildManualTab(),
          ),
        );
      }

  // Common Filter Widget
  Widget _buildFilterContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PremiumTheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE3EEF7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: PremiumTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Class Filters',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: PremiumTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Course',
                  value: _selectedCourse,
                  items: _courses,
                  onChanged: (val) => setState(() {
                    _selectedCourse = val!;
                    _selectedSubject = null;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Year',
                  value: _selectedYear,
                  items: _years,
                  onChanged: (val) => setState(() {
                    _selectedYear = val!;
                    _selectedSemester = _semesters.first;
                    _selectedSubject = null;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDateCard()),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Semester',
                  value: _semesters.contains(_selectedSemester)
                      ? _selectedSemester
                      : _semesters.first,
                  items: _semesters,
                  onChanged: (val) => setState(() {
                    _selectedSemester = val!;
                    _selectedSubject = null;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilterDropdown(
            label: 'Subject',
            value: _selectedSubject,
            items: BranchSubjects.getSubjects(
              _selectedCourse,
              _selectedYear,
              _selectedSemester,
            ).map((s) => s.name).toList(),
            onChanged: (val) {
              setState(() => _selectedSubject = val);
              if (val != null) _fetchStudents();
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _fetchStudents,
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_rounded, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Fetch Class List',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildFilterContent(),
          ),
        ),

        // Attendance Summary (Only if students are loaded)
        if (_students.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildAttendanceSummary(),
          ),

        // Action Bar (Bulk Actions)
        if (_students.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Text(
                    'CLASS LIST (${_students.length})',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  _buildQuickAction(
                    'All P',
                    Colors.green,
                    _isAttendanceSaved ? null : () => _markAll('Present'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAction(
                    'All A',
                    Colors.red,
                    _isAttendanceSaved ? null : () => _markAll('Absent'),
                  ),
                ],
              ),
            ),
          ),

        // List Content
        if (_isLoading && _students.isEmpty)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (!_hasFetched)
          SliverFillRemaining(
            child: Center(
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_alt_rounded,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Configure filters and fetch list',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_students.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                'No students found for this class',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _buildStudentItem(_students[index], index);
              }, childCount: _students.length),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading 
                        ? null 
                        : (_isAttendanceSaved ? _generateAndDownloadCSV : _submitAttendance),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAttendanceSaved ? Colors.green[600] : PremiumTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: (_isAttendanceSaved ? Colors.green : PremiumTheme.primary).withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_isAttendanceSaved ? Icons.share_rounded : Icons.save_rounded, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                _isAttendanceSaved ? 'Share CSV Report' : 'Save Attendance',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ],
    );
  }

  Widget _buildStudentItem(Map<String, dynamic> student, int index) {
    final String id = student['id'];
    final String status = _attendanceMap[id] ?? 'Present';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: status == 'Absent' 
              ? Colors.red.withValues(alpha: 0.2) 
              : const Color(0xFFE3EEF7),
          width: status == 'Absent' ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PremiumTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                (student['name'] ?? 'U')[0].toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  color: PremiumTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
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
                  student['name'] ?? 'Unknown Student',
                  style: GoogleFonts.plusJakartaSans(
                    color: PremiumTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'ID: ${student['studentUID'] ?? 'N/A'}',
                        style: GoogleFonts.inter(
                          color: PremiumTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (student['course'] != null) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '• ${student['course']}',
                          style: GoogleFonts.inter(
                            color: PremiumTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (student['year'] != null) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '• Year ${student['year']}',
                          style: GoogleFonts.inter(
                            color: PremiumTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusOption(id, 'Present', 'P', Colors.green),
              const SizedBox(width: 8),
              _buildStatusOption(id, 'Absent', 'A', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, Color color, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: PremiumTheme.primary,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Date',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: PremiumTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          style: GoogleFonts.inter(
            color: PremiumTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.inter(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey[400],
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    int present = _attendanceMap.values.where((v) => v == 'Present').length;
    int absent = _attendanceMap.values.where((v) => v == 'Absent').length;
    int holiday = _attendanceMap.values.where((v) => v == 'Holiday').length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3EEF7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Present', present, Colors.green),
          _buildSummaryDivider(),
          _buildSummaryItem('Absent', absent, Colors.red),
          _buildSummaryDivider(),
          _buildSummaryItem('Holiday', holiday, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryDivider() {
    return Container(
      height: 30,
      width: 1,
      color: const Color(0xFFE3EEF7),
    );
  }

  Widget _buildStatusOption(
    String studentId,
    String status,
    String label,
    Color color,
  ) {
    final isSelected = _attendanceMap[studentId] == status;
    return GestureDetector(
      onTap: _isAttendanceSaved ? null : () {
        setState(() {
          _attendanceMap[studentId] = status;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
