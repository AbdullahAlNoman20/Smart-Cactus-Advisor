import React, { useState } from "react";
import { predictImage, downloadPdfReport } from "../api";
import ResultCard from "./ResultCard";
import Loader from "./Loader";

const MAX_FILE_SIZE_MB = 5;
const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/bmp"];

export default function UploadDashboard() {
  const [file, setFile] = useState(null);
  const [previewUrl, setPreviewUrl] = useState(null);
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const [downloading, setDownloading] = useState(false);
  const [error, setError] = useState("");

  function handleFileChange(e) {
    const selected = e.target.files[0];
    setError("");
    setResult(null);
    if (!selected) return;

    if (!ALLOWED_TYPES.includes(selected.type)) {
      setError("Only JPG, PNG, or BMP images are allowed.");
      return;
    }
    if (selected.size > MAX_FILE_SIZE_MB * 1024 * 1024) {
      setError(`File is too large. Maximum size is ${MAX_FILE_SIZE_MB} MB.`);
      return;
    }

    setFile(selected);
    setPreviewUrl(URL.createObjectURL(selected));
  }

  async function handleAnalyze() {
    if (!file) {
      setError("Please choose a cactus image first.");
      return;
    }
    setLoading(true);
    setError("");
    try {
      const data = await predictImage(file);
      setResult(data);
    } catch (err) {
      setError(err?.response?.data?.error || "Prediction failed. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  async function handleDownloadPdf() {
    if (!file) return;
    setDownloading(true);
    try {
      await downloadPdfReport(file);
    } catch (err) {
      setError("Could not generate the PDF report. Please try again.");
    } finally {
      setDownloading(false);
    }
  }

  return (
    <div className="dashboard">
      <h1>Smart Cactus Advisor</h1>
      <p className="subtitle">
        Upload a cactus photo to identify the species and get an evidence-based advisory report.
      </p>

      <div className="upload-box no-print">
        <input type="file" accept="image/jpeg,image/png,image/bmp" onChange={handleFileChange} />
        {previewUrl && <img src={previewUrl} alt="Preview" className="preview-thumb" />}
        <button onClick={handleAnalyze} disabled={loading}>
          {loading ? "Analyzing…" : "Identify Cactus"}
        </button>
        {error && <p className="error-text">{error}</p>}
      </div>

      {loading && <Loader />}

      <ResultCard
        result={result}
        previewUrl={previewUrl}
        onDownloadPdf={handleDownloadPdf}
        downloading={downloading}
      />
    </div>
  );
}
