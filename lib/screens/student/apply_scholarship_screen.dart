import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/document_service.dart';
import '../../models/scholarship.dart';
import '../../models/student_profile.dart';
import '../../models/application.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/loading_widget.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';

class ApplyScholarshipScreen extends StatefulWidget {
  final Scholarship scholarship;
  final StudentProfile profile;

  const ApplyScholarshipScreen({
    super.key,
    required this.scholarship,
    required this.profile,
  });

  @override
  State<ApplyScholarshipScreen> createState() => _ApplyScholarshipScreenState();
}

class _ApplyScholarshipScreenState extends State<ApplyScholarshipScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _hasApplied = false;

  String? _selectedCaste;
  final TextEditingController _incomeController = TextEditingController();

  final List<PlatformFile> _pickedFiles = [];
  final Map<String, String> _documentTypes = {};
  final Map<String, TextEditingController> _customDocumentControllers = {};

  final List<String> _casteOptions = ['General', 'OBC', 'SC', 'ST', 'EWS'];
  final List<String> _docTypeOptions = [
    'Income Certificate',
    'Caste Certificate',
    'Mark Sheet',
    'Bonafide Certificate',
    'Aadhar Card',
    'Bank Passbook',
    'Other',
  ];

  Application? _existingApplication;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyApplied();
    if (_casteOptions.contains(widget.profile.category)) {
      _selectedCaste = widget.profile.category;
    }
    if (widget.profile.familyIncome > 0) {
      _incomeController.text = widget.profile.familyIncome.toString();
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    for (var controller in _customDocumentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _checkIfAlreadyApplied() async {
    try {
      final firestoreService = context.read<FirestoreService>();
      final application = await firestoreService.getApplication(
        widget.profile.studentUID,
        widget.scholarship.id,
      );

      if (mounted) {
        setState(() {
          _existingApplication = application;
          _hasApplied = application != null && !application.isReverted;
        });
      }
    } catch (e) {
      debugPrint('Error checking application status: $e');
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _pickedFiles.addAll(result.files);
          for (var file in result.files) {
            if (!_documentTypes.containsKey(file.name)) {
              _documentTypes[file.name] = _docTypeOptions.first;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e')),
        );
      }
    }
  }

  void _removeFile(PlatformFile file) {
    setState(() {
      _pickedFiles.remove(file);
      _documentTypes.remove(file.name);
      _customDocumentControllers[file.name]?.dispose();
      _customDocumentControllers.remove(file.name);
    });
  }

  Future<List<String>> _uploadDocuments() async {
    List<String> uploadedUrls = [];
    final documentService = context.read<DocumentService>();

    for (var file in _pickedFiles) {
      if (file.path == null) continue;
      final fileFile = File(file.path!);
      final bytes = await fileFile.readAsBytes();

      final url = await documentService.uploadDocument(
        studentUID: widget.profile.studentUID,
        fileBytes: bytes,
        fileName: file.name,
        category: 'scholarship',
      );
      uploadedUrls.add(url);
    }
    return uploadedUrls;
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one document.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final firestoreService = context.read<FirestoreService>();
      List<String> uploadedUrls = await _uploadDocuments();

      Map<String, String> finalDocTypes = {};
      for (int i = 0; i < uploadedUrls.length; i++) {
        final url = uploadedUrls[i];
        final file = _pickedFiles[i];
        String type = _documentTypes[file.name] ?? 'Other';

        if (type == 'Other') {
          final customName = _customDocumentControllers[file.name]?.text.trim();
          if (customName != null && customName.isNotEmpty) {
            type = customName;
          }
        }
        finalDocTypes[url] = type;
      }

      final application = Application(
        id: _existingApplication?.id ?? '',
        studentUID: widget.profile.studentUID,
        scholarshipId: widget.scholarship.id,
        status: 'pending',
        submittedAt: DateTime.now(),
        caste: _selectedCaste,
        familyIncome: double.tryParse(_incomeController.text),
        uploadedDocuments: uploadedUrls,
        documentTypes: finalDocTypes,
        notificationStatus: 'none',
      );

      if (_existingApplication != null && _existingApplication!.isReverted) {
        final appData = application.toFirestore();
        await FirebaseFirestore.instance
            .collection('applications')
            .doc(_existingApplication!.id)
            .update(appData);
      } else {
        await firestoreService.submitApplication(application);
      }

      if (mounted) {
        await context.read<NotificationService>().sendNotification(
          userId: widget.profile.studentUID,
          title: 'Application Submitted',
          message: 'Your application for ${widget.scholarship.title} was successful.',
          type: 'success',
        );

        if (mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Success!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded, color: PremiumTheme.success, size: 64),
                  const SizedBox(height: 16),
                  Text('Your application has been submitted and is under review.', 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Great'),
                ),
              ],
            ),
          );
          if (mounted) Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: PremiumTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: PremiumTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Application Form',
          style: GoogleFonts.plusJakartaSans(
            color: PremiumTheme.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScholarshipSummary(),
                  const SizedBox(height: 32),
                  
                  if (_existingApplication != null && _existingApplication!.isReverted)
                    _buildRevertedNotice(),

                  Text(
                    'Verification Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: PremiumTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDropdownField(),
                  const SizedBox(height: 20),
                  _buildIncomeField(),
                  
                  const SizedBox(height: 40),
                  
                  _buildDocumentSectionHeader(),
                  const SizedBox(height: 16),
                  
                  if (_pickedFiles.isEmpty) _buildEmptyDocsState(),
                  
                  ..._pickedFiles.map((file) => _buildFileCard(file)),
                  
                  const SizedBox(height: 120), // Bottom padding for button
                ],
              ),
            ),
          ),
          
          _buildBottomActionButton(),
          
          if (_isSubmitting)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: LoadingWidget(color: Colors.white, size: 40)),
            ),
        ],
      ),
    );
  }

  Widget _buildScholarshipSummary() {
    return NeoGlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PremiumTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.school_rounded, color: PremiumTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.scholarship.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: PremiumTheme.textPrimary,
                  ),
                ),
                Text(
                  '₹${widget.scholarship.amount.toStringAsFixed(0)} Grant',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: PremiumTheme.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevertedNotice() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PremiumTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PremiumTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: PremiumTheme.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Correction Required',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: PremiumTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _existingApplication!.facultyComments ?? 'Please review your documents.',
            style: GoogleFonts.inter(color: PremiumTheme.textPrimary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: DropdownButtonFormField<String>(
          initialValue: _selectedCaste,
        decoration: InputDecoration(
          labelText: 'Caste Category',
          labelStyle: GoogleFonts.inter(color: PremiumTheme.textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.category_rounded, color: PremiumTheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        items: _casteOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (val) => setState(() => _selectedCaste = val),
        validator: (val) => val == null ? 'Selection required' : null,
      ),
    );
  }

  Widget _buildIncomeField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextFormField(
        controller: _incomeController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Annual Family Income (₹)',
          labelStyle: GoogleFonts.inter(color: PremiumTheme.textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: PremiumTheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        validator: (val) => (val == null || val.isEmpty) ? 'Enter income' : null,
      ),
    );
  }

  Widget _buildDocumentSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Documents',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: PremiumTheme.textPrimary,
          ),
        ),
        TextButton.icon(
          onPressed: _pickFiles,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text('Add Files', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          style: TextButton.styleFrom(
            foregroundColor: PremiumTheme.primary,
            backgroundColor: PremiumTheme.primary.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDocsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_upload_outlined, color: Colors.grey.withValues(alpha: 0.3), size: 48),
          const SizedBox(height: 12),
          Text(
            'Upload Certificates (PDF, JPG)',
            style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(PlatformFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PremiumTheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.insert_drive_file_rounded, color: PremiumTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  file.name,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: PremiumTheme.error, size: 20),
                onPressed: () => _removeFile(file),
              ),
            ],
          ),
          const Divider(),
          DropdownButton<String>(
            isExpanded: true,
            underline: const SizedBox(),
            value: _documentTypes[file.name],
            items: _docTypeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.inter(fontSize: 13)))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                   _documentTypes[file.name] = val;
                   if (val == 'Other') {
                     _customDocumentControllers[file.name] ??= TextEditingController();
                   }
                });
              }
            },
          ),
          if (_documentTypes[file.name] == 'Other')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: _customDocumentControllers[file.name],
                decoration: InputDecoration(
                  hintText: 'Specify name...',
                  fillColor: PremiumTheme.background,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButton() {
    final bool canSubmit = !_isSubmitting && (!_hasApplied || (_existingApplication?.isReverted ?? false));

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PremiumTheme.background.withValues(alpha: 0),
              PremiumTheme.background.withValues(alpha: 0.9),
              PremiumTheme.background,
            ],
          ),
        ),
        child: ElevatedButton(
          onPressed: canSubmit ? _submitApplication : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: PremiumTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: PremiumTheme.primary.withValues(alpha: 0.4),
          ),
          child: Text(
            _existingApplication != null && _existingApplication!.isReverted
                ? 'Resubmit Application'
                : (_hasApplied ? 'Already Submitted' : 'Submit Application'),
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
