import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:exif/exif.dart';
import 'package:crypto/crypto.dart';
import 'package:mime/mime.dart';
import '../models/document_verification_result.dart';

class DocumentVerificationService {
  // List of editing software that indicates tampering
  static const List<String> _editingSoftware = [
    'Adobe Photoshop',
    'Photoshop',
    'GIMP',
    'Canva',
    'Pixlr',
    'Paint.NET',
    'Affinity Photo',
    'Sketch',
    'Figma',
  ];

  // List of acceptable software (cameras, scanners, etc.)
  static const List<String> _acceptableSoftware = [
    'Camera',
    'Scanner',
    'CamScanner',
    'Adobe Scan',
    'Microsoft Lens',
    'Google Drive',
  ];

  /// Verify document before upload
  static Future<DocumentVerificationResult> verifyDocument(File file) async {
    try {
      final mimeType = lookupMimeType(file.path);

      if (mimeType == null) {
        return DocumentVerificationResult.invalid(
          reason: 'Unable to determine file type',
        );
      }

      // Check file type - Allow images and PDFs
      if (mimeType.startsWith('image/')) {
        // Images MUST have EXIF data (already enforced in _verifyImage)
        return await _verifyImage(file);
      } else if (mimeType == 'application/pdf') {
        return await _verifyPDF(file);
      } else {
        return DocumentVerificationResult.invalid(
          reason: 'Unsupported file type. Only images and PDFs are allowed.',
        );
      }
    } catch (e) {
      debugPrint('Verification error: $e');
      return DocumentVerificationResult.invalid(
        reason: 'Verification failed: ${e.toString()}',
      );
    }
  }

  /// Verify image file
  static Future<DocumentVerificationResult> _verifyImage(File file) async {
    try {
      final bytes = await file.readAsBytes();

      // Calculate file hash
      final hash = sha256.convert(bytes).toString();

      // Extract EXIF data
      final exifData = await readExifFromBytes(bytes);

      if (exifData.isEmpty) {
        // STRICT: No metadata - reject
        return DocumentVerificationResult.invalid(
          reason:
              'No metadata found in the image. This could indicate the file '
              'has been edited, metadata was stripped, or it is a screenshot. '
              'Please upload a photo taken directly from your camera or a '
              'scanned document from an official scanner app.',
          metadata: {'hash': hash, 'exif': 'none'},
        );
      }

      final metadata = <String, dynamic>{'hash': hash};
      final warnings = <String>[];
      int confidence = 100;

      // Check software
      final software = exifData['Image Software']?.toString();
      if (software != null) {
        metadata['software'] = software;

        // Check for editing software
        if (_editingSoftware.any((s) => software.contains(s))) {
          return DocumentVerificationResult.invalid(
            reason:
                'Document appears to have been edited using $software. '
                'Please upload the original certificate.',
            metadata: metadata,
          );
        }

        // STRICT: Check for acceptable software
        if (!_acceptableSoftware.any((s) => software.contains(s))) {
          return DocumentVerificationResult.invalid(
            reason:
                'Document created using unknown software: $software. '
                'Only documents from official cameras and scanner apps are accepted.',
            metadata: metadata,
          );
        }
      }

      // Check modification date - STRICT MODE
      final dateTime = exifData['Image DateTime']?.toString();
      final dateTimeOriginal = exifData['EXIF DateTimeOriginal']?.toString();

      if (dateTime != null && dateTimeOriginal != null) {
        metadata['modified'] = dateTime;
        metadata['original'] = dateTimeOriginal;

        // STRICT: Reject if file was modified after creation
        if (dateTime != dateTimeOriginal) {
          return DocumentVerificationResult.invalid(
            reason:
                'File has been modified after creation. '
                'Original: $dateTimeOriginal, Modified: $dateTime. '
                'Please upload the unmodified original document.',
            metadata: metadata,
          );
        }
      }

      // Check image dimensions
      final width = exifData['EXIF ExifImageWidth']?.toString();
      final height = exifData['EXIF ExifImageLength']?.toString();
      if (width != null && height != null) {
        metadata['dimensions'] = '${width}x$height';
      }

      // Check camera make/model
      final make = exifData['Image Make']?.toString();
      final model = exifData['Image Model']?.toString();
      if (make != null) metadata['camera_make'] = make;
      if (model != null) metadata['camera_model'] = model;

      // Check orientation
      final orientation = exifData['Image Orientation']?.toString();
      if (orientation != null) {
        metadata['orientation'] = orientation;
      }

      if (warnings.isEmpty) {
        return DocumentVerificationResult.valid(
          confidence: confidence,
          metadata: metadata,
        );
      } else {
        return DocumentVerificationResult.suspicious(
          warnings: warnings,
          confidence: confidence,
          metadata: metadata,
        );
      }
    } catch (e) {
      debugPrint('Image verification error: $e');
      return DocumentVerificationResult.invalid(
        reason: 'Unable to verify image: ${e.toString()}',
      );
    }
  }

  /// Verify PDF file
  static Future<DocumentVerificationResult> _verifyPDF(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString();

      // Convert bytes to string to search for metadata
      final pdfContent = String.fromCharCodes(bytes);

      final metadata = <String, dynamic>{'hash': hash, 'type': 'PDF'};
      final warnings = <String>[];
      int confidence = 90;

      // Check for PDF metadata markers
      // Look for Creator field
      final creatorMatch = RegExp(
        r'/Creator\s*\((.*?)\)',
      ).firstMatch(pdfContent);
      if (creatorMatch != null) {
        final creator = creatorMatch.group(1) ?? '';
        metadata['creator'] = creator;

        // Check for editing software
        if (_editingSoftware.any((s) => creator.contains(s))) {
          return DocumentVerificationResult.invalid(
            reason:
                'PDF was created/edited using $creator. '
                'Please upload the original scanned certificate.',
            metadata: metadata,
          );
        }
      }

      // Check for Producer
      final producerMatch = RegExp(
        r'/Producer\s*\((.*?)\)',
      ).firstMatch(pdfContent);
      if (producerMatch != null) {
        final producer = producerMatch.group(1) ?? '';
        metadata['producer'] = producer;

        // STRICT: Reject if producer is editing software
        if (_editingSoftware.any((s) => producer.contains(s))) {
          return DocumentVerificationResult.invalid(
            reason:
                'PDF processed by editing software: $producer. '
                'Please upload the original scanned certificate.',
            metadata: metadata,
          );
        }
      }

      // STRICT: Check modification count
      final modCountMatch = RegExp(r'/ModDate').allMatches(pdfContent).length;
      if (modCountMatch > 1) {
        return DocumentVerificationResult.invalid(
          reason:
              'PDF has been modified multiple times. '
              'Please upload the original unmodified PDF.',
          metadata: metadata,
        );
      }

      // STRICT: If no metadata found, reject
      if (!metadata.containsKey('creator') &&
          !metadata.containsKey('producer')) {
        return DocumentVerificationResult.invalid(
          reason:
              'PDF has minimal or missing metadata. This could indicate '
              'the file has been edited or metadata was stripped. '
              'Please upload a PDF from an official scanner app.',
          metadata: metadata,
        );
      }

      if (warnings.isEmpty) {
        return DocumentVerificationResult.valid(
          confidence: confidence,
          metadata: metadata,
        );
      } else {
        return DocumentVerificationResult.suspicious(
          warnings: warnings,
          confidence: confidence,
          metadata: metadata,
        );
      }
    } catch (e) {
      debugPrint('PDF verification error: $e');
      return DocumentVerificationResult.invalid(
        reason: 'Unable to verify PDF: ${e.toString()}',
      );
    }
  }

  /// Get a summary of verification result for UI display
  static String getSummary(DocumentVerificationResult result) {
    if (!result.isValid) {
      return '❌ ${result.reason ?? "Verification failed"}';
    }

    if (result.confidence >= 90) {
      return '✅ Document verified (${result.confidence}% confidence)';
    } else if (result.confidence >= 70) {
      return '⚠️ Document acceptable (${result.confidence}% confidence)';
    } else {
      return '⚠️ Document suspicious (${result.confidence}% confidence)';
    }
  }
}
