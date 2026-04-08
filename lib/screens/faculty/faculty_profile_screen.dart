import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/faculty_profile.dart';
import '../../services/auth_service.dart';
import '../../services/faculty_service.dart';
import '../../services/cloudinary_service.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

class FacultyProfileScreen extends StatefulWidget {
  const FacultyProfileScreen({super.key});

  @override
  State<FacultyProfileScreen> createState() => _FacultyProfileScreenState();
}

class _FacultyProfileScreenState extends State<FacultyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FacultyService _facultyService = FacultyService();

  bool _isEditing = false;
  bool _isLoading = true;
  FacultyProfile? _profile;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Controllers
  final _nameController = TextEditingController();
  final _empIdController = TextEditingController();
  final _deptController = TextEditingController();
  final _desigController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qualController = TextEditingController();
  final _specController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      final profile = await _facultyService.getProfile(user.uid);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
          if (profile != null) {
            _populateControllers(profile);
          } else {
            _isEditing = true; // Mode to create new
          }
        });
      }
    }
  }

  void _populateControllers(FacultyProfile profile) {
    _nameController.text = profile.name;
    _empIdController.text = profile.employeeId;
    _deptController.text = profile.department;
    _desigController.text = profile.designation;
    _phoneController.text = profile.phone;
    _qualController.text = profile.qualification;
    _specController.text = profile.specialization;
    _selectedImage = null;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null) return;

      String finalPhotoUrl = _profile?.profilePhoto ?? '';

      if (_selectedImage != null) {
        final result = await _cloudinaryService.uploadFile(
          file: _selectedImage!,
          folder: 'faculty_profiles',
        );
        finalPhotoUrl = result['secure_url'];
      }

      final profile = FacultyProfile(
        id: user.uid,
        employeeId: _empIdController.text,
        name: _nameController.text,
        email: user.email!, // Use auth email
        department: _deptController.text,
        designation: _desigController.text,
        phone: _phoneController.text,
        qualification: _qualController.text,
        specialization: _specController.text,
        joiningDate: _profile?.joiningDate ?? DateTime.now(),
        profilePhoto: finalPhotoUrl,
        isVerified: _profile?.isVerified ?? false,
        createdAt: _profile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _facultyService.saveProfile(profile);

      if (mounted) {
        setState(() {
          _profile = profile;
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.outfit(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                if (_isEditing && _profile != null) {
                  _populateControllers(_profile!); // Revert changes
                  _selectedImage = null; // Revert selected image
                }
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _isEditing ? _pickImage : null,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: PremiumTheme.primary,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!) as ImageProvider
                                  : (_profile?.profilePhoto.isNotEmpty == true
                                      ? CachedNetworkImageProvider(_profile!.profilePhoto)
                                      : null),
                              child: (_selectedImage == null &&
                                      (_profile?.profilePhoto == null ||
                                       _profile!.profilePhoto.isEmpty))
                                  ? Text(
                                      _nameController.text.isNotEmpty
                                          ? _nameController.text[0]
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 40,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 20, color: PremiumTheme.primary),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionHeader('Personal Information'),
                    _buildTextField('Full Name', _nameController, Icons.person),
                    _buildTextField(
                      'Employee ID',
                      _empIdController,
                      Icons.badge,
                    ),
                    _buildTextField(
                      'Phone Number',
                      _phoneController,
                      Icons.phone,
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Professional Details'),
                    _buildTextField(
                      'Department',
                      _deptController,
                      Icons.business,
                    ),
                    _buildTextField(
                      'Designation',
                      _desigController,
                      Icons.work,
                    ),
                    _buildTextField(
                      'Qualification',
                      _qualController,
                      Icons.school,
                    ),
                    _buildTextField(
                      'Specialization',
                      _specController,
                      Icons.star,
                    ),

                    const SizedBox(height: 40),

                    if (_isEditing)
                      FutureButton(
                        text: 'Save Profile',
                        onPressed: _saveProfile,
                        // color: PremiumTheme.primary, // Removed or changed to valid param if needed.
                        // FutureButton usually takes generic style or looks up theme?
                        // Let's assume it doesn't have 'color' based on lint.
                        // I'll check definition first, but safer to remove or use correct one.
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: PremiumTheme.primary,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: PremiumTheme.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: _isEditing
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        ),
        validator: (value) => value!.isEmpty ? 'Required' : null,
      ),
    );
  }
}
