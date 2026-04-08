import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../services/result_service.dart';
import '../../utils/constants.dart';
import '../../theme/premium_theme.dart';

class ManageResultsScreen extends StatefulWidget {
  final bool showAppBar;
  const ManageResultsScreen({super.key, this.showAppBar = true});

  @override
  State<ManageResultsScreen> createState() => _ManageResultsScreenState();
}

class _ManageResultsScreenState extends State<ManageResultsScreen> {
  final ResultService _resultService = ResultService();

  // Selection State
  String _selectedCourse = 'Computer Engineering';
  String _selectedYear = '1st Year';
  String _selectedSemester = 'Semester 1';

  // Data State
  bool _isLoading = false;
  List<String> _courses = [];

  @override
  void initState() {
    super.initState();
    _initializeCourses();
  }

  void _initializeCourses() {
    setState(() {
      _courses = Courses.all;
      if (!_courses.contains(_selectedCourse)) {
        _selectedCourse = _courses.contains('Computer Engineering')
            ? 'Computer Engineering'
            : _courses.first;
      }
    });
  }

  List<String> get _semesters {
    if (_selectedYear == '1st Year') return ['Semester 1', 'Semester 2'];
    if (_selectedYear == '2nd Year') return ['Semester 3', 'Semester 4'];
    if (_selectedYear == '3rd Year') return ['Semester 5', 'Semester 6'];
    if (_selectedYear == '4th Year') return ['Semester 7', 'Semester 8'];
    return ['Semester 1'];
  }

  Future<void> _pickAndUploadCSV() async {
    try {
      debugPrint('Starting CSV pick (Wide Format)...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('No file selected');
        return;
      }

      final fileObj = result.files.single;
      final path = fileObj.path;
      debugPrint('Selected file path: $path, extension: ${fileObj.extension}');

      // Validate Extension
      if (fileObj.extension?.toLowerCase() != 'csv' &&
          (path == null || !path.toLowerCase().endsWith('.csv'))) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a .csv file')),
          );
        }
        return;
      }

      setState(() => _isLoading = true);

      String csvString;
      try {
        if (path != null) {
          final file = File(path);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            csvString = utf8.decode(bytes, allowMalformed: true);
          } else {
            throw Exception('File does not exist at path: $path');
          }
        } else if (fileObj.bytes != null) {
          csvString = utf8.decode(fileObj.bytes!, allowMalformed: true);
        } else {
          throw Exception('No file path or bytes available');
        }
      } catch (e) {
        debugPrint('Error reading file: $e');
        throw Exception('Could not read file content: $e');
      }

      // Parse CSV
      final lines = const LineSplitter().convert(csvString);
      if (lines.isEmpty) throw Exception('Empty CSV file');

      // 1. Process Headers
      final headers = lines.first.split(',').map((e) => e.trim()).toList();
      debugPrint('Headers found: $headers');

      // Find identifying columns
      final idIndex = headers.indexWhere(
        (h) =>
            h.toLowerCase().contains('id') ||
            h.toLowerCase().contains('student id'),
      );

      if (idIndex == -1) {
        throw Exception('CSV must contain a "Student ID" column.');
      }

      // 2. Map Columns to Subjects
      // We look for columns that are NOT ID or Name, and match them to valid subjects
      final validSubjects = BranchSubjects.getSubjects(
        _selectedCourse,
        _selectedYear,
        _selectedSemester,
      );

      // Map<ColumnIndex, SubjectModel>
      final Map<int, SubjectModel> columnSubjectMap = {};

      for (int i = 0; i < headers.length; i++) {
        if (i == idIndex) continue; // Skip ID column
        // Skip common non-subject columns like 'Name', 'Roll No', etc. if they exist
        if ([
          'name',
          'student name',
          'roll',
          'sr',
          'no',
        ].contains(headers[i].toLowerCase())) {
          continue;
        }

        final headerName = headers[i];

        // Match header to subject
        final matchedSubject = validSubjects.firstWhere(
          (s) =>
              s.name.toLowerCase() == headerName.toLowerCase() ||
              s.name.toLowerCase().contains(
                headerName.toLowerCase(),
              ) || // e.g., "Physics" matches "Applied Physics"
              headerName.toLowerCase().contains(
                s.name.toLowerCase(),
              ) || // e.g., "Engg Math-I" matches "Math" (maybe too loose? Be careful)
              _matchSubjectFuzzy(
                s.name,
                headerName,
              ), // Helper for "Engineering Mathematics-1" vs "Engineering Mathematics I"
          orElse: () => SubjectModel('Unknown', 0),
        );

        if (matchedSubject.name != 'Unknown') {
          columnSubjectMap[i] = matchedSubject;
          debugPrint(
            'Mapped Column "$headerName" -> Subject "${matchedSubject.name}"',
          );
        } else {
          debugPrint('Unmapped Column: "$headerName"');
        }
      }

      if (columnSubjectMap.isEmpty) {
        throw Exception(
          'No valid subject columns found. Check your CSV headers against the curriculum.',
        );
      }

      // 3. Process Rows (Grades)
      // Group: SubjectName -> List<{id, grade}>
      Map<String, List<Map<String, dynamic>>> resultsBySubject = {};

      // Initialize lists
      for (var sub in columnSubjectMap.values) {
        resultsBySubject[sub.name] = [];
      }

      int processedStudents = 0;

      for (int i = 1; i < lines.length; i++) {
        try {
          final cells = lines[i].split(',').map((e) => e.trim()).toList();
          if (cells.length <= idIndex) {
            continue;
          }

          String studentId = cells[idIndex];
          if (studentId.isEmpty) {
            continue;
          }

          bool hasData = false;

          // Check each mapped subject column
          for (var entry in columnSubjectMap.entries) {
            int colIndex = entry.key;
            SubjectModel subject = entry.value;

            if (cells.length > colIndex) {
              String gradeVal = cells[colIndex];
              if (gradeVal.isNotEmpty) {
                resultsBySubject[subject.name]!.add({
                  'id': studentId,
                  'sgpa': gradeVal,
                });
                hasData = true;
              }
            }
          }

          if (hasData) processedStudents++;
        } catch (e) {
          debugPrint('Error processing row $i: $e');
        }
      }

      if (processedStudents == 0) {
        throw Exception('No student data found.');
      }

      // 4. Publish Results per Subject
      for (var entry in resultsBySubject.entries) {
        final subjectName = entry.key;
        final results = entry.value;
        if (results.isEmpty) continue;

        // Get credits from the already matched subject model (or lookup again to be safe)
        final credits = columnSubjectMap.values
            .firstWhere((s) => s.name == subjectName)
            .credits;

        debugPrint('Publishing ${results.length} results for $subjectName');
        await _resultService.publishResults(
          course: _selectedCourse,
          semester: _selectedSemester,
          subjectName: subjectName,
          subjectCredits: credits,
          studentResults: results,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Uploaded results for $processedStudents students across ${columnSubjectMap.length} subjects!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('Error uploading CSV: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading CSV: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Improved Fuzzy Matcher
  bool _matchSubjectFuzzy(String subjectName, String headerName) {
    String cleanSub = subjectName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    String cleanHead = headerName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );

    // Explicit checks for Roman Numerals vs Digits (I/II vs 1/2)
    cleanSub = cleanSub
        .replaceAll('i', '1')
        .replaceAll('ii', '2'); // Naive but often effective for sem 1/2
    cleanHead = cleanHead.replaceAll('i', '1').replaceAll('ii', '2');

    return cleanSub.contains(cleanHead) || cleanHead.contains(cleanSub);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => widget.showAppBar ? [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: PremiumTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: PremiumTheme.heroGradient,
                ),
              ),
              title: Text(
                'Manage Results',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            )
          ),
        ] : [],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FILTERS CARD
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: PremiumTheme.surface,
                  borderRadius: BorderRadius.circular(PremiumTheme.radiusCard),
                  boxShadow: [
                    BoxShadow(
                      color: PremiumTheme.primary.withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Curriculum Filters',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: PremiumTheme.textPrimary,
                        letterSpacing: -0.02,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Course',
                      value: _selectedCourse,
                      items: _courses,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCourse = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: 'Year',
                            value: _selectedYear,
                            items: [
                              '1st Year',
                              '2nd Year',
                              '3rd Year',
                              '4th Year',
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedYear = val;
                                  _selectedSemester = _semesters.first;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Semester',
                            value: _semesters.contains(_selectedSemester)
                                ? _selectedSemester
                                : _semesters.first,
                            items: _semesters,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedSemester = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // CSV UPLOAD SECTION
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: PremiumTheme.surface,
                  borderRadius: BorderRadius.circular(PremiumTheme.radiusCard),
                  boxShadow: [
                    BoxShadow(
                      color: PremiumTheme.primary.withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: PremiumTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.upload_file_rounded,
                            color: PremiumTheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bulk Upload Results',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: PremiumTheme.textPrimary,
                                  letterSpacing: -0.02,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Wide format CSV supported',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 13,
                                  color: PremiumTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: PremiumTheme.surfaceContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(PremiumTheme.radiusInput),
                        border: Border.all(
                          color: PremiumTheme.primary.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: PremiumTheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Format: Student ID, Name, Subject1, Subject2...\nColumns must match the curriculum precisely.',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                color: PremiumTheme.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _pickAndUploadCSV,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.cloud_upload_rounded,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isLoading ? 'Processing...' : 'Upload CSV File',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: PremiumTheme.primary.withValues(alpha: 0.3),
                          elevation: 8,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(PremiumTheme.radiusPill),
                          ),
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.disabled)
                                ? Colors.grey[400]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.beVietnamPro(
          color: PremiumTheme.textSecondary,
          fontSize: 14,
        ),
        filled: true,
        fillColor: PremiumTheme.surfaceContainer.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PremiumTheme.radiusPill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PremiumTheme.radiusPill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PremiumTheme.radiusPill),
          borderSide: const BorderSide(color: PremiumTheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      icon: const Icon(Icons.expand_more_rounded, color: PremiumTheme.primary),
      style: GoogleFonts.beVietnamPro(fontSize: 15, color: PremiumTheme.textPrimary),
      dropdownColor: PremiumTheme.surface,
      borderRadius: BorderRadius.circular(PremiumTheme.radiusCard),
      isExpanded: true,
      initialValue: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
