import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/certificate.dart';

class CertificateService {
  final ApiService _apiService = ApiService();

  /// Generate certificate for a student
  Future<Certificate> generateCertificate({
    required String studentUid,
    required String studentName,
    required String studentId,
    required String course,
    required String semester,
    required double cgpa,
    required double sgpa,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiService.generateCertificate(
        studentUid: studentUid,
        studentName: studentName,
        studentId: studentId,
        course: course,
        semester: semester,
        cgpa: cgpa,
        sgpa: sgpa,
        metadata: metadata,
      );

      if (response['success'] == true) {
        return Certificate.fromJson(response['certificate']);
      } else {
        throw Exception('Certificate generation failed');
      }
    } catch (e) {
      debugPrint('Certificate Service Error: $e');
      rethrow;
    }
  }

  /// Verify certificate by ID
  Future<CertificateVerificationResult> verifyCertificate(
    String certificateId,
  ) async {
    try {
      final response = await _apiService.verifyCertificate(certificateId);
      return CertificateVerificationResult.fromJson(response);
    } catch (e) {
      debugPrint('Verification Service Error: $e');
      rethrow;
    }
  }

  /// Get all certificates for a student
  Future<List<Certificate>> getStudentCertificates(String studentUid) async {
    try {
      final certificatesJson = await _apiService.getStudentCertificates(
        studentUid,
      );
      return certificatesJson
          .map((json) => Certificate.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Get Certificates Service Error: $e');
      rethrow;
    }
  }

  /// Revoke a certificate
  Future<bool> revokeCertificate(String certificateId, String reason) async {
    try {
      final response = await _apiService.revokeCertificate(
        certificateId,
        reason,
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Revoke Certificate Service Error: $e');
      rethrow;
    }
  }
}
