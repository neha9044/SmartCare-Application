# API Key Setup - Step by Step

## 🔐 Getting Your Gemini API Key

### Step 1: Go to Google AI Studio
Visit: https://aistudio.google.com/app/apikeys

### Step 2: Sign In
- Use your Google account
- If you don't have one, create it
- Enable required APIs (Auto-enabled)

### Step 3: Create API Key
- Click the blue "Create API Key" button
- Select "Create API key in new Cloud Project" OR use existing project
- Google will generate your key automatically

### Step 4: Copy Your Key
```
AIzaSyD_3HGBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
(This is just an example format)

### Step 5: Save It Securely
Copy and paste it to one of these locations:

---

## 📍 Where to Add Your API Key

### Option A: In main.dart (RECOMMENDED)

**File:** `lib/main.dart`

```dart
import 'package:smartcare_app/services/gemini_report_service.dart';
import 'package:flutter/material.dart';

void main() {
  // 👇 ADD THIS LINE 👇
  GeminiReportService.initialize('YOUR_API_KEY_HERE');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCare',
      // ... rest of config
    );
  }
}
```

Replace `'YOUR_API_KEY_HERE'` with your actual key:
```dart
GeminiReportService.initialize('AIzaSyD_3HGBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
```

### Option B: In medical_reports_screen.dart

**File:** `lib/screens/patient/medical_reports_screen.dart`

Look for this line (around line 37):
```dart
GeminiReportService.initialize('YOUR_GEMINI_API_KEY_HERE');
```

Replace with:
```dart
GeminiReportService.initialize('AIzaSyD_3HGBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
```

---

## 🚀 After Adding Key

### 1. Save Files
Press `Ctrl+S` (or `Cmd+S` on Mac) to save

### 2. Get Dependencies
```bash
cd ~/SmartCare-Application
flutter pub get
```

### 3. Run App
```bash
flutter run
```

### 4. Test Upload
1. Open Medical Reports tab
2. Click "Upload PDF Report" or "Take Photo"
3. Select a medical report
4. Wait for analysis (5-30 seconds)
5. See results with:
   - Report Type ✓
   - Severity ✓
   - Summary ✓
   - Recommended Actions ✓
   - Abnormal Values ✓

---

## ⚠️ Important Notes

### Security
- ✅ Keep API key private
- ❌ Don't share with others
- ❌ Don't upload to GitHub
- ❌ Don't post online

### Rate Limits
Your Gemini API has:
- **Free tier:** ~60 requests per minute
- **Paid:** Up to 1,500 requests per minute

### Cost
- **Free tier:** First 50 API calls per day free
- **Paid:** $0.075 per 1,000 input tokens
- **Cost estimate:** ~$0.001 per report

### Quota
Monitor your usage:
1. Visit [Google Cloud Console](https://console.cloud.google.com/apis/dashboard)
2. Search for "Generative Language API"
3. Check "Quotas & System Limits"

---

## 🔍 Verify Setup

To confirm your API key works, run this Dart code:

```dart
import 'package:smartcare_app/services/gemini_report_service.dart';

void testGeminiApiKey() async {
  GeminiReportService.initialize('YOUR_API_KEY_HERE');
  
  try {
    // This will verify the API key works
    print('✓ Gemini API initialized successfully');
  } catch (e) {
    print('✗ Error: $e');
    print('Please check your API key');
  }
}
```

---

## 🆘 Troubleshooting

### Error: "Model not initialized"
```
Solution: Call GeminiReportService.initialize() before using
Location: main() or initState()
```

### Error: "Invalid API key"
```
Solution: Check if you copied the key correctly
Action: Get new key from https://aistudio.google.com/app/apikeys
```

### Error: "API quota exceeded"
```
Solution: You've made too many requests
Action: Wait a few minutes or upgrade to paid plan
```

### Error: "Resource has been exhausted"
```
Solution: API limit reached
Action: Check usage at Google Cloud Console
```

### Error: "Permission denied"
```
Solution: API key doesn't have required permissions
Action: Enable "Generative Language API" in Google Cloud Console
```

---

## 🔄 Regenerate API Key

If your key is compromised:

1. Go to https://aistudio.google.com/app/apikeys
2. Find the compromised key
3. Click **Delete** (trash icon)
4. Click **Create API Key**
5. Copy the new key
6. Update your code with new key
7. Redeploy your app

---

## 💾 Secure Storage (Advanced)

### For Production Apps:

#### Option 1: Android Secure Storage
```dart
import 'flutter_secure_storage/flutter_secure_storage.dart';

const secureStorage = FlutterSecureStorage();

// Save key
await secureStorage.write(
  key: 'gemini_api_key',
  value: 'YOUR_API_KEY',
);

// Read key
final apiKey = await secureStorage.read(key: 'gemini_api_key');
GeminiReportService.initialize(apiKey ?? '');
```

#### Option 2: Firebase Remote Config
```dart
import 'firebase_remote_config/firebase_remote_config.dart';

final remoteConfig = FirebaseRemoteConfig.instance;
await remoteConfig.setConfigSettings(
  RemoteConfigSettings(
    fetchTimeout: Duration(seconds: 10),
    minimumFetchInterval: Duration(hours: 1),
  ),
);
await remoteConfig.fetchAndActivate();
final apiKey = remoteConfig.getString('gemini_api_key');
GeminiReportService.initialize(apiKey);
```

#### Option 3: Backend Server
```dart
// Store API key on your backend
// Your app requests analysis from backend
// Backend calls Gemini API with its own key
// Results returned to app
```

---

## 📊 Monitoring & Analytics

Track your API usage:

```dart
int requestCount = 0;
Duration totalTime = Duration.zero;

Future<void> analyzeWithTracking(File file) async {
  final startTime = DateTime.now();
  
  try {
    final result = await GeminiReportService.uploadReport(file, userId);
    
    requestCount++;
    totalTime += DateTime.now().difference(startTime);
    
    print('Request #$requestCount completed');
    print('Average time: ${totalTime.inSeconds / requestCount}s');
    
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## ✅ Checklist Before Deployment

- [ ] API key added to code
- [ ] pubspec.yaml has google_generative_ai
- [ ] No hardcoded test keys in final build
- [ ] Error handling implemented
- [ ] Tested with real reports
- [ ] Tested on target devices
- [ ] Rate limiting considered
- [ ] Cost monitoring set up
- [ ] Secure storage configured
- [ ] Documentation updated

---

## 🎯 Next Steps

1. ✅ Get API key from Google AI Studio
2. ✅ Add key to main.dart or medical_reports_screen.dart
3. ✅ Run `flutter pub get`
4. ✅ Run `flutter run`
5. ✅ Test with a medical report
6. ✅ Celebrate! 🎉

---

**Need Help?**
- Google AI Studio: https://aistudio.google.com
- Documentation: https://ai.google.dev/docs
- Issue Tracker: Check your API logs in Google Cloud Console

**Last Updated:** March 6, 2026
