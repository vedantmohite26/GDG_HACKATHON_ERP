import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/attendance_service.dart';
import '../../models/student_profile.dart';
import '../../theme/premium_theme.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final StudentProfile profile;

  const StudentAttendanceScreen({super.key, required this.profile});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();

  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _attendanceData = {};

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    try {
      final report = await _attendanceService.getStudentAttendanceReport(
        studentId: widget.profile.id,
        branch: widget.profile.course, // Using course as branch
        year: widget.profile.year.toString(), // Service maps "1" -> "1st Year"
      );

      if (mounted) {
        setState(() {
          _attendanceData = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading attendance: $e')));
      }
    }
  }

  double _calculatePercentage(Map<String, dynamic> stats) {
    final total = stats['total'] as int? ?? 0;
    final present = stats['present'] as int? ?? 0;
    if (total == 0) return 0.0;
    return (present / total) * 100;
  }

  Color _getStatusColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, d MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Attendance',
          style: GoogleFonts.outfit(
            color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: PremiumTheme.primary),
            )
          : _attendanceData.isEmpty
          ? Center(
              child: Text(
                "No attendance records found.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _attendanceData.length,
              itemBuilder: (context, index) {
                final subject = _attendanceData.keys.elementAt(index);
                final stats = _attendanceData[subject]!;
                final percentage = _calculatePercentage(stats);
                final total = stats['total'];
                final present = stats['present'];
                final absent = stats['absent'];
                final history =
                    stats['history'] as Map<String, List<DateTime>>?;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.all(16),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  subject,
                                  style: GoogleFonts.outfit(
                                    color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    percentage,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getStatusColor(percentage),
                                  ),
                                ),
                                child: Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: GoogleFonts.inter(
                                    color: _getStatusColor(percentage),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[800],
                              valueColor: AlwaysStoppedAnimation(
                                _getStatusColor(percentage),
                              ),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Total', '$total', Colors.blue),
                              _buildStatItem(
                                'Present',
                                '$present',
                                Colors.green,
                              ),
                              _buildStatItem('Absent', '$absent', Colors.red),
                            ],
                          ),
                        ],
                      ),
                      children: [
                        const Divider(color: Colors.grey),
                        if (history != null) ...[
                          if (history['Absent']!.isNotEmpty)
                            _buildDateList(
                              'Absent Logs',
                              history['Absent']!,
                              Colors.red,
                            ),
                          if (history['Holiday']!.isNotEmpty)
                            _buildDateList(
                              'Holiday Logs',
                              history['Holiday']!,
                              Colors.orange,
                            ),
                          if (history['Present']!.isNotEmpty)
                            _buildDateList(
                              'Present Logs',
                              history['Present']!,
                              Colors.green,
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDateList(String title, List<DateTime> dates, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: dates
              .map(
                (date) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _formatDate(date),
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
