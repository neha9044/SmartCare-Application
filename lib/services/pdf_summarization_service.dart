import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Data model for bilingual summary (English + Hindi)
class BilingualSummary {
  final String english;
  final String hindi;

  BilingualSummary({
    required this.english,
    required this.hindi,
  });
}

class PdfSummarizationService {
  final String hfApiKey = "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"; // 🔑 Hugging Face API Key
  final String libreTranslateUrl = "https://libretranslate.de/translate"; // ✅ No billing required

  /// Extracts text from PDF file
  Future<String> extractTextFromPdf(File file) async {
    try {
      final PdfDocument document =
      PdfDocument(inputBytes: await file.readAsBytes());
      String extractedText = '';
      PdfTextExtractor extractor = PdfTextExtractor(document);

      for (int i = 0; i < document.pages.count; i++) {
        extractedText +=
            extractor.extractText(startPageIndex: i, endPageIndex: i);
      }

      document.dispose();
      return extractedText.trim().isEmpty
          ? "No text found in the PDF."
          : extractedText;
    } catch (e) {
      print("Error extracting text: $e");
      return "Error extracting text from PDF.";
    }
  }

  /// Summarizes the extracted text using Hugging Face model
  Future<String> summarizeMedicalReport(String text) async {
    try {
      final Uri apiUrl = Uri.parse(
          "https://api-inference.huggingface.co/models/facebook/bart-large-cnn");

      final response = await http.post(
        apiUrl,
        headers: {
          'Authorization': 'Bearer $hfApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "inputs": text.length > 2000 ? text.substring(0, 2000) : text,
        }),
      );

      if (response.statusCode != 200) {
        print("Summarization failed: ${response.statusCode} ${response.body}");
        return "Failed to summarize report (Code: ${response.statusCode}).";
      }

      final decoded = jsonDecode(response.body);
      if (decoded is List && decoded.isNotEmpty) {
        final summaryText = decoded[0]['summary_text'];
        return summaryText ?? "No summary generated.";
      }
      return "No summary generated.";
    } catch (e) {
      print("Error summarizing: $e");
      return "Error summarizing text.";
    }
  }

  Future<String> translateToHindi(String text) async {
    try {
      final Uri apiUrl = Uri.parse(
          "https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=en|hi");

      final response = await http.get(apiUrl);

      if (response.statusCode != 200) {
        print("Translation failed: ${response.statusCode} ${response.body}");
        return "Failed to translate to Hindi.";
      }

      final decoded = jsonDecode(response.body);
      final translatedText = decoded['responseData']?['translatedText'];
      return translatedText ?? "No Hindi translation found.";
    } catch (e) {
      print("Error translating to Hindi: $e");
      return "Error translating text to Hindi.";
    }
  }


  /// Full process: Extract → Summarize → Translate
  Future<BilingualSummary> summarizePdfReport(String pdfPath) async {
    try {
      final file = File(pdfPath);
      final extractedText = await extractTextFromPdf(file);

      if (extractedText.startsWith("Error") ||
          extractedText == "No text found in the PDF.") {
        return BilingualSummary(english: extractedText, hindi: extractedText);
      }

      final englishSummary = await summarizeMedicalReport(extractedText);
      final hindiSummary = await translateToHindi(englishSummary);

      return BilingualSummary(english: englishSummary, hindi: hindiSummary);
    } catch (e) {
      print("Error in summarizePdfReport: $e");
      return BilingualSummary(
        english: "Error processing PDF.",
        hindi: "PDF संसाधित करने में त्रुटि हुई।",
      );
    }
  }
}
