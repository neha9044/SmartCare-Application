# untitled

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



# 🏥 SmartCare - AI Medical Report Analysis System

## 🚀 Quick Start

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Run server
uvicorn main:app --reload

# 3. Test system (optional)
python test_complete_system.py
```

Server runs at: **http://localhost:8000**

---

## ✨ Features

- **PDF Text Extraction** - Extract text from medical reports
- **Report Type Classification** - ML-based detection (Lab/Radiology/Discharge)
- **Abnormal Value Detection** - Hemoglobin, WBC, Platelets, Glucose
- **Severity Classification** - Normal/Mild/Moderate/Severe
- **Text Summarization** - AI-powered report summaries
- **Firebase Database** - Store reports and user history
- **RESTful API** - Easy integration with mobile/web apps

### API Response Format
```json
{
  "report_type": "Lab Report",
  "summary": "Complete Blood Count test results...",
  "abnormal": ["Low Hemoglobin (11.5 g/dL)"],
  "severity": "Mild",
  "timestamp": "2026-02-24T10:30:00",
  "document_id": "firebase_doc_id"
}
```

---

## 📡 API Endpoints

### 1. Health Check
```http
GET http://localhost:8000/
```

### 2. Upload & Analyze Report
```http
POST http://localhost:8000/upload?user_id=patient123
Content-Type: multipart/form-data
Body: file=report.pdf
```

### 3. Get User Reports
```http
GET http://localhost:8000/reports/patient123?limit=10
```

### 4. Get User Statistics
```http
GET http://localhost:8000/statistics/patient123
```

---

## 📁 Project Structure

```
smartcare_backend/
├── main.py                              # Main FastAPI application
├── requirements.txt                     # Python dependencies
├── firebase-key.json                    # Firebase credentials (download separately)
├── tests/                               # Test files
└── uploads/                             # Temporary PDF storage
```

---

## 🔧 Technologies

- **Backend:** FastAPI + Uvicorn
- **ML:** scikit-learn (TF-IDF + Logistic Regression)
- **NLP:** Sumy (TextRank)
- **PDF:** pdfplumber
- **Database:** Firebase Firestore

---

## 🏥 Abnormal Detection Ranges

| Parameter | Normal Range | Detection |
|-----------|-------------|-----------|
| Hemoglobin | 12-17 g/dL | Low/High |
| WBC | 4,000-11,000 cells/μL | Low/High |
| Platelets | 150,000-450,000 per μL | Low/High |
| Glucose | 70-140 mg/dL | Low/High |

---

## 🎯 Severity Classification

- **Normal:** 0 abnormal values
- **Mild:** 1 abnormal value  
- **Moderate:** 2 abnormal values
- **Severe:** 3+ abnormal values

---

## 🔐 Firebase Setup

1. Create Firebase project at [console.firebase.google.com](https://console.firebase.google.com/)
2. Enable Firestore Database
3. Download service account key → Save as `firebase-key.json` in the backend directory
4. Backend auto-detects and configures

**Note:** System works without Firebase (database features will be disabled)

---

## 🧪 Testing

```bash
# Run comprehensive tests
python tests/test_complete_system.py
```

---

## 📚 Need More Details?

- See `COMPLETE_DOCUMENTATION.md` for detailed documentation
- Check `flutter_integration_example.dart` for Flutter integration code
- Open `doctor_dashboard.html` for web dashboard example
