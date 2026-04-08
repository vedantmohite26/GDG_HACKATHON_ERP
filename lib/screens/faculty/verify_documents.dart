import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/document_service.dart';
import '../../theme/premium_theme.dart';

import '../../widgets/premium_widgets.dart'; // Import TechInput

class VerifyDocuments extends StatefulWidget {
  final bool showAppBar;
  const VerifyDocuments({super.key, this.showAppBar = true});

  @override
  State<VerifyDocuments> createState() => _VerifyDocumentsState();
}

class _VerifyDocumentsState extends State<VerifyDocuments> {
  final DocumentService _documentService = DocumentService();
  final TextEditingController _searchController =
      TextEditingController(); // Define Controller
  String _selectedCategory = 'All'; // All, Academic, Personal, Identity

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // Rebuild on search input
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.background,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                'Verify Documents',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: PremiumTheme.textPrimary,
                ),
              ),
              backgroundColor: PremiumTheme.background,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: PremiumTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showAppBar) const SizedBox(height: 10),
            if (!widget.showAppBar) ...[
              // We hide the redundant title here
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verify student documents. Approved documents are visible on student profiles.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: PremiumTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search Bar
            TechInput(
              label: 'Search Student UID or Document Name',
              icon: Icons.search,
              controller: _searchController,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () => _searchController.clear(),
              ),
            ),
            const SizedBox(height: 16),

            // Filter tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab('All'),
                  _buildTab('Academic'),
                  _buildTab('Personal'),
                  _buildTab('Identity'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Documents Stream
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _documentService.streamAllDocuments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data ?? [];

                final String query = _searchController.text
                    .toLowerCase()
                    .trim();

                // Filter
                final filteredDocs = docs.where((doc) {
                  final matchesCategory =
                      _selectedCategory == 'All' ||
                      doc['category'].toString().toLowerCase() ==
                          _selectedCategory.toLowerCase();

                  if (!matchesCategory) return false;

                  if (query.isEmpty) return true;

                  final fileName =
                      doc['fileName']?.toString().toLowerCase() ?? '';
                  final studentUID =
                      doc['studentUID']?.toString().toLowerCase() ?? '';

                  return fileName.contains(query) || studentUID.contains(query);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No documents found',
                        style: GoogleFonts.inter(color: PremiumTheme.textSecondary),
                      ),
                    ),
                  );
                }

                return Column(
                  children: filteredDocs
                      .map((doc) => _buildDocumentCard(doc))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label) {
    bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? PremiumTheme.primary
              : PremiumTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? PremiumTheme.primary
                : PremiumTheme.textSecondary.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : PremiumTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final status = doc['status'] ?? 'pending';
    final isPending = status == 'pending';
    final docId = doc['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PremiumTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PremiumTheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description, color: Colors.blueAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc['fileName'] ?? 'Document',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: PremiumTheme.textPrimary,
                      ),
                    ),
                    // Student ID Display
                    Text(
                      'ID: ${doc['studentUID']}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: PremiumTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${doc['fileType']} • ${_documentService.formatFileSize(doc['fileSize'] ?? 0)}',
                style: GoogleFonts.inter(fontSize: 12, color: PremiumTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (doc['storageUrl'] != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewDocument(doc['storageUrl']),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blueAccent),
                      foregroundColor: Colors.blueAccent,
                    ),
                  ),
                ),
              if (isPending) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmAction(docId, 'verified'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Verify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumTheme.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(docId),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red[400]!),
                      foregroundColor: Colors.red[600],
                    ),
                  ),
                ),
              ] else ...[
                // Allow changing status if needed (Revert)
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Change Status',
                  icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                  onPressed: () => _showChangeStatusDialog(docId, status),
                ),
              ],
            ],
          ),
          if (doc['rejectionReason'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Text(
                'Reason: ${doc['rejectionReason']}',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.red[300]),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  void _viewDocument(String? url) async {
    if (url == null) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch document')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening document: $e')));
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'verified':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // --- Dialogs ---

  void _confirmAction(String docId, String status) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Verification'),
        content: const Text(
          'Are you sure you want to mark this document as verified?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _documentService.updateDocumentStatus(docId, status);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String docId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g. Blurred image, Wrong document...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await _documentService.updateDocumentStatus(
                docId,
                'rejected',
                rejectionReason: controller.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showChangeStatusDialog(String docId, String currentStatus) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Change Status'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmAction(docId, 'verified');
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Mark as Verified'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _showRejectDialog(docId);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Mark as Rejected'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () async {
              await _documentService.updateDocumentStatus(docId, 'pending');
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Revert to Pending'),
            ),
          ),
        ],
      ),
    );
  }
}
