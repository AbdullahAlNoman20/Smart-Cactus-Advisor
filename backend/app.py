import os
import uuid

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from werkzeug.utils import secure_filename

from config import UPLOAD_TEMP_DIR, MAX_CONTENT_LENGTH_MB
from utils.preprocessing import validate_image_file, InvalidImageError
from utils.inference import predict_species, load_model_once, load_knowledge_base_once
from utils.pdf_report import build_pdf_report

app = Flask(__name__)
CORS(app)  # In production: CORS(app, origins=["https://yourdomain.com"])

app.config["MAX_CONTENT_LENGTH"] = MAX_CONTENT_LENGTH_MB * 1024 * 1024

os.makedirs(UPLOAD_TEMP_DIR, exist_ok=True)

# Load the model and knowledge base once, at server startup, so every
# request is fast (no reloading the model on every call).
load_model_once()
load_knowledge_base_once()


def save_uploaded_file(file_storage):
    ext = validate_image_file(file_storage)
    safe_name = secure_filename(f"{uuid.uuid4().hex}{ext}")
    dest_path = os.path.join(UPLOAD_TEMP_DIR, safe_name)
    file_storage.save(dest_path)
    return dest_path


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})


@app.route("/api/predict", methods=["POST"])
def predict():
    if "image" not in request.files or request.files["image"].filename == "":
        return jsonify({"error": "No image file provided under field name 'image'."}), 400

    temp_path = None
    try:
        temp_path = save_uploaded_file(request.files["image"])
        result, _ = predict_species(temp_path)
        return jsonify(result), 200
    except InvalidImageError as e:
        return jsonify({"error": str(e)}), 400
    except Exception:
        return jsonify({"error": "Internal server error while processing the image."}), 500
    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)


@app.route("/api/predict-pdf", methods=["POST"])
def predict_pdf():
    if "image" not in request.files or request.files["image"].filename == "":
        return jsonify({"error": "No image file provided under field name 'image'."}), 400

    temp_path = None
    pdf_image_path = None
    try:
        temp_path = save_uploaded_file(request.files["image"])
        result, original_img = predict_species(temp_path)

        pdf_image_path = os.path.join(UPLOAD_TEMP_DIR, f"{uuid.uuid4().hex}.jpg")
        pdf_buffer = build_pdf_report(result, original_img, pdf_image_path)

        return send_file(
            pdf_buffer,
            mimetype="application/pdf",
            as_attachment=True,
            download_name="Smart_Cactus_Advisor_Report.pdf",
        )
    except InvalidImageError as e:
        return jsonify({"error": str(e)}), 400
    except Exception:
        return jsonify({"error": "Internal server error while generating the report."}), 500
    finally:
        for path in (temp_path, pdf_image_path):
            if path and os.path.exists(path):
                os.remove(path)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
