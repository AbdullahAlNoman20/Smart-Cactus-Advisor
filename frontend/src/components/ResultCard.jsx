import React from "react";

const FIELD_LABELS = {
  scientific_name: "Scientific Name",
  botanical_family: "Botanical Family",
  medicinal_benefit: "Medicinal Benefit",
  environmental_benefit: "Environmental Benefit",
  ecological_importance: "Ecological Importance",
  human_uses: "Human Uses",
  water_requirement: "Water Requirement",
  sunlight_requirement: "Sunlight Requirement",
  toxicity: "Toxicity",
  care_guide: "Care Guide",
};

export default function ResultCard({ result, previewUrl, onDownloadPdf, downloading }) {
  if (!result) return null;

  const speciesName = result.predicted_species.replace(/_/g, " ");
  const confidencePct = (result.confidence_score * 100).toFixed(2);
  const advisory = result.advisory_report;

  return (
    <div className="result-card" id="printable-report">
      <div className="result-header">
        {previewUrl && <img src={previewUrl} alt="Uploaded cactus" className="result-thumb" />}
        <div>
          <h2>{speciesName}</h2>
          <p className={result.low_confidence_warning ? "confidence low" : "confidence high"}>
            Confidence: {confidencePct}%
          </p>
          {result.low_confidence_warning && (
            <p className="warning-text">Low confidence — manual expert verification is recommended.</p>
          )}
        </div>
      </div>

      {typeof advisory === "object" && (
        <table className="advisory-table">
          <tbody>
            {Object.entries(FIELD_LABELS).map(([key, label]) => (
              <tr key={key}>
                <td className="label-cell">{label}</td>
                <td>{advisory[key] || "N/A"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      <div className="action-row no-print">
        <button onClick={onDownloadPdf} disabled={downloading}>
          {downloading ? "Preparing PDF…" : "Download PDF Report"}
        </button>
        <button onClick={() => window.print()}>Print</button>
      </div>
    </div>
  );
}
