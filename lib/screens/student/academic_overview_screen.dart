import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../services/academic_record_service.dart';
import '../../services/firestore_service.dart';
import '../../models/student_profile.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';
import '../../utils/result_utils.dart';

class AcademicOverviewScreen extends StatefulWidget {
  final StudentProfile? profile;
  const AcademicOverviewScreen({super.key, this.profile});

  @override
  State<AcademicOverviewScreen> createState() => _AcademicOverviewScreenState();
}

class _AcademicOverviewScreenState extends State<AcademicOverviewScreen> {
  final AcademicRecordService _academicService = AcademicRecordService();
  String? _studentUID;
  Map<String, dynamic>? _academicData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      _studentUID = widget.profile!.studentUID;
      _fetchAcademicRecords();
    } else {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user != null) {
      final userData = await authService.getUserData(user.uid);
      if (userData != null) {
        if (!mounted) return; // Fix async gap
        if (userData.studentUID.isNotEmpty) {
          setState(() => _studentUID = userData.studentUID);
        } else {
          // Fallback
          final firestore = context.read<FirestoreService>();
          final profile = await firestore.getStudentProfileByFirebaseUID(
            user.uid,
          );
          if (mounted && profile != null) {
            setState(() => _studentUID = profile.studentUID);
          }
        }
        await _fetchAcademicRecords();
      }
    }
  }

  Future<void> _fetchAcademicRecords() async {
    if (_studentUID == null) return;
    try {
      final data = await _academicService.getAcademicRecords(_studentUID!);
      if (mounted) {
        setState(() {
          _academicData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching academic records: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Academic Overview',
          style: GoogleFonts.outfit(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).iconTheme.color),
            onPressed: _fetchData,
            tooltip: 'Refresh Records',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: PremiumTheme.primary),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_academicData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No academic records found',
              style: GoogleFonts.inter(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final currentCGPA = (_academicData!['currentCGPA'] ?? 0.0) as double;
    final overallAttendance =
        (_academicData!['overallAttendance'] ?? 0.0) as double;
    final semesters = (_academicData!['semesters'] as List<dynamic>? ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'CGPA',
                  value: currentCGPA.toStringAsFixed(2),
                  subtitle: 'Scale 10.0',
                  icon: Icons.trending_up,
                  color: PremiumTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Attendance',
                  value: '${(overallAttendance * 100).toInt()}%',
                  subtitle: 'Overall',
                  icon: Icons.check_circle_outline,
                  color: PremiumTheme.success,
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: 0.1),

          const SizedBox(height: 24),

          _buildChartSection(semesters),

          const SizedBox(height: 24),

          Text(
            'Recent Semesters',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 16),

          ...semesters.reversed.map((sem) => _buildSemesterCard(sem)),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return NeoGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(List<dynamic> semesters) {
    if (semesters.isEmpty) return const SizedBox.shrink();

    List<FlSpot> spots = [];
    for (int i = 0; i < semesters.length; i++) {
      double cgpa = (semesters[i]['cgpa'] ?? 0.0) as double;
      spots.add(FlSpot(i.toDouble(), cgpa));
    }

    return NeoGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Trend',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < semesters.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'S${index + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
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
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: PremiumTheme.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: PremiumTheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildSemesterCard(dynamic semester) {
    final subjects = semester['subjects'] as List<dynamic>? ?? [];
    final sgpa = (semester['cgpa'] ?? 0.0) as double;
    final isFail = sgpa < 4.0;

    return NeoGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                semester['semesterName'] ?? 'Semester',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              HoloBadge(
                text: 'SGPA: ${sgpa.toStringAsFixed(2)}',
                color: isFail ? PremiumTheme.error : PremiumTheme.secondary,
              ),
            ],
          ),
          if (isFail) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: PremiumTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: PremiumTheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: PremiumTheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'STATUS: FAIL - Eligible for re-exam',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: PremiumTheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...subjects.map(
            (sub) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      sub['name'] ?? 'Subject',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  Text(
                    ResultUtils.formatSGPA(sub['sgpa'] ?? sub['grade']),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: ResultUtils.getGradeColor(sub['sgpa'] ?? sub['grade']),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }
}
