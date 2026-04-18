"""
parser/parser.py
----------------
Parses raw timetable text into structured subject/faculty data.

Expected timetable entry format (space/slash separated):
    SUBJECT / DIVISION(optional) / FACULTY / ROOM(optional)

Examples:
    DBMS /A /KKD /LAB4
    DS /NR
    PACO /C /JS /LAB8

Regex target:
    ([A-Z]{2,})\s*/\s*([A-Z]?)\s*/\s*([A-Z]{2,})
    Captures: subject, optional division, faculty code
"""

import re
from collections import Counter
from typing import Tuple, List, Dict


# ---------------------------------------------------------------------------
# Core regex – matches SUBJECT / [DIVISION /] FACULTY
# Ignores trailing room tokens (LABn, ROOMn, etc.)
# ---------------------------------------------------------------------------
_ENTRY_PATTERN = re.compile(
    r"\b([A-Z]{2,})"           # group 1: subject (≥2 uppercase letters)
    r"\s*/\s*"                  # delimiter
    r"([A-Z])?"                 # group 2: optional single-letter division
    r"\s*/?\s*"                  # optional delimiter
    r"([A-Z]{2,})\b"            # group 3: faculty code (≥2 uppercase letters)
)

# Tokens that look like faculty codes but are actually rooms/labs
_ROOM_TOKENS = re.compile(r"^(LAB|ROOM|HALL|CR|COMP)\d*$")


def parse_timetable(text: str) -> Tuple[List[Dict], Dict[str, int]]:
    """
    Parse raw timetable text and return:
      1. A list of dicts  → [{"subject": "DBMS", "faculty": "KKD"}, ...]
      2. A frequency dict → {"DBMS": 3, "DS": 4, ...}

    Args:
        text: Raw string extracted from the timetable file.

    Returns:
        Tuple[List[Dict], Dict[str, int]]
    """
    raw_entries: List[Dict] = []

    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue

        # Try to match one or more entries on this line
        for match in _ENTRY_PATTERN.finditer(line):
            subject = match.group(1)
            faculty_candidate = match.group(3)

            # Skip if the "faculty" token looks like a room label
            if _ROOM_TOKENS.match(faculty_candidate):
                continue

            raw_entries.append({
                "subject": subject,
                "faculty": faculty_candidate,
            })

    # Build frequency count per subject
    subject_counts: Dict[str, int] = dict(
        Counter(entry["subject"] for entry in raw_entries)
    )

    # Deduplicate: keep first occurrence per subject (retain faculty mapping)
    seen = set()
    deduplicated: List[Dict] = []
    for entry in raw_entries:
        if entry["subject"] not in seen:
            seen.add(entry["subject"])
            deduplicated.append(entry)

    return deduplicated, subject_counts
