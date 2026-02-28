// lib/services/medical_report_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service class for communicating with SmartCare ML Backend API
class MedicalReportService {
  // Backend URL configuration
  // For Android Emulator, use: http://10.0.2.2:8000
  // For iOS Simulator, use: http://localhost:8000
  // For Physical Device on same network, use: http://YOUR_LOCAL_IP:8000
  // For Production, use: https://your-domain.com
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://localhost:8000';
    }
  }

  /// Upload PDF and get ML analysis results
  ///
  /// Returns:
  /// {
  ///   "report_type": "Lab Report",
  ///   "summary": "Complete Blood Count test results...",
  ///   "abnormal": ["Low Hemoglobin (11.5 g/dL)"],
  ///   "severity": "Mild",
  ///   "timestamp": "2026-02-24T10:30:00.123456",
  ///   "document_id": "firebase_doc_id"
  /// }
  static Future<Map<String, dynamic>> uploadReport(
    PlatformFile platformFile,
    String userId,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload?user_id=$userId'),
      );

      // Add PDF file - handle both web and mobile
      if (kIsWeb) {
        // Web: use bytes
        if (platformFile.bytes == null) {
          throw Exception('File bytes are null');
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            platformFile.bytes!,
            filename: platformFile.name,
          ),
        );
      } else {
        // Mobile/Desktop: use path
        if (platformFile.path == null) {
          throw Exception('File path is null');
        }
        request.files.add(
          await http.MultipartFile.fromPath('file', platformFile.path!),
        );
      }

      // Set timeout for request (longer for OCR processing)
      var streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception(
            'Upload timeout - OCR processing takes 2-3 minutes for image-based PDFs',
          );
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading report: $e');
    }
  }

  /// Get all reports for a user
  static Future<Map<String, dynamic>> getUserReports(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/reports/$userId?limit=$limit'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 503) {
        throw Exception('Database not available');
      } else {
        throw Exception('Failed to fetch reports');
      }
    } catch (e) {
      throw Exception('Error fetching reports: $e');
    }
  }

  /// Get health statistics for a user
  static Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/statistics/$userId'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 503) {
        throw Exception('Database not available');
      } else {
        throw Exception('Failed to fetch statistics');
      }
    } catch (e) {
      throw Exception('Error fetching statistics: $e');
    }
  }

  /// Check API health status
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get API information
  static Future<Map<String, dynamic>?> getApiInfo() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Upload IMAGE and get ML analysis with OCR
  ///
  /// Supports: JPG, PNG, BMP, TIFF
  /// Uses OCR to extract text from image
  ///
  /// Returns: Same format as uploadReport
  static Future<Map<String, dynamic>> uploadImage(
    XFile imageFile,
    String userId,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-image?user_id=$userId'),
      );

      // Add image file
      if (kIsWeb) {
        // Web: use bytes
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: imageFile.name),
        );
      } else {
        // Mobile/Desktop: use path
        request.files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );
      }

      // Set timeout for OCR request (OCR takes longer)
      var streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception(
            'OCR timeout - image processing takes time, please wait',
          );
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Image upload failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  /// Pick image from camera and upload for OCR analysis
  static Future<Map<String, dynamic>> pickAndUploadFromCamera(
    String userId,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Balance between quality and file size
      );

      if (image == null) {
        throw Exception('No image selected');
      }

      return await uploadImage(image, userId);
    } catch (e) {
      throw Exception('Camera error: $e');
    }
  }

  /// Pick image from gallery and upload for OCR analysis
  static Future<Map<String, dynamic>> pickAndUploadFromGallery(
    String userId,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        throw Exception('No image selected');
      }

      return await uploadImage(image, userId);
    } catch (e) {
      throw Exception('Gallery error: $e');
    }
  }
}
