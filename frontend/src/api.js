import axios from "axios";

const API_BASE_URL = process.env.REACT_APP_API_BASE_URL || "http://localhost:5000";

export async function predictImage(file) {
  const formData = new FormData();
  formData.append("image", file);
  const response = await axios.post(`${API_BASE_URL}/api/predict`, formData, {
    headers: { "Content-Type": "multipart/form-data" },
  });
  return response.data;
}

export async function downloadPdfReport(file) {
  const formData = new FormData();
  formData.append("image", file);
  const response = await axios.post(`${API_BASE_URL}/api/predict-pdf`, formData, {
    headers: { "Content-Type": "multipart/form-data" },
    responseType: "blob",
  });

  const blob = new Blob([response.data], { type: "application/pdf" });
  const url = window.URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = "Smart_Cactus_Advisor_Report.pdf";
  document.body.appendChild(link);
  link.click();
  link.remove();
  window.URL.revokeObjectURL(url);
}
