import io
from datetime import datetime

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Image as RLImage, Table, TableStyle
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle


def build_pdf_report(prediction_result, original_img, image_temp_path):
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4, topMargin=1.5 * cm, bottomMargin=1.5 * cm)
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle("TitleStyle", parent=styles["Title"], textColor=colors.HexColor("#1F4E3D"))
    heading_style = ParagraphStyle("HeadingStyle", parent=styles["Heading2"], textColor=colors.HexColor("#2E5E4E"))

    elements = [
        Paragraph("Smart Cactus Advisor — AI Advisory Report", title_style),
        Paragraph(datetime.now().strftime("Generated on %d %B %Y, %H:%M"), styles["Normal"]),
        Spacer(1, 0.6 * cm),
    ]

    original_img.save(image_temp_path, format="JPEG", quality=90)
    elements.append(RLImage(image_temp_path, width=6 * cm, height=6 * cm))
    elements.append(Spacer(1, 0.4 * cm))

    species = prediction_result["predicted_species"].replace("_", " ")
    confidence_pct = f"{prediction_result['confidence_score'] * 100:.2f}%"
    elements.append(Paragraph(f"Predicted Species: <b>{species}</b>", heading_style))
    elements.append(Paragraph(f"Confidence Score: <b>{confidence_pct}</b>", styles["Normal"]))

    if prediction_result["low_confidence_warning"]:
        warn_style = ParagraphStyle("Warn", parent=styles["Normal"], textColor=colors.red)
        elements.append(Paragraph(
            "Warning: Confidence is below the recommended threshold. "
            "Manual expert verification is advised.",
            warn_style
        ))

    elements.append(Spacer(1, 0.5 * cm))

    advisory = prediction_result["advisory_report"]
    if isinstance(advisory, dict):
        field_labels = {
            "scientific_name": "Scientific Name",
            "botanical_family": "Botanical Family",
            "medicinal_benefit": "Medicinal Benefit",
            "environmental_benefit": "Environmental Benefit",
            "ecological_importance": "Ecological Importance",
            "human_uses": "Human Uses",
            "water_requirement": "Water Requirement",
            "sunlight_requirement": "Sunlight Requirement",
            "toxicity": "Toxicity",
            "care_guide": "Care Guide",
        }
        table_data = [["Attribute", "Detail"]]
        for key, label in field_labels.items():
            value = advisory.get(key, "N/A")
            table_data.append([Paragraph(label, styles["Normal"]), Paragraph(value, styles["Normal"])])

        table = Table(table_data, colWidths=[4 * cm, 11 * cm])
        table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#2E5E4E")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F5F8F7")]),
        ]))
        elements.append(table)
    else:
        elements.append(Paragraph(str(advisory), styles["Normal"]))

    doc.build(elements)
    buffer.seek(0)
    return buffer
