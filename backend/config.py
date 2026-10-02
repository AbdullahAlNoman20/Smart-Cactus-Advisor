import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# ------------------------------------------------------------------
# IMPORTANT: after downloading your trained model from Colab, place
# the .keras file here and make sure the filename below matches it.
# See README.md at the project root for the exact steps.
# ------------------------------------------------------------------
MODEL_PATH = os.path.join(BASE_DIR, "model", "smart_cactus_advisor_best_model.keras")
KNOWLEDGE_BASE_PATH = os.path.join(BASE_DIR, "knowledge_base.json")

IMG_SIZE = (224, 224)
CLASS_NAMES = [
    "Ball_Cactus",
    "Bunny_Ear_Cactus",
    "Chin_Cactus",
    "Easter_Lily_Cactus",
    "Starfish_Cactus",
]

VALID_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp"}
MAX_CONTENT_LENGTH_MB = 5
CONFIDENCE_THRESHOLD = 0.5

# Must match the architecture that won the "Model Comparison" cell in
# the Colab notebook. Change this ONE value to match your best model:
#   "custom"        -> Custom CNN
#   "resnet50"       -> ResNet50
#   "densenet"        -> DenseNet121
#   "efficientnet"    -> EfficientNetB0
#   "mobilenet_v3"    -> MobileNetV3
BEST_MODEL_PREPROCESSOR = "densenet"

UPLOAD_TEMP_DIR = os.path.join(BASE_DIR, "static", "uploads")
