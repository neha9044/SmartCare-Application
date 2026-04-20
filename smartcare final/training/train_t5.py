from datasets import Dataset
from transformers import T5Tokenizer, T5ForConditionalGeneration, Trainer, TrainingArguments
import json

# -------- LOAD DATA --------
with open("dataset/medical_dataset_FIXED.json") as f:
    data = json.load(f)

dataset = Dataset.from_list(data)

# -------- LOAD MODEL --------
model_name = "t5-small"
tokenizer = T5Tokenizer.from_pretrained(model_name)
model = T5ForConditionalGeneration.from_pretrained(model_name)

# -------- PREPROCESS --------
def preprocess(example):
    input_text = "summarize: " + example["text"]

    inputs = tokenizer(
        input_text,
        max_length=512,
        truncation=True,
        padding="max_length"
    )

    targets = tokenizer(
        example["summary"],
        max_length=128,
        truncation=True,
        padding="max_length"
    )

    inputs["labels"] = targets["input_ids"]
    return inputs

dataset = dataset.map(preprocess, batched=False)

# -------- TRAIN --------
training_args = TrainingArguments(
    output_dir="./results",
    num_train_epochs=3,
    max_steps=-1,
    per_device_train_batch_size=8,
    logging_dir="./logs",
    save_strategy="epoch"
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=dataset
)

trainer.train()

# -------- SAVE --------
model.save_pretrained("medical_t5_model")
tokenizer.save_pretrained("medical_t5_model")

print("✅ Training complete!")