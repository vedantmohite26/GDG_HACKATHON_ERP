import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/document_service.dart';

class FacultyDocumentsViewer extends StatefulWidget {
  final bool showAppBar;
  const FacultyDocumentsViewer({super.key, this.showAppBar = true});

  @override
  State<FacultyDocumentsViewer> createState() => _FacultyDocumentsViewerState();
}

class _FacultyDocumentsViewerState extends State<FacultyDocumentsViewer> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documentService = context.read<DocumentService>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                'Student Documents',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
            )
          : null,
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by student ID, name, or file name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardTheme.color,
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
                const SizedBox(height: 12),
                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _selectedCategory == null,
                        onTap: () => setState(() => _selectedCategory = null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Academic',
                        selected: _selectedCategory == 'academic',
                        onTap: () =>
                            setState(() => _selectedCategory = 'academic'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Personal',
                        selected: _selectedCategory == 'personal',
                        onTap: () =>
                            setState(() => _selectedCategory = 'personal'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Identity',
                        selected: _selectedCategory == 'identity',
                        onTap: () =>
                            setState(() => _selectedCategory = 'identity'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Documents List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: documentService.streamAllDocuments(
                category: _selectedCategory,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var documents = snapshot.data ?? [];

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  documents = documents.where((doc) {
                    final fileName = (doc['fileName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final studentUID = (doc['studentUID'] ?? '')
                        .toString()
                        .toLowerCase();
                    return fileName.contains(_searchQuery) ||
                        studentUID.contains(_searchQuery);
                  }).toList();
                }

                if (documents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No documents found',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    return _DocumentCard(
                      document: doc,
                      documentService: documentService,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : Colors.grey[400],
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Map<String, dynamic> document;
  final DocumentService documentService;

  const _DocumentCard({required this.document, required this.documentService});

  IconData _getFileIcon(String fileType) {
    switch (fileType.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'JPG':
      case 'JPEG':
      case 'PNG':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileType) {
    switch (fileType.toUpperCase()) {
      case 'PDF':
        return Colors.orangeAccent;
      case 'JPG':
      case 'JPEG':
      case 'PNG':
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }

  Future<void> _downloadDocument(BuildContext context) async {
    final url = document['storageUrl'] as String?;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download URL not available')),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Cannot open document')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = document['fileName'] ?? 'Unknown';
    final fileType = document['fileType'] ?? 'FILE';
    final fileSize = document['fileSize'] as int? ?? 0;
    final studentUID = document['studentUID'] ?? 'Unknown';
    final category = document['category'] ?? 'uncategorized';
    final uploadedAt = document['uploadedAt'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // File Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getFileColor(fileType).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getFileIcon(fileType),
                color: _getFileColor(fileType).withValues(alpha: 0.8),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),

            // File Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Student: $studentUID',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        documentService.formatFileSize(fileSize),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      const Text('•', style: TextStyle(color: Colors.grey)),
                      Text(
                        documentService.getTimeAgo(uploadedAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Download Button
            IconButton(
              icon: const Icon(Icons.download_rounded),
              color: Theme.of(context).colorScheme.secondary,
              onPressed: () => _downloadDocument(context),
              tooltip: 'Download',
            ),
          ],
        ),
      ),
    );
  }
}
