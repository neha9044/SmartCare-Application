"""
Test script for Severity Classification
Phase 6 - Demonstrating rule-based severity classification
"""


def classify_severity(abnormal_list):
    """
    Classify severity based on number of abnormal values.
    
    Args:
        abnormal_list: List of abnormal findings from detect_abnormal()
    
    Returns:
        Severity level as string: "Normal", "Mild", "Moderate", or "Severe"
    
    Classification Logic:
        - 0 abnormal values → Normal
        - 1 abnormal value  → Mild
        - 2 abnormal values → Moderate
        - 3+ abnormal values → Severe
    """
    abnormal_count = len(abnormal_list)
    
    if abnormal_count == 0:
        return "Normal"
    elif abnormal_count == 1:
        return "Mild"
    elif abnormal_count == 2:
        return "Moderate"
    else:  # 3 or more
        return "Severe"


# Test Cases
print("=" * 80)
print("SEVERITY CLASSIFICATION - TEST RESULTS")
print("=" * 80)
print()

# Test Case 1: Normal (0 abnormalities)
test1_abnormal = []
severity1 = classify_severity(test1_abnormal)
print("Test 1 - No Abnormalities:")
print(f"  Abnormal Count: {len(test1_abnormal)}")
print(f"  Abnormal Values: {test1_abnormal if test1_abnormal else 'None'}")
print(f"  ➜ Severity: {severity1}")
print()

# Test Case 2: Mild (1 abnormality)
test2_abnormal = ["Low Hemoglobin (10.5 g/dL)"]
severity2 = classify_severity(test2_abnormal)
print("Test 2 - Single Abnormality:")
print(f"  Abnormal Count: {len(test2_abnormal)}")
print(f"  Abnormal Values: {test2_abnormal}")
print(f"  ➜ Severity: {severity2}")
print()

# Test Case 3: Moderate (2 abnormalities)
test3_abnormal = [
    "Low Hemoglobin (10.5 g/dL)",
    "High Glucose (165 mg/dL)"
]
severity3 = classify_severity(test3_abnormal)
print("Test 3 - Two Abnormalities:")
print(f"  Abnormal Count: {len(test3_abnormal)}")
print(f"  Abnormal Values:")
for abnormal in test3_abnormal:
    print(f"    - {abnormal}")
print(f"  ➜ Severity: {severity3}")
print()

# Test Case 4: Severe (3 abnormalities)
test4_abnormal = [
    "Low Hemoglobin (9.8 g/dL)",
    "High WBC (13500 cells/μL)",
    "High Glucose (195 mg/dL)"
]
severity4 = classify_severity(test4_abnormal)
print("Test 4 - Three Abnormalities:")
print(f"  Abnormal Count: {len(test4_abnormal)}")
print(f"  Abnormal Values:")
for abnormal in test4_abnormal:
    print(f"    - {abnormal}")
print(f"  ➜ Severity: {severity4}")
print()

# Test Case 5: Severe (4+ abnormalities)
test5_abnormal = [
    "Low Hemoglobin (10.5 g/dL)",
    "High WBC (14500 cells/μL)",
    "Low Platelets (135000 per μL)",
    "High Glucose (195 mg/dL)"
]
severity5 = classify_severity(test5_abnormal)
print("Test 5 - Four Abnormalities:")
print(f"  Abnormal Count: {len(test5_abnormal)}")
print(f"  Abnormal Values:")
for abnormal in test5_abnormal:
    print(f"    - {abnormal}")
print(f"  ➜ Severity: {severity5}")
print()

# Summary Table
print("=" * 80)
print("CLASSIFICATION SUMMARY TABLE")
print("=" * 80)
print()
print("┌─────────────────┬─────────────┬──────────────────────────────────┐")
print("│ Abnormal Count  │  Severity   │  Description                     │")
print("├─────────────────┼─────────────┼──────────────────────────────────┤")
print("│       0         │   Normal    │  All values within normal range  │")
print("│       1         │   Mild      │  One parameter abnormal          │")
print("│       2         │   Moderate  │  Two parameters abnormal         │")
print("│      3+         │   Severe    │  Three or more abnormal          │")
print("└─────────────────┴─────────────┴──────────────────────────────────┘")
print()

# Test Results Summary
print("=" * 80)
print("TEST RESULTS VERIFICATION")
print("=" * 80)
test_results = [
    (0, "Normal", severity1),
    (1, "Mild", severity2),
    (2, "Moderate", severity3),
    (3, "Severe", severity4),
    (4, "Severe", severity5)
]

all_passed = True
for count, expected, actual in test_results:
    status = "✓ PASS" if expected == actual else "✗ FAIL"
    if expected != actual:
        all_passed = False
    print(f"{status} - {count} abnormality(ies): Expected '{expected}', Got '{actual}'")

print()
if all_passed:
    print("✅ All tests passed!")
else:
    print("❌ Some tests failed!")

print()
print("=" * 80)
print("DELIVERABLE STATUS")
print("=" * 80)
print("✓ Rule-based classification: Implemented")
print("✓ 4 severity levels: Normal, Mild, Moderate, Severe")
print("✓ Count-based logic: Working correctly")
print("✓ Integration ready: Function available for API")
print()
print("Phase 6: Severity Classification - COMPLETE ✓")
print("=" * 80)
