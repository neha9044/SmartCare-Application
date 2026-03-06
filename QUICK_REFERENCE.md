# Gemini Report Service - Quick Reference

## Basic Usage

### Initialize in main()
```dart
import 'package:smartcare_app/services/gemini_report_service.dart';

void main() {
  GeminiReportService.initialize('YOUR_API_KEY');
  runApp(const MyApp());
}
```

### Or in your screen
```dart
@override
void initState() {
  super.initState();
  GeminiReportService.initialize('YOUR_API_KEY');
}
```

## Upload Examples

### Upload PDF Report
```dart
final user = FirebaseAuth.instance.currentUser;
final platformFile = /* your FilePickerResult.files.single */;

final result = await GeminiReportService.uploadReport(platformFile, user.uid);
print('Report Type: ${result['report_type']}');
print('Severity: ${result['severity']}');
print('Summary: ${result['summary']}');
print('Actions: ${result['actions']}');
```

### Take Photo
```dart
final result = await GeminiReportService.pickAndUploadFromCamera(userId);
```

### Pick from Gallery
```dart
final result = await GeminiReportService.pickAndUploadFromGallery(userId);
```

## Response Structure

```dart
Map<String, dynamic> response = {
  'report_type': 'Lab Report',           // String
  'severity': 'high',                    // 'high' | 'medium' | 'low'
  'summary': 'Your test shows...',       // String
  'abnormal': [                          // List<String>
    'Low Hemoglobin (11.5 g/dL)',
    'High Glucose (150 mg/dL)'
  ],
  'findings': 'Main clinical findings...', // String
  'actions': [                           // List<String>
    'Consult a hematologist',
    'Take iron supplements',
    'Retest in 2 weeks'
  ],
  'key_values': {                        // Map<String, dynamic>
    'Hemoglobin': '11.5 g/dL',
    'Glucose': '150 mg/dL'
  },
  'timestamp': '2026-03-06T10:30:00Z'   // String (ISO8601)
}
```

## Display in UI

### Show Report Type with Icon
```dart
Text(result['report_type'])  // e.g., "Lab Report"
```

### Show Severity Chip
```dart
Container(
  child: Text(
    result['severity'],
    style: TextStyle(
      color: _getSeverityColor(result['severity'])
    ),
  ),
)

Color _getSeverityColor(String severity) {
  switch(severity) {
    case 'high': return Colors.red;
    case 'medium': return Colors.orange;
    case 'low': return Colors.green;
    default: return Colors.grey;
  }
}
```

### Show Summary
```dart
Text(result['summary'])
```

### Show Actions
```dart
ListView(
  children: (result['actions'] as List)
    .map((action) => ListTile(
      leading: Icon(Icons.check_circle),
      title: Text(action),
    ))
    .toList()
)
```

### Show Abnormal Values
```dart
if ((result['abnormal'] as List).isNotEmpty)
  ListView(
    children: (result['abnormal'] as List)
      .map((item) => ListTile(
        leading: Icon(Icons.warning),
        title: Text(item),
      ))
      .toList()
  )
```

## Error Handling

```dart
try {
  final result = await GeminiReportService.uploadReport(file, userId);
  // Handle success
} on FormatException catch (e) {
  // Invalid file format
  print('Invalid file: $e');
} on Exception catch (e) {
  // Other errors
  print('Error: $e');
  // Show user-friendly message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Analysis failed: Check internet and try again'),
      backgroundColor: Colors.red,
    )
  );
}
```

## API Key Management

### ❌ DON'T DO THIS
```dart
// Don't hardcode in production
const String apiKey = 'AIzaSyD...';
GeminiReportService.initialize(apiKey);
```

### ✅ DO THIS
```dart
// Option 1: Environment variable
const String apiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: 'YOUR_API_KEY'
);
GeminiReportService.initialize(apiKey);

// Option 2: Firebase Remote Config (recommended)
// await setupGeminiFromRemoteConfig();
```

## Processing Time Expectations

| Input Type | Content | Time |
|-----------|---------|------|
| PDF | Text-based | 5-10s |
| PDF | Scanned | 20-30s |
| Image | Normal | 15-25s |
| Image | Complex | 25-35s |

Show user feedback:
```dart
if (_isUploading)
  Center(
    child: Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Processing report... This may take 20-30 seconds'),
      ],
    )
  )
```

## Common Report Types Detected

- Lab Report (Blood test, urinalysis, etc.)
- Radiology Report (X-ray, CT, MRI, etc.)
- ECG Report (Heart monitoring)
- Pathology Report (Biopsy results)
- Discharge Summary (Hospital discharge)
- Prescription/Medication
- General Medical Report

## Severity Levels Explained

### High Severity
- Critical abnormalities
- Immediate medical attention needed
- Dangerous values
- Color: Red

### Medium Severity
- Concerning results
- Needs follow-up
- Requires monitoring
- Color: Orange

### Low Severity
- Minor findings
- Normal ranges
- No immediate concern
- Color: Green

## Testing Sample Reports

For testing, you can use:
1. Standard medical reports (lab results, imaging)
2. Scanned documents (tests OCR capability)
3. Handwritten reports (tests OCR accuracy)
4. Multi-page documents
5. Reports with tables and charts

## FAQs

**Q: Why is processing slow?**
A: Scanned PDFs need OCR, which takes 20-30 seconds. This is normal.

**Q: Can I use without internet?**
A: No, Gemini API requires internet connection.

**Q: Is my data secure?**
A: Yes, but don't send sensitive PHI without proper safeguards.

**Q: Can I cache results?**
A: Yes, save the response to local storage or Firestore.

**Q: What file formats are supported?**
A: PDF, PNG, JPG, GIF, WebP

**Q: Can I batch upload?**
A: Currently uploads one at a time. You can queue multiple uploads.

## Production Checklist

- [ ] Move API key to secure storage
- [ ] Set up error handling and logging
- [ ] Implement rate limiting
- [ ] Add request timeout handling
- [ ] Test on all target devices
- [ ] Verify OCR accuracy
- [ ] Set up monitoring/analytics
- [ ] Create user documentation
- [ ] Test offline scenarios
- [ ] Verify HIPAA compliance (if needed)
- [ ] Set up backup/recovery
- [ ] Test with real medical reports

## Useful Links

- [Google AI Studio](https://aistudio.google.com)
- [Google Generative AI Docs](https://ai.google.dev/docs)
- [API Key Management](https://aistudio.google.com/app/apikeys)
- [Gemini Models](https://ai.google.dev/models)
- [Vision API Guide](https://ai.google.dev/tutorials/vision)

---

For full integration guide, see `GEMINI_SETUP.md`
For implementation details, see `IMPLEMENTATION_SUMMARY.md`
