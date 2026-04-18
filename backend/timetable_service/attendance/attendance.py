"""
attendance/attendance.py
------------------------
Calculates attendance statistics for each subject.

Formulas used:
  - monthly   = weekly * 4
  - attendance% = (attended / total) * 100
  - safe_bunks: max classes that can be missed while staying ≥ 75%
  - classes_needed: min extra classes to attend to reach 75% (if below)

Faculty mapping: short code → full name.
Extend this dict as needed for your college.
"""

from typing import Dict, List, Tuple


# ---------------------------------------------------------------------------
# Faculty lookup table  (add more entries as needed)
# ---------------------------------------------------------------------------
FACULTY_MAP: Dict[str, str] = {
    "KKD": "Dr. Kailas Devadkar",
    "NR":  "Dr. Nataasha Raul",
    "JS":  "Prof. J. Sharma",
    "RS":  "Prof. R. Singh",
    "PM":  "Prof. P. Mehta",
    "SK":  "Prof. S. Kumar",
    "AD":  "Prof. A. Desai",
    "MG":  "Prof. M. Gupta",
    "VR":  "Prof. V. Rao",
    "SP":  "Prof. S. Patil",
}

# Attendance threshold (percentage)
ATTENDANCE_THRESHOLD = 75.0


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def calculate_attendance(
    parsed: List[Dict],
    counts: Dict[str, int],
) -> Dict:
    """
    Build the final attendance summary for every subject.

    Args:
        parsed : Deduplicated list → [{"subject": "DBMS", "faculty": "KKD"}, ...]
        counts : Frequency map      → {"DBMS": 3, "DS": 4, ...}

    Returns:
        Dict with keys:
          "subjects" → per-subject attendance data
          "raw"      → raw parsed list (passed through unchanged)
    """
    # Build a quick lookup: subject → faculty code
    faculty_lookup: Dict[str, str] = {
        entry["subject"]: entry["faculty"]
        for entry in parsed
    }

    subjects_result = {}

    for subject, weekly in counts.items():
        monthly = weekly * 4
        faculty_code = faculty_lookup.get(subject, "")
        faculty_name = FACULTY_MAP.get(faculty_code, faculty_code)  # fallback to code

        safe_bunks = _calc_safe_bunks(monthly)
        classes_needed = _calc_classes_needed(monthly)

        subjects_result[subject] = {
            "faculty": faculty_name,
            "weekly": weekly,
            "monthly": monthly,
            "safe_bunks": safe_bunks,
            "classes_needed": classes_needed,
        }

    return {
        "subjects": subjects_result,
        "raw": parsed,
    }


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

def _attendance_percent(attended: int, total: int) -> float:
    """Return attendance percentage; 0.0 if total is 0."""
    if total == 0:
        return 0.0
    return (attended / total) * 100


def _calc_safe_bunks(total: int) -> int:
    """
    Starting from 100% attendance (all classes attended), find the maximum
    number of classes that can be skipped while staying at or above 75%.

    We simulate: if you miss `n` classes out of `total`, is attendance ≥ 75%?
    """
    safe = 0
    for missed in range(total + 1):
        attended = total - missed
        if _attendance_percent(attended, total) >= ATTENDANCE_THRESHOLD:
            safe = missed          # this many misses still keeps you ≥ 75%
        else:
            break
    return safe


def _calc_classes_needed(total: int) -> int:
    """
    Assuming current attendance is at the minimum (0 attended), calculate
    how many additional classes must be attended to reach 75%.

    In practice, this represents "if you have 0 attended out of `total`
    scheduled, attend `n` more so that n / (total + n) ≥ 75%."

    For the hackathon demo we keep it simple:
    Return how many classes above the 75% mark are needed from a 0-base.
    """
    needed = 0
    extra = 0
    while True:
        attended = extra
        new_total = total + extra
        if new_total == 0 or _attendance_percent(attended, new_total) >= ATTENDANCE_THRESHOLD:
            needed = extra
            break
        extra += 1
        if extra > 1000:          # safety guard
            needed = -1
            break
    return needed
