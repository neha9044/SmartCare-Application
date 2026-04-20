import pandas as pd
import pickle

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import LinearSVC
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score
from sklearn.preprocessing import LabelEncoder

from utils.preprocess import clean_text

df = pd.read_csv("dataset/mtsamples (1).csv")

# Filter out classes with fewer than 20 samples for better generalization
counts = df['label'].value_counts()
df = df[df['label'].isin(counts[counts >= 20].index)]

print(f"Training on {len(df)} samples across {df['label'].nunique()} classes")

df["text"] = df["text"].apply(clean_text)

X = df["text"]
y = df["label"]

# Stratified split preserves class distribution in train/test sets
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# LinearSVC is the gold standard for high-dimensional sparse TF-IDF text classification.
# Pipeline keeps vectorizer + model tightly coupled and prevents data leakage.
pipeline = Pipeline([
    ('tfidf', TfidfVectorizer(
        max_features=30000,
        ngram_range=(1, 3),
        sublinear_tf=True,
        strip_accents='unicode',
        analyzer='word',
        min_df=2,
    )),
    ('clf', LinearSVC(
        C=0.8,
        class_weight='balanced',
        max_iter=2000,
        random_state=42
    ))
])

pipeline.fit(X_train, y_train)
y_pred = pipeline.predict(X_test)

accuracy = accuracy_score(y_test, y_pred)
print(f"\nAccuracy: {accuracy:.4f} ({accuracy*100:.2f}%)")
print("\nClassification Report:")
print(classification_report(y_test, y_pred))

# Save the full pipeline (vectorizer + model bundled together)
pickle.dump(pipeline, open("models/classifier.pkl", "wb"))
# Also save vectorizer separately for backward compatibility with api/main.py
pickle.dump(pipeline.named_steps['tfidf'], open("models/tfidf_vectorizer.pkl", "wb"))
print("\nModel saved to models/classifier.pkl")
