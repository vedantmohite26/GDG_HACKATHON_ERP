import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiService {
  // Update this to your backend URL
  static const String baseUrl = 'http://localhost:3000/api';

  String? _jwtToken;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Set JWT token after login
  void setToken(String token) {
    _jwtToken = token;
  }

  /// Clear JWT token on logout
  void clearToken() {
    _jwtToken = null;
  }

  /// Get authorization headers
  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_jwtToken != null) {
      headers['Authorization'] = 'Bearer $_jwtToken';
    }
    return headers;
  }

  /// Login and get JWT token
  Future<Map<String, dynamic>> login({
    required String firebaseUid,
    required String email,
    required String role,
    String? studentUid,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebase_uid': firebaseUid,
          'email': email,
          'role': role,
          'student_uid': studentUid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setToken(data['token']);
        }
        return data;
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API Login Error: $e');
      rethrow;
    }
  }

  /// Generate certificate
  Future<Map<String, dynamic>> generateCertificate({
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
      final response = await http.post(
        Uri.parse('$baseUrl/certificates/generate'),
        headers: _headers,
        body: jsonEncode({
          'student_uid': studentUid,
          'student_name': studentName,
          'student_id': studentId,
          'course': course,
          'semester': semester,
          'cgpa': cgpa,
          'sgpa': sgpa,
          'metadata': metadata ?? {},
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Certificate generation failed');
      }
    } catch (e) {
      debugPrint('Generate Certificate Error: $e');
      rethrow;
    }
  }

  /// Verify certificate
  Future<Map<String, dynamic>> verifyCertificate(String certificateId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/certificates/verify/$certificateId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return {'valid': false, 'error': 'Certificate not found'};
      } else {
        throw Exception('Verification failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Verify Certificate Error: $e');
      rethrow;
    }
  }

  /// Get all certificates for a student
  Future<List<dynamic>> getStudentCertificates(String studentUid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/certificates/student/$studentUid'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['certificates'] ?? [];
      } else {
        throw Exception('Failed to fetch certificates');
      }
    } catch (e) {
      debugPrint('Get Certificates Error: $e');
      rethrow;
    }
  }

  /// Revoke certificate
  Future<Map<String, dynamic>> revokeCertificate(
    String certificateId,
    String reason,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/certificates/revoke/$certificateId'),
        headers: _headers,
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Revocation failed');
      }
    } catch (e) {
      debugPrint('Revoke Certificate Error: $e');
      rethrow;
    }
  }

  /// Publish results
  Future<Map<String, dynamic>> publishResults({
    required String course,
    required String semester,
    required String subjectName,
    required int subjectCredits,
    required List<Map<String, dynamic>> studentResults,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/results/publish'),
        headers: _headers,
        body: jsonEncode({
          'course': course,
          'semester': semester,
          'subject_name': subjectName,
          'subject_credits': subjectCredits,
          'student_results': studentResults,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to publish results');
      }
    } catch (e) {
      debugPrint('Publish Results Error: $e');
      rethrow;
    }
  }
}
