/**
 * Unit Test Suite - Module 2: Fraud Risk Detection & Adjudication Workflow
 * Framework: Node.js Built-in Test Runner (JUnit Compatible assertions)
 * Test Cases: 5 total (4 PASS, 1 FAIL)
 */

const { test, describe } = require('node:test');
const assert = require('node:assert');
const FraudDetectionEngine = require('../services/fraudEngine');

describe('MODULE 2: Explainable Fraud Risk Analytics & Adjudication Workflow', () => {

  /**
   * TC_MOD2_01 [PASS]
   * Description: Verify that policy inception velocity heuristic fires (+22 pts) when incident occurs within 30 days of policy start
   */
  test('TC_MOD2_01 [PASS] - Should trigger RULE_INCEPTION_VELOCITY when incident occurs shortly after policy purchase', () => {
    const analysis = FraudDetectionEngine.analyze({
      claim: {
        id: 101,
        claim_amount: 5000,
        incident_date: '2026-06-15',
        description: 'Minor parking scrape with another passenger vehicle while driving.'
      },
      policy: {
        coverage_amount: 50000,
        start_date: '2026-06-01' // 14 days velocity
      },
      userClaimHistory: [],
      documents: [{ id: 1, file_name: 'police_report.pdf' }]
    });

    const rule = analysis.triggered_rules.find(r => r.ruleId === 'RULE_INCEPTION_VELOCITY');
    assert.ok(rule, 'RULE_INCEPTION_VELOCITY should be present in triggered rules');
    assert.strictEqual(rule.weight, 22, 'Inception velocity rule weight must equal 22 points');
    assert.strictEqual(rule.severity, 'HIGH', 'Rule severity must be HIGH');
  });

  /**
   * TC_MOD2_02 [PASS]
   * Description: Verify that coverage exhaustion heuristic fires (+25 pts) when claim amount is >= 85% of coverage limit
   */
  test('TC_MOD2_02 [PASS] - Should trigger RULE_COVERAGE_EXHAUSTION when claim utilizes >= 85% of max policy coverage', () => {
    const analysis = FraudDetectionEngine.analyze({
      claim: {
        id: 102,
        claim_amount: 45000, // 90% of 50,000 limit
        incident_date: '2026-08-01',
        description: 'Extensive collision damage requiring complete engine replacement.'
      },
      policy: {
        coverage_amount: 50000,
        start_date: '2025-01-01'
      },
      userClaimHistory: [],
      documents: [{ id: 1, file_name: 'estimate.pdf' }]
    });

    const rule = analysis.triggered_rules.find(r => r.ruleId === 'RULE_COVERAGE_EXHAUSTION');
    assert.ok(rule, 'RULE_COVERAGE_EXHAUSTION must be triggered for 90% coverage ratio');
    assert.strictEqual(rule.weight, 25, 'Coverage exhaustion weight must equal 25 points');
  });

  /**
   * TC_MOD2_03 [PASS]
   * Description: Verify that prior fraudulent or rejected claim history triggers RULE_PRIOR_SUSPICIOUS_HISTORY (+25 pts)
   */
  test('TC_MOD2_03 [PASS] - Should detect prior fraudulent or rejected claim history on claimant record', () => {
    const pastClaims = [
      { id: 91, current_status: 'APPROVED', fraud_risk_level: 'LOW' },
      { id: 92, current_status: 'REJECTED', fraud_risk_level: 'HIGH' } // Prior rejection
    ];

    const analysis = FraudDetectionEngine.analyze({
      claim: {
        id: 103,
        claim_amount: 3000,
        incident_date: '2026-08-01',
        description: 'Cracked windshield from road debris while commuting.'
      },
      policy: {
        coverage_amount: 50000,
        start_date: '2025-01-01'
      },
      userClaimHistory: pastClaims,
      documents: [{ id: 1, file_name: 'glass_receipt.pdf' }]
    });

    const rule = analysis.triggered_rules.find(r => r.ruleId === 'RULE_PRIOR_SUSPICIOUS_HISTORY');
    assert.ok(rule, 'RULE_PRIOR_SUSPICIOUS_HISTORY must be triggered when past rejection exists');
    assert.strictEqual(rule.weight, 25, 'Prior history penalty must equal 25 points');
  });

  /**
   * TC_MOD2_04 [PASS]
   * Description: Verify that standard low-exposure claim evaluates to risk_level: 'LOW'
   */
  test('TC_MOD2_04 [PASS] - Should classify legitimate low-exposure claim as LOW risk tier', () => {
    const analysis = FraudDetectionEngine.analyze({
      claim: {
        id: 104,
        claim_amount: 1200, // low claim amount
        incident_date: '2026-08-10',
        description: 'Comprehensive doctor consultation and prescribed medication following acute illness.'
      },
      policy: {
        coverage_amount: 50000,
        start_date: '2025-01-01' // mature policy
      },
      userClaimHistory: [],
      documents: [{ id: 1, file_name: 'medical_bill.pdf' }]
    });

    assert.strictEqual(analysis.risk_level, 'LOW', 'Mature low-ratio claim must be classified as LOW risk');
    assert.strictEqual(analysis.is_suspicious, false, 'Claim must not be marked suspicious');
    assert.strictEqual(analysis.recommendation, 'STANDARD_PROCESSING', 'Should recommend standard processing');
  });

  /**
   * TC_MOD2_05 [FAIL] - INTENTIONAL DEFECT 2
   * Description: Verify that claims scoring >= 65% are assigned risk_level: 'HIGH' and recommended for SIU investigation
   * Defect Note: Threshold was altered from 65 to 95 in fraudEngine.js line 238
   */
  test('TC_MOD2_05 [FAIL] - Should classify high-risk claims (score >= 65%) into HIGH severity tier for SIU review', () => {
    // High risk claim: High coverage ratio (27k/30k: 90% => +25), Early inception velocity (14 days => +22),
    // and suspicious keyword ('unattended' => +12). Score evaluates to 78% (>= 65% HIGH threshold).
    const analysis = FraudDetectionEngine.analyze({
      claim: {
        id: 105,
        claim_amount: 27000,
        incident_date: '2026-06-15',
        description: 'Vehicle was left unattended and damaged.'
      },
      policy: {
        coverage_amount: 30000,
        start_date: '2026-06-01' // 14 days after policy start (Early velocity)
      },
      userClaimHistory: [],
      documents: [{ id: 1, file_name: 'accident_report.pdf' }]
    });

    // Score is approx 75 - 82
    assert.ok(analysis.risk_score >= 65, `Expected score >= 65, got ${analysis.risk_score}`);

    // Business Requirement: Any claim with score >= 65% MUST be classified as HIGH risk!
    assert.strictEqual(
      analysis.risk_level,
      'HIGH',
      `Expected risk_level to be 'HIGH' for score ${analysis.risk_score}%, but received '${analysis.risk_level}' due to threshold defect.`
    );
    assert.strictEqual(
      analysis.recommendation,
      'FLAG_FOR_FRAUD_INVESTIGATION',
      'Should recommend SIU investigation flag'
    );
  });

});
