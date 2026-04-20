from fastapi import FastAPI, UploadFile, File
import shutil
import os

from training.summarizer_engine import MedicalSummarizerEngine
from utils.pdf_extractor import extract_text

app = FastAPI()

engine = MedicalSummarizerEngine()


@app.get("/")
def home():
    return {"message": "SmartCare API is running 🚀"}


@app.post("/analyze-report/")
async def analyze_report(file: UploadFile = File(...)):
    
    try:
        file_path = f"temp_{file.filename}"

        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        raw_text = extract_text(file_path)

        if not raw_text.strip():
            return {"summary": "❌ No text extracted from PDF."}

        # ✅ NEW MODEL USED HERE
        summary = engine.summarize(raw_text)

        return {"summary": summary}

    except Exception as e:
        return {"error": str(e)}

    finally:
        if os.path.exists(file_path):
            os.remove(file_path)