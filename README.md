# Smart Cactus Advisor — Web Application

This project is a ready-made Flask + React application for the Smart Cactus
Advisor model. Everything is already wired together — you only need to add
your trained model file. No code changes are required.

---

## STEP 1 — Download the trained model from Google Colab

In your Colab notebook, after the "Model Comparison & Best Model Selection"
cell finishes running, the best model is automatically saved to Google
Drive at:

```
/content/drive/MyDrive/Dataset/models/smart_cactus_advisor_best_model.keras
```

Also locate the knowledge base file:

```
/content/drive/MyDrive/Dataset/knowledge_base.json
```

Open **Google Drive** in your browser, navigate to these two files, and
**download them** to your computer (right-click → Download).

> Note: a copy of `knowledge_base.json` is already included in this project
> (`backend/knowledge_base.json`), so you only strictly need to download the
> `.keras` model file. Only replace the included JSON if you edited the
> botanical information in Colab.

---

## STEP 2 — Place the model file (no code editing required)

1. Open this project folder on your computer.
2. Go into: `backend/model/`
3. Copy the file you downloaded (`smart_cactus_advisor_best_model.keras`)
   into that folder.
4. Make sure the filename is **exactly**:
   ```
   smart_cactus_advisor_best_model.keras
   ```
   (If your browser renamed it, e.g. `smart_cactus_advisor_best_model (1).keras`,
   rename it back to the name above.)
5. You may delete `backend/model/PLACE_YOUR_MODEL_HERE.txt` — it is just a
   placeholder note and is not used by the code.

### Only if your best model was NOT DenseNet121

The project is pre-configured for **DenseNet121** (the best-performing
model in the reference run). If a different architecture won in your run,
open `backend/config.py` and change ONE line:

```python
BEST_MODEL_PREPROCESSOR = "densenet"
```

to one of:

| Your best model  | Set this value        |
|-------------------|-----------------------|
| Custom CNN         | `"custom"`             |
| ResNet50           | `"resnet50"`           |
| DenseNet121        | `"densenet"` (default) |
| EfficientNetB0      | `"efficientnet"`        |
| MobileNetV3          | `"mobilenet_v3"`         |

If DenseNet121 was your best model, skip this — no change needed.

---

## STEP 3 — Run the backend (Flask API)

Open a terminal in the project folder and run:

```bash
cd backend
python -m venv venv

# Activate the virtual environment:
source venv/bin/activate        # macOS/Linux
venv\Scripts\activate           # Windows

pip install -r requirements.txt
python app.py
```

The backend will start at: **http://localhost:5000**

Leave this terminal window running.

---

## STEP 4 — Run the frontend (React dashboard)

Open a **second** terminal window in the project folder and run:

```bash
cd frontend
npm install
npm start
```

The dashboard will open automatically at: **http://localhost:3000**

(Requires Node.js installed on your computer — download from nodejs.org
if you don't have it.)

---

## STEP 5 — Use the app

1. Go to **http://localhost:3000** in your browser.
2. Click "Choose File" and select a cactus photo (JPG, PNG, or BMP, max 5 MB).
3. Click **"Identify Cactus"** — the predicted species, confidence score,
   and the full advisory report (scientific name, medicinal benefit,
   care guide, etc.) will appear.
4. Click **"Download PDF Report"** to get a formatted PDF you can save or
   print, or click **"Print"** to print directly from the browser.

---

## Folder Reference

```
cactus-advisor/
├── README.md                          <- you are here
├── backend/
│   ├── requirements.txt
│   ├── config.py                      <- only file you may need to edit (1 line)
│   ├── app.py                         <- Flask server / API routes
│   ├── knowledge_base.json            <- botanical info (already filled in)
│   ├── model/
│   │   └── smart_cactus_advisor_best_model.keras   <- YOU add this file
│   └── utils/
│       ├── preprocessing.py           <- image validation + preprocessing
│       ├── inference.py               <- loads model, runs prediction
│       └── pdf_report.py              <- generates the downloadable PDF
└── frontend/
    ├── package.json
    ├── public/index.html
    └── src/
        ├── App.jsx
        ├── api.js                     <- calls the Flask API
        └── components/
            ├── UploadDashboard.jsx    <- upload form + main page
            ├── ResultCard.jsx         <- shows prediction + advisory table
            └── Loader.jsx
```

---

## Troubleshooting

- **"Model file not found" error when predicting** → you haven't placed the
  `.keras` file in `backend/model/`, or it's misnamed. See Step 2.
- **Predictions look wrong / confidence always low** → your model was
  probably not DenseNet121; set `BEST_MODEL_PREPROCESSOR` correctly in
  `backend/config.py` (see Step 2).
- **Frontend shows a network/CORS error** → make sure the backend
  (`python app.py`) is running and shows `http://localhost:5000` before
  you use the dashboard.
- **Port already in use** → close any other program using port 5000 or
  3000, or change the port in `backend/app.py` (`app.run(port=5001)`) and
  update `REACT_APP_API_BASE_URL` accordingly.

---

## Production Notes (optional, for later deployment)

- Restrict CORS before going public: `CORS(app, origins=["https://yourdomain.com"])`
- Build the React app for production: `npm run build` (inside `frontend/`),
  then serve the generated `build/` folder with Nginx or similar.
- Run Flask via a production server (e.g. `gunicorn app:app`) behind a
  reverse proxy instead of `python app.py`.
- Set the `REACT_APP_API_BASE_URL` environment variable if the API is
  hosted on a different domain than the frontend.
