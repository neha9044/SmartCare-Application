from fastapi import FastAPI, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import pdfplumber
import shutil
import re
from datetime import datetime
import os

from sumy.parsers.plaintext import PlaintextParser
from sumy.nlp.tokenizers import Tokenizer
from sumy.summarizers.text_rank import TextRankSummarizer

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import joblib

# Firebase Admin SDK
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    FIREBASE_ENABLED = True
except ImportError:
    FIREBASE_ENABLED = False
    print("⚠️ Firebase Admin SDK not installed. Database features disabled.")
    print("   Install with: pip install firebase-admin")


app = FastAPI(title="SmartCare Medical Report API", version="1.0.0")

# Enable CORS for Flutter/Web frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# FIREBASE INITIALIZATION (Phase 8)

db = None

def initialize_firebase():
    """
    Initialize Firebase Admin SDK.
    
    Setup:
    1. Download service account key from Firebase Console
    2. Save as 'firebase-key.json' in project root
    3. This function will automatically connect to Firestore
    """
    global db
    
    if not FIREBASE_ENABLED:
        return False
    
    try:
        # Check if already initialized
        if firebase_admin._apps:
            db = firestore.client()
            return True
        
        # Check for service account key
        key_path = "firebase-key.json"
        
        if os.path.exists(key_path):
            cred = credentials.Certificate(key_path)
            firebase_admin.initialize_app(cred)
            db = firestore.client()
            print("✓ Firebase connected successfully")
            return True
        else:
            print("⚠️ firebase-key.json not found. Database features disabled.")
            print("   Download from: Firebase Console → Project Settings → Service Accounts")
            return False
            
    except Exception as e:
        print(f"⚠️ Firebase initialization error: {e}")
        return False


# Try to initialize Firebase at startup
initialize_firebase()


# PDF TEXT EXTRACTION

def extract_text(file_path):
    """
    Extract text from PDF with comprehensive error handling and fallback methods.
    """
    text = ""
    
    try:
        # Method 1: Try pdfplumber (best for most PDFs)
        with pdfplumber.open(file_path) as pdf:
            print(f"📄 Processing PDF: {file_path}")
            print(f"   Total pages: {len(pdf.pages)}")
            
            for i, page in enumerate(pdf.pages):
                page_text = page.extract_text()
                if page_text:
                    text += page_text + "\n"
                    print(f"   ✓ Page {i+1}: {len(page_text)} characters extracted")
                else:
                    print(f"   ⚠ Page {i+1}: No text found (might be image-based)")
        
        print(f"✓ Total text extracted: {len(text)} characters")
        
        # If no text was extracted, try alternative method
        if not text or len(text.strip()) < 10:
            print("⚠ pdfplumber failed, trying PyPDF2 as fallback...")
            try:
                import PyPDF2
                with open(file_path, 'rb') as file:
                    pdf_reader = PyPDF2.PdfReader(file)
                    for i, page in enumerate(pdf_reader.pages):
                        page_text = page.extract_text()
                        if page_text:
                            text += page_text + "\n"
                            print(f"   ✓ Page {i+1}: {len(page_text)} characters extracted (PyPDF2)")
            except ImportError:
                print("   PyPDF2 not installed - install with: pip install PyPDF2")
            except Exception as e:
                print(f"   PyPDF2 also failed: {str(e)}")
        
        return text.strip()
        
    except Exception as e:
        print(f"❌ Error extracting text: {str(e)}")
        import traceback
        traceback.print_exc()
        raise Exception(f"PDF processing failed: {str(e)}")



# OCR FOR IMAGE-BASED TEXT EXTRACTION

# Initialize EasyOCR reader (lazy loading)
ocr_reader = None

def get_ocr_reader():
    """
    Get or initialize EasyOCR reader.
    Lazy loading to avoid startup delays.
    """
    global ocr_reader
    if ocr_reader is None:
        try:
            import easyocr
            print("🔄 Initializing EasyOCR (first time only)...")
            # Use English only for better accuracy on medical reports
            ocr_reader = easyocr.Reader(['en'], gpu=False)
            print("✓ EasyOCR initialized successfully")
        except ImportError:
            raise Exception("EasyOCR not installed. Install with: pip install easyocr")
        except Exception as e:
            raise Exception(f"Failed to initialize OCR: {str(e)}")
    return ocr_reader


def extract_text_from_image(image_path):
    """
    Extract text from image using OCR.
    
    Supports: JPG, JPEG, PNG, BMP, TIFF
    
    Args:
        image_path: Path to image file
        
    Returns:
        Extracted text as string
    """
    try:
        from PIL import Image
        import cv2
        import numpy as np
        
        print(f"📷 Processing image: {image_path}")
        
        # Load image
        image = cv2.imread(image_path)
        if image is None:
            raise Exception(f"Failed to load image: {image_path}")
        
        # Preprocess image for better OCR
        # Upscale image for better OCR accuracy
        height, width = image.shape[:2]
        scale_factor = 2.0
        image = cv2.resize(image, (int(width * scale_factor), int(height * scale_factor)), 
                          interpolation=cv2.INTER_CUBIC)
        
        # Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Denoise the image
        gray = cv2.fastNlMeansDenoising(gray, h=30)
        
        # Apply adaptive thresholding for better text recognition
        # This works better than global thresholding for varying lighting
        gray = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                                     cv2.THRESH_BINARY, 11, 2)
        
        # Dilate slightly to connect broken characters
        kernel = np.ones((1, 1), np.uint8)
        gray = cv2.dilate(gray, kernel, iterations=1)
        
        # Save preprocessed image temporarily
        temp_path = image_path.replace('.', '_processed.')
        cv2.imwrite(temp_path, gray)
        
        print(f"   ✓ Image preprocessed (upscaled {scale_factor}x, denoised, enhanced)")
        
        # Use OCR to extract text with optimized parameters
        reader = get_ocr_reader()
        result = reader.readtext(
            temp_path, 
            detail=0,  # Returns only text, no coordinates
            paragraph=False,  # Extract line by line
            text_threshold=0.7,  # Confidence threshold (default: 0.7)
            low_text=0.4  # Filter out weak text
        )
        
        # Clean up temp file
        if os.path.exists(temp_path):
            os.remove(temp_path)
        
        # Combine all text lines with proper spacing
        text = " ".join(result)  # Use space instead of newline for better flow
        
        # Clean up common OCR errors
        text = cleanup_ocr_text(text)
        
        print(f"   ✓ OCR completed: {len(text)} characters extracted")
        print(f"   ✓ Found {len(result)} text blocks")
        print(f"   ✓ Text cleaned for common OCR errors")
        
        return text.strip()
        
    except ImportError as e:
        raise Exception(f"Missing required library: {str(e)}. Install with: pip install easyocr opencv-python Pillow")
    except Exception as e:
        print(f"❌ OCR Error: {str(e)}")
        import traceback
        traceback.print_exc()
        raise Exception(f"OCR processing failed: {str(e)}")


def extract_text_with_ocr_fallback(file_path):
    """
    Enhanced PDF text extraction with OCR fallback.
    
    First tries normal PDF text extraction.
    If that fails or returns minimal text, uses OCR on PDF pages.
    
    Args:
        file_path: Path to PDF file
        
    Returns:
        Extracted text as string
    """
    try:
        # Try normal text extraction first
        text = extract_text(file_path)
        
        # If we got good text, return it
        if text and len(text.strip()) > 100:
            return text
        
        print("⚠️ Normal extraction returned minimal text, trying OCR...")
        
        # Convert PDF pages to images and use OCR
        from pdf2image import convert_from_path
        
        print("🔄 Converting PDF to images...")
        images = convert_from_path(file_path, dpi=300)  # High DPI for better OCR
        print(f"   ✓ Converted to {len(images)} images")
        
        ocr_text = ""
        for i, image in enumerate(images):
            # Save image temporarily
            temp_image_path = f"temp_page_{i+1}.png"
            image.save(temp_image_path, 'PNG')
            
            print(f"   Processing page {i+1}/{len(images)} with OCR...")
            page_text = extract_text_from_image(temp_image_path)
            ocr_text += page_text + "\n\n"
            
            # Clean up temp image
            if os.path.exists(temp_image_path):
                os.remove(temp_image_path)
        
        print(f"✓ OCR completed: {len(ocr_text)} characters extracted from PDF")
        return ocr_text.strip()
        
    except ImportError:
        raise Exception("pdf2image not installed. Install with: pip install pdf2image")
    except Exception as e:
        print(f"❌ Error in OCR fallback: {str(e)}")
        raise Exception(f"Failed to extract text even with OCR: {str(e)}")


def cleanup_ocr_text(text):
    """
    Clean up common OCR errors in extracted text.
    
    Common OCR mistakes:
    - O (letter O) vs 0 (zero)
    - l (lowercase L) vs 1 (one) vs I (uppercase i)
    - S vs 5
    - B vs 8
    - Spaces in numbers
    
    Args:
        text: Raw OCR extracted text
        
    Returns:
        Cleaned text with common errors fixed
    """
    import re
    
    # Fix common number recognition errors in medical values
    # Fix "O" to "0" when surrounded by digits or decimal points
    text = re.sub(r'(\d+)[Oo](\d+)', r'\g<1>0\g<2>', text)
    text = re.sub(r'(\d+\.)[ ]?[Oo]([\d ])', r'\g<1>0\g<2>', text)
    
    # Fix lowercase "l" to "1" when in numeric context
    text = re.sub(r'(\d+)[lI](\d+)', r'\g<1>1\g<2>', text)
    
    # Fix "S" to "5" in numeric context
    text = re.sub(r'(\d+)[Ss](\d+)', r'\g<1>5\g<2>', text)
    
    # Remove extra spaces within numbers
    text = re.sub(r'(\d+)\s+(\d+)', r'\g<1>\g<2>', text)
    
    # Fix common medical term typos
    replacements = {
        'Hcmoglobin': 'Hemoglobin',
        'Haemoglobin': 'Hemoglobin',
        'Hgb': 'Hemoglobin',
        'GIucose': 'Glucose',
        'Giucose': 'Glucose',
        'PIatelets': 'Platelets',
        'Piatelet': 'Platelet',
        'mgldl': 'mg/dl',
        'mg ldl': 'mg/dl',
        'mgldi': 'mg/dl',
        'mgld': 'mg/dl',
        'mg/d': 'mg/dl',
        'mmolll': 'mmol/l',
        'mmol ll': 'mmol/l',
        'mmol/': 'mmol/l',
    }
    
    for wrong, correct in replacements.items():
        text = re.sub(wrong, correct, text, flags=re.IGNORECASE)
    
    return text


def structure_summary(text, report_type="Unknown"):
    """
    Create an intelligent structured summary that adapts to different report types.
    
    Args:
        text: Raw OCR text from medical report
        report_type: Type of report (Lab Report, Radiology Report, Discharge Summary)
    
    Returns:
        Structured markdown-style summary with universal fields + type-specific sections
    """
    if not text or len(text.strip()) < 20:
        return text
    
    structured = []
    
    # ========== UNIVERSAL FIELDS (present in most reports) ==========
    
    # Extract patient information
    patient_patterns = [
        r'Patient[:\s]*Name[:\s]*([^\n\r]+)',
        r'Patient[:\s]+([^\n\r]+)',
        r'Name[:\s]*:?\s*([A-Z][a-z]+\s+[A-Z][a-z]+)',
    ]
    for pattern in patient_patterns:
        patient_match = re.search(pattern, text, re.IGNORECASE)
        if patient_match:
            patient_name = patient_match.group(1).strip()
            # Filter out common non-name text
            if len(patient_name) > 3 and not re.search(r'\d{4}', patient_name):
                structured.append(f"📋 PATIENT: {patient_name}")
                break
    
    # Extract date
    date_patterns = [
        r'Date[:\s]*:?\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
        r'Date[:\s]*:?\s*([A-Za-z]+\s+\d{1,2},?\s+\d{4})',
        r'(?:on|dated)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
    ]
    for pattern in date_patterns:
        date_match = re.search(pattern, text, re.IGNORECASE)
        if date_match:
            structured.append(f"📅 DATE: {date_match.group(1).strip()}")
            break
    
    if structured:
        structured.append("")  # Add spacing
    
    # ========== TYPE-SPECIFIC FORMATTING ==========
    
    if report_type == "Lab Report":
        # For lab reports: extract test values
        lab_values_section = []
        
        # Find all NUMBER: VALUE patterns (common in lab reports)
        lab_values = re.findall(
            r'([A-Za-z\s]+)[:\s-]+(\d+\.?\d*)\s*([a-zA-Z/μ]+)',
            text
        )
        
        if lab_values:
            for test_name, value, unit in lab_values[:8]:  # Show up to 8 values
                clean_name = test_name.strip()
                if len(clean_name) > 2 and len(clean_name) < 40:
                    lab_values_section.append(f"  • {clean_name}: {value} {unit}")
        
        # If no structured values found, show key lines with numbers
        if not lab_values:
            lines_with_numbers = [
                line.strip() for line in text.split('\n')
                if re.search(r'\d+\.?\d*', line) and len(line.strip()) > 10
            ]
            for line in lines_with_numbers[:5]:
                lab_values_section.append(f"  • {line}")
        
        # Only add the header if we found content
        if lab_values_section:
            structured.append("🔬 LAB VALUES:")
            structured.extend(lab_values_section)
    
    elif report_type == "Radiology Report":
        # For radiology: extract imaging technique and findings
        technique_match = re.search(
            r'(CT|MRI|X-Ray|Ultrasound|Mammography)[:\s]+([^\n\r]+)',
            text, re.IGNORECASE
        )
        if technique_match:
            structured.append(f"🏥 IMAGING: {technique_match.group(0).strip()}\n")
        
        # Extract findings
        findings_patterns = [
            r'Findings[:\s]*:?\s*([^\n\r]+(?:\n[^\n\r]+){0,3})',
            r'Impression[:\s]*:?\s*([^\n\r]+(?:\n[^\n\r]+){0,2})',
            r'Interpretation[:\s]*:?\s*([^\n\r]+)',
        ]
        for pattern in findings_patterns:
            findings_match = re.search(pattern, text, re.IGNORECASE)
            if findings_match:
                findings_text = findings_match.group(1).strip()
                # Split into sentences
                sentences = re.split(r'[.!]\s+', findings_text)
                findings_list = [s.strip() for s in sentences[:3] if s.strip()]
                
                # Only add header if we have findings
                if findings_list:
                    structured.append(f"🔍 FINDINGS:")
                    for sentence in findings_list:
                        structured.append(f"  • {sentence}")
                break
    
    elif report_type == "Discharge Summary":
        # For discharge summaries: diagnosis, treatment, medications, follow-up
        diagnosis_patterns = [
            r'Diagnosis[:\s]*:?\s*([^\n\r]+)',
            r'Diagnosed[:\s]+with[:\s]+([^\n\r]+)',
            r'Admitted[:\s]+(?:with|for)[:\s]+([^\n\r]+)',
        ]
        for pattern in diagnosis_patterns:
            diag_match = re.search(pattern, text, re.IGNORECASE)
            if diag_match:
                structured.append(f"🏥 DIAGNOSIS: {diag_match.group(1).strip()}\n")
                break
        
        # Extract treatment/medications
        treatment_patterns = [
            r'Treatment[:\s]*:?\s*([^\n\r]+)',
            r'Medications?[:\s]*:?\s*([^\n\r]+)',
            r'Prescribed[:\s]*:?\s*([^\n\r]+)',
        ]
        for pattern in treatment_patterns:
            treatment_match = re.search(pattern, text, re.IGNORECASE)
            if treatment_match:
                structured.append(f"💊 TREATMENT: {treatment_match.group(1).strip()}\n")
                break
        
        # Extract follow-up
        followup_patterns = [
            r'Follow-?up[:\s]*:?\s*([^\n\r]+)',
            r'Discharge[:\s]+(?:Advice|Instructions)[:\s]*:?\s*([^\n\r]+)',
        ]
        for pattern in followup_patterns:
            followup_match = re.search(pattern, text, re.IGNORECASE)
            if followup_match:
                structured.append(f"📝 FOLLOW-UP: {followup_match.group(1).strip()}")
                break
    
    # ========== AI-GENERATED KEY POINTS (fallback for any missing info) ==========
    
    # If we didn't extract much structured data, add AI summary
    if len(structured) < 5:
        structured.append("\n📌 KEY POINTS:")
        try:
            # Use TextRank to extract 3-4 most important sentences
            parser = PlaintextParser.from_string(text, Tokenizer("english"))
            summarizer = TextRankSummarizer()
            summary_sentences = summarizer(parser.document, 4)
            
            for sentence in summary_sentences:
                sentence_text = str(sentence).strip()
                if len(sentence_text) > 15:  # Skip very short sentences
                    structured.append(f"  • {sentence_text}")
        except:
            # If summarization fails, show first few lines
            lines = [line.strip() for line in text.split('\n') if len(line.strip()) > 20]
            for line in lines[:4]:
                structured.append(f"  • {line}")
    
    # ========== DOCTOR/PHYSICIAN INFO ==========
    
    doctor_patterns = [
        r'([A-Z][a-z]+\s+[A-Z][a-z]+,?\s+M\.?D\.?)',
        r'Dr\.?\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)',
        r'Physician[:\s]*:?\s*([^\n\r]+)',
    ]
    for pattern in doctor_patterns:
        doctor_match = re.search(pattern, text)
        if doctor_match:
            structured.append(f"\n👨‍⚕️ PHYSICIAN: {doctor_match.group(1).strip()}")
            break
    
    # Return structured summary or fallback to raw text
    if len(structured) > 2:
        return '\n'.join(structured)
    else:
        # Complete fallback: just show cleaned text
        return text[:600].strip()


# ABNORMAL DETECTION

def detect_abnormal(text):
    """
    Detect abnormal lab values using rule-based logic.
    
    Normal Ranges:
    - Hemoglobin: 12-17 g/dL
    - WBC: 4-11 × 10^9/L (or 4000-11000 cells/μL)
    - Platelets: 150-450 × 10^9/L (or 150000-450000 per μL)
    - Glucose: 70-140 mg/dL
    """
    abnormal = []
    
    # Hemoglobin Detection (12-17 g/dL)
    hemoglobin_patterns = [
        r'Hemoglobin[:\s-]+(\d+\.?\d*)',
        r'Hb[:\s-]+(\d+\.?\d*)',
        r'HGB[:\s-]+(\d+\.?\d*)',
        r'Haemoglobin[:\s-]+(\d+\.?\d*)',
        r'Hgb[:\s-]+(\d+\.?\d*)'
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
    
    # WBC Detection (4-11 × 10^9/L or 4000-11000 cells/μL)
    wbc_patterns = [
        r'WBC[:\s-]+(\d+\.?\d*)',
        r'White Blood Cell[s]?[:\s-]+(\d+\.?\d*)',
        r'Leukocyte[s]?[:\s-]+(\d+\.?\d*)',
        r'W[\s]?B[\s]?C[:\s-]+(\d+\.?\d*)'
    ]
    
    for pattern in wbc_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            value = float(match.group(1))
            # Handle both formats: if value > 100, assume cells/μL format
            if value > 100:
                if value < 4000:
                    abnormal.append(f"Low WBC ({value} cells/μL)")
                elif value > 11000:
                    abnormal.append(f"High WBC ({value} cells/μL)")
            else:
                # Assume × 10^9/L format
                if value < 4:
                    abnormal.append(f"Low WBC ({value} × 10^9/L)")
                elif value > 11:
                    abnormal.append(f"High WBC ({value} × 10^9/L)")
            break
    
    # Platelets Detection (150-450 × 10^9/L or 150000-450000 per μL)
    platelet_patterns = [
        r'Platelet[s]?[:\s-]+(\d+\.?\d*)',
        r'PLT[:\s-]+(\d+\.?\d*)',
        r'Thrombocyte[s]?[:\s-]+(\d+\.?\d*)',
        r'P[\s]?L[\s]?T[:\s-]+(\d+\.?\d*)'
    ]
    
    for pattern in platelet_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            value = float(match.group(1))
            # Handle both formats: if value > 1000, assume per μL format
            if value > 1000:
                if value < 150000:
                    abnormal.append(f"Low Platelets ({value} per μL)")
                elif value > 450000:
                    abnormal.append(f"High Platelets ({value} per μL)")
            else:
                # Assume × 10^9/L format
                if value < 150:
                    abnormal.append(f"Low Platelets ({value} × 10^9/L)")
                elif value > 450:
                    abnormal.append(f"High Platelets ({value} × 10^9/L)")
            break
    
    # Glucose Detection (70-140 mg/dL)
    glucose_patterns = [
        r'Glucose[:\s-]+(\d+\.?\d*)',
        r'Blood Glucose[:\s-]+(\d+\.?\d*)',
        r'Blood Sugar[:\s-]+(\d+\.?\d*)',
        r'GLU[:\s-]+(\d+\.?\d*)',
        r'GLUCOSE[:\s-]+[\w\s()]*?(\d+\.?\d*)\s*mg',
        r'Giucose[:\s-]+(\d+\.?\d*)'
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
    
    # Creatinine Detection (0.7-1.3 mg/dL)
    creatinine_patterns = [
        r'Creatinine[:\s-]+[\w\s()]*?(\d+\.?\d*)',
        r'CREAT[:\s-]+(\d+\.?\d*)',
        r'Serum Creatinine[:\s-]+[\w\s()]*?(\d+\.?\d*)',
        r'CREATNTNE[:\s-]+[\w\s()]*?(\d+\.?\d*)'
    ]
    
    for pattern in creatinine_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            try:
                value = float(match.group(1))
                if value < 0.7:
                    abnormal.append(f"Low Creatinine ({value} mg/dL)")
                elif value > 1.3:
                    abnormal.append(f"High Creatinine ({value} mg/dL)")
                break
            except ValueError:
                continue
    
    # BUN Detection (7-20 mg/dL)
    bun_patterns = [
        r'BUN[:\s-]+[\w\s()]*?(\d+\.?\d*)',
        r'Blood Urea Nitrogen[:\s-]+(\d+\.?\d*)',
        r'Urea[:\s-]+(\d+\.?\d*)'
    ]
    
    for pattern in bun_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            try:
                value = float(match.group(1))
                if value < 7:
                    abnormal.append(f"Low BUN ({value} mg/dL)")
                elif value > 20:
                    abnormal.append(f"High BUN ({value} mg/dL)")
                break
            except ValueError:
                continue
    
    # Sodium Detection (135-145 mmol/L)
    sodium_patterns = [
        r'Sodium[:\s-]+[\w\s()]*?(\d+\.?\d*)',
        r'Na[:\s-]+(\d+\.?\d*)',
        r'SODIUM[:\s-]+[\w\s()]*?(\d+\.?\d*)'
    ]
    
    for pattern in sodium_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            try:
                value = float(match.group(1))
                if value < 135:
                    abnormal.append(f"Low Sodium ({value} mmol/L)")
                elif value > 145:
                    abnormal.append(f"High Sodium ({value} mmol/L)")
                break
            except ValueError:
                continue
    
    # Potassium Detection (3.5-5.1 mmol/L)
    potassium_patterns = [
        r'Potassium[:\s-]+[\w\s()]*?(\d+\.?\d*)',
        r'K[:\s-]+(\d+\.?\d*)',
        r'POTASSIUM[:\s-]+[\w\s()]*?(\d+\.?\d*)'
    ]
    
    for pattern in potassium_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            try:
                value = float(match.group(1))
                if value < 3.5:
                    abnormal.append(f"Low Potassium ({value} mmol/L)")
                elif value > 5.1:
                    abnormal.append(f"High Potassium ({value} mmol/L)")
                break
            except ValueError:
                continue
    
    return abnormal



# SUMMARIZATION

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



# SEVERITY CLASSIFICATION

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



# REPORT TYPE DETECTION (ML COMPONENT)

# Training Data for Report Type Classification
TRAINING_DATA = [
    # Lab Reports
    ("Complete Blood Count test results. Hemoglobin 14.5 g/dL, WBC 7800 cells/μL, Platelets 245000 per μL, RBC 4.8 million/μL. Glucose 95 mg/dL, Creatinine 0.9 mg/dL.", "Lab Report"),
    ("Laboratory Report: Blood Chemistry Panel. Glucose 110 mg/dL, Hemoglobin 13.2 g/dL, Total Cholesterol 180 mg/dL, HDL 55 mg/dL, LDL 100 mg/dL, Triglycerides 125 mg/dL.", "Lab Report"),
    ("Lab Test Results: Liver Function Test. ALT 28 U/L, AST 32 U/L, Alkaline Phosphatase 85 U/L, Total Bilirubin 0.8 mg/dL, Albumin 4.2 g/dL. WBC count 6500 cells/μL.", "Lab Report"),
    ("Urinalysis Report: Color Yellow, Clarity Clear, pH 6.5, Specific Gravity 1.020, Protein Negative, Glucose Negative, RBC 0-2/HPF, WBC 0-3/HPF.", "Lab Report"),
    ("Blood Test: Hemoglobin A1C 5.8%, Fasting Glucose 92 mg/dL, TSH 2.5 mIU/L, Vitamin D 35 ng/mL, Platelets 320000 per μL, Hemoglobin 15.1 g/dL.", "Lab Report"),
    ("CBC Results: WBC 9200 cells/μL, Hemoglobin 16.2 g/dL, Hematocrit 48%, MCV 88 fL, MCH 30 pg, MCHC 34 g/dL, Platelets 280000 per μL.", "Lab Report"),
    ("Lipid Profile: Total Cholesterol 195 mg/dL, LDL 115 mg/dL, HDL 48 mg/dL, Triglycerides 160 mg/dL, VLDL 32 mg/dL. Glucose 105 mg/dL.", "Lab Report"),
    ("Kidney Function Test: Creatinine 1.1 mg/dL, BUN 18 mg/dL, eGFR 85 mL/min, Sodium 140 mEq/L, Potassium 4.2 mEq/L, Chloride 102 mEq/L.", "Lab Report"),
    
    # Radiology Reports
    ("Chest X-Ray Report: PA and lateral views of chest obtained. Lungs are clear bilaterally. No pleural effusion. Heart size normal. No acute cardiopulmonary abnormality.", "Radiology Report"),
    ("CT Scan Abdomen: Contrast enhanced CT imaging of abdomen and pelvis. Liver, spleen, pancreas unremarkable. No free fluid. Kidneys show normal enhancement. No mass lesion identified.", "Radiology Report"),
    ("MRI Brain Report: Axial T1, T2, FLAIR sequences obtained. No acute infarct. No intracranial hemorrhage. Ventricles normal size. No mass effect. White matter appears normal.", "Radiology Report"),
    ("Ultrasound Abdomen: Liver normal in size and echogenicity. Gallbladder shows no stones. Spleen normal. Both kidneys normal size without hydronephrosis. No free fluid.", "Radiology Report"),
    ("X-Ray Left Knee: AP and lateral views demonstrate no acute fracture. Joint space preserved. No effusion. Soft tissues unremarkable. Impression: Normal knee radiograph.", "Radiology Report"),
    ("Mammography Report: Bilateral screening mammogram. Breast tissue is heterogeneously dense. No suspicious mass, calcifications or architectural distortion. BI-RADS Category 1.", "Radiology Report"),
    ("CT Chest: High resolution CT chest without contrast. Lung parenchyma clear. No nodules or masses. Mediastinal structures normal. No lymphadenopathy. Airways patent.", "Radiology Report"),
    ("Abdominal X-Ray: Supine and upright views. Normal bowel gas pattern. No dilated loops. No free air under diaphragm. Psoas shadows visible bilaterally. No abnormal calcifications.", "Radiology Report"),
    
    # Discharge Summaries
    ("Discharge Summary: Patient admitted with chest pain. Cardiac workup negative. ECG normal sinus rhythm. Troponin negative. Diagnosed with costochondritis. Discharged on ibuprofen. Follow-up in 2 weeks.", "Discharge Summary"),
    ("Hospital Discharge: 55 year old male admitted for pneumonia. Treated with antibiotics. Chest X-ray showed improvement. Vitals stable. Discharged home on oral antibiotics for 7 days. Outpatient follow-up arranged.", "Discharge Summary"),
    ("Discharge Summary: Patient presented with acute appendicitis. Underwent laparoscopic appendectomy. Post-operative course uneventful. Pain controlled. Tolerating diet. Discharged on POD 2. Return if fever or increased pain.", "Discharge Summary"),
    ("Summary of Hospitalization: Admitted for diabetic ketoacidosis. Insulin drip initiated. Electrolytes corrected. Transitioned to subcutaneous insulin. Blood sugar controlled. Discharged with diabetes education. Endocrine follow-up scheduled.", "Discharge Summary"),
    ("Discharge Report: Patient admitted with congestive heart failure exacerbation. Diuresed with IV furosemide. Echocardiogram showed EF 35%. Started on ACE inhibitor. Symptoms improved. Discharged with cardiology appointment.", "Discharge Summary"),
    ("Hospital Discharge Summary: 68 year old female with hip fracture. Underwent ORIF surgery. Physical therapy initiated. Pain managed. Ambulating with walker. Discharged to rehab facility. Orthopedic follow-up in 6 weeks.", "Discharge Summary"),
    ("Discharge: Admitted for cellulitis left lower extremity. IV antibiotics administered. Marked improvement noted. Swelling decreased. Switched to oral antibiotics. Discharged home. Follow-up with PCP in 1 week.", "Discharge Summary"),
    ("Discharge Summary: Patient admitted with stroke symptoms. MRI confirmed ischemic stroke. tPA administered. Neurological deficits resolved. Started on antiplatelet therapy. Discharged to acute rehab. Neurology follow-up arranged.", "Discharge Summary"),
]

# Initialize and train the ML model
def train_report_classifier():
    """
    Train a machine learning classifier for report type detection.
    
    Uses:
        - TF-IDF (Term Frequency-Inverse Document Frequency) for text vectorization
        - Logistic Regression for classification
        - Train-Test Split for validation
    
    Returns:
        Trained sklearn Pipeline object
    """
    # Separate training texts and labels
    texts, labels = zip(*TRAINING_DATA)
    
    # Split data: 80% training, 20% testing
    X_train, X_test, y_train, y_test = train_test_split(
        texts, labels, 
        test_size=0.2, 
        random_state=42, 
        stratify=labels  # Ensures balanced split across classes
    )
    
    # Create ML Pipeline: TF-IDF → Logistic Regression
    model = Pipeline([
        ('tfidf', TfidfVectorizer(
            max_features=500,
            ngram_range=(1, 2),
            stop_words='english',
            lowercase=True
        )),
        ('classifier', LogisticRegression(
            max_iter=1000,
            random_state=42,
            multi_class='multinomial'
        ))
    ])
    
    # Train the model on training set
    model.fit(X_train, y_train)
    
    # Evaluate on test set
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    # Print training summary
    print("\n" + "="*60)
    print("✓ ML MODEL TRAINING COMPLETE")
    print("="*60)
    print(f"  Training Samples: {len(X_train)}")
    print(f"  Test Samples: {len(X_test)}")
    print(f"  Test Accuracy: {accuracy:.2%}")
    print(f"  Classes: {list(model.classes_)}")
    print("\n  Classification Report:")
    print(classification_report(y_test, y_pred, target_names=model.classes_))
    print("="*60 + "\n")
    
    # Save model to disk
    try:
        joblib.dump(model, 'report_classifier_model.pkl')
        print("✓ Model saved to: report_classifier_model.pkl")
    except Exception as e:
        print(f"⚠️ Model save failed: {e}")
    
    return model


# Load or train model at startup
model_path = 'report_classifier_model.pkl'

if os.path.exists(model_path):
    try:
        report_classifier = joblib.load(model_path)
        print("\n✓ ML model loaded from disk (report_classifier_model.pkl)")
        print(f"  Classes: {list(report_classifier.classes_)}")
        print("  Status: Ready for predictions\n")
    except Exception as e:
        print(f"⚠️ Model loading failed: {e}")
        print("  Training new model...\n")
        report_classifier = train_report_classifier()
else:
    print("\n⚠️ No saved model found. Training new model...")
    report_classifier = train_report_classifier()


def detect_report_type(text):
    """
    Classify medical report type using ML.
    
    Pipeline: Text → TF-IDF → Logistic Regression → Prediction
    
    Args:
        text: Extracted report text
    
    Returns:
        String: "Lab Report", "Radiology Report", or "Discharge Summary"
    
    Example Output:
        "Lab Report"
    """
    if not text or len(text.strip()) < 10:
        return "Unknown"
    
    try:
        # Predict report type
        prediction = report_classifier.predict([text])[0]
        return prediction
    except Exception as e:
        return f"Classification error: {str(e)}"



# FIREBASE DATABASE STORAGE (Phase 8)

def store_report_in_firebase(user_id, report_data):
    """
    Store medical report results in Firebase Firestore.
    
    Collection Structure:
    reports/
        - user_id: string
        - report_type: string (Lab Report/Radiology Report/Discharge Summary)
        - report_text: string (extracted text)
        - summary: string
        - abnormal: array
        - severity: string
        - timestamp: datetime
    
    Args:
        user_id: User identifier
        report_data: Dictionary containing report analysis results
    
    Returns:
        Document ID if successful, None if failed
    """
    if not db:
        print("⚠️ Firebase not initialized. Skipping database storage.")
        return None
    
    try:
        # Add to Firestore 'reports' collection
        doc_ref = db.collection('reports').add(report_data)
        print(f"✓ Report stored with ID: {doc_ref[1].id}")
        return doc_ref[1].id
        
    except Exception as e:
        print(f"⚠️ Database storage error: {e}")
        return None


def get_user_reports(user_id, limit=10):
    """
    Retrieve all reports for a specific user.
    
    Args:
        user_id: User identifier
        limit: Maximum number of reports to return (default: 10)
    
    Returns:
        List of report documents
    """
    if not db:
        return []
    
    try:
        reports = db.collection('reports') \
            .where('user_id', '==', user_id) \
            .order_by('timestamp', direction=firestore.Query.DESCENDING) \
            .limit(limit) \
            .get()
        
        return [{
            'id': doc.id,
            **doc.to_dict()
        } for doc in reports]
        
    except Exception as e:
        print(f"⚠️ Database retrieval error: {e}")
        return []


# API ENDPOINTS (Phase 9 & 10)

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "online",
        "service": "SmartCare Medical Report API",
        "version": "1.0.0",
        "firebase_enabled": db is not None,
        "features": [
            "PDF Text Extraction",
            "Report Type Detection (ML)",
            "Abnormal Value Detection",
            "Severity Classification",
            "Report Summarization",
            "Firebase Storage"
        ]
    }


@app.post("/upload")
async def upload(file: UploadFile, user_id: str = "anonymous"):
    """
    Upload and analyze medical report PDF.
    
    Phase 9: Final API Output Format
    
    Args:
        file: PDF file upload
        user_id: User identifier (optional, default: "anonymous")
    
    Returns:
        {
            "report_type": "Lab Report",
            "summary": "...",
            "abnormal": ["Low Hemoglobin"],
            "severity": "Mild",
            "timestamp": "2026-02-24T10:30:00",
            "document_id": "firebase_doc_id" (if Firebase enabled)
        }
    """
    path = None
    try:
        # Validate file type
        if not file.filename.lower().endswith('.pdf'):
            raise HTTPException(status_code=400, detail="Only PDF files are accepted")
        
        print(f"\n{'='*60}")
        print(f"📥 New upload request:")
        print(f"   File: {file.filename}")
        print(f"   User: {user_id}")
        print(f"   Content-Type: {file.content_type}")
        
        # Save uploaded file with unique name to avoid conflicts
        import uuid
        unique_filename = f"{uuid.uuid4()}_{file.filename}"
        path = os.path.join("uploads", unique_filename)
        
        # Create uploads directory if it doesn't exist
        os.makedirs("uploads", exist_ok=True)
        
        # Save file
        with open(path, "wb") as buffer:
            content = await file.read()
            buffer.write(content)
        
        file_size = os.path.getsize(path)
        print(f"   ✓ File saved: {file_size} bytes")
        
        # Validate it's a real PDF
        if file_size < 100:
            raise HTTPException(status_code=400, detail="File is too small to be a valid PDF")

        # Extract and analyze
        try:
            # Use OCR fallback for image-based PDFs
            text = extract_text_with_ocr_fallback(path)
        except Exception as e:
            raise HTTPException(
                status_code=400, 
                detail=f"Unable to extract text from PDF: {str(e)}"
            )
        
        if not text or len(text.strip()) < 20:
            raise HTTPException(
                status_code=400, 
                detail="Unable to extract text from PDF. The PDF appears to be empty or image-based (scanned). Please ensure the PDF contains selectable text."
            )
        
        print(f"✓ Text extracted successfully: {len(text)} characters")
        
        report_type = detect_report_type(text)
        print(f"✓ Report type detected: {report_type}")
        
        abnormal = detect_abnormal(text)
        print(f"✓ Abnormal values found: {len(abnormal)}")
        
        summary = structure_summary(text, report_type)
        print(f"✓ Structured summary generated")
        
        severity = classify_severity(abnormal)
        print(f"✓ Severity classified: {severity}")
        
        timestamp = datetime.now().isoformat()

        # Prepare response
        response = {
            "report_type": report_type,
            "summary": summary,
            "abnormal": abnormal,
            "severity": severity,
            "timestamp": timestamp
        }

        # Store in Firebase (Phase 8)
        if db:
            firebase_data = {
                "user_id": user_id,
                "report_type": report_type,
                "report_text": text[:5000],  # Store first 5000 chars
                "summary": summary,
                "abnormal": abnormal,
                "severity": severity,
                "timestamp": firestore.SERVER_TIMESTAMP,
                "filename": file.filename
            }
            doc_id = store_report_in_firebase(user_id, firebase_data)
            if doc_id:
                response["document_id"] = doc_id
                print(f"✓ Stored in Firebase: {doc_id}")

        # Clean up uploaded file
        try:
            if path and os.path.exists(path):
                os.remove(path)
                print(f"✓ Temporary file cleaned up")
        except Exception as cleanup_err:
            print(f"⚠ Cleanup warning: {cleanup_err}")

        print(f"✅ Upload completed successfully")
        print(f"{'='*60}\n")
        
        return response
        
    except HTTPException:
        # Clean up file on error
        if path and os.path.exists(path):
            try:
                os.remove(path)
            except:
                pass
        raise
    except Exception as e:
        # Clean up file on error
        if path and os.path.exists(path):
            try:
                os.remove(path)
            except:
                pass
        print(f"❌ Upload failed: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Processing error: {str(e)}")


@app.post("/upload-image")
async def upload_image(file: UploadFile, user_id: str = "anonymous"):
    """
    Upload and analyze medical report IMAGE (JPG, PNG, etc.) using OCR.
    
    Args:
        file: Image file upload (JPG, PNG, BMP, TIFF)
        user_id: User identifier (optional, default: "anonymous")
    
    Returns:
        {
            "report_type": "Lab Report",
            "summary": "...",
            "abnormal": ["Low Hemoglobin"],
            "severity": "Mild",
            "timestamp": "2026-02-24T10:30:00",
            "document_id": "firebase_doc_id" (if Firebase enabled)
        }
    """
    path = None
    try:
        # Validate file type
        allowed_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif']
        file_ext = os.path.splitext(file.filename)[1].lower()
        
        if file_ext not in allowed_extensions:
            raise HTTPException(
                status_code=400, 
                detail=f"Invalid file type. Supported: {', '.join(allowed_extensions)}"
            )
        
        print(f"\n{'='*60}")
        print(f"📥 New IMAGE upload request:")
        print(f"   File: {file.filename}")
        print(f"   User: {user_id}")
        print(f"   Content-Type: {file.content_type}")
        
        # Save uploaded file with unique name
        import uuid
        unique_filename = f"{uuid.uuid4()}_{file.filename}"
        path = os.path.join("uploads", unique_filename)
        
        # Create uploads directory if it doesn't exist
        os.makedirs("uploads", exist_ok=True)
        
        # Save file
        with open(path, "wb") as buffer:
            content = await file.read()
            buffer.write(content)
        
        file_size = os.path.getsize(path)
        print(f"   ✓ File saved: {file_size} bytes")
        
        if file_size < 100:
            raise HTTPException(status_code=400, detail="File is too small to be a valid image")

        # Extract text using OCR
        try:
            text = extract_text_from_image(path)
        except Exception as e:
            raise HTTPException(
                status_code=400, 
                detail=f"OCR failed: {str(e)}"
            )
        
        if not text or len(text.strip()) < 20:
            raise HTTPException(
                status_code=400, 
                detail="Unable to extract sufficient text from image. Please ensure the image is clear and contains readable text."
            )
        
        print(f"✓ Text extracted successfully: {len(text)} characters")
        
        # Analyze the extracted text
        report_type = detect_report_type(text)
        print(f"✓ Report type detected: {report_type}")
        
        abnormal = detect_abnormal(text)
        print(f"✓ Abnormal values found: {len(abnormal)}")
        
        summary = structure_summary(text, report_type)
        print(f"✓ Structured summary generated")
        
        severity = classify_severity(abnormal)
        print(f"✓ Severity classified: {severity}")
        
        timestamp = datetime.now().isoformat()

        # Prepare response
        response = {
            "report_type": report_type,
            "summary": summary,
            "abnormal": abnormal,
            "severity": severity,
            "timestamp": timestamp
        }

        # Store in Firebase
        if db:
            firebase_data = {
                "user_id": user_id,
                "report_type": report_type,
                "summary": summary,
                "abnormal": abnormal,
                "severity": severity,
                "timestamp": timestamp,
                "filename": file.filename,
                "file_type": "image",
                "extraction_method": "OCR"
            }
            
            try:
                doc_ref = db.collection("medical_reports").add(firebase_data)
                document_id = doc_ref[1].id
                response["document_id"] = document_id
                print(f"✓ Stored in Firebase: {document_id}")
            except Exception as e:
                print(f"⚠️ Firebase storage failed: {e}")

        # Clean up uploaded file
        try:
            os.remove(path)
            print(f"✓ Cleaned up temporary file")
        except:
            pass

        print(f"✓ Processing completed successfully")
        print(f"{'='*60}\n")
        
        return response

    except HTTPException:
        # Clean up file on error
        if path and os.path.exists(path):
            try:
                os.remove(path)
            except:
                pass
        raise
    except Exception as e:
        # Clean up file on error
        if path and os.path.exists(path):
            try:
                os.remove(path)
            except:
                pass
        print(f"❌ Image upload failed: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Processing error: {str(e)}")


@app.get("/reports/{user_id}")
async def get_reports(user_id: str, limit: int = 10):
    """
    Get all reports for a user (For Doctor Dashboard - Phase 11).
    
    Args:
        user_id: User identifier
        limit: Maximum reports to return
    
    Returns:
        List of user's medical reports
    """
    if not db:
        raise HTTPException(status_code=503, detail="Database not available")
    
    reports = get_user_reports(user_id, limit)
    
    return {
        "user_id": user_id,
        "total_reports": len(reports),
        "reports": reports
    }


@app.get("/statistics/{user_id}")
async def get_statistics(user_id: str):
    """
    Get health statistics for a user (For Doctor Dashboard - Phase 11).
    
    Returns:
        Summary statistics of user's reports
    """
    if not db:
        raise HTTPException(status_code=503, detail="Database not available")
    
    reports = get_user_reports(user_id, limit=100)
    
    # Calculate statistics
    stats = {
        "total_reports": len(reports),
        "report_types": {},
        "severity_distribution": {},
        "recent_abnormals": []
    }
    
    for report in reports:
        # Count report types
        rtype = report.get('report_type', 'Unknown')
        stats['report_types'][rtype] = stats['report_types'].get(rtype, 0) + 1
        
        # Count severity
        severity = report.get('severity', 'Unknown')
        stats['severity_distribution'][severity] = stats['severity_distribution'].get(severity, 0) + 1
        
        # Collect recent abnormal findings
        abnormal = report.get('abnormal', [])
        if abnormal:
            stats['recent_abnormals'].extend(abnormal[:3])  # Top 3 from each report
    
    # Limit abnormals to most recent 10
    stats['recent_abnormals'] = stats['recent_abnormals'][:10]
    
    return {
        "user_id": user_id,
        "statistics": stats
    }