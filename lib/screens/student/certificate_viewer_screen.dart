import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/certificate.dart';
import '../../services/certificate_service.dart';

class CertificateViewerScreen extends StatefulWidget {
  final String? certificateId;
  final String? studentUid;

  const CertificateViewerScreen({
    super.key,
    this.certificateId,
    this.studentUid,
  });

  @override
  State<CertificateViewerScreen> createState() =>
      _CertificateViewerScreenState();
}

class _CertificateViewerScreenState extends State<CertificateViewerScreen> {
  final CertificateService _certService = CertificateService();

  List<Certificate>? _certificates;
  CertificateVerificationResult? _verificationResult;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.certificateId != null) {
        // Verify single certificate
        final result = await _certService.verifyCertificate(
          widget.certificateId!,
        );
        setState(() {
          _verificationResult = result;
          _isLoading = false;
        });
      } else if (widget.studentUid != null) {
        // Load all certificates for student
        final certs = await _certService.getStudentCertificates(
          widget.studentUid!,
        );
        setState(() {
          _certificates = certs;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.certificateId != null
              ? 'Certificate Verification'
              : 'My Certificates',
        ),
        actions: [
          if (_certificates != null || _verificationResult != null)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    // Show verification result
    if (_verificationResult != null) {
      return _buildVerificationView(_verificationResult!);
    }

    // Show list of certificates
    if (_certificates != null) {
      if (_certificates!.isEmpty) {
        return const Center(child: Text('No certificates found'));
      }
      return _buildCertificateList(_certificates!);
    }

    return const Center(child: Text('No data'));
  }

  Widget _buildVerificationView(CertificateVerificationResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Card
          Card(
            color: result.valid ? Colors.green.shade50 : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    result.valid ? Icons.verified : Icons.cancel,
                    size: 80,
                    color: result.valid ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    result.valid ? 'VALID CERTIFICATE' : 'INVALID CERTIFICATE',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: result.valid ? Colors.green : Colors.red,
                    ),
                  ),
                  if (result.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      result.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (result.valid && result.certificate != null) ...[
            const SizedBox(height: 24),
            _buildCertificateCard(result.certificate!),

            // Verification Details
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verification Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'Hash Validation',
                      result.isHashValid ? 'Passed ✓' : 'Failed ✗',
                      result.isHashValid ? Colors.green : Colors.red,
                    ),
                    _buildInfoRow(
                      'Signature Validation',
                      result.isSignatureValid ? 'Passed ✓' : 'Failed ✗',
                      result.isSignatureValid ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCertificateList(List<Certificate> certificates) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: certificates.length,
      itemBuilder: (context, index) {
        final cert = certificates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CertificateViewerScreen(
                    certificateId: cert.certificateId,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cert.semester,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Course: ${cert.course}'),
                  Text('CGPA: ${cert.cgpa.toStringAsFixed(2)}'),
                  Text('SGPA: ${cert.sgpa.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  Text(
                    'Issued: ${cert.formattedDate}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCertificateCard(Certificate cert) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: QrImageView(
                data: cert.certificateId,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Certificate Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Student Name', cert.studentName),
            _buildInfoRow('Student ID', cert.studentId),
            _buildInfoRow('Course', cert.course),
            _buildInfoRow('Semester', cert.semester),
            _buildInfoRow('CGPA', cert.cgpa.toStringAsFixed(2)),
            _buildInfoRow('SGPA', cert.sgpa.toStringAsFixed(2)),
            _buildInfoRow('Issued Date', cert.formattedDate),
            _buildInfoRow('Certificate ID', cert.certificateId, Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Hash: ${cert.certificateHash.substring(0, 32)}...',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
