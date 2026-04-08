import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CloudinaryService {
  static const String _cloudName = 'deu0oe2uh';
  static const String _uploadPreset = 'student_docs_public';

  // Upload file to Cloudinary
  Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String folder,
    String? startFileName,
  }) async {
    try {
      final fileName = startFileName ?? file.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();
      final resourceType = (extension == 'pdf') ? 'raw' : 'auto';

      debugPrint(
        'Cloudinary Upload: fileName=$fileName, extension=$extension, resourceType=$resourceType',
      );

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = folder;

      // Add file
      final stream = http.ByteStream(file.openRead());
      final length = await file.length();

      final multipartFile = http.MultipartFile(
        'file',
        stream,
        length,
        filename: startFileName ?? file.path.split('/').last,
      );

      request.files.add(multipartFile);

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseData.body);
        return {
          'success': true,
          'secure_url': jsonResponse['secure_url'],
          'public_id': jsonResponse['public_id'],
          'format': jsonResponse['format'],
          'bytes': jsonResponse['bytes'],
        };
      } else {
        throw Exception('Failed to upload file: ${responseData.body}');
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  // Delete file (Not supported with Unsigned preset without backend signature)
  Future<void> deleteFile(String publicId) async {
    // Note: Deleting files requires a signed API call (API Key & Secret).
    // Since we are using an unsigned preset securely from the client side,
    // we cannot delete files directly without exposing the API Secret.
    // For now, we will just log this. In a production app, you would verify
    // the user on your backend and then call Cloudinary API to delete.
    debugPrint(
      'Pseudo-delete: $publicId (Deletion requires backend signature)',
    );
  }
}
