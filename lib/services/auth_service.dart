// Firebase Authentication Service

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/student_profile.dart';
import '../models/faculty_profile.dart'; // Import FacultyProfile
import '../utils/constants.dart';
import 'cache_service.dart'; // Import CacheService
import 'cloudinary_service.dart'; // NEW: Cloudinary Service

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = CacheService(); // Initialize CacheService
  final CloudinaryService _cloudinaryService = CloudinaryService(); // NEW: Cloudinary Service

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Fetch user data from Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          final user = UserModel.fromFirestore(userDoc);
          debugPrint('AuthService: Login successful for ${user.email} (${user.role})');
          
          // CRITICAL PERFORMANCE: Cache BEFORE returning so AuthWrapper is instant
          await _cacheService.cacheUser(user.uid, data);
          
          // Proactive Pre-warming: Fetch profile in background while UI transitions
          _prewarmProfile(user);
          
          return user;
        } else {
          debugPrint('AuthService: Firebase Auth succeeded, but Firestore /users doc is MISSING for ${credential.user!.uid}');
        }
      }

      return null;
    } on FirebaseAuthException catch (e) {
      throw _getAuthException(e);
    }
  }

  // Register new user
  Future<UserModel?> register({
    required String email,
    required String password,
    required String role,
    required String studentUID,
    String? name,
    String? branch,
    int? currentYear,
    String? passoutYear,
    String? shift,
    String? dob,
    String? bloodGroup,
    String? contactNumber,
    String? parentContactNumber,
    double? familyIncome,
    String? gender,
    File? profilePhoto,
  }) async {
    try {
      // Clear any existing cache to prevent profile leakage from previous sessions
      await _cacheService.clearAll();
      
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Handle Photo Upload using Cloudinary (Optimized)
        String photoUrl = '';
        String? photoPublicId;
        if (profilePhoto != null) {
          try {
            final result = await _cloudinaryService.uploadFile(
              file: profilePhoto,
              folder: role == 'student' ? 'student_profiles' : 'faculty_profiles',
              startFileName: '${credential.user!.uid}_profile',
            );
            if (result['success']) {
              photoUrl = result['secure_url'];
              photoPublicId = result['public_id'];
            }
          } catch (e) {
            debugPrint('Error uploading profile photo to Cloudinary: $e');
          }
        }

        // Create user document in Firestore
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          role: role,
          studentUID: studentUID,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toFirestore());

        // Cache user data
        await _cacheService.cacheUser(
          credential.user!.uid,
          userModel.toFirestore(),
        );

        // Also create a student profile if role is student
        if (role == 'student') {
          final profile = StudentProfile(
            id: studentUID, // Document ID is studentUID
            userId: credential.user!.uid,
            studentUID: studentUID,
            name: name ?? email.split('@')[0], 
            gender: gender ?? 'Male',
            course: branch ?? '',
            year: currentYear ?? 1,
            passoutYear: passoutYear ?? '',
            category: 'General',
            familyIncome: familyIncome ?? 0.0,
            contactNumber: contactNumber ?? '',
            parentContactNumber: parentContactNumber ?? '',
            profilePhoto: photoUrl,
            photoPublicId: photoPublicId,
            bloodGroup: bloodGroup ?? 'Not Specified',
            dateOfBirth: dob ?? '',
            shift: shift ?? 'FIRST',
            validFrom: DateFormat('dd.MM.yyyy').format(DateTime.now()),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await _firestore
              .collection(Collections.studentProfiles)
              .doc(studentUID)
              .set(profile.toFirestore());

          // Cache profile data
          await _cacheService.cacheProfile(studentUID, profile.toFirestore());
        } else if (role == 'faculty') {
          // Create Faculty Profile
          final profile = FacultyProfile(
            id: credential.user!.uid, // Document ID is Auth UID
            employeeId: studentUID, // Passed as studentUID from register form
            name: name ?? email.split('@')[0],
            email: email,
            department: 'Unassigned',
            designation: 'Faculty Member',
            phone: contactNumber ?? '',
            qualification: '',
            specialization: '',
            joiningDate: DateTime.now(),
            profilePhoto: photoUrl,
            isVerified: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await _firestore
              .collection('faculty_profiles')
              .doc(credential.user!.uid)
              .set(profile.toFirestore());
        }

        // Performance optimization: DO NOT clearAll() here. 
        // We want the newly registered user to have an instant first login.
        // Cache is already populated in the steps above.
        return userModel;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      throw _getAuthException(e);
    }
  }

  // Ensure a profile exists (Auto-repair for legacy/migrated users)
  Future<void> ensureProfileExists({bool forceRefresh = false}) async {
    final user = currentUser;
    if (user == null) return;

    final userData = await getUserData(user.uid, forceRefresh: forceRefresh);
    if (userData == null) return;

    // --- STUDENT CHECK ---
    if (userData.role == 'student') {
      // Check if profile exists by studentUID (primary)
      if (userData.studentUID.isNotEmpty) {
        // Check cache unless forceRefresh
        if (!forceRefresh) {
          final cached = _cacheService.getCachedProfile(userData.studentUID);
          if (cached != null) return; // Cache hit
        }

        final profileDoc = await _firestore
            .collection(Collections.studentProfiles)
            .doc(userData.studentUID)
            .get();
        if (profileDoc.exists) {
          _cacheService.cacheProfile(userData.studentUID, profileDoc.data()!);
          return; 
        }
      }

      // Check if profile exists by userId (fallback lookup)
      final profileQuery = await _firestore
          .collection(Collections.studentProfiles)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (profileQuery.docs.isNotEmpty) return; // All good

      // Create stub profile for Student
      final studentId = userData.studentUID.isNotEmpty
          ? userData.studentUID
          : 'TEMP_${user.uid.substring(0, 8)}';

      final profile = StudentProfile(
        id: studentId,
        userId: user.uid,
        studentUID: studentId,
        name: user.email?.split('@')[0] ?? 'Student',
        course: Courses.compEng,
        year: 1,
        category: 'General',
        familyIncome: 0.0,
        contactNumber: '',
        parentContactNumber: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(Collections.studentProfiles)
          .doc(studentId)
          .set(profile.toFirestore());

      // Update user document if studentUID was empty
      if (userData.studentUID.isEmpty) {
        await _firestore.collection('users').doc(user.uid).update({
          'studentUID': studentId,
        });
      }
    }
    // --- FACULTY CHECK ---
    // --- FACULTY & COMMITTEE CHECK ---
    else if (userData.role == 'faculty' || userData.role == 'committee') {
      final profileDoc = await _firestore
          .collection('faculty_profiles')
          .doc(user.uid)
          .get();

      if (profileDoc.exists) return; // All good

      // Create stub profile for Faculty/Committee
      final profile = FacultyProfile(
        id: user.uid,
        employeeId: userData.studentUID.isNotEmpty
            ? userData.studentUID
            : 'EMP_${user.uid.substring(0, 6)}',
        name:
            user.email?.split('@')[0] ??
            (userData.role == 'committee'
                ? 'Committee Member'
                : 'Faculty Member'),
        email: user.email ?? '',
        department: userData.role == 'committee' ? 'Committee' : 'Unassigned',
        designation: userData.role == 'committee'
            ? 'Committee Member'
            : 'Faculty Member',
        phone: '',
        qualification: '',
        specialization: '',
        joiningDate: DateTime.now(),
        profilePhoto: '',
        isVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('faculty_profiles')
          .doc(user.uid)
          .set(profile.toFirestore());
    }
  }

  // Reactive user data stream
  Stream<UserModel?> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        // Handle registration grace period noise internally
        final isNewUser = currentUser?.metadata.creationTime != null &&
            DateTime.now().difference(currentUser!.metadata.creationTime!).inSeconds < 120;
            
        if (!isNewUser) {
          debugPrint('AuthService: Profile missing for existing user $uid');
        }
        return null;
      }

      final data = snapshot.data()!;
      final userModel = UserModel.fromFirestore(snapshot);
      
      // Update cache in the background (Non-blocking)
      _cacheService.cacheUser(uid, data).then((_) {
        // Pre-warm profile data in background
        _prewarmProfile(userModel);
      });

      return userModel;
    });
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid, {bool forceRefresh = false}) async {
    try {
      // Check cache first
      if (!forceRefresh) {
        final cachedData = _cacheService.getCachedUser(uid);
        if (cachedData != null) {
        debugPrint('Returning cached user data for $uid');
        // Only refresh if cache is older than 10 minutes
        if (_cacheService.shouldRefresh(CacheService.userBoxName, uid)) {
          debugPrint('Stale cache for $uid, scheduling refresh');
          _firestore.collection('users').doc(uid).get().then((doc) {
            if (doc.exists) {
              final data = doc.data()!;
              _cacheService.cacheUser(uid, data);
              _prewarmProfile(UserModel.fromMap(data, uid));
            }
          });
        }
        return UserModel.fromMap(cachedData, uid);
      }
    }

      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final user = UserModel.fromFirestore(userDoc);
        await _cacheService.cacheUser(uid, data);

        // Pre-warm profile data in background
        _prewarmProfile(user);

        return user;
      }

      // If document is missing, only log if user is NOT new (avoiding registration race noise)
      final isNewUser = currentUser?.metadata.creationTime != null &&
          DateTime.now().difference(currentUser!.metadata.creationTime!).inSeconds < 120;
          
      if (!isNewUser) {
        debugPrint('AuthService: Profile missing for existing user $uid');
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Get cached role for instant routing
  String? getCachedRole() {
    final user = currentUser;
    if (user == null) return null;
    final cachedData = _cacheService.getCachedUser(user.uid);
    return cachedData?['role'] as String?;
  }

  // Get student UID from cache
  String? getCachedStudentUID() {
    final user = currentUser;
    if (user == null) return null;
    final cachedData = _cacheService.getCachedUser(user.uid);
    return cachedData?['studentUID'] as String?;
  }

  // Get cached profile data
  Map<String, dynamic>? getCachedProfile() {
    final studentUID = getCachedStudentUID();
    if (studentUID == null) return null;
    return _cacheService.getCachedProfile(studentUID);
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _cacheService.clearAll(); // Clear cache on logout
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _getAuthException(e);
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      await currentUser?.verifyBeforeUpdateEmail(newEmail);

      // Update in Firestore
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'email': newEmail,
        });
      }
    } on FirebaseAuthException catch (e) {
      throw _getAuthException(e);
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _getAuthException(e);
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      if (currentUser != null) {
        // Delete Firestore user document
        await _firestore.collection('users').doc(currentUser!.uid).delete();

        // Delete Firebase Auth user
        await currentUser!.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw _getAuthException(e);
    }
  }

  // Dashboard Caching Proxies
  void cacheDashboardStats(String userId, Map<String, dynamic> stats) {
    _cacheService.cacheDashboardStats(userId, stats);
  }

  Map<String, dynamic>? getCachedDashboardStats(String userId) {
    return _cacheService.getCachedDashboardStats(userId);
  }

  // Pre-warm Profile Data
  void _prewarmProfile(UserModel user) {
    if (user.role == 'student' && user.studentUID.isNotEmpty) {
      if (!_cacheService.shouldRefresh(CacheService.profileBoxName, user.studentUID)) {
        return; // Already recently cached
      }
      _firestore
          .collection(Collections.studentProfiles)
          .doc(user.studentUID)
          .get()
          .then((doc) {
            if (doc.exists) {
              _cacheService.cacheProfile(user.studentUID, doc.data()!);
              debugPrint('Pre-warmed student profile for ${user.studentUID}');
            }
          });
    } else if (user.role == 'faculty' || user.role == 'committee') {
      // Optional: Add faculty profile caching if needed
    }
  }

  // Helper method to convert Firebase Auth exceptions to readable messages
  String _getAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
