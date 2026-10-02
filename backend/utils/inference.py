import json
import numpy as np
import tensorflow as tf

from config import MODEL_PATH, KNOWLEDGE_BASE_PATH, CLASS_NAMES, CONFIDENCE_THRESHOLD
from utils.preprocessing import load_and_preprocess_image

_model = None
_knowledge_base = None


def load_model_once():
    global _model
    if _model is None:
        _model = tf.keras.models.load_model(MODEL_PATH)
    return _model


def load_knowledge_base_once():
    global _knowledge_base
    if _knowledge_base is None:
        with open(KNOWLEDGE_BASE_PATH, "r", encoding="utf-8") as f:
            _knowledge_base = json.load(f)
    return _knowledge_base


def predict_species(file_path):
    model = load_model_once()
    knowledge_base = load_knowledge_base_once()

    img_array, original_img = load_and_preprocess_image(file_path)
    predictions = model.predict(img_array, verbose=0)[0]

    pred_idx = int(np.argmax(predictions))
    confidence = float(predictions[pred_idx])
    predicted_class = CLASS_NAMES[pred_idx]

    all_probs = {CLASS_NAMES[i]: round(float(p), 4) for i, p in enumerate(predictions)}
    advisory_report = knowledge_base.get(predicted_class)

    result = {
        "predicted_species": predicted_class,
        "confidence_score": round(confidence, 4),
        "low_confidence_warning": confidence < CONFIDENCE_THRESHOLD,
        "all_class_probabilities": all_probs,
        "advisory_report": advisory_report or "No botanical knowledge entry found.",
    }
    return result, original_img
