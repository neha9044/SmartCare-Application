"""
Quick script to test the trained model
"""
import pickle

# Load the trained model
with open('report_classifier_model.pkl', 'rb') as f:
    model = pickle.load(f)

print("\n" + "="*60)
print("🧪 TESTING TRAINED MODEL")
print("="*60)

print(f"\n✓ Model loaded successfully")
print(f"  Classes: {list(model.classes_)}")

# Test samples
test_samples = [
    ("LAB REPORT\n\nHemoglobin: 17.5 g/dL\nWBC: 13361 cells/uL\nGlucose: 156 mg/dL", "Lab Report"),
    ("RADIOLOGY REPORT\nExamination: Chest X-Ray\nFindings: bilateral pulmonary infiltrates", "Radiology Report"),
    ("DISCHARGE SUMMARY\nPatient discharged in stable condition", "Discharge Summary"),
]

print("\n📊 Prediction Tests:")
print("-" * 60)

correct = 0
for text, expected in test_samples:
    prediction = model.predict([text])[0]
    status = "✓" if prediction == expected else "✗"
    correct += (prediction == expected)
    
    print(f"\n{status} Expected: {expected}")
    print(f"  Got: {prediction}")
    print(f"  Sample: {text[:50]}...")

print("\n" + "="*60)
print(f"Accuracy: {correct}/{len(test_samples)} ({100*correct/len(test_samples):.0f}%)")
print("="*60 + "\n")
