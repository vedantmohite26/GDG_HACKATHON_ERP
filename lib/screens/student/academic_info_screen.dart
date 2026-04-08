import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../theme/premium_theme.dart';
import '../../services/auth_service.dart';
import '../../services/academic_record_service.dart';
import '../../utils/result_utils.dart';

class AcademicInfoScreen extends StatefulWidget {
  const AcademicInfoScreen({super.key});

  @override
  State<AcademicInfoScreen> createState() => _AcademicInfoScreenState();
}

class _AcademicInfoScreenState extends State<AcademicInfoScreen> {
  int _selectedYear = 0; // 0 = All Years, 1-4 = Individual years
  final AcademicRecordService _recordService = AcademicRecordService();

  String? _studentUID;
  Map<int, Map<String, dynamic>> _yearlyData = {};
  bool _isLoading = true;
  double _overallCGPA = 0.0;
  double _overallAttendance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user != null) {
      final userData = await authService.getUserData(user.uid);
      if (userData != null) {
        _studentUID = userData.studentUID;
        await _loadAcademicRecords();
      }
    }
  }

  Future<void> _loadAcademicRecords() async {
    if (_studentUID == null) return;

    try {
      final data = await _recordService.getAcademicRecords(_studentUID!);

      if (data != null && mounted) {
        _processData(data);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading records: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processData(Map<String, dynamic> data) {
    _overallCGPA = (data['currentCGPA'] ?? 0.0).toDouble();
    _overallAttendance =
        (data['overallAttendance'] ?? 0.0).toDouble() * 100; // Convert to %

    List<dynamic> semesters = data['semesters'] ?? [];

    // Group by Year
    Map<int, Map<String, dynamic>> processed = {};

    for (int year = 1; year <= 4; year++) {
      // Find semesters for this year (e.g., Year 1 = Sem 1, 2)
      int startSem = (year - 1) * 2 + 1;
      int endSem = startSem + 1;

      final yearSemesters = semesters.where((s) {
        final name = s['semesterName'] as String;
        // Parse "Semester X"
        final num = int.tryParse(name.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return num == startSem || num == endSem;
      }).toList();

      if (yearSemesters.isNotEmpty) {
        double yearCGPA = 0;
        double yearAttendance = 0;
        List<dynamic> allSubjects = [];

        for (var sem in yearSemesters) {
          yearCGPA += (sem['cgpa'] ?? 0.0);
          yearAttendance += (sem['attendance'] ?? 0.0);
          allSubjects.addAll(sem['subjects'] ?? []);
        }

        processed[year] = {
          'cgpa': yearCGPA / yearSemesters.length,
          'attendance': (yearAttendance / yearSemesters.length) * 100,
          'subjects': allSubjects,
        };
      }
    }

    setState(() {
      _yearlyData = processed;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: PremiumTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Academic Analytics',
          style: GoogleFonts.outfit(
            color: PremiumTheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: PremiumTheme.primary),
            onPressed: () => _fetchData(),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _yearlyData.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Year Selector
                  _buildYearSelector().animate().fadeIn().slideX(),

                  const SizedBox(height: 24),

                  // Stats Cards
                  _buildStatsCards()
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // CGPA Trend Graph
                  if (_selectedYear == 0)
                    _buildCGPATrendCard()
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // Attendance Graph
                  if (_selectedYear == 0)
                    _buildAttendanceCard()
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // Subject-wise Performance
                  if (_selectedYear > 0)
                    _buildSubjectPerformance()
                        .animate()
                        .fadeIn(delay: 500.ms)
                        .slideY(begin: 0.1),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No academic data available',
            style: GoogleFonts.inter(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
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
          _buildYearChip('All Years', 0),
          if (_yearlyData.containsKey(1)) _buildYearChip('1st Year', 1),
          if (_yearlyData.containsKey(2)) _buildYearChip('2nd Year', 2),
          if (_yearlyData.containsKey(3)) _buildYearChip('3rd Year', 3),
          if (_yearlyData.containsKey(4)) _buildYearChip('4th Year', 4),
        ],
      ),
    );
  }

  Widget _buildYearChip(String label, int year) {
    final isSelected = _selectedYear == year;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedYear = year),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? PremiumTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    double cgpa = _overallCGPA;
    double attendance = _overallAttendance;

    if (_selectedYear > 0 && _yearlyData.containsKey(_selectedYear)) {
      cgpa = _yearlyData[_selectedYear]!['cgpa'];
      attendance = _yearlyData[_selectedYear]!['attendance'];
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            _selectedYear == 0 ? 'Overall CGPA' : 'Year CGPA',
            cgpa.toStringAsFixed(2),
            Icons.school_rounded,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Attendance',
            '${attendance.toStringAsFixed(1)}%',
            Icons.event_available_rounded,
            attendance >= 75 ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: PremiumTheme.primary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCGPATrendCard() {
    List<FlSpot> spots = [];
    for (int i = 1; i <= 4; i++) {
      if (_yearlyData.containsKey(i)) {
        spots.add(FlSpot(i.toDouble(), _yearlyData[i]!['cgpa']));
      }
    }

    if (spots.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CGPA Trend',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: PremiumTheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value >= 1 && value <= 4) {
                          return Text(
                            'Year ${value.toInt()}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 1,
                maxX: 4,
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: PremiumTheme.secondary,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: PremiumTheme.secondary.withValues(alpha: 0.1),
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

  Widget _buildAttendanceCard() {
    List<BarChartGroupData> barGroups = [];
    for (int i = 1; i <= 4; i++) {
      double val = _yearlyData.containsKey(i)
          ? _yearlyData[i]!['attendance']
          : 0.0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              color: val >= 75 ? Colors.green : Colors.orange,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance by Year',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: PremiumTheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value >= 1 && value <= 4) {
                          return Text(
                            'Year ${value.toInt()}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                maxY: 100,
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectPerformance() {
    if (!_yearlyData.containsKey(_selectedYear)) return const SizedBox.shrink();

    final subjects = _yearlyData[_selectedYear]!['subjects'] as List;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject-wise Performance',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: PremiumTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          ...subjects.map((subject) {
            double percentage = 0;
            String displayScore = '';

            if (subject['marks'] != null) {
              percentage = (subject['marks'] / (subject['total'] ?? 100)) * 100;
              displayScore = '${subject['marks']}/${subject['total'] ?? 100}';
            final grade = (subject['sgpa'] ?? subject['grade']);
            final numVal = ResultUtils.getGradePoint(grade);
            displayScore = ResultUtils.formatSGPA(grade);
            percentage = (numVal / 10.0) * 100;
          }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subject['name'] ?? 'Unknown',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: PremiumTheme.primary,
                        ),
                      ),
                      Text(
                        displayScore,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: PremiumTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage >= 90
                            ? Colors.green
                            : percentage >= 75
                            ? Colors.blue
                            : percentage >= 60
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
