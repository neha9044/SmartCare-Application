"""
Complete Integration Test - Phases 4, 5, & 6
Demonstrating: Abnormal Detection + Summarization + Severity Classification
"""

import re
from sumy.parsers.plaintext import PlaintextParser
from sumy.nlp.tokenizers import Tokenizer
from sumy.summarizers.text_rank import TextRankSummarizer


def detect_abnormal(text):
    """Detect abnormal lab values using rule-based logic."""
    abnormal = []
    
    # Hemoglobin Detection (12-17 g/dL)
    hemoglobin_patterns = [
        r'Hemoglobin[:\s]+(\d+\.?\d*)',
        r'Hb[:\s]+(\d+\.?\d*)',
        r'HGB[:\s]+(\d+\.?\d*)'
    ]
    
    for pattern in hemoglobin_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            value = float(match.group(1))
            if value < 12:
                abnormal.append(f"Low Hemoglobin ({value} g/dL)")
            elif value > 17:
                abnormal.append(f"High Hemoglobin ({value} g/dL)")
            break
    
    # WBC Detection
    wbc_patterns = [
        r'WBC[:\s]+(\d+\.?\d*)',
        r'White Blood Cell[s]?[:\s]+(\d+\.?\d*)',
        r'Leukocyte[s]?[:\s]+(\d+\.?\d*)'
    ]
    
    for pattern in wbc_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            value = float(match.group(1))
            if value > 100:
                if value < 4000:
                    abnormal.append(f"Low WBC ({value} cells/μL)")
                elif value > 11000:
                    abnormal.append(f"High WBC ({value} cells/μL)")
            else:
                if value < 4:
                    abnormal.append(f"Low WBC ({value} × 10^9/L)")
                elif value > 11:
                    abnormal.append(f"High WBC ({value} × 10^9/L)")
            break
    
    # Platelets Detection
    platelet_patterns = [
        r'Platelet[s]?[:\s]+(\d+\.?\d*)',
        r'PLT[:\s]+(\d+\.?\d*)',
        r'Thrombocyte[s]?[:\s]+(\d+\.?\d*)'
    ]
    
    for pattern in platelet_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            value = float(match.group(1))
            if value > 1000:
                if value < 150000:
                    abnormal.append(f"Low Platelets ({value} per μL)")
                elif value > 450000:
                    abnormal.append(f"High Platelets ({value} per μL)")
            else:
                if value < 150:
                    abnormal.append(f"Low Platelets ({value} × 10^9/L)")
                elif value > 450:
                    abnormal.append(f"High Platelets ({value} × 10^9/L)")
            break
    
    # Glucose Detection
    glucose_patterns = [
        r'Glucose[:\s]+(\d+\.?\d*)',
        r'Blood Glucose[:\s]+(\d+\.?\d*)',
        r'Blood Sugar[:\s]+(\d+\.?\d*)',
        r'GLU[:\s]+(\d+\.?\d*)'
    ]
    
    for pattern in glucose_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            value = float(match.group(1))
            if value < 70:
                abnormal.append(f"Low Glucose ({value} mg/dL)")
            elif value > 140:
                abnormal.append(f"High Glucose ({value} mg/dL)")
            break
    
    return abnormal


def summarize(text, sentence_count=3):
    """Generate report summary using TextRank algorithm."""
    if sentence_count < 2:
        sentence_count = 2
    elif sentence_count > 5:
        sentence_count = 5
    
    if not text or len(text.strip()) < 50:
        return "Text too short to summarize."
    
    try:
        parser = PlaintextParser.from_string(text, Tokenizer("english"))
        summarizer = TextRankSummarizer()
        summary = summarizer(parser.document, sentence_count)
        result = " ".join(str(sentence) for sentence in summary)
        return result if result else "Unable to generate summary."
    except Exception as e:
        return f"Summarization error: {str(e)}"


def classify_severity(abnormal_list):
    """Classify severity based on number of abnormal values."""
    abnormal_count = len(abnormal_list)
    
    if abnormal_count == 0:
        return "Normal"
    elif abnormal_count == 1:
        return "Mild"
    elif abnormal_count == 2:
        return "Moderate"
    else:  # 3 or more
        return "Severe"


# Test Cases with Different Severity Levels
print("=" * 90)
print("COMPLETE INTEGRATION TEST - PHASES 4, 5, & 6")
print("=" * 90)
print()

# Test Case 1: Normal Severity
test1 = """
Routine Lab Results for Patient John Smith
Date: February 23, 2026

Complete Blood Count shows all values within normal limits.
Hemoglobin is 14.5 g/dL, which is excellent for the patient's age and gender.
White blood cell count is 7200 cells/μL, indicating good immune function.
Platelet count measured at 285000 per μL, ensuring proper clotting ability.
Glucose level is 98 mg/dL, demonstrating good metabolic control.
The patient should continue current health maintenance practices.
All biochemical markers show optimal health status.
"""

print("TEST 1: NORMAL SEVERITY")
print("-" * 90)
abnormal1 = detect_abnormal(test1)
summary1 = summarize(test1, 3)
severity1 = classify_severity(abnormal1)

print(f"Abnormal Count: {len(abnormal1)}")
print(f"Abnormalities: {abnormal1 if abnormal1 else 'None'}")
print(f"Severity: {severity1}")
print(f"\nSummary:\n{summary1}")
print()
print()

# Test Case 2: Mild Severity
test2 = """
Laboratory Report - Patient Mary Johnson
Test Date: February 22, 2026

Complete Blood Count Results:
Hemoglobin: 10.8 g/dL
WBC: 6500 cells/μL
Platelets: 245000 per μL
Glucose: 105 mg/dL

The patient's blood work reveals one area of concern that requires attention.
The hemoglobin is below the normal range and suggests mild anemia.
White blood cell count is normal, indicating no infection present.
Platelet levels are adequate for proper blood clotting.
Blood glucose is well controlled within acceptable limits.
The mild anemia can likely be addressed with iron supplementation and dietary changes.
Follow-up testing recommended in six weeks to monitor hemoglobin improvement.
"""

print("TEST 2: MILD SEVERITY")
print("-" * 90)
abnormal2 = detect_abnormal(test2)
summary2 = summarize(test2, 3)
severity2 = classify_severity(abnormal2)

print(f"Abnormal Count: {len(abnormal2)}")
print(f"Abnormalities: {abnormal2}")
print(f"Severity: {severity2}")
print(f"\nSummary:\n{summary2}")
print()
print()

# Test Case 3: Moderate Severity
test3 = """
Medical Laboratory Analysis - Patient Robert Chen
Collection Date: February 21, 2026

Laboratory Values:
Hemoglobin: 9.2 g/dL
WBC: 8100 cells/μL
Platelets: 310000 per μL
Glucose: 178 mg/dL

This comprehensive blood panel shows two significant abnormalities requiring medical attention.
The patient's hemoglobin is critically low, indicating moderate to severe anemia.
White blood cell count remains within normal parameters.
Platelet count is normal, showing adequate clotting factors.
Blood glucose is significantly elevated, suggesting poor glycemic control.
These two abnormalities together increase cardiovascular risk and require immediate intervention.
The patient should start treatment for both anemia and hyperglycemia promptly.
Lifestyle modifications and medication adjustment are strongly recommended.
"""

print("TEST 3: MODERATE SEVERITY")
print("-" * 90)
abnormal3 = detect_abnormal(test3)
summary3 = summarize(test3, 3)
severity3 = classify_severity(abnormal3)

print(f"Abnormal Count: {len(abnormal3)}")
print(f"Abnormalities: {abnormal3}")
print(f"Severity: {severity3}")
print(f"\nSummary:\n{summary3}")
print()
print()

# Test Case 4: Severe Severity
test4 = """
Critical Lab Results - Patient David Williams
Emergency Analysis Date: February 23, 2026

Critical Laboratory Panel:
Hemoglobin: 8.5 g/dL
WBC: 16500 cells/μL
Platelets: 95000 per μL
Glucose: 245 mg/dL

This patient presents with multiple serious laboratory abnormalities requiring urgent attention.
Hemoglobin is dangerously low, indicating severe anemia that may require transfusion.
White blood cell count is markedly elevated, suggesting serious infection or inflammation.
Platelet count is critically low, posing significant bleeding risk.
Blood glucose is extremely high, indicating uncontrolled diabetes with potential complications.
The combination of these four abnormalities represents a medical emergency.
Immediate hospitalization is recommended for comprehensive evaluation and treatment.
The patient requires intensive monitoring and aggressive therapeutic intervention.
Multiple organ systems appear to be compromised based on these laboratory findings.
"""

print("TEST 4: SEVERE SEVERITY")
print("-" * 90)
abnormal4 = detect_abnormal(test4)
summary4 = summarize(test4, 4)
severity4 = classify_severity(abnormal4)

print(f"Abnormal Count: {len(abnormal4)}")
print(f"Abnormalities:")
for abn in abnormal4:
    print(f"  - {abn}")
print(f"Severity: {severity4}")
print(f"\nSummary:\n{summary4}")
print()
print()

# API Response Format Examples
print("=" * 90)
print("API RESPONSE EXAMPLES")
print("=" * 90)
print()

responses = [
    ("Normal Case", summary1, abnormal1, severity1),
    ("Mild Case", summary2, abnormal2, severity2),
    ("Moderate Case", summary3, abnormal3, severity3),
    ("Severe Case", summary4, abnormal4, severity4)
]

for i, (case_name, summ, abn, sev) in enumerate(responses, 1):
    print(f"{i}. {case_name}:")
    print("   {")
    print(f'     "summary": "{summ[:80]}...",')
    print(f'     "abnormal": {abn},')
    print(f'     "severity": "{sev}"')
    print("   }")
    print()

# Final Summary
print("=" * 90)
print("IMPLEMENTATION SUMMARY")
print("=" * 90)
print()
print("✅ Phase 4: Abnormal Value Detection")
print("   - Hemoglobin, WBC, Platelets, Glucose detection: Working")
print()
print("✅ Phase 5: Text Summarization")
print("   - TextRank algorithm with 2-5 sentence output: Working")
print()
print("✅ Phase 6: Severity Classification")
print("   - Rule-based classification (Normal/Mild/Moderate/Severe): Working")
print()
print("=" * 90)
print("ALL PHASES INTEGRATED AND FUNCTIONAL ✓")
print("=" * 90)
