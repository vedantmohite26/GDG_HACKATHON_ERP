import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'cloudinary_service.dart';
import 'document_verification_service.dart';
import '../models/document_verification_result.dart';
import '../utils/constants.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Upload document
  Future<String> uploadDocument({
    required String studentUID,
    required List<int> fileBytes,
    required String fileName,
    required String category,
  }) async {
    try {
      // 1. Write bytes to temporary file (required for Google Drive API)
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(fileBytes);

      return await _performUpload(
        studentUID: studentUID,
        file: tempFile,
        fileName: fileName,
        category: category,
        deleteFileAfter: true,
      );
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  // Upload document from File (Mobile/Desktop) - Optimized
  Future<String> uploadDocumentFromFile({
    required String studentUID,
    required File file,
    required String fileName,
    required String category,
  }) async {
    return await _performUpload(
      studentUID: studentUID,
      file: file,
      fileName: fileName,
      category: category,
      deleteFileAfter: false, // Don't delete original file picked from storage
    );
  }

  /// Upload document with verification
  Future<Map<String, dynamic>> uploadDocumentWithVerification({
    required String studentUID,
    required File file,
    required String fileName,
    required String category,
  }) async {
    // 1. Verify document first
    final verificationResult = await DocumentVerificationService.verifyDocument(
      file,
    );

    if (!verificationResult.isValid) {
      throw Exception(
        'Document verification failed: ${verificationResult.reason}',
      );
    }

    // 2. Perform upload with verification metadata
    final downloadUrl = await _performUpload(
      studentUID: studentUID,
      file: file,
      fileName: fileName,
      category: category,
      deleteFileAfter: false,
      verificationResult: verificationResult,
    );

    return {'url': downloadUrl, 'verification': verificationResult};
  }

  // Helper method to perform the actual upload
  Future<String> _performUpload({
    required String studentUID,
    required File file,
    required String fileName,
    required String category,
    required bool deleteFileAfter,
    DocumentVerificationResult? verificationResult,
  }) async {
    try {
      // 2. Upload to Cloudinary
      final result = await _cloudinaryService.uploadFile(
        file: file,
        folder: 'student_documents/$studentUID',
        startFileName: fileName,
      );

      // 3. Clean up temp file ONLY if we created it
      if (deleteFileAfter && await file.exists()) {
        await file.delete();
      }

      final downloadUrl = result['secure_url'] as String;
      final publicId = result['public_id'] as String;
      final fileSize = result['bytes'] as int;
      final extension = fileName.split('.').last;

      // 4. Save metadata to Firestore with verification info
      final Map<String, dynamic> firestoreData = {
        'userId': FirebaseAuth
            .instance
            .currentUser
            ?.uid, // Add Auth UID for security rules
        'studentUID': studentUID,
        'fileName': fileName,
        'fileType': extension.toUpperCase(),
        'fileSize': fileSize,
        'category': category,
        'status': 'verified',
        'storageUrl': downloadUrl,
        'storagePath': publicId, // Storing Cloudinary Public ID
        'uploadedAt': FieldValue.serverTimestamp(),
        'source': 'cloudinary',
      };

      // Add verification metadata if available
      if (verificationResult != null) {
        firestoreData['verification'] = {
          'isValid': verificationResult.isValid,
          'confidence': verificationResult.confidence,
          'warnings': verificationResult.warnings,
          'metadata': verificationResult.metadata,
          'verifiedAt': FieldValue.serverTimestamp(),
        };
      }

      await _firestore.collection(Collections.documentsMeta).add(firestoreData);

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  // Get documents by student
  Future<List<Map<String, dynamic>>> getDocuments(
    String studentUID, {
    String? category,
  }) async {
    try {
      Query query = _firestore
          .collection(Collections.documentsMeta)
          .where('studentUID', isEqualTo: studentUID);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();

      final docs = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort in memory by uploadedAt descending
      docs.sort((a, b) {
        final aTime = a['uploadedAt'] as Timestamp?;
        final bTime = b['uploadedAt'] as Timestamp?;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return docs;
    } catch (e) {
      debugPrint('Error getting documents: $e');
      return [];
    }
  }

  // Stream documents for real-time updates
  Stream<List<Map<String, dynamic>>> documentsStream(
    String studentUID, {
    String? category,
  }) {
    Query query = _firestore
        .collection(Collections.documentsMeta)
        .where('studentUID', isEqualTo: studentUID);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      final docs = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort in memory by uploadedAt descending
      docs.sort((a, b) {
        final aTime = a['uploadedAt'] as Timestamp?;
        final bTime = b['uploadedAt'] as Timestamp?;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return docs;
    });
  }

  // Stream ALL documents (for Faculty/Admin verification)
  Stream<List<Map<String, dynamic>>> streamAllDocuments({
    String? status,
    String? category,
  }) {
    Query query = _firestore.collection(Collections.documentsMeta);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      final docs = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort in memory by uploadedAt descending
      docs.sort((a, b) {
        final aTime = a['uploadedAt'] as Timestamp?;
        final bTime = b['uploadedAt'] as Timestamp?;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return docs;
    });
  }

  // Update document status (Admin/Committee only)
  Future<void> updateDocumentStatus(
    String docId,
    String status, {
    String? rejectionReason,
    String? verifiedBy,
  }) async {
    try {
      // 1. Fetch document to get user ID for notification
      final docSnapshot = await _firestore
          .collection(Collections.documentsMeta)
          .doc(docId)
          .get();

      if (!docSnapshot.exists) throw Exception('Document not found');
      final docData = docSnapshot.data() as Map<String, dynamic>;
      final userId = docData['userId'] as String?;
      final fileName = docData['fileName'] as String? ?? 'Document';

      // 2. Prepare update data
      final Map<String, dynamic> data = {'status': status};

      if (status == 'pending') {
        // If reverting to pending, clear verification fields
        data['verifiedAt'] = FieldValue.delete();
        data['verifiedBy'] = FieldValue.delete();
        data['rejectionReason'] = FieldValue.delete();
      } else {
        // If verifying or rejecting, set timestamp
        data['verifiedAt'] = FieldValue.serverTimestamp();

        if (rejectionReason != null) {
          data['rejectionReason'] = rejectionReason;
        } else {
          data['rejectionReason'] = FieldValue.delete();
        }

        if (verifiedBy != null) data['verifiedBy'] = verifiedBy;
      }

      // 3. Update document
      await _firestore
          .collection(Collections.documentsMeta)
          .doc(docId)
          .update(data);

      // 4. Send Notification if Rejected or Reverted (Pending)
      if (userId != null && (status == 'rejected' || status == 'pending')) {
        String title = '';
        String message = '';

        if (status == 'rejected') {
          title = 'Document Rejected';
          message =
              'Your document "$fileName" was rejected. Reason: ${rejectionReason ?? 'No reason provided.'}';
        } else if (status == 'pending') {
          title = 'Document Status Reverted';
          message =
              'The status of your document "$fileName" has been reverted to Pending.';
        }

        await _firestore.collection('notifications').add({
          'userId': userId,
          'title': title,
          'message': message,
          'type': 'document',
          'relatedId': docId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to update document status: $e');
    }
  }

  // Delete document
  Future<void> deleteDocument(String docId) async {
    try {
      // Get document metadata
      final doc = await _firestore
          .collection(Collections.documentsMeta)
          .doc(docId)
          .get();
      final data = doc.data();

      if (data != null && data['storagePath'] != null) {
        // Only delete from Cloudinary if source is cloudinary
        if (data['source'] == 'cloudinary') {
          await _cloudinaryService.deleteFile(data['storagePath']);
        }
      }

      // Delete metadata from Firestore
      await _firestore
          .collection(Collections.documentsMeta)
          .doc(docId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  // Get document count by category
  Future<int> getDocumentCount(String studentUID, {String? category}) async {
    try {
      Query query = _firestore
          .collection(Collections.documentsMeta)
          .where('studentUID', isEqualTo: studentUID);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Format file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Get time ago string
  String getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';

    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }
}
