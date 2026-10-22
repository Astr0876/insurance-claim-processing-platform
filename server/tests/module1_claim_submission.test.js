/**
 * Unit Test Suite - Module 1: Claim Submission & Document Management
 * Framework: Node.js Built-in Test Runner (JUnit Compatible assertions)
 * Test Cases: 5 total (4 PASS, 1 FAIL)
 */

const { test, describe } = require('node:test');
const assert = require('node:assert');
const ClaimValidator = require('../services/claimValidator');

describe('MODULE 1: Online Claim Submission & Document Management', () => {

  /**
   * TC_MOD1_01 [PASS]
   * Description: Verify that unique Claim ID matches the mandated enterprise format CLM-YYYY-XXXX
   */
  test('TC_MOD1_01 [PASS] - Should validate standard Claim ID format (CLM-YYYY-XXXX)', () => {
    const validClaimId = 'CLM-2026-4891';
    const invalidClaimId1 = 'CLAIM-2026-4891';
    const invalidClaimId2 = 'CLM-26-4891';
    const invalidClaimId3 = 'CLM-2026-ABC';

    assert.strictEqual(ClaimValidator.validateClaimIdFormat(validClaimId), true, 'Valid Claim ID format should pass');
    assert.strictEqual(ClaimValidator.validateClaimIdFormat(invalidClaimId1), false, 'Prefix must be CLM');
    assert.strictEqual(ClaimValidator.validateClaimIdFormat(invalidClaimId2), false, 'Year must be 4 digits');
    assert.strictEqual(ClaimValidator.validateClaimIdFormat(invalidClaimId3), false, 'Sequence must be 4 numeric digits');
  });

  /**
   * TC_MOD1_02 [PASS]
   * Description: Verify that a valid claim amount within policy coverage limit passes validation
   */
  test('TC_MOD1_02 [PASS] - Should approve claim amount within policy coverage bounds', () => {
    const claimAmount = 15000.00;
    const policyCoverage = 50000.00;

    const result = ClaimValidator.validateClaimAmount(claimAmount, policyCoverage);

    assert.strictEqual(result.valid, true, 'Claim within policy limit must be valid');
    assert.strictEqual(result.error, null, 'No error should be returned for valid amount');
  });

  /**
   * TC_MOD1_03 [PASS]
   * Description: Verify that file upload validator only accepts permitted document MIME types
   */
  test('TC_MOD1_03 [PASS] - Should allow valid insurance evidence MIME types and reject executables', () => {
    const pdfMime = 'application/pdf';
    const pngMime = 'image/png';
    const jpegMime = 'image/jpeg';
    const exeMime = 'application/x-msdownload';
    const scriptMime = 'text/javascript';

    assert.strictEqual(ClaimValidator.validateDocumentMimeType(pdfMime), true, 'PDF documents must be accepted');
    assert.strictEqual(ClaimValidator.validateDocumentMimeType(pngMime), true, 'PNG images must be accepted');
    assert.strictEqual(ClaimValidator.validateDocumentMimeType(jpegMime), true, 'JPEG images must be accepted');
    assert.strictEqual(ClaimValidator.validateDocumentMimeType(exeMime), false, 'Executables (.exe) must be rejected');
    assert.strictEqual(ClaimValidator.validateDocumentMimeType(scriptMime), false, 'Script files must be rejected');
  });

  /**
   * TC_MOD1_04 [PASS]
   * Description: Verify that document verification status transition from PENDING to VERIFIED is allowed
   */
  test('TC_MOD1_04 [PASS] - Should permit authorized document lifecycle status transitions', () => {
    assert.strictEqual(
      ClaimValidator.validateDocumentTransition('PENDING', 'VERIFIED'),
      true,
      'PENDING to VERIFIED transition must be permitted'
    );
    assert.strictEqual(
      ClaimValidator.validateDocumentTransition('PENDING', 'REJECTED'),
      true,
      'PENDING to REJECTED transition must be permitted'
    );
    assert.strictEqual(
      ClaimValidator.validateDocumentTransition('UNKNOWN_STATUS', 'VERIFIED'),
      false,
      'Invalid origin status must be rejected'
    );
  });

  /**
   * TC_MOD1_05 [FAIL] - INTENTIONAL DEFECT 1
   * Description: Verify that a claim amount exceeding the policy coverage limit is strictly rejected
   * Defect Note: ClaimValidator allows amounts up to 2x limit due to operator defect in claimValidator.js
   */
  test('TC_MOD1_05 [FAIL] - Should reject claim when claim amount exceeds maximum policy coverage limit', () => {
    const claimAmount = 60000.00; // Incurred loss exceeds policy
    const policyCoverage = 50000.00; // Max liability

    const result = ClaimValidator.validateClaimAmount(claimAmount, policyCoverage);

    // Business Requirement: A $60,000 claim against a $50,000 policy MUST be rejected!
    assert.strictEqual(
      result.valid,
      false,
      `Expected claim of $${claimAmount} against $${policyCoverage} limit to be rejected, but received valid: ${result.valid}`
    );
    assert.strictEqual(
      result.error,
      'Claim amount exceeds policy coverage limit',
      'Should return coverage exhaustion error message'
    );
  });

});
