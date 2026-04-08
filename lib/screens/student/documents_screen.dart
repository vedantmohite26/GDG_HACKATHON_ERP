import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../services/document_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';
import '../../widgets/verified_document_upload_dialog.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _studentUID;
  final bool _isLoading = false;
  final DocumentService _documentService = DocumentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchStudentUID();
  }

  Future<void> _fetchStudentUID() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user != null) {
      final userData = await authService.getUserData(user.uid);
      if (mounted && userData != null) {
        if (userData.studentUID.isNotEmpty) {
          setState(() => _studentUID = userData.studentUID);
        } else {
          // Fallback: try to find profile by Firebase UID
          final firestore = context.read<FirestoreService>();
          final profile = await firestore.getStudentProfileByFirebaseUID(
            user.uid,
          );
          if (mounted && profile != null) {
            setState(() => _studentUID = profile.studentUID);
          }
        }
      }
    }
  }

  Future<void> _pickAndUpload() async {
    if (_studentUID == null) return;

    // Capture messenger before any async gap
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (!mounted) return;

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        final name = pickedFile.name;

        // Validation: 5MB limit
        if (pickedFile.size > 5 * 1024 * 1024) {
          _showError('File is too large (Max 5MB)');
          return;
        }

        // Determine category based on tab
        String category = 'academic';
        if (_tabController.index == 2) category = 'personal';
        if (_tabController.index == 3) category = 'identity';

        // Get file object
        File? file;
        if (pickedFile.path != null) {
          file = File(pickedFile.path!);
        } else {
          _showError('Unable to access file. Please try again.');
          return;
        }

        // Show verification dialog
        final success = await showVerifiedDocumentUploadDialog(
          context: context,
          file: file,
          title: 'Upload ${category.toUpperCase()} Document',
          onUpload: (verifiedFile) async {
            final result = await _documentService
                .uploadDocumentWithVerification(
                  studentUID: _studentUID!,
                  file: verifiedFile,
                  fileName: name,
                  category: category,
                );
            return result['url'];
          },
        );

        if (success && mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('✅ $name verified and uploaded!'),
              backgroundColor: PremiumTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      _showError('Upload failed: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: PremiumTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Documents',
          style: GoogleFonts.outfit(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).iconTheme.color),
            onPressed: () => _fetchStudentUID(),
            tooltip: 'Refresh Documents',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color.fromARGB(255, 0, 0, 0),
          unselectedLabelColor: PremiumTheme.textSecondary,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          indicatorColor: PremiumTheme.primary,
          tabs: const [
            Tab(text: 'All Files'),
            Tab(text: 'Academic'),
            Tab(text: 'Personal'),
            Tab(text: 'Identity'),
          ],
          onTap: (index) => setState(() {}), // Refresh filter
        ),
      ),
      body: _studentUID == null
          ? const Center(child: CircularProgressIndicator())
          : _buildDocumentList(),
      floatingActionButton: FutureButton(
        text: 'Upload File',
        icon: Icons.upload_rounded,
        isLoading: _isLoading,
        onPressed: _pickAndUpload,
      ).animate().scale(delay: 500.ms),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDocumentList() {
    String? category;
    if (_tabController.index == 1) category = 'academic';
    if (_tabController.index == 2) category = 'personal';
    if (_tabController.index == 3) category = 'identity';

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _documentService.documentsStream(
        _studentUID!,
        category: category,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No documents found',
                  style: GoogleFonts.inter(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _buildDocCard(doc, index);
          },
        );
      },
    );
  }

  Widget _buildDocCard(Map<String, dynamic> doc, int index) {
    final status = doc['status'] ?? 'pending';
    Color statusColor = Colors.orange;
    if (status == 'verified') statusColor = PremiumTheme.success;
    if (status == 'rejected') statusColor = PremiumTheme.error;

    return NeoGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PremiumTheme.primary.withValues(alpha: 0.1), // Fixed
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getFileIcon(doc['fileType']),
              color: PremiumTheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['fileName'] ?? 'Unknown',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_documentService.formatFileSize(doc['fileSize'] ?? 0)} • ${_documentService.getTimeAgo(doc['uploadedAt'])}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: PremiumTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          HoloBadge(text: status, color: statusColor),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.visibility_rounded, color: Colors.blue),
            onPressed: () => _viewDocument(doc['storageUrl']),
            tooltip: 'View Document',
          ),
          if (status == 'pending' ||
              status == 'rejected' ||
              true) // Enabled for all for cleanup
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.red),
              onPressed: () => _confirmDelete(doc['id']),
              tooltip: 'Delete Document',
            ),
        ],
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1);
  }

  Future<void> _viewDocument(String? url) async {
    if (url == null) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not launch document');
      }
    } catch (e) {
      _showError('Error opening document: $e');
    }
  }

  Future<void> _confirmDelete(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document?'),
        content: const Text(
          'This will permanently remove the document from your records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _documentService.deleteDocument(docId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Document deleted successfully'),
              backgroundColor: PremiumTheme.success,
            ),
          );
        }
      } catch (e) {
        _showError('Failed to delete: $e');
      }
    }
  }

  IconData _getFileIcon(String? type) {
    if (type == 'PDF') return Icons.picture_as_pdf;
    if (type == 'JPG' || type == 'PNG') return Icons.image;
    return Icons.insert_drive_file;
  }
}
