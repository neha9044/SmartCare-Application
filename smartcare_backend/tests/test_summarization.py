"""
Test script for Text Summarization
Phase 5 - Demonstrating TextRank summarization with sumy
"""

from sumy.parsers.plaintext import PlaintextParser
from sumy.nlp.tokenizers import Tokenizer
from sumy.summarizers.text_rank import TextRankSummarizer


def summarize(text, sentence_count=3):
    """
    Generate report summary using TextRank algorithm.
    
    Args:
        text: Input text to summarize
        sentence_count: Number of sentences to extract (default: 3, range: 2-5)
    
    Returns:
        Summary as a string with 2-5 important sentences
    """
    # Validate sentence count is within range
    if sentence_count < 2:
        sentence_count = 2
    elif sentence_count > 5:
        sentence_count = 5
    
    # Handle empty or very short text
    if not text or len(text.strip()) < 50:
        return "Text too short to summarize."
    
    try:
        # Parse text and apply TextRank summarization
        parser = PlaintextParser.from_string(text, Tokenizer("english"))
        summarizer = TextRankSummarizer()
        
        # Extract top sentences
        summary = summarizer(parser.document, sentence_count)
        
        # Format output with proper spacing
        result = " ".join(str(sentence) for sentence in summary)
        
        return result if result else "Unable to generate summary."
        
    except Exception as e:
        return f"Summarization error: {str(e)}"


# Sample Medical Reports
print("=" * 80)
print("TEXT SUMMARIZATION - TEST RESULTS (TextRank Algorithm)")
print("=" * 80)
print()

# Test Case 1: Comprehensive Medical Report
test1 = """
Patient Name: John Doe
Date: February 23, 2026
Chief Complaint: The patient presents with persistent headaches and fatigue over the past two weeks.
Medical History: The patient has a history of hypertension controlled with medication.
Physical Examination: Blood pressure was measured at 145/95 mmHg, which is slightly elevated.
Heart rate is 78 beats per minute and regular. The patient appears tired but is alert and oriented.
Respiratory examination shows clear lung fields bilaterally with no wheezing or crackles.
Laboratory Results: Complete blood count shows Hemoglobin at 11.2 g/dL, which is below normal range.
White blood cell count is 8500 cells/μL, within normal limits. Platelets are 280000 per μL, normal.
Blood glucose is 168 mg/dL, indicating hyperglycemia. Liver function tests are within normal limits.
Kidney function appears normal with creatinine at 0.9 mg/dL.
Assessment: The patient is experiencing anemia and poorly controlled diabetes, which likely contribute to 
the fatigue and may require adjustment of current medications. The elevated blood pressure needs monitoring.
Plan: Increase iron supplementation for anemia. Adjust diabetes medication to better control blood sugar.
Schedule follow-up appointment in two weeks to reassess symptoms and laboratory values.
The patient is advised to maintain a healthy diet and regular exercise routine.
"""

print("Test 1 - Comprehensive Medical Report (3 sentences):")
print("-" * 80)
result1 = summarize(test1, sentence_count=3)
print("SUMMARY:")
print(result1)
print()
print()

# Test Case 2: Lab Report with Abnormal Values
test2 = """
Laboratory Report Summary
Patient ID: 45678
Date of Collection: February 20, 2026

This laboratory report contains the results of comprehensive blood work ordered by Dr. Smith.
The patient's hemoglobin level is significantly low at 9.8 g/dL, suggesting possible anemia that
requires immediate attention and further investigation. White blood cell count is elevated at
13500 cells/μL, which may indicate an ongoing infection or inflammatory process in the body.
Platelet count is within the normal range at 245000 per μL, showing adequate clotting function.
The glucose reading of 195 mg/dL is notably high, suggesting poor glycemic control and possible
diabetes mellitus that needs management. Additional metabolic panel shows normal electrolytes
including sodium at 142 mEq/L and potassium at 4.1 mEq/L. Kidney function markers including
blood urea nitrogen and creatinine are within acceptable limits. The patient should follow up
with their primary care physician within one week to discuss these results and treatment options.
Lifestyle modifications including diet and exercise are strongly recommended.
"""

print("Test 2 - Lab Report (5 sentences):")
print("-" * 80)
result2 = summarize(test2, sentence_count=5)
print("SUMMARY:")
print(result2)
print()
print()

# Test Case 3: Patient History
test3 = """
Patient Medical History
The patient is a 45-year-old male with a complex medical history spanning several years.
He was first diagnosed with type 2 diabetes mellitus ten years ago and has been on metformin since.
Five years ago, he developed hypertension and was started on an ACE inhibitor which has been effective.
The patient has no known drug allergies and no history of surgical procedures.
Family history is significant for cardiovascular disease, with his father having a myocardial infarction at age 55.
The patient is a non-smoker and reports occasional alcohol consumption on weekends.
He works as a software engineer and leads a predominantly sedentary lifestyle.
Recent complaints include increased fatigue, occasional dizziness, and difficulty concentrating at work.
"""

print("Test 3 - Patient History (2 sentences):")
print("-" * 80)
result3 = summarize(test3, sentence_count=2)
print("SUMMARY:")
print(result3)
print()
print()

# Test Case 4: Clinical Notes
test4 = """
Clinical Progress Notes
Today's visit focuses on the management of the patient's chronic conditions and response to treatment.
The patient reports feeling better overall since the last visit three months ago.
Blood pressure readings at home have been consistently in the range of 130/85 mmHg.
Diabetes management has improved with HbA1c dropping from 8.2% to 7.1% over the past quarter.
The patient has been compliant with medications including metformin 1000mg twice daily and lisinopril 10mg once daily.
Dietary modifications have been implemented with reduced carbohydrate intake and increased vegetable consumption.
Exercise routine now includes 30 minutes of walking five days per week.
Laboratory results from last week show improvement in lipid profile with LDL cholesterol at 115 mg/dL.
The patient will continue current medication regimen and maintain lifestyle modifications.
Next appointment scheduled in three months with lab work to be done one week prior.
"""

print("Test 4 - Clinical Progress Notes (4 sentences):")
print("-" * 80)
result4 = summarize(test4, sentence_count=4)
print("SUMMARY:")
print(result4)
print()
print()

# Test Case 5: Short Text (Edge Case)
test5 = """
Patient complains of headache. Blood pressure normal.
"""

print("Test 5 - Very Short Text (Edge Case):")
print("-" * 80)
result5 = summarize(test5, sentence_count=3)
print("SUMMARY:")
print(result5)
print()
print()

print("=" * 80)
print("SUMMARY OF FEATURES")
print("=" * 80)
print("✓ TextRank Algorithm: Implemented via sumy library")
print("✓ Configurable Output: 2-5 sentences as required")
print("✓ Automatic Sentence Extraction: Most important sentences selected")
print("✓ Proper Formatting: Clean output with spacing")
print("✓ Error Handling: Edge cases managed")
print("✓ Libraries Used:")
print("  - sumy (TextRank Summarizer)")
print("  - nltk (Tokenization)")
print()
print("Phase 5: Text Summarization - COMPLETE ✓")
print("=" * 80)
