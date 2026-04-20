import pandas as pd
import pickle
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from imblearn.over_sampling import SMOTE

from utils.preprocess import clean_text


print("🔥 NEW SPECIALITY MODEL V2 RUNNING 🔥")


# =============================
# 1. LOAD DATA
# =============================
df = pd.read_csv("dataset/mtsamples (1).csv")
df = df.dropna(subset=['transcription', 'medical_specialty'])


# =============================
# 2. MAP SPECIALTIES (MORE CLASSES)
# =============================
def map_specialties(spec):
    spec = str(spec).lower()

    if 'radiology' in spec: return 'Radiology'
    if 'discharge' in spec or 'consult' in spec: return 'Discharge'
    if 'surgery' in spec or 'orthopedic' in spec: return 'Surgery'
    if 'cardio' in spec: return 'Cardiology'
    if 'neuro' in spec: return 'Neurology'
    if 'gastro' in spec: return 'Gastroenterology'
    if 'urology' in spec: return 'Urology'
    if 'derma' in spec: return 'Dermatology'
    if 'ent' in spec or 'otolaryngology' in spec: return 'ENT'
    if 'pulmonary' in spec: return 'Pulmonology'

    return None


df['label'] = df['medical_specialty'].apply(map_specialties)
df = df.dropna(subset=['label'])
df = df[df['label'] != 'Radiology']


# =============================
# 3. REMOVE SMALL CLASSES
# =============================
counts = df['label'].value_counts()
df = df[df['label'].isin(counts[counts >= 200].index)]

print(f"\nTotal samples after filtering: {len(df)}")
print("\nSamples per class:\n", df['label'].value_counts())


# =============================
# 4. CLEAN TEXT
# =============================
X = df['transcription'].apply(clean_text)
y = df['label']


# =============================
# 5. TF-IDF
# =============================
vectorizer = TfidfVectorizer(
    max_features=15000,
    ngram_range=(1, 3),
    min_df=3,
    max_df=0.85,
    sublinear_tf=True,
    stop_words='english'
)

X_vec = vectorizer.fit_transform(X)


# =============================
# 6. SMOTE BALANCING
# =============================
smote = SMOTE(random_state=42)
X_vec, y = smote.fit_resample(X_vec, y)

print("\nAfter SMOTE balancing:")
print(pd.Series(y).value_counts())


# =============================
# 7. TRAIN / TEST SPLIT
# =============================
X_train, X_test, y_train, y_test = train_test_split(
    X_vec, y,
    test_size=0.2,
    random_state=42,
    stratify=y
)


# =============================
# 8. MODEL (LOGISTIC REGRESSION)
# =============================
model = LogisticRegression(
    C=1.5,
    class_weight='balanced',
    max_iter=4000,
    solver='lbfgs'
)

model.fit(X_train, y_train)


# =============================
# 9. EVALUATION
# =============================
y_pred = model.predict(X_test)

accuracy = accuracy_score(y_test, y_pred)

print(f"\n🔥 Final Accuracy: {accuracy:.4f} ({accuracy*100:.2f}%)")
print("\nClassification Report:\n")
print(classification_report(y_test, y_pred))

print("\nConfusion Matrix:\n")
print(confusion_matrix(y_test, y_pred))


# =============================
# 10. SAVE MODEL
# =============================
pickle.dump(model, open("models/specialty_classifier_v2.pkl", "wb"))
pickle.dump(vectorizer, open("models/specialty_vectorizer_v2.pkl", "wb"))

print("\n✅ V2 Model saved successfully!")