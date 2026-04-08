import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/notice.dart';
import '../../utils/constants.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';

class UploadResourceScreen extends StatefulWidget {
  const UploadResourceScreen({super.key});

  @override
  State<UploadResourceScreen> createState() => _UploadResourceScreenState();
}

class _UploadResourceScreenState extends State<UploadResourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _linkController = TextEditingController();

  String _resourceType = NoticeType.courseMaterial;
  String _selectedCourse = Courses.all.first;
  String _selectedYear = '1st Year';
  String _selectedSemester = 'Semester 1';
  bool _isLoading = false;

  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

  List<String> get _semesters {
    if (_selectedYear == '1st Year') return ['Semester 1', 'Semester 2'];
    if (_selectedYear == '2nd Year') return ['Semester 3', 'Semester 4'];
    if (_selectedYear == '3rd Year') return ['Semester 5', 'Semester 6'];
    if (_selectedYear == '4th Year') return ['Semester 7', 'Semester 8'];
    return ['Semester 1'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _submitResource() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final firestoreService = context.read<FirestoreService>();
      final user = authService.currentUser;

      if (user == null) throw Exception('User not logged in');

      final userData = await authService.getUserData(user.uid);
      final postedByName = userData != null
          ? (userData.email.split('@').first)
          : 'Staff';

      await firestoreService.createNotice(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        postedBy: user.uid,
        postedByName: postedByName,
        type: _resourceType,
        externalLink: _linkController.text.trim(),
        course: _selectedCourse,
        year: _selectedYear,
        semester: _selectedSemester,
        isPinned: true,
        priority: 'Medium',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resource posted successfully!'),
            backgroundColor: PremiumTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: PremiumTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Theme(
      data: PremiumTheme.lightTheme,
      child: Scaffold(
        backgroundColor: PremiumTheme.background,
        appBar: AppBar(
          title: Text(
            'Upload Resources',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: PremiumTheme.textPrimary,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: PremiumTheme.textPrimary,
                size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Resource Type'),
                const SizedBox(height: 16),
                _buildTypeSelector(),
                const SizedBox(height: 32),

                _buildSectionTitle('General Information'),
                const SizedBox(height: 16),
                NeoGlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Title'),
                      TextFormField(
                        controller: _titleController,
                        decoration: _inputDecoration('e.g., Semester 5 DS Question Bank'),
                        style: GoogleFonts.inter(color: PremiumTheme.textPrimary),
                        validator: (v) => v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('Description'),
                      TextFormField(
                        controller: _contentController,
                        decoration: _inputDecoration('Enter details about this resource'),
                        style: GoogleFonts.inter(color: PremiumTheme.textPrimary),
                        maxLines: 3,
                        validator: (v) => v?.isEmpty == true ? 'Required' : null,
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 32),

                _buildSectionTitle('Target Audience'),
                const SizedBox(height: 16),
                NeoGlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildDropdown(
                        label: 'Course',
                        value: _selectedCourse,
                        items: Courses.all,
                        onChanged: (v) => setState(() => _selectedCourse = v!),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Year',
                              value: _selectedYear,
                              items: _years,
                              onChanged: (v) {
                                setState(() {
                                  _selectedYear = v!;
                                  _selectedSemester = _semesters.first;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Semester',
                              value: _selectedSemester,
                              items: _semesters,
                              onChanged: (v) => setState(() => _selectedSemester = v!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.milliseconds).slideY(begin: 0.1),

                const SizedBox(height: 32),

                _buildSectionTitle('Source Link'),
                const SizedBox(height: 16),
                NeoGlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Link URL'),
                      TextFormField(
                        controller: _linkController,
                        decoration: _inputDecoration('https://drive.google.com/...'),
                        style: GoogleFonts.inter(color: PremiumTheme.textPrimary),
                        keyboardType: TextInputType.url,
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Required';
                          if (!v!.startsWith('http')) {
                            return 'Link must start with http/https';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 150.milliseconds).slideY(begin: 0.1),

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  child: FutureButton(
                    onPressed: _submitResource,
                    text: 'Post Resource',
                    icon: Icons.cloud_upload_rounded,
                    isLoading: _isLoading,
                  ),
                ).animate().fadeIn(delay: 200.milliseconds).slideY(begin: 0.1),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: PremiumTheme.primary,
        letterSpacing: 1.5,
      ),
    );
  }
 
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: PremiumTheme.textSecondary,
        ),
      ),
    );
  }
 
  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeCard(
            type: NoticeType.courseMaterial,
            label: 'Course',
            icon: Icons.menu_book_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTypeCard(
            type: NoticeType.examResult,
            label: 'Online Test',
            icon: Icons.emoji_events_rounded,
          ),
        ),
      ],
    );
  }
 
  Widget _buildTypeCard({
    required String type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _resourceType == type;
    return GestureDetector(
      onTap: () => setState(() => _resourceType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected
              ? PremiumTheme.primary.withValues(alpha: 0.15)
              : PremiumTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? PremiumTheme.primary
                : PremiumTheme.primary.withValues(alpha: 0.05),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: PremiumTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? PremiumTheme.primary : PremiumTheme.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? PremiumTheme.primary : PremiumTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: PremiumTheme.surface,
          decoration: _inputDecoration(''),
          style: GoogleFonts.inter(
            color: PremiumTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
 
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: PremiumTheme.textSecondary.withValues(alpha: 0.6),
        fontSize: 14,
      ),
      filled: true,
      fillColor: PremiumTheme.surfaceVariant.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: PremiumTheme.primary.withValues(alpha: 0.05)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: PremiumTheme.primary.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: PremiumTheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
