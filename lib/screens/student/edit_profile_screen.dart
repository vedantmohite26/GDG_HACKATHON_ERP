import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/firestore_service.dart';
import '../../models/student_profile.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';
import '../../utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/student_profile_service.dart';
import '../../services/auth_service.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final StudentProfile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _parentPhoneController;
  late TextEditingController _yearController;
  late TextEditingController _incomeController;

  String? _selectedCourse;
  String? _selectedCategory;
  String? _selectedGender;
  String? _selectedShift;
  String? _selectedBloodGroup;

  late TextEditingController _dobController;
  late TextEditingController _validFromController;

  bool _isLoading = false;
  File? _imageFile;
  final StudentProfileService _profileService = StudentProfileService();

  @override
  void initState() {
    super.initState();
    _resetFields();
  }

  void _resetFields() {
    _nameController = TextEditingController(text: widget.profile.name);
    _phoneController = TextEditingController(
      text: widget.profile.contactNumber,
    );
    _parentPhoneController = TextEditingController(
      text: widget.profile.parentContactNumber,
    );
    _yearController = TextEditingController(
      text: widget.profile.year.toString(),
    );
    _incomeController = TextEditingController(
      text: widget.profile.familyIncome.toString(),
    );

    _selectedCourse =
        widget.profile.course.isNotEmpty &&
            Courses.all.contains(widget.profile.course)
        ? widget.profile.course
        : Courses.all.first;
    _selectedCategory =
        widget.profile.category.isNotEmpty &&
            StudentCategory.all.contains(widget.profile.category)
        ? widget.profile.category
        : StudentCategory.all.first;
    _selectedGender = widget.profile.gender.isNotEmpty
        ? widget.profile.gender
        : 'Male';
    
    _selectedShift = widget.profile.shift.isNotEmpty 
        ? widget.profile.shift 
        : AcademicShift.all.first;
    
    _selectedBloodGroup = widget.profile.bloodGroup != 'Not Specified'
        ? widget.profile.bloodGroup
        : BloodGroup.all.first;

    _dobController = TextEditingController(text: widget.profile.dateOfBirth);
    _validFromController = TextEditingController(text: widget.profile.validFrom);

    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    _yearController.dispose();
    _incomeController.dispose();
    _dobController.dispose();
    _validFromController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Client-side compression
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));

        // Upload immediately or on save? Let's do it on save or now.
        // For better UX, let's just hold it and upload on save.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final firestoreService = context.read<FirestoreService>();
      final authService = context.read<AuthService>();
      String profilePhotoUrl = widget.profile.profilePhoto;

      // 1. Upload new image if picked
      if (_imageFile != null) {
        profilePhotoUrl = await _profileService.uploadProfilePhoto(
          widget.profile.id,
          _imageFile!,
        );
      }

      // 2. Update profile
      final updatedProfile = widget.profile.copyWith(
        userId: authService.currentUser?.uid,
        name: _nameController.text.trim(),
        contactNumber: _phoneController.text.trim(),
        parentContactNumber: _parentPhoneController.text.trim(),
        course: _selectedCourse,
        gender: _selectedGender,
        year: int.tryParse(_yearController.text) ?? 1,
        category: _selectedCategory,
        familyIncome: double.tryParse(_incomeController.text) ?? 0.0,
        profilePhoto: profilePhotoUrl,
        bloodGroup: _selectedBloodGroup ?? 'Not Specified',
        dateOfBirth: _dobController.text.trim(),
        shift: _selectedShift ?? 'FIRST',
        validFrom: _validFromController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await firestoreService.updateStudentProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: PremiumTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: PremiumTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // IMMERSIVE APP BAR
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: PremiumTheme.heroGradient,
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    right: -50,
                    child: CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        _buildStylizedAvatar(),
                        const SizedBox(height: 12),
                        Text(
                          'Personalize Profile',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.white70,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _resetFields,
                tooltip: 'Reset Fields',
              ),
            ],
          ),

          // FORM CONTENT
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildSection(
                    title: 'Personal details',
                    icon: Icons.person_outline_rounded,
                    children: [
                      TechInput(
                        label: 'Full Name',
                        controller: _nameController,
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Gender',
                        value: _selectedGender,
                        items: const ['Male', 'Female', 'Other'],
                        icon: Icons.person_2_outlined,
                        onChanged: (val) =>
                            setState(() => _selectedGender = val),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Category',
                        value: _selectedCategory,
                        items: StudentCategory.all,
                        icon: Icons.category_outlined,
                        onChanged: (val) =>
                            setState(() => _selectedCategory = val),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),

                  const SizedBox(height: 24),

                  _buildSection(
                    title: 'Academic Status',
                    icon: Icons.school_outlined,
                    children: [
                      _buildDropdown(
                        label: 'Branch / Course',
                        value: _selectedCourse,
                        items: Courses.all,
                        icon: Icons.account_tree_outlined,
                        onChanged: (val) =>
                            setState(() => _selectedCourse = val),
                      ),
                      const SizedBox(height: 16),
                      TechInput(
                        label: 'Academic Year',
                        controller: _yearController,
                        icon: Icons.calendar_today_outlined,
                      ),
                      const SizedBox(height: 16),
                      TechInput(
                        label: 'Annual Family Income',
                        controller: _incomeController,
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  _buildSection(
                    title: 'Contact Information',
                    icon: Icons.alternate_email_outlined,
                    children: [
                      TechInput(
                        label: 'Personal Phone',
                        controller: _phoneController,
                        icon: Icons.phone_android_outlined,
                      ),
                      const SizedBox(height: 16),
                      TechInput(
                        label: "Parent's Phone",
                        controller: _parentPhoneController,
                        icon: Icons.contact_phone_outlined,
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  _buildSection(
                    title: 'Identity Card Details',
                    icon: Icons.badge_outlined,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Blood Group',
                              value: _selectedBloodGroup,
                              items: BloodGroup.all,
                              icon: Icons.bloodtype_outlined,
                              onChanged: (val) =>
                                  setState(() => _selectedBloodGroup = val),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Shift',
                              value: _selectedShift,
                              items: AcademicShift.all,
                              icon: Icons.access_time_outlined,
                              onChanged: (val) =>
                                  setState(() => _selectedShift = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDateField(
                        label: 'Date of Birth',
                        controller: _dobController,
                        icon: Icons.cake_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildDateField(
                        label: 'Academic Session Start (Valid From)',
                        controller: _validFromController,
                        icon: Icons.event_available_outlined,
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: FutureButton(
                      text: 'Save Profile Changes',
                      icon: Icons.save_rounded,
                      onPressed: _saveProfile,
                      isLoading: _isLoading,
                    ),
                  ).animate().fadeIn(delay: 1000.ms),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylizedAvatar() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Colors.white24, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: PremiumTheme.primary,
              child: _imageFile != null
                  ? ClipOval(
                      child: Image.file(
                        _imageFile!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    )
                  : ClipOval(
                      child: widget.profile.profilePhoto.isNotEmpty
                          ? Image.network(
                              widget.profile.profilePhoto,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.outfit(
                                      fontSize: 36,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white70,
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.outfit(
                                  fontSize: 36,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 14,
                  color: PremiumTheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return NeoGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: PremiumTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: PremiumTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: PremiumTheme.primary.withValues(alpha: 0.5),
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    hint: Text(
                      label,
                      style: GoogleFonts.inter(
                        color: PremiumTheme.textSecondary,
                      ),
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: PremiumTheme.primary,
                    ),
                    dropdownColor: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    items: items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          style: GoogleFonts.inter(fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
          firstDate: DateTime(1990),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: PremiumTheme.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: PremiumTheme.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            controller.text =
                "${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}";
          });
        }
      },
      child: AbsorbPointer(
        child: TechInput(
          label: label,
          controller: controller,
          icon: icon,
        ),
      ),
    );
  }
}
