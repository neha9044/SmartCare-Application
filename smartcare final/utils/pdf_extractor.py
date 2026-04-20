import pdfplumber
import re

def extract_text(pdf_path):

    text = ""

    with pdfplumber.open(pdf_path) as pdf:

        for page in pdf.pages:

            page_text = page.extract_text()

            if page_text:
                text += page_text + " "

    # remove pdf artifacts
    text = re.sub(r'\(cid:\d+\)', '', text)

    # normalize whitespace
    text = re.sub(r'\s+', ' ', text)

    return text.strip()