from fastapi import FastAPI, UploadFile, File
import shutil
import os

from training.summarizer_engine import MedicalSummarizerEngine
from utils.pdf_extractor import extract_text

app = FastAPI()

# Load model once
engine = MedicalSummarizerEngine(
    "models/summary_model.pkl",
    "models/summary_vectorizer.pkl"
)

@app.post("/analyze-report/")
async def analyze_report(file: UploadFile = File(...)):
    
    # Save uploaded file
    file_path = f"temp_{file.filename}"
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Extract text
    raw_text = extract_text(file_path)

    # Generate summary
    summary = engine.summarize_ml(raw_text)

    # Delete temp file
    os.remove(file_path)

    return {
        "summary": summary
    }