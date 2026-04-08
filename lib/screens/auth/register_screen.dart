import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentUIDController = TextEditingController();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _parentContactController = TextEditingController();
  final _familyIncomeController = TextEditingController();

  XFile? _selectedImage;
  String? _selectedBranch;
  String? _selectedCurrentYear;
  String? _selectedPassoutYear;
  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _selectedShift;
  DateTime? _selectedDOB;

  bool _acceptedTerms = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final String _selectedRole = UserRole.student;

  @override
  void dispose() {
    _studentUIDController.dispose();
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _parentContactController.dispose();
    _familyIncomeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: PremiumTheme.primary,
              onPrimary: Colors.white,
              onSurface: PremiumTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDOB = picked);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile photo for your ID card')),
      );
      return;
    }

    if (_selectedDOB == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Date of Birth')),
      );
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept terms and conditions')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      int parsedYear = 1;
      if (_selectedCurrentYear != null) {
        if (_selectedCurrentYear!.contains('1st')) parsedYear = 1;
        if (_selectedCurrentYear!.contains('2nd')) parsedYear = 2;
        if (_selectedCurrentYear!.contains('3rd')) parsedYear = 3;
        if (_selectedCurrentYear!.contains('4th')) parsedYear = 4;
      }

      await authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        studentUID: _studentUIDController.text.trim(),
        name: _nameController.text.trim(),
        branch: _selectedBranch,
        currentYear: parsedYear,
        passoutYear: _selectedPassoutYear,
        shift: _selectedShift,
        dob: DateFormat('dd.MM.yyyy').format(_selectedDOB!),
        bloodGroup: _selectedBloodGroup,
        contactNumber: _contactController.text.trim(),
        parentContactNumber: _parentContactController.text.trim(),
        familyIncome: double.tryParse(_familyIncomeController.text.trim()) ?? 0.0,
        gender: _selectedGender,
        profilePhoto: File(_selectedImage!.path),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Profile and ID card created.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateStudentID(String? value) {
    if (value == null || value.isEmpty) {
      return 'Student ID is required';
    }
    final regex = RegExp(r'^\d{4}[A-Z]{2,4}\d{4}$');
    if (!regex.hasMatch(value)) {
      return 'Format: YearBranchNumber (e.g., 2024DS0001)';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'UNIVERSITY PORTAL',
          style: GoogleFonts.inter(
            color: PremiumTheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: PremiumTheme.primary.withValues(alpha: 0.2), width: 2),
                        ),
                        child: _selectedImage != null
                            ? CircleAvatar(
                                radius: 55,
                                backgroundImage: FileImage(File(_selectedImage!.path)),
                              )
                            : CircleAvatar(
                                radius: 55,
                                backgroundColor: isDark ? PremiumTheme.darkSurfaceVariant : Colors.grey[200],
                                child: Icon(Icons.person, size: 50, color: Colors.grey[400]),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: PremiumTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Join the Portal',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.displayMedium?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete your profile for the Digital ID Card.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 32),

                _buildSectionHeader('PERSONAL INFORMATION'),
                const SizedBox(height: 16),
                
                TechInput(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Gender',
                        hint: 'Select',
                        value: _selectedGender,
                        items: ['Male', 'Female', 'Other'],
                        onChanged: (v) => setState(() => _selectedGender = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Blood Group',
                        hint: 'A+',
                        value: _selectedBloodGroup,
                        items: BloodGroup.all,
                        onChanged: (v) => setState(() => _selectedBloodGroup = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Date of Birth'),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              decoration: _inputDecoration(),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 20, color: PremiumTheme.primary),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedDOB == null 
                                        ? ' ' 
                                        : DateFormat('dd.MM.yyyy').format(_selectedDOB!),
                                    style: GoogleFonts.inter(
                                      color: _selectedDOB == null ? Colors.grey[400] : Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TechInput(
                        controller: _contactController,
                        label: 'Contact No',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.length < 10 ? 'Invalid' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TechInput(
                  controller: _parentContactController,
                  label: 'Parent Contact No',
                  icon: Icons.contact_phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Parent phone is required' : (v.length < 10 ? 'Invalid' : null),
                ),

                const SizedBox(height: 32),
                _buildSectionHeader('ACADEMIC DETAILS'),
                const SizedBox(height: 16),

                TechInput(
                  controller: _studentUIDController,
                  label: 'Student ID / Enrollment',
                  icon: Icons.badge_outlined,
                  validator: _validateStudentID,
                ),
                const SizedBox(height: 16),

                TechInput(
                  controller: _familyIncomeController,
                  label: 'Annual Family Income (₹)',
                  icon: Icons.account_balance_wallet_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Income is required' : (double.tryParse(v) == null ? 'Invalid amount' : null),
                ),
                const SizedBox(height: 16),

                TechInput(
                  controller: _emailController,
                  label: 'College Email',
                  icon: Icons.alternate_email_rounded,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),

                _buildDropdown(
                  label: 'Branch / Course',
                  hint: 'Select your branch',
                  value: _selectedBranch,
                  items: Courses.all,
                  onChanged: (v) => setState(() => _selectedBranch = v),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Current Year',
                        hint: 'Year',
                        value: _selectedCurrentYear,
                        items: ['1st Year', '2nd Year', '3rd Year', '4th Year'],
                        onChanged: (v) => setState(() => _selectedCurrentYear = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Shift',
                        hint: 'Shift',
                        value: _selectedShift,
                        items: AcademicShift.all,
                        onChanged: (v) => setState(() => _selectedShift = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildDropdown(
                  label: 'Passout Year',
                  hint: 'Select Year',
                  value: _selectedPassoutYear,
                  items: List.generate(6, (i) => (DateTime.now().year + i).toString()),
                  onChanged: (v) => setState(() => _selectedPassoutYear = v),
                ),

                const SizedBox(height: 32),
                _buildSectionHeader('SECURITY'),
                const SizedBox(height: 16),

                TechInput(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: _obscurePassword,
                  validator: Validators.validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: PremiumTheme.primary,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 16),

                TechInput(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock_outline,
                  isPassword: _obscureConfirmPassword,
                  validator: _validateConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: PremiumTheme.primary,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
                      activeColor: PremiumTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    Expanded(
                      child: Text(
                        'I agree to the Terms of Service and Privacy Policy',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: FutureButton(
                    text: 'Create Account',
                    onPressed: _handleRegister,
                    isLoading: _isLoading,
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: PremiumTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: PremiumTheme.primary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
      ),
    );
  }

  BoxDecoration _inputDecoration() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? PremiumTheme.darkSurfaceVariant : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 8),
        Container(
          decoration: _inputDecoration(),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: onChanged,
            validator: (v) => v == null ? 'Required' : null,
          ),
        ),
      ],
    );
  }
}

