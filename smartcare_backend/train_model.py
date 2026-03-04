"""
Medical Report Classifier Training Script

This script trains the ML model using external JSON dataset and saves it to disk.
Run this whenever you want to retrain with new data.

Usage:
    python train_model.py --dataset path/to/dataset.json
"""

import json
import pickle
import argparse
from pathlib import Path
from sklearn.pipeline import Pipeline
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix


# Label mapping from JSON to model classes
LABEL_MAP = {
    "lab": "Lab Report",
    "radiology": "Radiology Report",
    "discharge": "Discharge Summary"
}


def load_dataset(json_path):
    """
    Load training data from JSON file.
    
    Args:
        json_path: Path to JSON dataset file
    
    Returns:
        Tuple of (texts, labels)
    """
    print(f"\n📂 Loading dataset from: {json_path}")
    
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    texts = []
    labels = []
    
    for item in data:
        # Use the full text for training
        text = item.get('text', '')
        report_type = item.get('report_type', '')
        
        if text and report_type in LABEL_MAP:
            texts.append(text)
            labels.append(LABEL_MAP[report_type])
    
    print(f"✓ Loaded {len(texts)} training samples")
    
    # Count samples per class
    label_counts = {}
    for label in labels:
        label_counts[label] = label_counts.get(label, 0) + 1
    
    print("\n📊 Class Distribution:")
    for label, count in sorted(label_counts.items()):
        print(f"   {label}: {count} samples")
    
    return texts, labels


def train_classifier(texts, labels, test_size=0.2):
    """
    Train the ML classifier and evaluate performance.
    
    Args:
        texts: List of report texts
        labels: List of corresponding labels
        test_size: Fraction of data to use for testing (default: 0.2)
    
    Returns:
        Trained sklearn Pipeline
    """
    print(f"\n🔧 Training classifier with {len(texts)} samples...")
    
    # Split data: 80% training, 20% testing
    X_train, X_test, y_train, y_test = train_test_split(
        texts, labels,
        test_size=test_size,
        random_state=42,
        stratify=labels  # Ensures balanced split
    )
    
    print(f"   Training set: {len(X_train)} samples")
    print(f"   Test set: {len(X_test)} samples")
    
    # Create ML Pipeline: TF-IDF → Logistic Regression
    model = Pipeline([
        ('tfidf', TfidfVectorizer(
            max_features=1000,     # Increased from 500 for better accuracy
            ngram_range=(1, 3),    # Use 1-3 word combinations
            stop_words='english',
            lowercase=True,
            min_df=2,              # Ignore very rare terms
            max_df=0.9             # Ignore very common terms
        )),
        ('classifier', LogisticRegression(
            max_iter=2000,         # Increased iterations
            random_state=42,
            multi_class='multinomial',
            class_weight='balanced',  # Handle class imbalance
            C=1.0                     # Regularization strength
        ))
    ])
    
    # Train the model
    print("\n⏳ Training in progress...")
    model.fit(X_train, y_train)
    print("✓ Training completed!")
    
    # Evaluate on test set
    print("\n📈 Evaluating model performance...")
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    print("\n" + "="*70)
    print("🎯 MODEL PERFORMANCE REPORT")
    print("="*70)
    print(f"Test Accuracy: {accuracy:.2%}")
    print("\nDetailed Classification Report:")
    print(classification_report(y_test, y_pred, target_names=sorted(set(labels))))
    
    print("\nConfusion Matrix:")
    cm = confusion_matrix(y_test, y_pred, labels=sorted(set(labels)))
    print_confusion_matrix(cm, sorted(set(labels)))
    print("="*70 + "\n")
    
    return model


def print_confusion_matrix(cm, labels):
    """Pretty print confusion matrix."""
    print("\n           Predicted")
    print("           ", end="")
    for label in labels:
        print(f"{label[:12]:>12}", end=" ")
    print("\n")
    
    for i, label in enumerate(labels):
        print(f"Actual {label[:12]:>12} |", end=" ")
        for j in range(len(labels)):
            print(f"{cm[i][j]:>12}", end=" ")
        print()


def save_model(model, output_path):
    """
    Save trained model to disk using pickle.
    
    Args:
        model: Trained sklearn Pipeline
        output_path: Path where model should be saved
    """
    print(f"\n💾 Saving model to: {output_path}")
    
    with open(output_path, 'wb') as f:
        pickle.dump(model, f)
    
    file_size = Path(output_path).stat().st_size / 1024  # KB
    print(f"✓ Model saved successfully ({file_size:.1f} KB)")


def main():
    parser = argparse.ArgumentParser(description='Train medical report classifier')
    parser.add_argument(
        '--dataset',
        type=str,
        required=True,
        help='Path to JSON dataset file'
    )
    parser.add_argument(
        '--output',
        type=str,
        default='report_classifier_model.pkl',
        help='Output path for trained model (default: report_classifier_model.pkl)'
    )
    parser.add_argument(
        '--test-size',
        type=float,
        default=0.2,
        help='Fraction of data for testing (default: 0.2)'
    )
    
    args = parser.parse_args()
    
    print("\n" + "="*70)
    print("🏥 MEDICAL REPORT CLASSIFIER TRAINING")
    print("="*70)
    
    # Load dataset
    texts, labels = load_dataset(args.dataset)
    
    if len(texts) < 10:
        print("\n❌ ERROR: Dataset too small. Need at least 10 samples.")
        return
    
    # Train model
    model = train_classifier(texts, labels, test_size=args.test_size)
    
    # Save model
    save_model(model, args.output)
    
    print("\n✅ Training completed successfully!")
    print(f"\nTo use this model, update main.py to load '{args.output}'")
    print("="*70 + "\n")


if __name__ == "__main__":
    main()
