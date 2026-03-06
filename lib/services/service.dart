// lib/services/gemini_report_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';

/// Service class for Gemini AI-powered medical report analysis
class GeminiReportService {
  // Get your API key from: https://aistudio.google.com/app/apikeys
  static const String _apiKey = 'AIzaSyBORNbgHlbO7zSgQp3ewNirVMdOPxfCWF4';

  static late GenerativeModel _model;

  /// Initialize the Gemini model
  static void initialize(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey.isEmpty ? _apiKey : apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexualContent, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
    );
  }

  /// Extract text from file (PDF or Image)
  static Future<String> _extractTextFromFile(PlatformFile file) async {
    try {
      if (file.name.toLowerCase().endsWith('.pdf')) {
        return await _extractTextFromPDF(file);
      } else {
        return await _extractTextFromImage(file);
      }
    } catch (e) {
      throw Exception('Error extracting text: $e');
    }
  }

  /// Extract text from PDF using Gemini Vision
  static Future<String> _extractTextFromPDF(PlatformFile file) async {
    try {
      Uint8List fileBytes;
      if (kIsWeb) {
        fileBytes = file.bytes ?? Uint8List(0);
      } else {
        fileBytes = await File(file.path!).readAsBytes();
      }

      final request = [
        Content.text('''Please extract ALL the text from this PDF medical report. 
Provide the complete text content exactly as it appears in the document.
If it's a scanned PDF, use OCR to extract the text.
Return only the extracted text without any explanations.'''),
        Content.data('application/pdf', fileBytes),
      ];

      final response = await _model.generateContent(request);
      return response.text ?? '';
    } catch (e) {
      throw Exception('Error extracting text from PDF: $e');
    }
  }

  /// Extract text from image using Gemini Vision
  static Future<String> _extractTextFromImage(PlatformFile file) async {
    try {
      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = file.bytes ?? Uint8List(0);
      } else {
        imageBytes = await File(file.path!).readAsBytes();
      }

      // Determine content type
      final fileName = file.name.toLowerCase();
      String mimeType = 'image/jpeg';
      if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (fileName.endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      final request = [
        Content.text('''Please extract ALL the text from this medical report image. 
Use OCR to read scanned/handwritten text.
Provide the complete text content exactly as it appears.
Return only the extracted text without any explanations.'''),
        Content.data(mimeType, imageBytes),
      ];

      final response = await _model.generateContent(request);
      return response.text ?? '';
    } catch (e) {
      throw Exception('Error extracting text from image: $e');
    }
  }

  /// Analyze report using Gemini (Classification, Summary, Actions, Severity)
  static Future<Map<String, dynamic>> _analyzeReportText(
    String reportText,
  ) async {
    try {
      final prompt = '''You are a medical report analyzer. Analyze the following medical report and provide structured analysis.

Medical Report Text:
"""
$reportText
"""

Provide your response in the following JSON format (return ONLY valid JSON, no markdown):
{
  "report_type": "Type of report (e.g., Lab Report, Radiology, Discharge Summary, Pathology, etc.)",
  "severity": "high or medium or low (based on abnormal findings)",
  "summary": "Simple English summary of what the report says (2-3 sentences, easy to understand)",
  "abnormal": ["List of abnormal findings or values", "Only include actual abnormal results"],
  "findings": "Main findings in simple language",
  "actions": ["Recommended action 1", "Recommended action 2", "Follow-up required"],
  "key_values": {
    "test_name": "value or result"
  }
}

IMPORTANT RULES:
1. Severity: Mark as "high" only if critical/dangerous, "medium" for concerning findings, "low" for minor issues or normal
2. Summary: Use simple English, no medical jargon
3. Abnormal: Only list values/findings that are ACTUALLY abnormal
4. Actions: List specific next steps the patient should take
5. Return ONLY valid JSON, no additional text or markdown''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      String jsonString = response.text ?? '{}';

      // Clean up response if it contains markdown code blocks
      jsonString = jsonString
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Parse and validate JSON
      final result = _parseJsonResponse(jsonString);
      return result;
    } catch (e) {
      throw Exception('Error analyzing report: $e');
    }
  }

  /// Parse JSON response from Gemini
  static Map<String, dynamic> _parseJsonResponse(String jsonString) {
    try {
      final result = _parseJson(jsonString);
      
      // Validate and default missing fields
      return {
        'report_type': result['report_type'] ?? 'Medical Report',
        'severity': _validateSeverity(result['severity'] ?? 'low'),
        'summary': result['summary'] ?? 'Report analysis completed',
        'abnormal': _ensureList(result['abnormal']),
        'findings': result['findings'] ?? '',
        'actions': _ensureList(result['actions']),
        'key_values': result['key_values'] ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      // Return safe defaults if parsing fails
      return {
        'report_type': 'Medical Report',
        'severity': 'medium',
        'summary': 'Analysis completed. Please review the report.',
        'abnormal': [],
        'findings': '',
        'actions': ['Consult with healthcare provider'],
        'key_values': {},
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Parse JSON response with error handling
  static dynamic _parseJson(String jsonString) {
    try {
      return _parseJsonValue(jsonString.trim());
    } catch (e) {
      throw Exception('Invalid JSON: $e');
    }
  }

  /// Recursive JSON parser
  static dynamic _parseJsonValue(String value) {
    value = value.trim();
    if (value.startsWith('{')) {
      return _parseJsonObject(value);
    } else if (value.startsWith('[')) {
      return _parseJsonArray(value);
    } else if (value == 'null') {
      return null;
    } else if (value == 'true') {
      return true;
    } else if (value == 'false') {
      return false;
    } else if (value.startsWith('"')) {
      return _parseJsonString(value);
    } else {
      final num = num.tryParse(value);
      if (num != null) return num;
      return value;
    }
  }

  /// Parse JSON object
  static Map<String, dynamic> _parseJsonObject(String jsonStr) {
    final map = <String, dynamic>{};
    jsonStr = jsonStr.trim();
    if (!jsonStr.startsWith('{') || !jsonStr.endsWith('}')) {
      throw FormatException('Invalid JSON object');
    }

    String content = jsonStr.substring(1, jsonStr.length - 1).trim();
    if (content.isEmpty) return map;

    int i = 0;
    while (i < content.length) {
      // Skip whitespace
      while (i < content.length && content[i].trim().isEmpty) i++;
      if (i >= content.length) break;

      // Parse key
      if (content[i] != '"') {
        throw FormatException('Expected key at position $i');
      }
      int keyStart = i;
      i++;
      while (i < content.length && content[i] != '"') {
        if (content[i] == '\\') i++;
        i++;
      }
      i++;
      String key = content.substring(keyStart, i);
      key = _parseJsonString(key) as String;

      // Skip whitespace and colon
      while (i < content.length && (content[i].trim().isEmpty || content[i] == ':')) {
        i++;
      }

      // Parse value
      int valueStart = i;
      int braceCount = 0;
      int bracketCount = 0;
      bool inString = false;
      bool escaped = false;

      while (i < content.length) {
        if (escaped) {
          escaped = false;
          i++;
          continue;
        }

        final char = content[i];
        if (char == '\\') {
          escaped = true;
        } else if (char == '"' && !escaped) {
          inString = !inString;
        } else if (!inString) {
          if (char == '{') braceCount++;
          if (char == '}') braceCount--;
          if (char == '[') bracketCount++;
          if (char == ']') bracketCount--;
          if ((char == ',' || i == content.length - 1) &&
              braceCount == 0 &&
              bracketCount == 0) {
            break;
          }
        }
        i++;
      }

      String valueStr = content.substring(valueStart, i).trim();
      if (valueStr.endsWith(',')) {
        valueStr = valueStr.substring(0, valueStr.length - 1).trim();
      }

      map[key] = _parseJsonValue(valueStr);

      // Skip comma
      while (i < content.length && (content[i].trim().isEmpty || content[i] == ',')) {
        i++;
      }
    }

    return map;
  }

  /// Parse JSON array
  static List<dynamic> _parseJsonArray(String jsonStr) {
    final list = <dynamic>[];
    jsonStr = jsonStr.trim();
    if (!jsonStr.startsWith('[') || !jsonStr.endsWith(']')) {
      throw FormatException('Invalid JSON array');
    }

    String content = jsonStr.substring(1, jsonStr.length - 1).trim();
    if (content.isEmpty) return list;

    int i = 0;
    while (i < content.length) {
      int valueStart = i;
      int braceCount = 0;
      int bracketCount = 0;
      bool inString = false;
      bool escaped = false;

      while (i < content.length) {
        if (escaped) {
          escaped = false;
          i++;
          continue;
        }

        final char = content[i];
        if (char == '\\') {
          escaped = true;
        } else if (char == '"' && !escaped) {
          inString = !inString;
        } else if (!inString) {
          if (char == '{') braceCount++;
          if (char == '}') braceCount--;
          if (char == '[') bracketCount++;
          if (char == ']') bracketCount--;
          if ((char == ',' || i == content.length - 1) &&
              braceCount == 0 &&
              bracketCount == 0) {
            break;
          }
        }
        i++;
      }

      String valueStr = content.substring(valueStart, i).trim();
      if (valueStr.endsWith(',')) {
        valueStr = valueStr.substring(0, valueStr.length - 1).trim();
      }

      if (valueStr.isNotEmpty) {
        list.add(_parseJsonValue(valueStr));
      }

      // Skip comma
      while (i < content.length && (content[i].trim().isEmpty || content[i] == ',')) {
        i++;
      }
    }

    return list;
  }

  /// Parse JSON string
  static String _parseJsonString(String jsonString) {
    jsonString = jsonString.trim();
    if (!jsonString.startsWith('"') || !jsonString.endsWith('"')) {
      throw FormatException('Invalid JSON string');
    }

    String content = jsonString.substring(1, jsonString.length - 1);
    final buffer = StringBuffer();
    int i = 0;

    while (i < content.length) {
      final char = content[i];
      if (char == '\\' && i + 1 < content.length) {
        final next = content[i + 1];
        switch (next) {
          case '"':
          case '\\':
          case '/':
            buffer.write(next);
            i += 2;
            break;
          case 'b':
            buffer.write('\b');
            i += 2;
            break;
          case 'f':
            buffer.write('\f');
            i += 2;
            break;
          case 'n':
            buffer.write('\n');
            i += 2;
            break;
          case 'r':
            buffer.write('\r');
            i += 2;
            break;
          case 't':
            buffer.write('\t');
            i += 2;
            break;
          case 'u':
            if (i + 6 < content.length) {
              final hex = content.substring(i + 2, i + 6);
              final code = int.parse(hex, radix: 16);
              buffer.writeCharCode(code);
              i += 6;
            } else {
              buffer.write(char);
              i++;
            }
            break;
          default:
            buffer.write(char);
            i++;
        }
      } else {
        buffer.write(char);
        i++;
      }
    }

    return buffer.toString();
  }

  /// Validate severity value
  static String _validateSeverity(String severity) {
    final s = severity.toLowerCase().trim();
    if (s == 'high' || s == 'critical') return 'high';
    if (s == 'medium' || s == 'moderate') return 'medium';
    if (s == 'low' || s == 'mild' || s == 'normal') return 'low';
    return 'medium';
  }

  /// Ensure value is a list
  static List<String> _ensureList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return [];
  }

  /// Upload and analyze PDF report
  ///
  /// Returns:
  /// {
  ///   "report_type": "Lab Report",
  ///   "summary": "Summary in simple English...",
  ///   "abnormal": ["Abnormal finding 1"],
  ///   "severity": "high/medium/low",
  ///   "actions": ["Action 1"],
  ///   "findings": "Main findings",
  ///   "key_values": {},
  ///   "timestamp": "2026-03-06T..."
  /// }
  static Future<Map<String, dynamic>> uploadReport(
    PlatformFile platformFile,
    String userId,
  ) async {
    try {
      if (_model == null) {
        throw Exception('Gemini model not initialized. Call initialize() first.');
      }

      // Extract text from file
      final extractedText = await _extractTextFromFile(platformFile);

      if (extractedText.isEmpty) {
        throw Exception('No text could be extracted from the file');
      }

      // Analyze the extracted text
      final analysis = await _analyzeReportText(extractedText);

      return analysis;
    } catch (e) {
      throw Exception('Error processing report: $e');
    }
  }

  /// Pick and upload from camera
  static Future<Map<String, dynamic>> pickAndUploadFromCamera(
    String userId,
  ) async {
    try {
      if (_model == null) {
        throw Exception('Gemini model not initialized. Call initialize() first.');
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) {
        throw Exception('No image selected');
      }

      // Convert XFile to PlatformFile
      final bytes = await image.readAsBytes();
      final platformFile = PlatformFile(
        name: image.name,
        size: bytes.length,
        bytes: bytes,
      );

      // Extract text from image
      final extractedText = await _extractTextFromImage(platformFile);

      if (extractedText.isEmpty) {
        throw Exception('No text could be extracted from the image');
      }

      // Analyze the extracted text
      final analysis = await _analyzeReportText(extractedText);

      return analysis;
    } catch (e) {
      throw Exception('Error processing camera image: $e');
    }
  }

  /// Pick and upload from gallery
  static Future<Map<String, dynamic>> pickAndUploadFromGallery(
    String userId,
  ) async {
    try {
      if (_model == null) {
        throw Exception('Gemini model not initialized. Call initialize() first.');
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        throw Exception('No image selected');
      }

      // Convert XFile to PlatformFile
      final bytes = await image.readAsBytes();
      final platformFile = PlatformFile(
        name: image.name,
        size: bytes.length,
        bytes: bytes,
      );

      // Extract text from image
      final extractedText = await _extractTextFromImage(platformFile);

      if (extractedText.isEmpty) {
        throw Exception('No text could be extracted from the image');
      }

      // Analyze the extracted text
      final analysis = await _analyzeReportText(extractedText);

      return analysis;
    } catch (e) {
      throw Exception('Error processing gallery image: $e');
    }
  }
}
