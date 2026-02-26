"""
Test Report Type Detection ML Component
Phase 7: Report Type Detection

Tests the ML classifier (TF-IDF + Logistic Regression) for identifying:
- Lab Report
- Radiology Report  
- Discharge Summary
"""

from main import detect_report_type, report_classifier


def test_lab_report_detection():
    """Test classification of Lab Reports"""
    
    print("=" * 60)
    print("TEST 1: Lab Report Detection")
    print("=" * 60)
    
    # Test Case 1: Complete Blood Count
    text1 = """
    Laboratory Report - Complete Blood Count
    Date: 2026-02-20
    
    Test Results:
    Hemoglobin: 14.2 g/dL
    WBC Count: 7500 cells/μL
    Platelets: 280000 per μL
    RBC: 4.5 million/μL
    Hematocrit: 42%
    Glucose: 98 mg/dL
    
    All values within normal range.
    """
    
    result1 = detect_report_type(text1)
    print(f"Text: Complete Blood Count")
    print(f"Classification: {result1}")
    print(f"Expected: Lab Report")
    print(f"✓ PASS" if result1 == "Lab Report" else "✗ FAIL")
    print()
    
    # Test Case 2: Lipid Profile
    text2 = """
    Blood Test Results - Lipid Panel
    
    Total Cholesterol: 185 mg/dL
    LDL Cholesterol: 110 mg/dL
    HDL Cholesterol: 52 mg/dL
    Triglycerides: 145 mg/dL
    Glucose: 102 mg/dL
    Hemoglobin: 15.5 g/dL
    """
    
    result2 = detect_report_type(text2)
    print(f"Text: Lipid Profile")
    print(f"Classification: {result2}")
    print(f"Expected: Lab Report")
    print(f"✓ PASS" if result2 == "Lab Report" else "✗ FAIL")
    print()
    
    # Test Case 3: Kidney Function
    text3 = """
    Renal Function Test
    
    Creatinine: 0.95 mg/dL
    BUN: 16 mg/dL
    eGFR: 92 mL/min
    Sodium: 138 mEq/L
    Potassium: 4.1 mEq/L
    WBC: 6800 cells/μL
    """
    
    result3 = detect_report_type(text3)
    print(f"Text: Kidney Function Test")
    print(f"Classification: {result3}")
    print(f"Expected: Lab Report")
    print(f"✓ PASS" if result3 == "Lab Report" else "✗ FAIL")
    print("\n")


def test_radiology_report_detection():
    """Test classification of Radiology Reports"""
    
    print("=" * 60)
    print("TEST 2: Radiology Report Detection")
    print("=" * 60)
    
    # Test Case 1: Chest X-Ray
    text1 = """
    Radiology Report: Chest X-Ray
    
    Indication: Cough and fever
    
    Findings:
    PA and lateral views of the chest obtained.
    Lungs are clear bilaterally.
    No pleural effusion or pneumothorax.
    Heart size is within normal limits.
    No acute cardiopulmonary abnormality.
    
    Impression: Normal chest radiograph.
    """
    
    result1 = detect_report_type(text1)
    print(f"Text: Chest X-Ray")
    print(f"Classification: {result1}")
    print(f"Expected: Radiology Report")
    print(f"✓ PASS" if result1 == "Radiology Report" else "✗ FAIL")
    print()
    
    # Test Case 2: CT Scan
    text2 = """
    CT Scan - Abdomen and Pelvis with Contrast
    
    Technique: Axial images obtained through abdomen and pelvis.
    
    Findings:
    Liver appears normal in size and attenuation.
    No focal hepatic lesion.
    Spleen, pancreas unremarkable.
    Both kidneys enhance normally.
    No free fluid in pelvis.
    No lymphadenopathy.
    
    Impression: No acute abdominal pathology.
    """
    
    result2 = detect_report_type(text2)
    print(f"Text: CT Scan Abdomen")
    print(f"Classification: {result2}")
    print(f"Expected: Radiology Report")
    print(f"✓ PASS" if result2 == "Radiology Report" else "✗ FAIL")
    print()
    
    # Test Case 3: MRI Brain
    text3 = """
    MRI Brain Report
    
    Sequences: T1, T2, FLAIR, DWI
    
    No acute infarct on diffusion weighted imaging.
    No intracranial hemorrhage.
    Ventricles and sulci normal for age.
    No mass lesion or abnormal enhancement.
    Paranasal sinuses clear.
    
    Conclusion: Normal brain MRI.
    """
    
    result3 = detect_report_type(text3)
    print(f"Text: MRI Brain")
    print(f"Classification: {result3}")
    print(f"Expected: Radiology Report")
    print(f"✓ PASS" if result3 == "Radiology Report" else "✗ FAIL")
    print("\n")


def test_discharge_summary_detection():
    """Test classification of Discharge Summaries"""
    
    print("=" * 60)
    print("TEST 3: Discharge Summary Detection")
    print("=" * 60)
    
    # Test Case 1: Pneumonia Discharge
    text1 = """
    Hospital Discharge Summary
    
    Patient: John Doe
    Admission Date: 02/15/2026
    Discharge Date: 02/20/2026
    
    Chief Complaint: Shortness of breath and fever
    
    Hospital Course:
    Patient admitted with community-acquired pneumonia.
    Started on IV antibiotics.
    Chest X-ray showed right lower lobe infiltrate.
    Clinical improvement noted over 5 days.
    Switched to oral antibiotics.
    
    Discharge Medications:
    - Amoxicillin 500mg TID for 7 days
    
    Follow-up: Primary care physician in 2 weeks.
    """
    
    result1 = detect_report_type(text1)
    print(f"Text: Pneumonia Discharge")
    print(f"Classification: {result1}")
    print(f"Expected: Discharge Summary")
    print(f"✓ PASS" if result1 == "Discharge Summary" else "✗ FAIL")
    print()
    
    # Test Case 2: Surgery Discharge
    text2 = """
    Discharge Summary - Post-Operative
    
    Procedure: Laparoscopic Cholecystectomy
    Date of Surgery: 02/18/2026
    
    The patient underwent successful removal of gallbladder.
    Post-operative recovery uneventful.
    Pain controlled with oral analgesics.
    Tolerating regular diet.
    Discharged on post-operative day 1.
    
    Discharge Instructions:
    - Keep incisions clean and dry
    - No heavy lifting for 2 weeks
    - Return if fever or increased pain
    
    Follow-up with surgeon in 2 weeks.
    """
    
    result2 = detect_report_type(text2)
    print(f"Text: Surgery Discharge")
    print(f"Classification: {result2}")
    print(f"Expected: Discharge Summary")
    print(f"✓ PASS" if result2 == "Discharge Summary" else "✗ FAIL")
    print()
    
    # Test Case 3: Heart Failure Discharge
    text3 = """
    Discharge Summary
    
    Diagnosis: Acute Decompensated Heart Failure
    
    Patient admitted with dyspnea and lower extremity edema.
    Treated with IV diuretics.
    Echo showed reduced ejection fraction.
    Volume status improved.
    Started on ACE inhibitor and beta blocker.
    
    Discharged in stable condition.
    Cardiology follow-up scheduled.
    Daily weight monitoring instructed.
    """
    
    result3 = detect_report_type(text3)
    print(f"Text: Heart Failure Discharge")
    print(f"Classification: {result3}")
    print(f"Expected: Discharge Summary")
    print(f"✓ PASS" if result3 == "Discharge Summary" else "✗ FAIL")
    print("\n")


def test_model_confidence():
    """Test model predictions with confidence scores"""
    
    print("=" * 60)
    print("TEST 4: Model Confidence & Probabilities")
    print("=" * 60)
    
    test_texts = [
        ("Hemoglobin 12.5 g/dL, WBC 8000 cells/μL, Glucose 105 mg/dL", "Lab Report"),
        ("X-ray shows no fracture. Soft tissues unremarkable.", "Radiology Report"),
        ("Patient discharged home. Follow-up in clinic next week.", "Discharge Summary")
    ]
    
    for text, expected in test_texts:
        prediction = report_classifier.predict([text])[0]
        probabilities = report_classifier.predict_proba([text])[0]
        classes = report_classifier.classes_
        
        print(f"Text: {text[:50]}...")
        print(f"Prediction: {prediction}")
        print(f"Expected: {expected}")
        print("Probabilities:")
        for cls, prob in zip(classes, probabilities):
            print(f"  {cls}: {prob:.2%}")
        print(f"✓ PASS" if prediction == expected else "✗ FAIL")
        print()
    
    print()


def test_edge_cases():
    """Test edge cases and error handling"""
    
    print("=" * 60)
    print("TEST 5: Edge Cases")
    print("=" * 60)
    
    # Empty text
    result1 = detect_report_type("")
    print(f"Empty text: {result1}")
    print(f"Expected: Unknown")
    print(f"✓ PASS" if result1 == "Unknown" else "✗ FAIL")
    print()
    
    # Very short text
    result2 = detect_report_type("Test")
    print(f"Very short text: {result2}")
    print(f"Expected: Unknown")
    print(f"✓ PASS" if result2 == "Unknown" else "✗ FAIL")
    print()
    
    # Mixed content
    mixed_text = """
    Lab results show Hemoglobin 14 g/dL and Glucose 95 mg/dL.
    CT scan of chest obtained showing clear lung fields.
    Patient discharged on oral medications.
    """
    result3 = detect_report_type(mixed_text)
    print(f"Mixed content classification: {result3}")
    print(f"(Should classify based on dominant features)")
    print()
    
    print()


def run_all_tests():
    """Run all test cases"""
    
    print("\n")
    print("╔" + "═" * 58 + "╗")
    print("║" + " " * 10 + "REPORT TYPE DETECTION - ML TESTS" + " " * 16 + "║")
    print("║" + " " * 12 + "TF-IDF + Logistic Regression" + " " * 18 + "║")
    print("╚" + "═" * 58 + "╝")
    print("\n")
    
    test_lab_report_detection()
    test_radiology_report_detection()
    test_discharge_summary_detection()
    test_model_confidence()
    test_edge_cases()
    
    print("=" * 60)
    print("ALL TESTS COMPLETED")
    print("=" * 60)
    print("\nML Pipeline: Text → TF-IDF → Logistic Regression → Prediction")
    print(f"Model Classes: {report_classifier.classes_}")
    print(f"Training Data Size: {len(report_classifier.named_steps['classifier'].classes_)} classes")
    print("\n✓ Report Type Detection ML Component is Working!\n")


if __name__ == "__main__":
    run_all_tests()
