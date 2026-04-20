import json
import pickle
import os
import re
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report

# Configuration
DATASET_PATH = "dataset/medical_REALWORLD_high_diversity_dataset.json"
MODEL_DEST = "models/summary_model.pkl"
VECTORIZER_DEST = "models/summary_vectorizer.pkl"

def train_medical_model():
    if not os.path.exists(DATASET_PATH):
        print(f"❌ Error: {DATASET_PATH} not found.")
        return

    with open(DATASET_PATH, "r") as f:
        data = json.load(f)

    print(f"✅ Dataset loaded. Building labels using Fuzzy Overlap...")

    processed_texts = []
    labels = []

    # 1. Create Binary Labels using Keyword Overlap
    # This fixes the "ValueError: only one class" by finding similar sentences
    for item in data:
        full_text = item.get('text', "")
        summary = item.get('summary', "").lower()
        summary_words = set(re.findall(r'\w+', summary))
        
        # Split into sentences
        sentences = re.split(r'\. |\n', full_text) 
        
        for sent in sentences:
            clean_sent = sent.strip()
            if len(clean_sent) < 15: 
                continue 
            
            # Check overlap between sentence words and summary words
            sent_words = set(re.findall(r'\w+', clean_sent.lower()))
            if not sent_words:
                continue
                
            overlap = sent_words.intersection(summary_words)
            
            processed_texts.append(clean_sent)
            
            # If >30% of words match the summary, it's an important sentence (Label 1)
            if (len(overlap) / len(sent_words)) > 0.3:
                labels.append(1)
            else:
                labels.append(0)

    # 2. Verify we have both classes (0s and 1s)
    unique_classes = np.unique(labels)
    counts = dict(zip(*np.unique(labels, return_counts=True)))
    print(f"📊 Data Distribution: {counts}")

    if len(unique_classes) < 2:
        print("❌ Error: Still only found one class. Try lowering the overlap threshold (0.3).")
        return

    # 3. Split Data
    X_train, X_test, y_train, y_test = train_test_split(
        processed_texts, labels, test_size=0.2, random_state=42, stratify=labels
    )

    # 4. Vectorization
    vectorizer = TfidfVectorizer(
        max_features=2000, 
        ngram_range=(1, 2), 
        stop_words='english'
    )
    X_train_tfidf = vectorizer.fit_transform(X_train)
    X_test_tfidf = vectorizer.transform(X_test)

    # 5. Training (C=0.1 prevents the 100% accuracy/overfitting bug)
    model = LogisticRegression(
        C=0.1, 
        solver='lbfgs', 
        class_weight='balanced', 
        max_iter=1000
    )
    model.fit(X_train_tfidf, y_train)

    # 6. Evaluation
    y_pred = model.predict(X_test_tfidf)
    print("\n--- Final Model Performance ---")
    print(classification_report(y_test, y_pred))

    # 7. Save Pickles
    os.makedirs("models", exist_ok=True)
    with open(MODEL_DEST, "wb") as f:
        pickle.dump(model, f)
    with open(VECTORIZER_DEST, "wb") as v:
        pickle.dump(vectorizer, v)

    print(f"\n🚀 Success! Model saved. You can now run your FastAPI app.")

if __name__ == "__main__":
    train_medical_model()