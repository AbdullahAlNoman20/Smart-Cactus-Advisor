import os
import numpy as np
from PIL import Image, UnidentifiedImageError
import tensorflow as tf

from config import IMG_SIZE, VALID_EXTENSIONS, BEST_MODEL_PREPROCESSOR

PREPROCESS_FUNCS = {
    "custom": lambda x: x / 255.0,
    "resnet50": tf.keras.applications.resnet50.preprocess_input,
    "densenet": tf.keras.applications.densenet.preprocess_input,
    "efficientnet": tf.keras.applications.efficientnet.preprocess_input,
    "mobilenet_v3": tf.keras.applications.mobilenet_v3.preprocess_input,
}


class InvalidImageError(Exception):
    pass


def validate_image_file(file_storage):
    filename = file_storage.filename or ""
    ext = os.path.splitext(filename)[1].lower()
    if ext not in VALID_EXTENSIONS:
        raise InvalidImageError(f"Unsupported file type: {ext or 'unknown'}")
    return ext


def load_and_preprocess_image(file_path):
    try:
        with Image.open(file_path) as img:
            img.verify()
        img = Image.open(file_path).convert("RGB")
    except (UnidentifiedImageError, OSError) as e:
        raise InvalidImageError(f"Corrupted or unreadable image: {e}")

    img_resized = img.resize(IMG_SIZE)
    img_array = np.array(img_resized, dtype=np.float32)
    img_array = np.expand_dims(img_array, axis=0)

    preprocess_fn = PREPROCESS_FUNCS[BEST_MODEL_PREPROCESSOR]
    img_array = preprocess_fn(img_array)

    return img_array, img
