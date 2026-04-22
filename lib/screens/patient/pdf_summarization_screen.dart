import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class PdfSummarizationScreen extends StatefulWidget {
  const PdfSummarizationScreen({Key? key}) : super(key: key);

  @override
  _PdfSummarizationScreenState createState() =>
      _PdfSummarizationScreenState();
}

class _PdfSummarizationScreenState extends State<PdfSummarizationScreen> {
  String englishSummary = "";
  String hindiSummary = "";
  bool isLoading = false;

  // 🔥 CHANGE THIS TO YOUR PC IP
  final String apiUrl = "http://192.168.82.105:8000/analyze-report/";

  Future<void> _pickAndSummarizePdf() async {
    setState(() {
      isLoading = true;
      englishSummary = "";
      hindiSummary = "";
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;

        // 🔥 API CALL
        var request = http.MultipartRequest(
          "POST",
          Uri.parse(apiUrl),
        );

        request.files.add(
          await http.MultipartFile.fromPath('file', filePath),
        );

        var response = await request.send();

        if (response.statusCode == 200) {
          final respStr = await response.stream.bytesToString();
          final jsonData = jsonDecode(respStr);

          setState(() {
            englishSummary = jsonData['summary'] ?? "No summary available";

// Remove duplicate for now
            hindiSummary = "";
          });
        } else {
          setState(() {
            englishSummary = "Error: Server issue";
            hindiSummary = "सर्वर त्रुटि";
          });
        }
      }
    } catch (e) {
      print("ERROR: $e"); // 🔥 IMPORTANT

      setState(() {
        englishSummary = "Error: $e";
        hindiSummary = "त्रुटि: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Medical Report Summarizer",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Upload Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Upload Medical Report",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Get instant summary in English & Hindi",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : _pickAndSummarizePdf,
                        icon: const Icon(Icons.upload_file, size: 20),
                        label: const Text(
                          "Choose PDF File",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1976D2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Loading
              if (isLoading)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text("Processing your report..."),
                      ],
                    ),
                  ),
                )
              else ...[
                if (englishSummary.isNotEmpty) ...[
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(englishSummary),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (hindiSummary.isNotEmpty) ...[
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(hindiSummary),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
