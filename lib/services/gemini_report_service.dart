// lib/services/gemini_report_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// Service class for Gemini AI-powered medical report analysis
class GeminiReportService {
  // Get your API key from: https://aistudio.google.com/app/apikeys
  static const String _defaultApiKey = 'AIzaSyCODSdkdCOlQO6zDRFs9zwQdHUN9Z59DUU';
  
  static String _apiKey = _defaultApiKey;
  static bool _initialized = false;

  /// Initialize the Gemini service with your API key
  static void initialize(String apiKey) {
    if (apiKey.isNotEmpty) {
      _apiKey = apiKey;
      _initialized = true;
    }
  }

  /// Make a request to Gemini API
  static Future<String> _makeGeminiRequest(
    String prompt,
    List<Map<String, dynamic>>? fileParts,
  ) async {
    try {
      if (!_initialized && _apiKey == _defaultApiKey) {
        throw Exception(
          'Gemini API key not configured. Call GeminiReportService.initialize(YOUR_API_KEY) first.',
        );
      }

      // Using the google_generative_ai package
      final request = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              if (fileParts != null) ...fileParts,
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 2048,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_NONE',
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_NONE',
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_NONE',
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_NONE',
          },
        ],
      };

      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey',
      );

      final http = _HttpClient();
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: _jsonEncode(request),
      );

      if (response.statusCode == 200) {
        final decoded = _jsonDecode(response.body);
        final content = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return content ?? '';
      } else {
        throw Exception('Gemini API error: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error calling Gemini API: $e');
    }
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

  /// Extract text from PDF
  static Future<String> _extractTextFromPDF(PlatformFile file) async {
    try {
      final bytes = kIsWeb ? file.bytes : await File(file.path!).readAsBytes();

      if (bytes == null || bytes.isEmpty) {
        throw Exception('No valid PDF data');
      }

      final base64Data = _base64Encode(bytes);

      final response = await _makeGeminiRequest(
        'Please extract ALL the text from this PDF medical report. Provide the complete text content exactly as it appears. If it\'s a scanned PDF, use OCR. Return only the extracted text.',
        [
          {
            'inlineData': {
              'mimeType': 'application/pdf',
              'data': base64Data,
            }
          }
        ],
      );

      return response;
    } catch (e) {
      throw Exception('Error extracting text from PDF: $e');
    }
  }

  /// Extract text from image
  static Future<String> _extractTextFromImage(PlatformFile file) async {
    try {
      final bytes = kIsWeb ? file.bytes : await File(file.path!).readAsBytes();

      if (bytes == null || bytes.isEmpty) {
        throw Exception('No valid image data');
      }

      final fileName = file.name.toLowerCase();
      String mimeType = 'image/jpeg';
      if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (fileName.endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      final base64Data = _base64Encode(bytes);

      final response = await _makeGeminiRequest(
        'Please extract ALL the text from this medical report image. Use OCR to read scanned/handwritten text. Return only the extracted text.',
        [
          {
            'inlineData': {
              'mimeType': mimeType,
              'data': base64Data,
            }
          }
        ],
      );

      return response;
    } catch (e) {
      throw Exception('Error extracting text from image: $e');
    }
  }

  /// Analyze report text
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
1. Severity: "high" only if critical/dangerous, "medium" for concerning, "low" for minor/normal
2. Summary: Use simple English, no medical jargon
3. Abnormal: Only list ACTUALLY abnormal values
4. Actions: Specific next steps for the patient
5. Return ONLY valid JSON, no additional text''';

      final response = await _makeGeminiRequest(prompt, null);

      return _parseJsonResponse(response);
    } catch (e) {
      throw Exception('Error analyzing report: $e');
    }
  }

  /// Parse JSON response
  static Map<String, dynamic> _parseJsonResponse(String jsonString) {
    try {
      // Clean the response
      var json = jsonString
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final result = _jsonDecode(json);

      return {
        'report_type': result['report_type'] ?? 'Medical Report',
        'severity': _validateSeverity(result['severity'] ?? 'low'),
        'summary': result['summary'] ?? 'Analysis completed',
        'abnormal': _ensureList(result['abnormal']),
        'findings': result['findings'] ?? '',
        'actions': _ensureList(result['actions']),
        'key_values': result['key_values'] ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'report_type': 'Medical Report',
        'severity': 'medium',
        'summary': 'Analysis completed. Please review details.',
        'abnormal': [],
        'findings': '',
        'actions': ['Consult healthcare provider'],
        'key_values': {},
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Validate severity
  static String _validateSeverity(String severity) {
    final s = severity.toLowerCase().trim();
    if (s.contains('high') || s.contains('critical')) return 'high';
    if (s.contains('medium') || s.contains('moderate')) return 'medium';
    return 'low';
  }

  /// Ensure value is list
  static List<String> _ensureList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return [];
  }

  /// Upload and analyze report
  static Future<Map<String, dynamic>> uploadReport(
    PlatformFile platformFile,
    String userId,
  ) async {
    try {
      final extractedText = await _extractTextFromFile(platformFile);

      if (extractedText.isEmpty) {
        throw Exception('No text extracted from file');
      }

      final analysis = await _analyzeReportText(extractedText);
      return analysis;
    } catch (e) {
      throw Exception('Error processing report: $e');
    }
  }

  /// Pick from camera
  static Future<Map<String, dynamic>> pickAndUploadFromCamera(
    String userId,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) {
        throw Exception('No image selected');
      }

      final bytes = await image.readAsBytes();
      final platformFile = PlatformFile(
        name: image.name,
        size: bytes.length,
        bytes: bytes,
      );

      final extractedText = await _extractTextFromImage(platformFile);

      if (extractedText.isEmpty) {
        throw Exception('No text extracted from image');
      }

      final analysis = await _analyzeReportText(extractedText);
      return analysis;
    } catch (e) {
      throw Exception('Error processing camera image: $e');
    }
  }

  /// Pick from gallery
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

      final bytes = await image.readAsBytes();
      final platformFile = PlatformFile(
        name: image.name,
        size: bytes.length,
        bytes: bytes,
      );

      final extractedText = await _extractTextFromImage(platformFile);

      if (extractedText.isEmpty) {
        throw Exception('No text extracted from image');
      }

      final analysis = await _analyzeReportText(extractedText);
      return analysis;
    } catch (e) {
      throw Exception('Error processing gallery image: $e');
    }
  }
}

// Simple HTTP client wrapper
class _HttpClient {
  Future<_HttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    final request = await HttpClient().postUrl(uri);

    headers.forEach((key, value) {
      request.headers.add(key, value);
    });

    request.add(body.codeUnits);
    final response = await request.close();
    final bytes = await response.fold<List<int>>(
      <int>[],
      (previous, element) => previous..addAll(element),
    );
    final responseBody = utf8.decode(bytes);

    return _HttpResponse(response.statusCode, responseBody);
  }
}

class _HttpResponse {
  final int statusCode;
  final String body;

  _HttpResponse(this.statusCode, this.body);
}
// Simple JSON encoding/decoding
String _jsonEncode(dynamic object) {
  if (object == null) return 'null';
  if (object is String) return '"${object.replaceAll('"', '\\"')}"';
  if (object is num || object is bool) return object.toString();
  if (object is Map) {
    final entries = object.entries
        .map((e) => '${_jsonEncode(e.key)}:${_jsonEncode(e.value)}')
        .join(',');
    return '{$entries}';
  }
  if (object is List) {
    return '[${object.map(_jsonEncode).join(',')}]';
  }
  return '{}';
}

dynamic _jsonDecode(String json) {
  json = json.trim();
  if (json == 'null') return null;
  if (json == 'true') return true;
  if (json == 'false') return false;
  if (json.startsWith('"')) {
    return json.substring(1, json.length - 1).replaceAll('\\"', '"');
  }
  if (json.startsWith('{')) {
    return _parseObject(json);
  }
  if (json.startsWith('[')) {
    return _parseArray(json);
  }
  final num = double.tryParse(json);
  return num ?? json;
}

Map<String, dynamic> _parseObject(String json) {
  final result = <String, dynamic>{};
  json = json.substring(1, json.length - 1).trim();

  if (json.isEmpty) return result;

  int i = 0;
  while (i < json.length) {
    // Skip whitespace
    while (i < json.length && json[i] == ' ') i++;

    // Get key
    if (json[i] != '"') break;
    int kStart = i + 1;
    i++;
    while (i < json.length && json[i] != '"') i++;
    final key = json.substring(kStart, i);
    i++;

    // Skip to :
    while (i < json.length && json[i] != ':') i++;
    i++;

    // Get value
    while (i < json.length && json[i] == ' ') i++;
    int vStart = i;
    int depth = 0;
    bool inString = false;

    while (i < json.length) {
      if (json[i] == '"' && (i == 0 || json[i - 1] != '\\')) {
        inString = !inString;
      }
      if (!inString) {
        if (json[i] == '{' || json[i] == '[') depth++;
        if (json[i] == '}' || json[i] == ']') depth--;
        if ((json[i] == ',' || i == json.length - 1) && depth == 0) break;
      }
      i++;
    }

    final value = json.substring(vStart, i).trim();
    result[key] = _jsonDecode(value);

    if (i < json.length && json[i] == ',') i++;
  }

  return result;
}

List<dynamic> _parseArray(String json) {
  final result = <dynamic>[];
  json = json.substring(1, json.length - 1).trim();

  if (json.isEmpty) return result;

  int i = 0;
  while (i < json.length) {
    int vStart = i;
    int depth = 0;
    bool inString = false;

    while (i < json.length) {
      if (json[i] == '"' && (i == 0 || json[i - 1] != '\\')) {
        inString = !inString;
      }
      if (!inString) {
        if (json[i] == '{' || json[i] == '[') depth++;
        if (json[i] == '}' || json[i] == ']') depth--;
        if ((json[i] == ',' || i == json.length - 1) && depth == 0) break;
      }
      i++;
    }

    final value = json.substring(vStart, i).trim();
    if (value.isNotEmpty) {
      result.add(_jsonDecode(value));
    }

    if (i < json.length && json[i] == ',') i++;
  }

  return result;
}

String _base64Encode(List<int> bytes) {
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  final buffer = StringBuffer();

  for (int i = 0; i < bytes.length; i += 3) {
    int b1 = bytes[i];
    int b2 = i + 1 < bytes.length ? bytes[i + 1] : 0;
    int b3 = i + 2 < bytes.length ? bytes[i + 2] : 0;

    int bitmap = (b1 << 16) | (b2 << 8) | b3;

    buffer.write(chars[(bitmap >> 18) & 63]);
    buffer.write(chars[(bitmap >> 12) & 63]);
    if (i + 1 < bytes.length) {
      buffer.write(chars[(bitmap >> 6) & 63]);
    } else {
      buffer.write('=');
    }
    if (i + 2 < bytes.length) {
      buffer.write(chars[bitmap & 63]);
    } else {
      buffer.write('=');
    }
  }

  return buffer.toString();
}
