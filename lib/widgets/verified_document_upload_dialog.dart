import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/document_verification_service.dart';
import '../../models/document_verification_result.dart';

class VerifiedDocumentUploadDialog extends StatefulWidget {
  final File file;
  final String title;
  final Future<String> Function(File) onUpload;

  const VerifiedDocumentUploadDialog({
    super.key,
    required this.file,
    required this.title,
    required this.onUpload,
  });

  @override
  State<VerifiedDocumentUploadDialog> createState() =>
      _VerifiedDocumentUploadDialogState();
}

class _VerifiedDocumentUploadDialogState
    extends State<VerifiedDocumentUploadDialog> {
  DocumentVerificationResult? _verificationResult;
  bool _isVerifying = true;
  bool _isUploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verifyDocument();
  }

  Future<void> _verifyDocument() async {
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final result = await DocumentVerificationService.verifyDocument(
        widget.file,
      );
      setState(() {
        _verificationResult = result;
        _isVerifying = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isVerifying = false;
      });
    }
  }

  Future<void> _proceedWithUpload() async {
    setState(() => _isUploading = true);

    try {
      await widget.onUpload(widget.file);
      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      setState(() {
        _error = 'Upload failed: $e';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(width: double.maxFinite, child: _buildContent()),
      actions: _buildActions(),
    );
  }

  Widget _buildContent() {
    if (_isVerifying) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Verifying document...'),
          SizedBox(height: 8),
          Text(
            'Checking for tampering and editing',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }

    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Verification Error',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center),
        ],
      );
    }

    if (_verificationResult != null) {
      return _buildVerificationResult(_verificationResult!);
    }

    return const SizedBox.shrink();
  }

  Widget _buildVerificationResult(DocumentVerificationResult result) {
    Color statusColor;
    IconData statusIcon;

    if (!result.isValid) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else if (result.confidence >= 90) {
      statusColor = Colors.green;
      statusIcon = Icons.verified;
    } else if (result.confidence >= 70) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.red.shade300;
      statusIcon = Icons.error_outline;
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status
          Center(
            child: Column(
              children: [
                Icon(statusIcon, size: 64, color: statusColor),
                const SizedBox(height: 12),
                Text(
                  result.statusText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confidence: ${result.confidence}%',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Reason for invalid
          if (!result.isValid) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.block, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.reason ?? 'Document verification failed',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Warnings
          if (result.hasWarnings) ...[
            const Text(
              'Warnings:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...result.warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Metadata
          if (result.metadata.isNotEmpty) ...[
            const Text(
              'Document Information:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: result.metadata.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            '${entry.key}:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    if (_isVerifying || _isUploading) {
      return [
        TextButton(
          onPressed: null,
          child: Text(_isUploading ? 'Uploading...' : 'Verifying...'),
        ),
      ];
    }

    if (_error != null || _verificationResult == null) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _verifyDocument, child: const Text('Retry')),
      ];
    }

    final result = _verificationResult!;

    // If invalid, only allow cancel
    if (!result.isValid) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Show help or contact support
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Upload Alternative'),
                content: const Text(
                  'If you believe this is a genuine document:\n\n'
                  '1. Take a new photo of the original certificate\n'
                  '2. Upload directly from camera (avoid editing)\n'
                  '3. Contact support if issues persist\n\n'
                  'For maximum security, only certificates issued by the '
                  'system can be verified automatically.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          child: const Text('Help'),
        ),
      ];
    }

    // If suspicious but valid, allow user to decide
    if (result.isSuspicious) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _proceedWithUpload,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Upload Anyway'),
        ),
      ];
    }

    // If valid, proceed
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: _proceedWithUpload,
        child: const Text('Upload'),
      ),
    ];
  }
}

/// Helper function to show verified upload dialog
Future<bool> showVerifiedDocumentUploadDialog({
  required BuildContext context,
  required File file,
  required String title,
  required Future<String> Function(File) onUpload,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => VerifiedDocumentUploadDialog(
      file: file,
      title: title,
      onUpload: onUpload,
    ),
  );
  return result ?? false;
}
