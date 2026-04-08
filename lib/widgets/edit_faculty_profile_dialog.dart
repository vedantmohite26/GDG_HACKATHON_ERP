import 'package:flutter/material.dart';
import '../models/faculty_profile.dart';
import '../services/faculty_service.dart';

class EditFacultyProfileDialog extends StatefulWidget {
  final String uid;
  final FacultyProfile initialProfile;

  const EditFacultyProfileDialog({
    super.key,
    required this.uid,
    required this.initialProfile,
  });

  @override
  State<EditFacultyProfileDialog> createState() =>
      _EditFacultyProfileDialogState();
}

class _EditFacultyProfileDialogState extends State<EditFacultyProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _deptController;
  late TextEditingController _designationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile.name);
    _phoneController = TextEditingController(text: widget.initialProfile.phone);
    _deptController = TextEditingController(
      text: widget.initialProfile.department,
    );
    _designationController = TextEditingController(
      text: widget.initialProfile.designation,
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FacultyService().updateProfileDetails(
        uid: widget.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        department: _deptController.text.trim(),
        designation: _designationController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deptController,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _designationController,
                decoration: const InputDecoration(labelText: 'Designation'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateProfile,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
