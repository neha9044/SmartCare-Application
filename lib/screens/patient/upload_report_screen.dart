// Example: How to use OCR functionality for medical reports
// lib/screens/patient/upload_report_screen.dart

import 'package:flutter/material.dart';
import '../../services/medical_report_service.dart';
import 'package:file_picker/file_picker.dart';

class UploadReportScreen extends StatefulWidget {
  final String userId;

  const UploadReportScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UploadReportScreen> createState() => _UploadReportScreenState();
}

class _UploadReportScreenState extends State<UploadReportScreen> {
  bool _isLoading = false;
  String? _result;
  String? _error;

  // Upload PDF (text-based or scanned with OCR)
  Future<void> _uploadPDF() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      // Pick PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;

        // Upload to backend (automatically uses OCR if needed)
        final response = await MedicalReportService.uploadReport(
          file,
          widget.userId,
        );

        setState(() {
          _result =
              '''
Report Type: ${response['report_type']}
Severity: ${response['severity']}
Abnormal Values: ${response['abnormal'].length}

Summary:
${response['summary']}

Abnormal Findings:
${response['abnormal'].join('\n')}
          ''';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Take photo and extract text with OCR
  Future<void> _takePhotoAndAnalyze() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      // Take photo with camera and upload
      final response = await MedicalReportService.pickAndUploadFromCamera(
        widget.userId,
      );

      setState(() {
        _result =
            '''
Report Type: ${response['report_type']}
Severity: ${response['severity']}
Abnormal Values: ${response['abnormal'].length}

Summary:
${response['summary']}

Abnormal Findings:
${response['abnormal'].join('\n')}
        ''';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Pick image from gallery and extract text with OCR
  Future<void> _pickImageAndAnalyze() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      // Pick image from gallery and upload
      final response = await MedicalReportService.pickAndUploadFromGallery(
        widget.userId,
      );

      setState(() {
        _result =
            '''
Report Type: ${response['report_type']}
Severity: ${response['severity']}
Abnormal Values: ${response['abnormal'].length}

Summary:
${response['summary']}

Abnormal Findings:
${response['abnormal'].join('\n')}
        ''';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Medical Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose how to upload your medical report:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Upload PDF button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _uploadPDF,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Upload PDF Report'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            // Take photo button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _takePhotoAndAnalyze,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo of Report'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            // Pick from gallery button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickImageAndAnalyze,
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing... OCR may take 30-60 seconds'),
                  ],
                ),
              ),

            // Error message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Result
            if (_result != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Analysis Result:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_result!),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
