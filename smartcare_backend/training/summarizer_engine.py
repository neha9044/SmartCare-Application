import nltk
import pickle
import re

# Ensure tokenizer
nltk.download('punkt', quiet=True)

class MedicalSummarizerEngine:
    def __init__(self, model_path, vectorizer_path):
        with open(model_path, "rb") as f:
            self.model = pickle.load(f)
        with open(vectorizer_path, "rb") as v:
            self.vectorizer = pickle.load(v)

        self.priority_terms = [
            "diagnosis", "consistent with", "suggestive of", "impression",
            "anemia", "croup", "angina", "infarct", "mass", "lesion", "ischemia"
        ]

    def _deep_clean(self, text):
        text = text.lower()

        noise_patterns = [
         r"electronically signed by.*",
         r"if your model is nice.*",
         ]

        for pattern in noise_patterns:
            text = re.sub(pattern, "", text)

        text = re.sub(r'\b\d+\.\s*', '', text)
        text = re.sub(r'[^a-z0-9.\n ]', ' ', text)
        text = re.sub(r'\s+', ' ', text).strip()

        return text

    def _calculate_clinical_weight(self, sentence):
        weight = 0.0

        if any(term in sentence for term in self.priority_terms):
            weight += 0.4

        if "normal" in sentence and any(org in sentence for org in ["brain", "heart", "lungs"]):
            weight += 0.3

        if any(junk in sentence for junk in ["doctor", "referring", "patient"]):
            weight -= 0.5

        return weight

    def summarize_ml(self, raw_text):
        cleaned_text = self._deep_clean(raw_text)

        sentences = nltk.sent_tokenize(cleaned_text)

        candidates = [
            s for s in sentences
            if len(s.split()) > 5
        ]

        if not candidates:
            return "No significant clinical findings identified."

        X = self.vectorizer.transform(candidates)
        probs = self.model.predict_proba(X)[:, 1]

        scored = []
        for i, sent in enumerate(candidates):
            score = probs[i] + self._calculate_clinical_weight(sent)
            scored.append((sent, score))

        ranked = sorted(scored, key=lambda x: x[1], reverse=True)

        selected = []
        seen = set()

        for sent, _ in ranked:
            if len(selected) >= 8:
                break

            key = sent[:20]
            if key not in seen:
                selected.append(sent)
                seen.add(key)

        return self._format_output(selected)

    def _format_output(self, sentences):
        formatted = []
        for s in sentences:
            s = s.strip().capitalize()
            if not s.endswith('.'):
                s += '.'
            formatted.append(s)

        return " ".join(formatted)