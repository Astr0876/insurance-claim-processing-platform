"""
app.py
------
Flask entry point for the timetable processing service.

POST /upload
  - Accepts: multipart/form-data with field "file" (PDF or image)
  - Returns: JSON attendance summary

Flow:
  1. extract_text(file)         → raw text
  2. parse_timetable(text)      → parsed list + subject counts
  3. calculate_attendance(...)  → final JSON result
"""

from flask import Flask, request, jsonify
from flask_cors import CORS

from extractor.extractor import extract_text
from parser.parser import parse_timetable
from attendance.attendance import calculate_attendance

app = Flask(__name__)
CORS(app)  # allow Flutter / web client on any origin


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@app.route("/health", methods=["GET"])
def health():
    """Simple liveness check."""
    return jsonify({"status": "ok"}), 200


@app.route("/upload", methods=["POST"])
def upload():
    """
    Accept a timetable file, process it, and return attendance insights.

    Expected request:
        Content-Type: multipart/form-data
        Body field:   file → <PDF or image>

    Returns:
        200  { subjects: {...}, raw: [...] }
        400  { error: "..." }
        500  { error: "..." }
    """
    # ── 1. Validate input ───────────────────────────────────────────────────
    if "file" not in request.files:
        return jsonify({"error": "No file provided. Send a 'file' field in form-data."}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "Empty filename. Please select a file before uploading."}), 400

    # ── 2. Extract text from the uploaded file ──────────────────────────────
    try:
        raw_text = extract_text(file)
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 400
    except Exception as exc:
        return jsonify({"error": f"Text extraction failed: {exc}"}), 500

    if not raw_text.strip():
        return jsonify({"error": "Could not extract any text from the file. "
                                 "Ensure the file contains readable content."}), 422

    # ── 3. Parse timetable entries ──────────────────────────────────────────
    try:
        parsed, counts = parse_timetable(raw_text)
    except Exception as exc:
        return jsonify({"error": f"Parsing failed: {exc}"}), 500

    if not parsed:
        return jsonify({"error": "No timetable entries found. "
                                 "Check the file format and content."}), 422

    # ── 4. Calculate attendance statistics ──────────────────────────────────
    try:
        result = calculate_attendance(parsed, counts)
    except Exception as exc:
        return jsonify({"error": f"Attendance calculation failed: {exc}"}), 500

    # ── 5. Return structured JSON ────────────────────────────────────────────
    return jsonify(result), 200


# ---------------------------------------------------------------------------
# Dev server
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)
