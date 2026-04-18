"""
extractor/extractor.py
----------------------
Handles file input and text extraction.

Supports:
  - PDF  → pdfplumber
  - Image → pytesseract (requires Tesseract installed on the host)
"""

import os
import pdfplumber
import pytesseract
from PIL import Image


def extract_text(file) -> str:
    """
    Accept a werkzeug FileStorage object and return the raw extracted text.

    Args:
        file: werkzeug.datastructures.FileStorage

    Returns:
        str: Raw text extracted from the file.

    Raises:
        ValueError: If the file type is unsupported.
    """
    filename = file.filename.lower()

    if filename.endswith(".pdf"):
        return _extract_from_pdf(file)
    elif filename.endswith((".png", ".jpg", ".jpeg", ".tiff", ".bmp", ".webp")):
        return _extract_from_image(file)
    else:
        raise ValueError(f"Unsupported file type: '{file.filename}'. "
                         "Upload a PDF or image (PNG/JPG/JPEG/TIFF/BMP/WEBP).")


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

def _extract_from_pdf(file) -> str:
    """Use pdfplumber to extract all text from every page of the PDF."""
    pages_text = []
    with pdfplumber.open(file) as pdf:
        for page in pdf.pages:
            text = page.extract_text()
            if text:
                pages_text.append(text)
    return "\n".join(pages_text)


def _extract_from_image(file) -> str:
    """Use pytesseract OCR to extract text from an image file."""
    image = Image.open(file)
    text = pytesseract.image_to_string(image)
    return text
