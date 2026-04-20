import pickle
import json
import pandas as pd
from sklearn.metrics import accuracy_score, classification_report
from utils.preprocess import clean_text

# Load model and vectorizer
try:
    model = pickle.load(open("models/classifier.pkl", "rb"))
    vectorizer = pickle.load(open("models/tfidf_vectorizer.pkl", "rb"))
except FileNotFoundError:
    print("Model or vectorizer not found. Please train the model first.")
    exit()

# Load dataset
with open("dataset/medical_REALWORLD_high_diversity_dataset.json", "r") as f:
    data = json.load(f)

texts = [item["text"] for item in data]
labels = [item["report_type"] for item in data]

# Preprocess
texts = [clean_text(t) for t in texts]

# Transform
# If it's a pipeline, we might need to handle it differently.
# Let's check if classifier.pkl is a pipeline or just the model.
if hasattr(model, 'named_steps'):
    # It's a pipeline
    y_pred = model.predict(texts)
else:
    # Separate vectorizer and model
    X_vec = vectorizer.transform(texts)
    y_pred = model.predict(X_vec)

# Evaluate
accuracy = accuracy_score(labels, y_pred)
print(f"Current Model Accuracy: {accuracy:.4f} ({accuracy*100:.2f}%)")
print("\nClassification Report:")
print(classification_report(labels, y_pred))
