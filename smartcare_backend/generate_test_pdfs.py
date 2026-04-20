from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.units import inch
from reportlab.lib import colors
import os

os.makedirs("test_pdfs", exist_ok=True)

styles = getSampleStyleSheet()
title_style = ParagraphStyle('Title', parent=styles['Heading1'], fontSize=16, spaceAfter=12)
heading_style = ParagraphStyle('Heading', parent=styles['Heading2'], fontSize=12, spaceAfter=6)
body_style = ParagraphStyle('Body', parent=styles['Normal'], fontSize=10, spaceAfter=6, leading=14)

# ===========================================================
# 1. DISCHARGE REPORT
# ===========================================================
doc = SimpleDocTemplate("test_pdfs/discharge_report.pdf", pagesize=letter,
                        rightMargin=inch, leftMargin=inch, topMargin=inch, bottomMargin=inch)
content = []

content.append(Paragraph("PATIENT DISCHARGE SUMMARY", title_style))
content.append(Paragraph("City General Hospital — Department of Internal Medicine", body_style))
content.append(Spacer(1, 0.2*inch))

content.append(Paragraph("Patient Information", heading_style))
content.append(Paragraph("<b>Name:</b> John Michael Carter", body_style))
content.append(Paragraph("<b>MRN:</b> 00482719", body_style))
content.append(Paragraph("<b>Date of Birth:</b> 14 June 1958 (Age: 67)", body_style))
content.append(Paragraph("<b>Admission Date:</b> 03 March 2026", body_style))
content.append(Paragraph("<b>Discharge Date:</b> 08 March 2026", body_style))
content.append(Paragraph("<b>Length of Stay:</b> 5 days", body_style))
content.append(Paragraph("<b>Attending Physician:</b> Dr. Sarah Johnson, MD", body_style))
content.append(Spacer(1, 0.1*inch))

content.append(Paragraph("Admitting Diagnosis", heading_style))
content.append(Paragraph(
    "The patient was admitted with a primary diagnosis of acute decompensated heart failure (ADHF) "
    "with preserved ejection fraction. Secondary diagnoses included hypertension, type 2 diabetes mellitus, "
    "and chronic kidney disease stage 3.", body_style))
content.append(Spacer(1, 0.1*inch))

content.append(Paragraph("Hospital Course", heading_style))
content.append(Paragraph(
    "The patient presented to the emergency department with progressive dyspnea on exertion, orthopnea, "
    "bilateral lower extremity edema, and a weight gain of 6 kg over the past two weeks. Upon admission, "
    "the patient was placed on supplemental oxygen and initiated on IV furosemide therapy with good diuretic "
    "response. A total fluid loss of approximately 4.5 liters was achieved over the hospitalization. "
    "Echocardiogram demonstrated preserved ejection fraction of 55% with diastolic dysfunction Grade II. "
    "Cardiology was consulted and recommended optimization of beta-blocker therapy. Renal function was "
    "monitored closely given underlying CKD; creatinine remained stable throughout the stay. "
    "Blood glucose management was achieved with sliding scale insulin and metformin was held upon discharge "
    "given contrast exposure during imaging.", body_style))
content.append(Spacer(1, 0.1*inch))

content.append(Paragraph("Discharge Condition", heading_style))
content.append(Paragraph("The patient was discharged in stable condition, ambulatory, and tolerating oral intake. "
    "Patient was hemodynamically stable with blood pressure 128/78 mmHg, heart rate 72 bpm, oxygen saturation "
    "96% on room air. Patient and family were educated on dietary sodium restriction (less than 2g/day), "
    "daily weight monitoring, and warning signs requiring emergency care.", body_style))
content.append(Spacer(1, 0.1*inch))

content.append(Paragraph("Discharge Medications", heading_style))
medications = [
    "Furosemide 40mg oral once daily",
    "Carvedilol 12.5mg oral twice daily",
    "Lisinopril 5mg oral once daily",
    "Amlodipine 5mg oral once daily",
    "Aspirin 81mg oral once daily",
    "Atorvastatin 40mg oral at bedtime",
    "Metformin 500mg oral twice daily (to be restarted after 48 hours)",
]
for med in medications:
    content.append(Paragraph(f"• {med}", body_style))
content.append(Spacer(1, 0.1*inch))

content.append(Paragraph("Follow-Up Instructions", heading_style))
content.append(Paragraph(
    "Patient instructed to follow up with primary care physician within 5 days of discharge. "
    "Cardiology follow-up scheduled in 2 weeks. Nephrology referral provided. "
    "Patient to present to emergency department if weight increases more than 2 kg in 24 hours, "
    "worsening shortness of breath, or chest pain occurs.", body_style))

doc.build(content)
print("✅ discharge_report.pdf created")


# ===========================================================
# 2. LAB REPORT
# ===========================================================
doc = SimpleDocTemplate("test_pdfs/lab_report.pdf", pagesize=letter,
                        rightMargin=inch, leftMargin=inch, topMargin=inch, bottomMargin=inch)
content = []

content.append(Paragraph("LABORATORY INVESTIGATION REPORT", title_style))
content.append(Paragraph("MediLab Diagnostics Pvt. Ltd. | NABL Accredited Laboratory", body_style))
content.append(Spacer(1, 0.2*inch))

content.append(Paragraph("Patient & Specimen Details", heading_style))
content.append(Paragraph("<b>Name:</b> Priya Anand", body_style))
content.append(Paragraph("<b>Age/Gender:</b> 34 Years / Female", body_style))
content.append(Paragraph("<b>Referring Doctor:</b> Dr. Ramesh Patel", body_style))
content.append(Paragraph("<b>Sample ID:</b> ML-2026-089341", body_style))
content.append(Paragraph("<b>Sample Type:</b> Venous Blood (EDTA + Serum)", body_style))
content.append(Paragraph("<b>Collection Date:</b> 09 March 2026, 07:30 AM", body_style))
content.append(Paragraph("<b>Report Date:</b> 09 March 2026, 02:00 PM", body_style))
content.append(Spacer(1, 0.1*inch))

content.append(Paragraph("Complete Blood Count (CBC)", heading_style))
cbc_data = [
    ("Hemoglobin", "10.2 g/dL", "12.0 – 16.0 g/dL", "LOW ↓"),
    ("RBC Count", "3.8 × 10⁶/µL", "3.8 – 5.2 × 10⁶/µL", "Normal"),
    ("Hematocrit (PCV)", "31%", "36 – 46%", "LOW ↓"),
    ("MCV", "72 fL", "80 – 100 fL", "LOW ↓"),
    ("MCH", "22 pg", "27 – 33 pg", "LOW ↓"),
    ("MCHC", "30 g/dL", "31.5 – 36.0 g/dL", "LOW ↓"),
    ("Platelets", "245 × 10³/µL", "150 – 400 × 10³/µL", "Normal"),
    ("WBC Count", "7.8 × 10³/µL", "4.0 – 11.0 × 10³/µL", "Normal"),
    ("Neutrophils", "62%", "40 – 75%", "Normal"),
    ("Lymphocytes", "28%", "20 – 40%", "Normal"),
]
content.append(Paragraph("<b>Test | Result | Reference Range | Flag</b>", body_style))
for test, result, ref, flag in cbc_data:
    content.append(Paragraph(f"• {test}: {result}  [Ref: {ref}]  — {flag}", body_style))
content.append(Spacer(1, 0.1*inch))

content.append(Paragraph("Iron Studies", heading_style))
iron_data = [
    ("Serum Iron", "42 µg/dL", "60 – 170 µg/dL", "LOW ↓"),
    ("TIBC", "415 µg/dL", "250 – 370 µg/dL", "HIGH ↑"),
    ("Transferrin Saturation", "10%", "20 – 55%", "LOW ↓"),
    ("Serum Ferritin", "6 ng/mL", "12 – 150 ng/mL", "LOW ↓"),
]
for test, result, ref, flag in iron_data:
    content.append(Paragraph(f"• {test}: {result}  [Ref: {ref}]  — {flag}", body_style))
content.append(Spacer(1, 0.1*inch))

content.append(Paragraph("Thyroid Function Tests", heading_style))
thyroid_data = [
    ("TSH", "2.4 mIU/L", "0.4 – 4.0 mIU/L", "Normal"),
    ("Free T3", "3.1 pmol/L", "2.6 – 5.7 pmol/L", "Normal"),
    ("Free T4", "14.2 pmol/L", "9.0 – 19.0 pmol/L", "Normal"),
]
for test, result, ref, flag in thyroid_data:
    content.append(Paragraph(f"• {test}: {result}  [Ref: {ref}]  — {flag}", body_style))
content.append(Spacer(1, 0.1*inch))

content.append(Paragraph("Interpretation", heading_style))
content.append(Paragraph(
    "The CBC and iron studies are consistent with iron deficiency anemia, characterized by low hemoglobin, "
    "microcytic hypochromic red cells (low MCV, MCH, MCHC), reduced serum ferritin, elevated TIBC, and "
    "decreased transferrin saturation. Thyroid function tests are within normal limits. "
    "Clinical correlation and dietary/supplementation follow-up is recommended. "
    "Please consult with the referring physician for further management.", body_style))

doc.build(content)
print("✅ lab_report.pdf created")


# ===========================================================
# 3. RADIOLOGY REPORT
# ===========================================================
doc = SimpleDocTemplate("test_pdfs/radiology_report.pdf", pagesize=letter,
                        rightMargin=inch, leftMargin=inch, topMargin=inch, bottomMargin=inch)
content = []

content.append(Paragraph("RADIOLOGY REPORT", title_style))
content.append(Paragraph("St. Luke's Medical Center — Department of Diagnostic Radiology", body_style))
content.append(Spacer(1, 0.2*inch))

content.append(Paragraph("Examination Details", heading_style))
content.append(Paragraph("<b>Patient:</b> Robert James Hargreaves", body_style))
content.append(Paragraph("<b>DOB:</b> 22 September 1972 (Age: 53)", body_style))
content.append(Paragraph("<b>MRN:</b> 77345621", body_style))
content.append(Paragraph("<b>Modality:</b> MRI Brain with and without Contrast (3.0 Tesla)", body_style))
content.append(Paragraph("<b>Clinical Indication:</b> New onset seizure, headache, right-sided weakness", body_style))
content.append(Paragraph("<b>Ordering Physician:</b> Dr. Helen Murray, Neurology", body_style))
content.append(Paragraph("<b>Radiologist:</b> Dr. Amir Khalid, MD, FRCR", body_style))
content.append(Paragraph("<b>Study Date:</b> 10 March 2026", body_style))
content.append(Spacer(1, 0.1*inch))

content.append(Paragraph("Technique", heading_style))
content.append(Paragraph(
    "MRI of the brain was performed on a 3.0 Tesla scanner using standard brain protocol including sagittal "
    "T1, axial T2, axial FLAIR, axial DWI with ADC mapping, axial T2* GRE, and axial T1 post-gadolinium "
    "(Gadovist 0.1 mmol/kg IV). No adverse reactions to contrast administration were noted.", body_style))
content.append(Spacer(1, 0.1*inch))

content.append(Paragraph("Findings", heading_style))
content.append(Paragraph("<b>Brain Parenchyma:</b>", body_style))
content.append(Paragraph(
    "There is a well-defined heterogeneous mass lesion in the left parietal lobe measuring approximately "
    "3.8 × 3.2 × 2.9 cm. The lesion demonstrates peripheral ring enhancement on post-contrast T1 sequences "
    "with a central area of necrosis. Marked perilesional T2/FLAIR hyperintensity is noted extending into "
    "the adjacent white matter, consistent with vasogenic edema. There is approximately 6 mm of midline shift "
    "to the right, with early subfalcine herniation.", body_style))
content.append(Spacer(1, 0.05*inch))

content.append(Paragraph("<b>Diffusion Weighted Imaging:</b>", body_style))
content.append(Paragraph(
    "Restricted diffusion is identified within the central necrotic component. No additional foci of "
    "restricted diffusion to suggest acute infarction in the remaining brain parenchyma.", body_style))
content.append(Spacer(1, 0.05*inch))

content.append(Paragraph("<b>Ventricular System:</b>", body_style))
content.append(Paragraph(
    "The right lateral ventricle appears mildly compressed due to the mass effect. The left lateral ventricle, "
    "third ventricle, and fourth ventricle are normal in caliber. No hydrocephalus identified.", body_style))
content.append(Spacer(1, 0.05*inch))

content.append(Paragraph("<b>Posterior Fossa:</b>", body_style))
content.append(Paragraph(
    "Cerebellum, brainstem, and cervicomedullary junction appear normal. No mass lesion or abnormal enhancement.", body_style))
content.append(Spacer(1, 0.05*inch))

content.append(Paragraph("<b>Skull Base and Calvarium:</b>", body_style))
content.append(Paragraph("No bony destruction or marrow infiltration identified.", body_style))
content.append(Spacer(1, 0.1*inch))

content.append(Paragraph("Impression", heading_style))
content.append(Paragraph(
    "1. Large heterogeneous ring-enhancing mass in the left parietal lobe (3.8 cm) with central necrosis, "
    "perilesional edema, and midline shift. The imaging characteristics are highly suspicious for a high-grade "
    "glioma (WHO Grade IV, Glioblastoma Multiforme) or metastatic disease. Primary CNS lymphoma is a less "
    "likely differential.\n"
    "2. Approximately 6 mm rightward midline shift with early subfalcine herniation — urgent neurosurgical "
    "review is recommended.\n"
    "3. No evidence of acute hemorrhage, infarction, or additional intracranial metastases on this study.", body_style))
content.append(Spacer(1, 0.1*inch))

content.append(Paragraph("Recommendation", heading_style))
content.append(Paragraph(
    "Urgent neurosurgical and neuro-oncology consultation is strongly recommended. "
    "MR Spectroscopy and MR Perfusion may be considered for further characterization. "
    "Tissue biopsy/resection will be required for definitive histopathological diagnosis. "
    "Correlation with clinical presentation and systemic imaging (CT chest/abdomen/pelvis) to evaluate "
    "for primary malignancy is advised.", body_style))

doc.build(content)
print("✅ radiology_report.pdf created")

print("\n✅ All 3 test PDFs saved to: test_pdfs/")
