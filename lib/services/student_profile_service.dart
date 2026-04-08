import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloudinary_service.dart';
import 'cache_service.dart'; // Import CacheService
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../utils/constants.dart';

class StudentProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final CacheService _cacheService = CacheService(); // Initialize CacheService

  // Create student profile after registration
  Future<void> createProfile({
    required String studentUID,
    required String userId,
    required String name,
    required String studentId,
    required String email,
    required String branch,
    required String currentYear,
    required String passoutYear,
    String? phone,
  }) async {
    await _firestore
        .collection(Collections.studentProfiles)
        .doc(studentUID)
        .set({
          'userId': userId,
          'name': name,
          'studentId': studentId,
          'email': email,
          'branch': branch,
          'currentYear': currentYear,
          'passoutYear': passoutYear,
          'phone': phone ?? '',
          'profilePhoto': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  // Get student profile
  Future<Map<String, dynamic>?> getProfile(String studentUID) async {
    try {
      // Check cache first
      final cached = _cacheService.getCachedProfile(studentUID);
      if (cached != null) {
        debugPrint('Returning cached profile for $studentUID');
        // Background refresh
        _firestore
            .collection(Collections.studentProfiles)
            .doc(studentUID)
            .get()
            .then((doc) {
              if (doc.exists) {
                _cacheService.cacheProfile(studentUID, doc.data()!);
              }
            });
        return cached;
      }

      final doc = await _firestore
          .collection(Collections.studentProfiles)
          .doc(studentUID)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _cacheService.cacheProfile(studentUID, data);
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return null;
    }
  }

  // Update profile
  Future<void> updateProfile(
    String studentUID,
    Map<String, dynamic> data,
  ) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection(Collections.studentProfiles)
        .doc(studentUID)
        .update(data);
  }

  // Upload profile photo
  Future<String> uploadProfilePhoto(String studentUID, File imageFile) async {
    try {
      final result = await _cloudinaryService.uploadFile(
        file: imageFile,
        folder: 'student_profiles/$studentUID',
        startFileName:
            'profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final url = result['secure_url'] as String;
      final publicId = result['public_id'] as String;

      // Update profile with photo URL and Public ID
      await updateProfile(studentUID, {
        'profilePhoto': url,
        'photoPublicId': publicId,
      });

      return url;
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  // Stream profile for real-time updates
  Stream<Map<String, dynamic>?> profileStream(String studentUID) {
    return _firestore
        .collection(Collections.studentProfiles)
        .doc(studentUID)
        .snapshots()
        .map((snapshot) => snapshot.exists ? snapshot.data() : null);
  }

  // Get students by branch and year
  Future<List<Map<String, dynamic>>> getStudentsByFilter({
    String? branch,
    String? year,
  }) async {
    try {
      Query query = _firestore.collection(Collections.studentProfiles);

      if (branch != null && branch != 'All') {
        // Model uses 'course', though previously 'branch' might have been used.
        // Checking 'course' based on user data.
        query = query.where('course', isEqualTo: branch);
      }

      if (year != null && year != 'All') {
        // Convert string "1st Year" -> int 1 to match DB
        int? yearInt;
        final digitRegExp = RegExp(r'\d+');
        final match = digitRegExp.firstMatch(year);
        if (match != null) {
          yearInt = int.parse(match.group(0)!);
          query = query.where('year', isEqualTo: yearInt);
        } else {
          // Fallback if parsing fails, though UI sends "1st Year" etc.
          // If DB has mixed types, this might be tricky, but screenshot shows int 1.
          // Try to query string if parsing failed? Or skip?
          // Let's assume int based on evidence.
          debugPrint('Could not parse year string: $year');
        }
      }

      final snapshot = await query.orderBy('name').get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching students: $e');
      return [];
    }
  }

  // Get available branches
  Future<List<String>> getAvailableBranches() async {
    // Optimization: Return static constants instead of fetching all students.
    // In a production app, this could be fetched from a single 'metadata' document.
    return Courses.all;
  }
}
