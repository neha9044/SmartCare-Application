// lib/services/medical_report_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
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

      // Set timeout for request
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout - please check your connection');
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
}
