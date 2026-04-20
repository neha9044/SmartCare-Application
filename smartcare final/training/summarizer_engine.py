from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
import re
import torch

class MedicalSummarizerEngine:
    def __init__(self):
        self.model_name = "Falconsai/medical_summarization"

        self.tokenizer = AutoTokenizer.from_pretrained(self.model_name)
        self.model = AutoModelForSeq2SeqLM.from_pretrained(self.model_name)

        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model.to(self.device)

    # =========================
    # CLEANING FUNCTION
    # =========================
    def _deep_clean(self, text):
        # Remove backslashes
        text = re.sub(r'\\+', '', text)

        # Remove PDF artifacts
        text = re.sub(r'\(cid:\d+\)', '', text)

        # Remove header metadata (IMPORTANT)
        text = re.sub(r'Patient Name.*?Modality.*?\.', '', text, flags=re.IGNORECASE)

        # Remove instruction/test text
        text = re.sub(r'this next one is.*?hospital\.', '', text, flags=re.IGNORECASE)
        text = re.sub(r'if your model is.*?\.', '', text, flags=re.IGNORECASE)

        # Normalize spaces
        text = re.sub(r'\s+', ' ', text).strip()

        # =========================
        # KEEP ONLY CLINICAL PART
        # =========================
        match = re.search(r'(FINDINGS|IMPRESSION|ASSESSMENT)(.*)', text, re.IGNORECASE)
        if match:
            text = match.group(0)

        return text

    # =========================
    # SUMMARIZATION
    # =========================
    def summarize(self, raw_text):
        cleaned_text = self._deep_clean(raw_text)

        if not cleaned_text or len(cleaned_text) < 20:
            return "No significant clinical findings identified."

        # Limit input length
        cleaned_text = cleaned_text[:1500]

        # SIMPLE PROMPT (works best)
        input_text = (
         "Summarize this medical report clearly. Include all important medical values, measurements, and findings:\n\n"
         f"{cleaned_text}"
        )

        inputs = self.tokenizer(
            input_text,
            return_tensors="pt",
            truncation=True,
            max_length=512
        ).to(self.device)

        outputs = self.model.generate(
            inputs["input_ids"],
            max_length=180,
            min_length=50,
            num_beams=5,
            repetition_penalty=2.5,
            length_penalty=1.1,
            early_stopping=True
        )

        summary = self.tokenizer.decode(outputs[0], skip_special_tokens=True)

        return self._format_output(summary)

    # =========================
    # FORMAT OUTPUT
    # =========================
    def _format_output(self, text):
        text = text.strip()

        sentences = re.split(r'(?<=[.])\s+', text)

        diagnosis = []
        findings = []
        treatment = []

        for s in sentences:
            s_lower = s.lower()

            if any(word in s_lower for word in ["diagnosis", "suggestive", "consistent", "malignancy", "disease"]):
                diagnosis.append(s)

            elif any(char.isdigit() for char in s):
                findings.append(s)

            elif any(word in s_lower for word in ["treat", "recommend", "plan", "follow", "therapy"]):
                treatment.append(s)

            else:
                findings.append(s)

        return (
            f"Diagnosis: {' '.join(diagnosis)}\n\n"
            f"Key Findings: {' '.join(findings)}\n\n"
            f"Treatment Plan: {' '.join(treatment)}"
        )