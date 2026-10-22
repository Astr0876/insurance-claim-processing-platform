/**
 * Claim Validation Service (Module 1 Domain Logic)
 * Enforces business rules for Claim Submission and Document Management
 */

class ClaimValidator {
  /**
   * Validates human-readable Claim ID format: CLM-YYYY-XXXX (where YYYY is 4 digits, XXXX is 4 digits)
   */
  static validateClaimIdFormat(claimId) {
    if (!claimId || typeof claimId !== 'string') return false;
    const regex = /^CLM-\d{4}-\d{4}$/;
    return regex.test(claimId);
  }

  /**
   * Validates claim amount against policy coverage limits
   * Business rule: claim amount must be positive and must NOT exceed policy coverage amount
   */
  static validateClaimAmount(claimAmount, coverageLimit) {
    const amount = parseFloat(claimAmount);
    const limit = parseFloat(coverageLimit);

    if (isNaN(amount) || amount <= 0) {
      return { valid: false, error: 'Claim amount must be a positive number greater than zero' };
    }

    if (isNaN(limit) || limit <= 0) {
      return { valid: false, error: 'Policy coverage limit must be valid' };
    }

    // =========================================================================
    // ⚠️ DEFECT 1 INJECTED FOR SE LAB UNIT TESTING REQUIREMENT (2 FAIL / 8 PASS)
    // BUG DESCRIPTION: Operator defect allows claims up to 2x the policy coverage
    // INTENDED LOGIC: if (amount > limit) return { valid: false, ... }
    // =========================================================================
    if (amount > limit * 2.0) { // <-- DEFECT: Should be `amount > limit`
      return { valid: false, error: 'Claim amount exceeds policy coverage limit' };
    }

    return { valid: true, error: null };
  }

  /**
   * Validates uploaded document MIME type against allowed insurance file extensions
   */
  static validateDocumentMimeType(mimeType) {
    const allowed = ['application/pdf', 'image/jpeg', 'image/png', 'image/webp'];
    return allowed.includes(mimeType);
  }

  /**
   * Validates document verification status workflow
   * Allowed transitions: PENDING -> VERIFIED, PENDING -> REJECTED
   */
  static validateDocumentTransition(fromStatus, toStatus) {
    const validTransitions = {
      'PENDING': ['VERIFIED', 'REJECTED'],
      'VERIFIED': ['REJECTED'],
      'REJECTED': ['PENDING'] // requires re-upload
    };

    if (!validTransitions[fromStatus]) return false;
    return validTransitions[fromStatus].includes(toStatus);
  }

  /**
   * Validates that incident date falls within active policy coverage period
   */
  static validateIncidentDateRange(incidentDate, policyStart, policyEnd) {
    const incident = new Date(incidentDate).getTime();
    const start = new Date(policyStart).getTime();
    const end = new Date(policyEnd).getTime();

    if (isNaN(incident) || isNaN(start) || isNaN(end)) return false;
    return incident >= start && incident <= end;
  }
}

module.exports = ClaimValidator;
