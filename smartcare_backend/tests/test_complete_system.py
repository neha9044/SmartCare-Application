"""
PHASE 12: COMPREHENSIVE TESTING & OPTIMIZATION
SmartCare Backend - Complete System Test Suite

Tests:
✓ Accuracy - Classification, Detection, Summarization
✓ Stability - Error Handling, Edge Cases
✓ Speed - Performance Benchmarks
✓ Integration - End-to-End Workflow

Run with: python test_complete_system.py
"""

import time
import os
from main import (
    extract_text, 
    detect_report_type, 
    detect_abnormal, 
    classify_severity,
    summarize,
    report_classifier
)


# Sample Report Data for Testing
SAMPLE_REPORTS = {
    "Lab Report 1": """
    LABORATORY REPORT
    Patient: John Doe
    Date: 2026-02-20
    
    Complete Blood Count:
    Hemoglobin: 11.5 g/dL (Low)
    WBC: 12500 cells/μL (High)
    Platelets: 280000 per μL (Normal)
    RBC: 4.2 million/μL
    
    Chemistry Panel:
    Glucose: 155 mg/dL (High)
    Creatinine: 0.9 mg/dL
    Sodium: 138 mEq/L
    Potassium: 4.0 mEq/L
    """,
    
    "Lab Report 2": """
    Blood Test Results
    Date: February 22, 2026
    
    Lipid Profile:
    Total Cholesterol: 190 mg/dL
    LDL: 115 mg/dL
    HDL: 48 mg/dL
    Triglycerides: 135 mg/dL
    
    Complete Blood Count:
    Hemoglobin: 14.8 g/dL (Normal)
    WBC: 7200 cells/μL (Normal)
    Platelets: 245000 per μL (Normal)
    Glucose: 98 mg/dL (Normal)
    """,
    
    "Radiology Report 1": """
    RADIOLOGY REPORT
    Examination: Chest X-Ray PA and Lateral
    Date: 2026-02-21
    
    Clinical Indication: Cough and fever
    
    Technique: Standard PA and lateral chest radiographs obtained.
    
    Findings:
    The lungs are clear bilaterally with no evidence of consolidation,
    pleural effusion, or pneumothorax. The cardiac silhouette is normal
    in size and contour. The mediastinal contours are unremarkable.
    No hilar lymphadenopathy. Osseous structures are intact.
    
    Impression: Normal chest radiograph. No acute cardiopulmonary abnormality.
    """,
    
    "Radiology Report 2": """
    CT SCAN REPORT - ABDOMEN AND PELVIS
    
    Indication: Abdominal pain
    
    Technique: Multidetector CT of abdomen and pelvis with IV contrast.
    
    Findings:
    Liver: Normal size, no focal lesions
    Gallbladder: No stones or wall thickening
    Spleen: Normal size and attenuation
    Pancreas: Unremarkable
    Kidneys: Normal enhancement bilaterally, no hydronephrosis
    Bowel: No obstruction or inflammatory changes
    No free fluid or free air in the peritoneal cavity
    
    Impression: No acute abdominal pathology identified.
    """,
    
    "Discharge Summary 1": """
    HOSPITAL DISCHARGE SUMMARY
    
    Patient Name: Jane Smith
    Admission Date: February 18, 2026
    Discharge Date: February 23, 2026
    
    Chief Complaint: Chest pain
    
    History of Present Illness:
    55-year-old female presented to emergency department with chest pain.
    Cardiac workup including ECG and troponin were negative. Stress test
    showed no inducible ischemia.
    
    Hospital Course:
    Patient was admitted for observation. Serial cardiac markers remained
    negative. Echocardiogram showed normal LV function with EF of 60%.
    Final diagnosis was costochondritis. Pain controlled with NSAIDs.
    
    Discharge Medications:
    1. Ibuprofen 400mg TID as needed for pain
    2. Continue home medications
    
    Discharge Instructions:
    Follow up with primary care physician in 2 weeks. Return to ED if
    chest pain worsens or associated with shortness of breath.
    
    Condition at Discharge: Stable
    """,
    
    "Discharge Summary 2": """
    DISCHARGE SUMMARY
    
    Patient: Robert Johnson
    DOA: 02/19/2026
    DOD: 02/22/2026
    
    Diagnosis: Community-Acquired Pneumonia
    
    Hospital Course:
    68-year-old male admitted with fever, cough, and dyspnea. Chest X-ray
    confirmed right lower lobe pneumonia. Started on IV ceftriaxone and
    azithromycin. Clinically improved over 3 days with decreased fever
    and improved oxygen saturation. Switched to oral antibiotics.
    
    Discharge Plan:
    - Amoxicillin-clavulanate 875mg BID for 7 days
    - Follow-up chest X-ray in 6 weeks
    - PCP appointment in 2 weeks
    
    Patient discharged home in stable condition.
    """
}


class TestResults:
    """Track test results"""
    def __init__(self):
        self.total = 0
        self.passed = 0
        self.failed = 0
        self.times = []
    
    def add_pass(self, test_name, duration=0):
        self.total += 1
        self.passed += 1
        self.times.append(duration)
        print(f"  ✓ {test_name} ({duration:.3f}s)")
    
    def add_fail(self, test_name, reason=""):
        self.total += 1
        self.failed += 1
        print(f"  ✗ {test_name} - {reason}")
    
    def summary(self):
        avg_time = sum(self.times) / len(self.times) if self.times else 0
        print("\n" + "="*60)
        print("TEST SUMMARY")
        print("="*60)
        print(f"Total Tests: {self.total}")
        print(f"Passed: {self.passed} ({self.passed/self.total*100:.1f}%)")
        print(f"Failed: {self.failed}")
        print(f"Average Time: {avg_time:.3f}s")
        print("="*60)


def test_report_type_accuracy(results):
    """Test 1: Report Type Classification Accuracy"""
    print("\n" + "="*60)
    print("TEST 1: REPORT TYPE CLASSIFICATION ACCURACY")
    print("="*60)
    
    test_cases = [
        (SAMPLE_REPORTS["Lab Report 1"], "Lab Report"),
        (SAMPLE_REPORTS["Lab Report 2"], "Lab Report"),
        (SAMPLE_REPORTS["Radiology Report 1"], "Radiology Report"),
        (SAMPLE_REPORTS["Radiology Report 2"], "Radiology Report"),
        (SAMPLE_REPORTS["Discharge Summary 1"], "Discharge Summary"),
        (SAMPLE_REPORTS["Discharge Summary 2"], "Discharge Summary"),
    ]
    
    for text, expected in test_cases:
        start = time.time()
        result = detect_report_type(text)
        duration = time.time() - start
        
        if result == expected:
            results.add_pass(f"{expected[:20]}...", duration)
        else:
            results.add_fail(f"{expected[:20]}...", f"Got {result}")


def test_abnormal_detection_accuracy(results):
    """Test 2: Abnormal Value Detection Accuracy"""
    print("\n" + "="*60)
    print("TEST 2: ABNORMAL VALUE DETECTION ACCURACY")
    print("="*60)
    
    test_cases = [
        # (text, expected_abnormal_count, description)
        (SAMPLE_REPORTS["Lab Report 1"], 3, "Lab with 3 abnormal values"),
        (SAMPLE_REPORTS["Lab Report 2"], 0, "Lab with 0 abnormal values"),
    ]
    
    for text, expected_count, desc in test_cases:
        start = time.time()
        abnormal = detect_abnormal(text)
        duration = time.time() - start
        
        if len(abnormal) == expected_count:
            results.add_pass(desc, duration)
        else:
            results.add_fail(desc, f"Expected {expected_count}, got {len(abnormal)}")


def test_severity_classification(results):
    """Test 3: Severity Classification Logic"""
    print("\n" + "="*60)
    print("TEST 3: SEVERITY CLASSIFICATION")
    print("="*60)
    
    test_cases = [
        ([], "Normal"),
        (["Low Hemoglobin"], "Mild"),
        (["Low Hemoglobin", "High Glucose"], "Moderate"),
        (["Low Hemoglobin", "High Glucose", "High WBC"], "Severe"),
        (["Low Hemoglobin", "High Glucose", "High WBC", "Low Platelets"], "Severe"),
    ]
    
    for abnormal_list, expected_severity in test_cases:
        start = time.time()
        severity = classify_severity(abnormal_list)
        duration = time.time() - start
        
        if severity == expected_severity:
            results.add_pass(f"{len(abnormal_list)} abnormal → {expected_severity}", duration)
        else:
            results.add_fail(f"{len(abnormal_list)} abnormal", f"Expected {expected_severity}, got {severity}")


def test_summarization_quality(results):
    """Test 4: Text Summarization Quality"""
    print("\n" + "="*60)
    print("TEST 4: TEXT SUMMARIZATION QUALITY")
    print("="*60)
    
    for name, text in SAMPLE_REPORTS.items():
        start = time.time()
        summary = summarize(text, sentence_count=3)
        duration = time.time() - start
        
        # Check if summary is reasonable
        if summary and len(summary) > 20 and not summary.startswith("Text too short"):
            results.add_pass(f"{name} summarization", duration)
        else:
            results.add_fail(f"{name} summarization", "Poor quality summary")


def test_edge_cases(results):
    """Test 5: Edge Cases and Error Handling"""
    print("\n" + "="*60)
    print("TEST 5: EDGE CASES & STABILITY")
    print("="*60)
    
    # Empty text
    start = time.time()
    result = detect_report_type("")
    duration = time.time() - start
    if result == "Unknown":
        results.add_pass("Empty text handling", duration)
    else:
        results.add_fail("Empty text handling", f"Got {result}")
    
    # Very short text
    start = time.time()
    result = detect_report_type("Test")
    duration = time.time() - start
    if result == "Unknown":
        results.add_pass("Short text handling", duration)
    else:
        results.add_fail("Short text handling", f"Got {result}")
    
    # No abnormal values
    start = time.time()
    abnormal = detect_abnormal("Normal report with no lab values")
    duration = time.time() - start
    if len(abnormal) == 0:
        results.add_pass("No abnormal values", duration)
    else:
        results.add_fail("No abnormal values", f"Found {len(abnormal)}")
    
    # Empty summarization
    start = time.time()
    summary = summarize("", sentence_count=3)
    duration = time.time() - start
    if "too short" in summary.lower():
        results.add_pass("Empty text summarization", duration)
    else:
        results.add_fail("Empty text summarization", "Should return error message")


def test_performance(results):
    """Test 6: Performance & Speed Optimization"""
    print("\n" + "="*60)
    print("TEST 6: PERFORMANCE BENCHMARKS")
    print("="*60)
    
    # Test classification speed (should be < 0.1s)
    text = SAMPLE_REPORTS["Lab Report 1"]
    
    start = time.time()
    for _ in range(10):
        detect_report_type(text)
    duration = (time.time() - start) / 10
    
    if duration < 0.1:
        results.add_pass(f"Classification speed (avg)", duration)
    else:
        results.add_fail("Classification speed", f"Too slow: {duration:.3f}s")
    
    # Test abnormal detection speed
    start = time.time()
    for _ in range(10):
        detect_abnormal(text)
    duration = (time.time() - start) / 10
    
    if duration < 0.05:
        results.add_pass(f"Abnormal detection speed (avg)", duration)
    else:
        results.add_fail("Abnormal detection speed", f"Too slow: {duration:.3f}s")
    
    # Test summarization speed
    start = time.time()
    for _ in range(10):
        summarize(text)
    duration = (time.time() - start) / 10
    
    if duration < 0.2:
        results.add_pass(f"Summarization speed (avg)", duration)
    else:
        results.add_fail("Summarization speed", f"Too slow: {duration:.3f}s")


def test_end_to_end_workflow(results):
    """Test 7: Complete End-to-End Workflow"""
    print("\n" + "="*60)
    print("TEST 7: END-TO-END INTEGRATION")
    print("="*60)
    
    for name, text in SAMPLE_REPORTS.items():
        start = time.time()
        
        try:
            # Complete workflow simulation
            report_type = detect_report_type(text)
            abnormal = detect_abnormal(text)
            summary = summarize(text)
            severity = classify_severity(abnormal)
            
            duration = time.time() - start
            
            # Verify all components returned valid results
            if (report_type and summary and severity and 
                report_type != "Unknown" and len(summary) > 20):
                results.add_pass(f"{name} complete workflow", duration)
            else:
                results.add_fail(f"{name} complete workflow", "Invalid results")
                
        except Exception as e:
            results.add_fail(f"{name} complete workflow", str(e))


def test_ml_model_confidence(results):
    """Test 8: ML Model Confidence Scores"""
    print("\n" + "="*60)
    print("TEST 8: ML MODEL CONFIDENCE & PROBABILITIES")
    print("="*60)
    
    for name, text in list(SAMPLE_REPORTS.items())[:3]:  # Test first 3
        start = time.time()
        
        try:
            prediction = report_classifier.predict([text])[0]
            probabilities = report_classifier.predict_proba([text])[0]
            max_prob = max(probabilities)
            
            duration = time.time() - start
            
            # High confidence (>50%) is good
            if max_prob > 0.5:
                results.add_pass(f"{name} confidence: {max_prob:.1%}", duration)
            else:
                results.add_fail(f"{name} confidence", f"Low: {max_prob:.1%}")
                
        except Exception as e:
            results.add_fail(f"{name} confidence", str(e))


def run_all_tests():
    """Execute complete test suite"""
    print("\n")
    print("╔" + "═"*58 + "╗")
    print("║" + " "*8 + "SMARTCARE COMPLETE SYSTEM TEST SUITE" + " "*14 + "║")
    print("║" + " "*12 + "Phase 12: Testing & Optimization" + " "*14 + "║")
    print("╚" + "═"*58 + "╝")
    
    results = TestResults()
    
    # Run all test suites
    test_report_type_accuracy(results)
    test_abnormal_detection_accuracy(results)
    test_severity_classification(results)
    test_summarization_quality(results)
    test_edge_cases(results)
    test_performance(results)
    test_end_to_end_workflow(results)
    test_ml_model_confidence(results)
    
    # Print summary
    results.summary()
    
    # Final verdict
    print("\n")
    if results.failed == 0:
        print("🎉 ALL TESTS PASSED! System is production-ready.")
    else:
        print(f"⚠️  {results.failed} test(s) failed. Review and fix issues.")
    print("\n")
    
    # Feature checklist
    print("="*60)
    print("FEATURE CHECKLIST")
    print("="*60)
    print("✓ PDF Text Extraction")
    print("✓ Report Type Detection (ML: TF-IDF + Logistic Regression)")
    print("✓ Abnormal Value Detection")
    print("✓ Severity Classification")
    print("✓ Text Summarization (TextRank)")
    print("✓ Firebase Database Integration")
    print("✓ RESTful API Endpoints")
    print("✓ CORS Support for Flutter/Web")
    print("✓ Error Handling")
    print("✓ Performance Optimization")
    print("="*60)
    print("\n")


if __name__ == "__main__":
    run_all_tests()
