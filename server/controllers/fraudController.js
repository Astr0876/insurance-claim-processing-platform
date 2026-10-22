const db = require('../config/db');
const { logAudit } = require('../middleware/auditLogger');
const { createNotification, notifyRole } = require('../services/notificationService');

/**
 * Get claims flagged for fraud investigation queue
 * Roles: FRAUD_INVESTIGATOR, ADMIN, MANAGER
 */
const getFraudQueue = async (req, res) => {
  try {
    const { status, riskLevel, search } = req.query;

    let conditions = [];
    let params = [];

    // Filter by high/medium or active investigation
    conditions.push("(c.fraud_risk_level IN ('HIGH', 'MEDIUM') OR fi.status IN ('OPEN', 'UNDER_INVESTIGATION'))");

    if (riskLevel) {
      conditions.push('c.fraud_risk_level = ?');
      params.push(riskLevel);
    }

    if (status) {
      conditions.push('fi.status = ?');
      params.push(status);
    }

    if (search) {
      conditions.push('(c.claim_id LIKE ? OR u.name LIKE ?)');
      params.push(`%${search}%`, `%${search}%`);
    }

    const whereClause = `WHERE ${conditions.join(' AND ')}`;

    const sql = `
      SELECT
        c.id as claim_db_id,
        c.claim_id,
        c.claim_type,
        c.claim_amount,
        c.incident_date,
        c.current_status,
        c.fraud_risk_score,
        c.fraud_risk_level,
        c.created_at as claim_submitted_at,
        u.name as customer_name,
        u.email as customer_email,
        p.policy_number,
        p.coverage_amount,
        fi.id as investigation_id,
        fi.status as investigation_status,
        fi.findings,
        fi.recommended_action,
        fi.assigned_at,
        inv.name as investigator_name
      FROM claims c
      JOIN users u ON c.user_id = u.id
      JOIN policies p ON c.policy_id = p.id
      LEFT JOIN fraud_investigations fi ON c.id = fi.claim_id
      LEFT JOIN users inv ON fi.investigator_id = inv.id
      ${whereClause}
      ORDER BY c.fraud_risk_score DESC, c.id DESC
    `;

    const queue = await db.query(sql, params);

    return res.status(200).json({
      success: true,
      count: queue.length,
      queue
    });
  } catch (error) {
    console.error('GetFraudQueue Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve fraud investigation queue.'
    });
  }
};

/**
 * Get detailed fraud analysis and investigation for a claim
 */
const getFraudDetails = async (req, res) => {
  try {
    const claimIdentifier = req.params.claimId;
    const isNumeric = /^\d+$/.test(claimIdentifier);

    const claim = await db.getOne(
      isNumeric ? 'SELECT * FROM claims WHERE id = ?' : 'SELECT * FROM claims WHERE claim_id = ?',
      [claimIdentifier]
    );

    if (!claim) {
      return res.status(404).json({
        success: false,
        message: 'Claim not found.'
      });
    }

    const policy = await db.getOne('SELECT * FROM policies WHERE id = ?', [claim.policy_id]);
    const customer = await db.getOne('SELECT id, name, email, phone, status FROM users WHERE id = ?', [claim.user_id]);
    const documents = await db.query('SELECT * FROM claim_documents WHERE claim_id = ?', [claim.id]);
    const fraudAnalysis = await db.getOne('SELECT * FROM fraud_analysis WHERE claim_id = ? ORDER BY id DESC LIMIT 1', [claim.id]);
    const investigation = await db.getOne('SELECT fi.*, u.name as investigator_name FROM fraud_investigations fi LEFT JOIN users u ON fi.investigator_id = u.id WHERE fi.claim_id = ? ORDER BY fi.id DESC LIMIT 1', [claim.id]);

    let parsedAnalysis = null;
    if (fraudAnalysis) {
      try {
        parsedAnalysis = {
          ...fraudAnalysis,
          triggered_rules: typeof fraudAnalysis.triggered_rules === 'string'
            ? JSON.parse(fraudAnalysis.triggered_rules)
            : fraudAnalysis.triggered_rules,
          analysis_details: typeof fraudAnalysis.analysis_details === 'string'
            ? JSON.parse(fraudAnalysis.analysis_details)
            : fraudAnalysis.analysis_details
        };
      } catch (e) {
        parsedAnalysis = fraudAnalysis;
      }
    }

    return res.status(200).json({
      success: true,
      claim,
      policy,
      customer,
      documents,
      fraud_analysis: parsedAnalysis,
      investigation
    });
  } catch (error) {
    console.error('GetFraudDetails Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve fraud analysis details.'
    });
  }
};

/**
 * Update investigation findings, status, and recommended action
 * Roles: FRAUD_INVESTIGATOR, ADMIN
 */
const updateInvestigation = async (req, res) => {
  try {
    const claimId = req.params.claimId;
    const { status, findings, recommendedAction } = req.body;
    // status: 'OPEN' | 'UNDER_INVESTIGATION' | 'CONFIRMED_FRAUD' | 'CLEARED'
    // recommendedAction: 'APPROVE_CLAIM' | 'DENY_CLAIM' | 'FURTHER_REVIEW' | 'REFER_LEGAL'

    if (!['OPEN', 'UNDER_INVESTIGATION', 'CONFIRMED_FRAUD', 'CLEARED'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status. Must be OPEN, UNDER_INVESTIGATION, CONFIRMED_FRAUD, or CLEARED.'
      });
    }

    const claim = await db.getOne('SELECT * FROM claims WHERE id = ?', [claimId]);
    if (!claim) {
      return res.status(404).json({
        success: false,
        message: 'Claim not found.'
      });
    }

    // Check if an investigation already exists
    let investigation = await db.getOne('SELECT * FROM fraud_investigations WHERE claim_id = ? ORDER BY id DESC LIMIT 1', [claimId]);

    const completedAt = (status === 'CONFIRMED_FRAUD' || status === 'CLEARED') ? new Date().toISOString() : null;

    if (investigation) {
      await db.query(
        `UPDATE fraud_investigations
         SET investigator_id = COALESCE(investigator_id, ?),
             status = ?,
             findings = COALESCE(?, findings),
             recommended_action = COALESCE(?, recommended_action),
             completed_at = ?
         WHERE id = ?`,
        [req.user.id, status, findings, recommendedAction, completedAt, investigation.id]
      );
    } else {
      const invResult = await db.query(
        `INSERT INTO fraud_investigations (claim_id, investigator_id, status, findings, recommended_action, completed_at)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [claimId, req.user.id, status, findings || 'Investigation initiated by fraud officer.', recommendedAction || 'FURTHER_REVIEW', completedAt]
      );
      investigation = { id: invResult.insertId };
    }

    // Handle claim status updates based on investigation verdict
    if (status === 'CONFIRMED_FRAUD') {
      await db.query(
        `UPDATE claims
         SET current_status = 'REJECTED',
             decision_reason = ?,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = ?`,
        [findings || 'Claim denied due to confirmed fraud investigation indicators and forensic audit findings.', claimId]
      );

      // Record in claim status history
      await db.query(
        `INSERT INTO claim_status_history (claim_id, from_status, to_status, changed_by_user_id, notes)
         VALUES (?, ?, 'REJECTED', ?, ?)`,
        [claimId, claim.current_status, req.user.id, `Fraud Investigation concluded: CONFIRMED FRAUD. ${findings || ''}`]
      );

      // Notify customer
      await createNotification({
        userId: claim.user_id,
        claimId: claim.id,
        title: 'Claim Adjudication Notice',
        message: `Your claim ${claim.claim_id} has been rejected following an integrity verification review.`,
        type: 'ALERT'
      });

      // Notify Claims Staff
      await notifyRole({
        roleName: 'INSURANCE_STAFF',
        claimId: claim.id,
        title: 'Fraud Alert Confirmed',
        message: `Claim ${claim.claim_id} has been confirmed fraudulent by Investigator ${req.user.name}. Status updated to REJECTED.`,
        type: 'ALERT'
      });
    } else if (status === 'CLEARED') {
      // Clear fraud flag and forward back to Staff for approval
      await db.query(
        `UPDATE claims
         SET current_status = 'UNDER_REVIEW',
             fraud_risk_level = 'LOW',
             updated_at = CURRENT_TIMESTAMP
         WHERE id = ?`,
        [claimId]
      );

      await db.query(
        `INSERT INTO claim_status_history (claim_id, from_status, to_status, changed_by_user_id, notes)
         VALUES (?, ?, 'UNDER_REVIEW', ?, ?)`,
        [claimId, claim.current_status, req.user.id, `Fraud Investigation concluded: CLEARED (False positive / explainable anomaly). ${findings || ''}`]
      );

      // Notify staff that claim is cleared for approval
      await notifyRole({
        roleName: 'INSURANCE_STAFF',
        claimId: claim.id,
        title: 'Claim Cleared of Fraud Alert',
        message: `Claim ${claim.claim_id} was reviewed and CLEARED by Investigator ${req.user.name}. It is now eligible for staff approval.`,
        type: 'SUCCESS'
      });

      // Notify customer
      await createNotification({
        userId: claim.user_id,
        claimId: claim.id,
        title: 'Verification Complete',
        message: `Routine underwriting verification for claim ${claim.claim_id} is complete. Your claim is proceeding to standard adjudication.`,
        type: 'INFO'
      });
    } else if (status === 'UNDER_INVESTIGATION') {
      await db.query(
        "UPDATE claims SET current_status = 'INVESTIGATION_IN_PROGRESS', updated_at = CURRENT_TIMESTAMP WHERE id = ?",
        [claimId]
      );

      await db.query(
        `INSERT INTO claim_status_history (claim_id, from_status, to_status, changed_by_user_id, notes)
         VALUES (?, ?, 'INVESTIGATION_IN_PROGRESS', ?, ?)`,
        [claimId, claim.current_status, req.user.id, `Special Investigation Unit case opened by ${req.user.name}.`]
      );
    }

    // Audit log
    await logAudit({
      userId: req.user.id,
      action: `FRAUD_INVESTIGATION_${status}`,
      entityType: 'FRAUD_INVESTIGATION',
      entityId: claim.claim_id,
      req,
      details: {
        claimId: claim.claim_id,
        status,
        recommendedAction,
        findings
      }
    });

    return res.status(200).json({
      success: true,
      message: `Investigation status updated to ${status}.`,
      investigation: {
        claimId: claim.claim_id,
        status,
        findings,
        recommendedAction
      }
    });
  } catch (error) {
    console.error('UpdateInvestigation Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update fraud investigation record.'
    });
  }
};

module.exports = {
  getFraudQueue,
  getFraudDetails,
  updateInvestigation
};
