/**
 * Fraud Detection Engine
 * Deterministic, explainable rule-based risk scoring system.
 * Designed to be modular so that a machine learning model pipeline
 * can easily replace or augment these heuristics in the future.
 */

class FraudDetectionEngine {
  /**
   * Evaluates a claim against fraud indicators and historical data
   * @param {Object} claim - Current claim details
   * @param {Object} policy - Associated policy details
   * @param {Array} userClaimHistory - Previous claims submitted by this policyholder
   * @param {Array} documents - Uploaded documents for this claim
   * @returns {Object} Fraud analysis result with score, level, and reasons
   */
  static analyze({ claim, policy, userClaimHistory = [], documents = [] }) {
    let score = 5; // Base baseline risk
    const triggeredRules = [];
    const breakdown = {
      financial: 0,
      velocity: 0,
      frequency: 0,
      documentation: 0,
      pattern: 0
    };

    const claimAmount = parseFloat(claim.claim_amount) || 0;
    const coverageAmount = policy ? parseFloat(policy.coverage_amount) || 0 : 0;

    // 1. Financial Anomaly: High ratio to policy coverage limit
    if (coverageAmount > 0) {
      const coverageRatio = claimAmount / coverageAmount;
      if (coverageRatio >= 0.85) {
        const weight = 25;
        score += weight;
        breakdown.financial += weight;
        triggeredRules.push({
          ruleId: "RULE_COVERAGE_EXHAUSTION",
          category: "Financial",
          severity: "HIGH",
          description: `Claim amount is ${Math.round(coverageRatio * 100)}% of policy coverage limit (unusually high exposure)`,
          weight
        });
      } else if (coverageRatio >= 0.6) {
        const weight = 15;
        score += weight;
        breakdown.financial += weight;
        triggeredRules.push({
          ruleId: "RULE_HIGH_COVERAGE_UTILIZATION",
          category: "Financial",
          severity: "MEDIUM",
          description: `Claim amount utilizes ${Math.round(coverageRatio * 100)}% of total policy coverage limit`,
          weight
        });
      }
    }

    // 2. High Absolute Amount Threshold
    if (claimAmount >= 40000) {
      const weight = 15;
      score += weight;
      breakdown.financial += weight;
      triggeredRules.push({
        ruleId: "RULE_HIGH_VALUE_THRESHOLD",
        category: "Financial",
        severity: "MEDIUM",
        description: `High-value claim ($${claimAmount.toLocaleString()}) exceeding tier-1 audit threshold`,
        weight
      });
    }

    // 3. Policy Inception Velocity: Claim filed shortly after policy creation
    if (policy && policy.start_date && claim.incident_date) {
      const policyStart = new Date(policy.start_date);
      const incidentDate = new Date(claim.incident_date);
      const daysSinceInception = Math.floor((incidentDate - policyStart) / (1000 * 60 * 60 * 24));

      if (daysSinceInception >= 0 && daysSinceInception <= 30) {
        const weight = 22;
        score += weight;
        breakdown.velocity += weight;
        triggeredRules.push({
          ruleId: "RULE_INCEPTION_VELOCITY",
          category: "Velocity",
          severity: "HIGH",
          description: `Incident occurred within ${daysSinceInception} days of policy start date (early loss hazard)`,
          weight
        });
      } else if (daysSinceInception < 0) {
        const weight = 45;
        score += weight;
        breakdown.velocity += weight;
        triggeredRules.push({
          ruleId: "RULE_PRE_POLICY_INCIDENT",
          category: "Velocity",
          severity: "CRITICAL",
          description: "Incident occurred BEFORE the policy effective start date",
          weight
        });
      }
    }

    // 4. Incident Reporting Delay / Timing Anomaly
    if (claim.incident_date) {
      const incidentDate = new Date(claim.incident_date);
      const now = new Date();
      const filingLagDays = Math.floor((now - incidentDate) / (1000 * 60 * 60 * 24));

      if (filingLagDays < 0) {
        const weight = 40;
        score += weight;
        breakdown.pattern += weight;
        triggeredRules.push({
          ruleId: "RULE_FUTURE_INCIDENT_DATE",
          category: "Pattern",
          severity: "CRITICAL",
          description: "Incident date is listed in the future",
          weight
        });
      } else if (filingLagDays > 90) {
        const weight = 14;
        score += weight;
        breakdown.pattern += weight;
        triggeredRules.push({
          ruleId: "RULE_EXCESSIVE_FILING_LAG",
          category: "Pattern",
          severity: "MEDIUM",
          description: `Delayed claim submission (${filingLagDays} days after incident occurrence)`,
          weight
        });
      }
    }

    // 5. Frequency & Prior Claims History
    const recentClaims = userClaimHistory.filter(c => {
      if (c.id === claim.id || c.claim_id === claim.claim_id) return false;
      const submitted = new Date(c.created_at || c.date_submitted || Date.now());
      const daysAgo = (Date.now() - submitted) / (1000 * 60 * 60 * 24);
      return daysAgo <= 180;
    });

    if (recentClaims.length >= 2) {
      const weight = 20;
      score += weight;
      breakdown.frequency += weight;
      triggeredRules.push({
        ruleId: "RULE_MULTIPLE_RECENT_CLAIMS",
        category: "Frequency",
        severity: "HIGH",
        description: `Customer submitted ${recentClaims.length} other claim(s) within the last 6 months`,
        weight
      });
    } else if (recentClaims.length === 1) {
      const weight = 8;
      score += weight;
      breakdown.frequency += weight;
      triggeredRules.push({
        ruleId: "RULE_REPEAT_CLAIM_ACTIVITY",
        category: "Frequency",
        severity: "LOW",
        description: "Repeat claim activity detected within current 6-month billing cycle",
        weight
      });
    }

    // Check for prior fraudulent or rejected claims
    const priorFraudulent = userClaimHistory.some(c =>
      c.current_status === 'REJECTED' || c.fraud_risk_level === 'HIGH'
    );
    if (priorFraudulent) {
      const weight = 25;
      score += weight;
      breakdown.frequency += weight;
      triggeredRules.push({
        ruleId: "RULE_PRIOR_SUSPICIOUS_HISTORY",
        category: "Frequency",
        severity: "HIGH",
        description: "Policyholder has prior claims that were rejected or flagged as high risk",
        weight
      });
    }

    // 6. Documentation Risk
    if (!documents || documents.length === 0) {
      const weight = 18;
      score += weight;
      breakdown.documentation += weight;
      triggeredRules.push({
        ruleId: "RULE_NO_SUPPORTING_DOCUMENTS",
        category: "Documentation",
        severity: "MEDIUM",
        description: "No supporting documentation or verification receipts attached to claim",
        weight
      });
    }

    // 7. Text Description Heuristics
    const desc = (claim.description || "").trim().toLowerCase();
    if (desc.length < 25) {
      const weight = 10;
      score += weight;
      breakdown.pattern += weight;
      triggeredRules.push({
        ruleId: "RULE_VAGUE_DESCRIPTION",
        category: "Pattern",
        severity: "LOW",
        description: "Incident description is unusually sparse (<25 characters) lacking crucial event context",
        weight
      });
    }

    const suspiciousKeywords = [
      "unattended", "lost without trace", "unknown person", "cash only",
      "no witness", "fire broke out suddenly", "staged", "total loss claim"
    ];
    const matchedKeywords = suspiciousKeywords.filter(k => desc.includes(k));
    if (matchedKeywords.length > 0) {
      const weight = 12;
      score += weight;
      breakdown.pattern += weight;
      triggeredRules.push({
        ruleId: "RULE_SUSPICIOUS_VOCABULARY",
        category: "Pattern",
        severity: "MEDIUM",
        description: `Description contains high-scrutiny keyword indicators: "${matchedKeywords.join(', ')}"`,
        weight
      });
    }

    // Normalizing Final Score (clamp between 5 and 99)
    const finalScore = Math.min(Math.max(score, 5), 98);

    // Determine Risk Level
    let riskLevel = "LOW";
    let recommendation = "STANDARD_PROCESSING";

    // =========================================================================
    // ⚠️ DEFECT 2 INJECTED FOR SE LAB UNIT TESTING REQUIREMENT (2 FAIL / 8 PASS)
    // BUG DESCRIPTION: High-risk cutoff threshold erroneously elevated from 65 to 95.
    // INTENDED LOGIC: if (finalScore >= 65) { riskLevel = "HIGH"; ... }
    // RESULT: Claims scoring between 65% and 94% are erroneously classified as MEDIUM.
    // =========================================================================
    if (finalScore >= 95) { // <-- DEFECT: Should be 65!
      riskLevel = "HIGH";
      recommendation = "FLAG_FOR_FRAUD_INVESTIGATION";
    } else if (finalScore >= 35) {
      riskLevel = "MEDIUM";
      recommendation = "REQUIRES_SUPERVISOR_REVIEW";
    }

    return {
      risk_score: finalScore,
      risk_level: riskLevel,
      recommendation,
      is_suspicious: finalScore >= 50,
      triggered_rules: triggeredRules,
      factor_breakdown: breakdown,
      analyzed_at: new Date().toISOString(),
      engine_version: "v1.2-rule-based-deterministic"
    };
  }
}

module.exports = FraudDetectionEngine;
