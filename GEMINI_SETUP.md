# Gemini API Setup for Medical Reports

## Quick Setup Guide

### 1. Get Gemini API Key
- Go to [Google AI Studio](https://aistudio.google.com/app/apikeys)
- Click "Create API Key"
- Copy your API key

### 2. Add API Key to Your App

#### Option A: Update main.dart (Best Practice)
In your `main.dart`, add this before running the app:

```dart
import 'package:smartcare_app/services/gemini_report_service.dart';

void main() {
  // Initialize Gemini with your API key
  GeminiReportService.initialize('YOUR_API_KEY_HERE');
  
  runApp(const MyApp());
}
```

#### Option B: Update medical_reports_screen.dart (Current Implementation)
In `lib/screens/patient/medical_reports_screen.dart`, line ~37:

```dart
GeminiReportService.initialize('YOUR_GEMINI_API_KEY_HERE');
```

Replace `'YOUR_GEMINI_API_KEY_HERE'` with your actual API key.

### 3. Features

✅ **Automatic Report Type Classification**
- Lab Report
- Radiology/Imaging
- Discharge Summary
- Pathology
- General Medical Reports

✅ **Smart Summarization**
- Simple English summaries
- Medical jargon simplified
- Key findings highlighted

✅ **Severity Assessment**
- High: Critical findings requiring immediate attention
- Medium: Concerning findings that need follow-up
- Low: Minor issues or normal results

✅ **Action Items**
- Personalized recommendations
- Follow-up instructions
- Next steps for the patient

✅ **Multiple Input Methods**
- PDF reports
- Camera capture (take photos of reports)
- Gallery images

### 4. Processing Times

- Text-based PDFs: 5-10 seconds
- Scanned PDFs (with OCR): 20-30 seconds
- Images (with OCR): 15-25 seconds

### 5. API Response Structure

```json
{
  "report_type": "Lab Report",
  "severity": "medium",
  "summary": "Your test results show...",
  "abnormal": ["Low Hemoglobin", "High Glucose"],
  "findings": "Main clinical findings...",
  "actions": ["Consult a cardiologist", "Take medication X"],
  "key_values": {
    "Hemoglobin": "11.5 g/dL",
    "Glucose": "150 mg/dL"
  },
  "timestamp": "2026-03-06T10:30:00.000Z"
}
```

### 6. Troubleshooting

**Issue**: "Gemini model not initialized"
- **Solution**: Make sure you've called `GeminiReportService.initialize()` before using any methods

**Issue**: "Invalid API key"
- **Solution**: Check your API key at https://aistudio.google.com/app/apikeys

**Issue**: "Slow processing"
- **Solution**: This is normal for scanned PDFs. The app displays "Processing..." during analysis.

### 7. Important Notes

- Keep your API key secure
- Don't commit your API key to version control
- For production, use environment variables or secure storage
- The app handles PDF extraction automatically
- OCR is used for scanned documents

---

**Need help?** Check the [Google Generative AI Docs](https://ai.google.dev/docs)
