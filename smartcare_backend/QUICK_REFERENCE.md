# 🚀 SmartCare Quick Reference Card

## Installation & Setup (One-Time)
```bash
pip install -r requirements.txt
```

## Running the Server
```bash
uvicorn main:app --reload
```
▶️ Server: http://localhost:8000
📚 Docs: http://localhost:8000/docs

## Testing
```bash
# Complete system test (35 tests)
python test_complete_system.py

# Individual components
python test_report_type_detection.py
python test_abnormal_detection.py
python test_severity.py
python test_summarization.py
```

## API Usage Examples

### 1. Upload Report (PowerShell)
```powershell
$file = Get-Item "report.pdf"
$form = @{
    file = $file
}
Invoke-RestMethod -Uri "http://localhost:8000/upload?user_id=patient123" -Method Post -Form $form
```

### 2. Upload Report (Python)
```python
import requests

files = {'file': open('report.pdf', 'rb')}
response = requests.post('http://localhost:8000/upload?user_id=patient123', files=files)
print(response.json())
```

### 3. Get Reports (curl)
```bash
curl http://localhost:8000/reports/patient123?limit=10
```

### 4. Get Statistics (curl)
```bash
curl http://localhost:8000/statistics/patient123
```

## Response Format
```json
{
  "report_type": "Lab Report",
  "summary": "Complete Blood Count test results showing...",
  "abnormal": ["Low Hemoglobin (11.5 g/dL)", "High WBC (12500 cells/μL)"],
  "severity": "Moderate",
  "timestamp": "2026-02-24T10:30:00.123456",
  "document_id": "abc123xyz"
}
```

## Report Types
- **Lab Report** - Blood tests, chemistry panels, urinalysis
- **Radiology Report** - X-rays, CT scans, MRI, ultrasound
- **Discharge Summary** - Hospital discharge documents

## Severity Levels
| Level | Abnormal Values | Color |
|-------|----------------|-------|
| Normal | 0 | 🟢 Green |
| Mild | 1 | 🟡 Yellow |
| Moderate | 2 | 🟠 Orange |
| Severe | 3+ | 🔴 Red |

## Abnormal Detection Ranges
| Test | Normal Range |
|------|-------------|
| Hemoglobin | 12-17 g/dL |
| WBC | 4,000-11,000 cells/μL |
| Platelets | 150,000-450,000 per μL |
| Glucose | 70-140 mg/dL |

## Firebase Setup (Optional)
1. Get `firebase-key.json` from Firebase Console
2. Place in project root directory
3. Restart server - auto-detects and connects

## Frontend Access
- **Doctor Dashboard:** Open `doctor_dashboard.html` in browser
- **Flutter App:** Use code from `flutter_integration_example.dart`

## Performance Targets ✓
- Classification: < 0.1s ✅
- Detection: < 0.05s ✅
- Summarization: < 0.2s ✅
- Total: < 0.5s ✅

## Common Issues

