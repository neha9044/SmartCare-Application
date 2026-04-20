import re
import nltk
from nltk.corpus import stopwords

nltk.download("stopwords")

stop_words = set(stopwords.words("english"))
def clean_text(text):
    # 1. REMOVE STRUCTURAL "GIVEAWAY" WORDS
    giveaways = [
        r'lab report', r'radiology report', r'discharge summary',
        r'examination', r'findings', r'impression', r'history of present illness',
        r'final diagnosis', r'hospital course', r'medications at discharge'
    ]
    for pattern in giveaways:
        text = re.sub(pattern, '', text, flags=re.IGNORECASE)

    # 2. Existing cleaning logic
    text = re.sub(r'\(cid:\d+\)', '', text)
    text = text.lower()
    text = re.sub(r'[^a-zA-Z\s]', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip()

    words = text.split()
    words = [w for w in words if w not in stop_words]
    return " ".join(words)