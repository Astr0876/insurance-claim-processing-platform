const db = require('../config/db');
const FraudDetectionEngine = require('../services/fraudEngine');
const { logAudit } = require('../middleware/auditLogger');
const { createNotification, notifyRole } = require('../services/notificationService');

/**
 * Generate a unique Claim ID: CLM-YYYY-XXXX
 */
const generateClaimId = async () => {
  const year = new Date().getFullYear();
  let unique = false;
  let claimId = '';

  while (!unique) {
    const randomDigits = Math.floor(1000 + Math.random() * 9000);
    claimId = `CLM-${year}-${randomDigits}`;
    const existing = await db.getOne('SELECT id FROM claims WHERE claim_id = ?', [claimId]);
    if (!existing) {
      unique = true;
    }
  }

  return claimId;
};

/**
 * Submit a new claim
 */
const createClaim = async (req, res) => {
  try {
    const {
      policyId,
      claimType,
      incidentDate,
      incidentLocation,
      claimAmount,
      description
    } = req.body;

    const userId = req.user.id;

    if (!policyId || !claimType || !incidentDate || !claimAmount || !description) {
      return res.status(400).json({
        success: false,
        message: 'Policy, claim type, incident date, claim amount, and incident description are required.'
      });
    }

    const parsedAmount = parseFloat(claimAmount);
    if (isNaN(parsedAmount) || parsedAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Claim amount must be a positive number.'
      });
    }

    // Verify policy exists and belongs to user (or staff acting)
    const policy = await db.getOne('SELECT * FROM policies WHERE id = ?', [policyId]);
    if (!policy) {
      return res.status(404).json({
        success: false,
        message: 'Selected policy does not exist.'
      });
    }

    if (req.user.role === 'CUSTOMER' && policy.user_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You can only submit claims for your own policies.'
      });
    }

    if (policy.status !== 'ACTIVE') {
      return res.status(400).json({
        success: false,
        message: `Cannot submit claim: Policy is currently ${policy.status}.`
      });
    }

    // Generate unique Claim ID
    const claimId = await generateClaimId();

    // Insert claim with initial status SUBMITTED
    const insertResult = await db.query(
      `INSERT INTO claims (
        claim_id, user_id, policy_id, claim_type, incident_date,
        incident_location, claim_amount, description, current_status,
        verification_status, fraud_risk_score, fraud_risk_level
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'SUBMITTED', 'PENDING', 0, 'LOW')`,
      [
        claimId,
        policy.user_id,
        policyId,
        claimType,
        incidentDate,
        incidentLocation || 'Not specified',
        parsedAmount,
        description.trim()
      ]
    );

    const claimDbId = insertResult.insertId;

    // Record initial status history
    await db.query(
      `INSERT INTO claim_status_history (claim_id, from_status, to_status, changed_by_user_id, notes)
       VALUES (?, NULL, 'SUBMITTED', ?, 'Claim submitted online by customer.')`,
      [claimDbId, userId]
    );

    // Process any uploaded files attached to the multipart form
    const uploadedDocs = [];
    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        const docType = req.body.documentType || 'Supporting Document';
        const docResult = await db.query(
          `INSERT INTO claim_documents (
            claim_id, document_type, file_name, original_name,
            file_path, file_size, mime_type, verification_status, uploaded_by
          ) VALUES (?, ?, ?, ?, ?, ?, ?, 'PENDING', ?)`,
          [
            claimDbId,
            docType,
            file.filename,
            file.originalname,
            `uploads/${file.filename}`,
            file.size,
            file.mimetype,
            userId
          ]
        );
        uploadedDocs.push({
          id: docResult.insertId,
          fileName: file.filename,
          originalName: file.originalname,
          size: file.size
        });
      }
    }

    // Fetch user claim history for fraud analysis
    const userClaimHistory = await db.query(
      'SELECT * FROM claims WHERE user_id = ? AND id != ? ORDER BY id DESC',
      [policy.user_id, claimDbId]
    );

    // Run Fraud Detection Engine
    const fraudResult = FraudDetectionEngine.analyze({
      claim: {
        id: claimDbId,
        claim_id: claimId,
        claim_amount: parsedAmount,
        incident_date: incidentDate,
        description
      },
      policy,
      userClaimHistory,
      documents: uploadedDocs
    });

    // Save fraud analysis record
    await db.query(
      `INSERT INTO fraud_analysis (
        claim_id, risk_score, risk_level, triggered_rules, analysis_details
      ) VALUES (?, ?, ?, ?, ?)`,
      [
        claimDbId,
        fraudResult.risk_score,
        fraudResult.risk_level,
        JSON.stringify(fraudResult.triggered_rules),
        JSON.stringify({
          factorBreakdown: fraudResult.factor_breakdown,
          recommendation: fraudResult.recommendation,
          engineVersion: fraudResult.engine_version
        })
      ]
    );

    // Determine lifecycle transition based on fraud score
    let nextStatus = 'UNDER_REVIEW';
    if (fraudResult.risk_score >= 65) {
      nextStatus = 'INVESTIGATION_REQUIRED';

      // Automatically register fraud investigation
      await db.query(
        `INSERT INTO fraud_investigations (claim_id, status, findings, recommended_action)
         VALUES (?, 'OPEN', 'Automated high fraud risk score flagged by system engine. Pending investigator assignment.', 'FURTHER_REVIEW')`,
        [claimDbId]
      );

      // Alert Fraud Investigation Officers
      await notifyRole({
        roleName: 'FRAUD_INVESTIGATOR',
        claimId: claimDbId,
        title: 'High Fraud Risk Alert',
        message: `Claim ${claimId} ($${parsedAmount.toLocaleString()}) scored ${fraudResult.risk_score}% fraud risk. Flagged for SIU review.`,
        type: 'ALERT'
      });
    } else {
      // Notify insurance staff
      await notifyRole({
        roleName: 'INSURANCE_STAFF',
        claimId: claimDbId,
        title: 'New Claim Submitted',
        message: `New claim ${claimId} submitted for policy ${policy.policy_number} ($${parsedAmount.toLocaleString()}).`,
        type: 'INFO'
      });
    }

    // Update claim with fraud scores and new lifecycle status
    await db.query(
      `UPDATE claims
       SET fraud_risk_score = ?,
           fraud_risk_level = ?,
           current_status = ?
       WHERE id = ?`,
      [fraudResult.risk_score, fraudResult.risk_level, nextStatus, claimDbId]
    );

    // Record lifecycle status transition
    await db.query(
      `INSERT INTO claim_status_history (claim_id, from_status, to_status, changed_by_user_id, notes)
       VALUES (?, 'SUBMITTED', ?, ?, ?)`,
      [
        claimDbId,
        nextStatus,
        userId,
        nextStatus === 'INVESTIGATION_REQUIRED'
          ? `System fraud engine flagged risk index ${fraudResult.risk_score}%. Routed to Fraud Unit.`
          : 'System underwriting checks cleared. Placed in staff review queue.'
      ]
    );

    // Customer Notification
    await createNotification({
      userId: policy.user_id,
      claimId: claimDbId,
      title: 'Claim Successfully Submitted',
      message: `Your claim ${claimId} has been registered. Our processing team has initiated document and underwriting checks.`,
      type: 'SUCCESS'
    });

    // Audit Log
    await logAudit({
      userId,
      action: 'CLAIM_SUBMITTED',
      entityType: 'CLAIM',
      entityId: claimId,
      req,
      details: {
        claimAmount: parsedAmount,
        policyNumber: policy.policy_number,
        fraudScore: fraudResult.risk_score,
        riskLevel: fraudResult.risk_level,
        documentsAttached: uploadedDocs.length
      }
    });

    return res.status(201).json({
      success: true,
      message: 'Claim submitted successfully.',
      claim: {
        id: claimDbId,
        claim_id: claimId,
        current_status: nextStatus,
        claim_amount: parsedAmount,
        claim_type: claimType,
        fraud_risk_level: fraudResult.risk_level,
        fraud_risk_score: req.user.role === 'CUSTOMER' ? undefined : fraudResult.risk_score,
        documentsCount: uploadedDocs.length
      }
    });
  } catch (error) {
    console.error('CreateClaim Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal error while processing claim submission.'
    });
  }
};

/**
 * List claims with flexible search, role filtering, and status filters
 */
const getClaims = async (req, res) => {
  try {
    const {
      status,
      fraud_level,
      claim_type,
      search,
      startDate,
      endDate
    } = req.query;

    let conditions = [];
    let params = [];

    // Role-based scoping
    if (req.user.role === 'CUSTOMER') {
      conditions.push('c.user_id = ?');
      params.push(req.user.id);
    } else if (req.user.role === 'FRAUD_INVESTIGATOR') {
      // Fraud investigators default to suspicious or under investigation claims unless specified
      if (!fraud_level && !status) {
        conditions.push("(c.fraud_risk_level = 'HIGH' OR c.current_status IN ('INVESTIGATION_REQUIRED', 'INVESTIGATION_IN_PROGRESS', 'CONFIRMED_FRAUD'))");
      }
    }

    if (status) {
      conditions.push('c.current_status = ?');
      params.push(status);
    }

    if (fraud_level) {
      conditions.push('c.fraud_risk_level = ?');
      params.push(fraud_level);
    }

    if (claim_type) {
      conditions.push('c.claim_type = ?');
      params.push(claim_type);
    }

    if (startDate) {
      conditions.push('c.incident_date >= ?');
      params.push(startDate);
    }

    if (endDate) {
      conditions.push('c.incident_date <= ?');
      params.push(endDate);
    }

    if (search) {
      conditions.push('(c.claim_id LIKE ? OR u.name LIKE ? OR c.incident_location LIKE ? OR c.description LIKE ?)');
      const pattern = `%${search}%`;
      params.push(pattern, pattern, pattern, pattern);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const sql = `
      SELECT
        c.id, c.claim_id, c.user_id, c.policy_id, c.claim_type,
        c.incident_date, c.incident_location, c.claim_amount, c.description,
        c.current_status, c.verification_status, c.fraud_risk_score, c.fraud_risk_level,
        c.assigned_staff_id, c.payout_amount, c.decision_reason, c.created_at, c.updated_at,
        u.name as customer_name, u.email as customer_email, u.phone as customer_phone,
        p.policy_number, p.coverage_amount,
        staff.name as assigned_staff_name,
        (SELECT COUNT(*) FROM claim_documents cd WHERE cd.claim_id = c.id) as document_count
      FROM claims c
      JOIN users u ON c.user_id = u.id
      JOIN policies p ON c.policy_id = p.id
      LEFT JOIN users staff ON c.assigned_staff_id = staff.id
      ${whereClause}
      ORDER BY c.id DESC
    `;

    const claims = await db.query(sql, params);

    // Sanitize customer view if needed
    const sanitizedClaims = claims.map(claim => {
      if (req.user.role === 'CUSTOMER') {
        return {
          ...claim,
          // Customers see friendly risk indicator instead of raw internal scoring details
          customer_risk_status: claim.fraud_risk_level === 'HIGH' ? 'In Review' : 'Verified'
        };
      }
      return claim;
    });

    return res.status(200).json({
      success: true,
      count: sanitizedClaims.length,
      claims: sanitizedClaims
    });
  } catch (error) {
    console.error('GetClaims Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve claims.'
    });
  }
};

/**
 * Get detailed claim information by ID
 */
const getClaimById = async (req, res) => {
  try {
    const claimIdentifier = req.params.id;

    // Can query by numeric id or CLM-XXXX code
    const isNumeric = /^\d+$/.test(claimIdentifier);
    const sql = isNumeric
      ? 'SELECT c.*, u.name as customer_name, u.email as customer_email, u.phone as customer_phone, p.policy_number, p.coverage_amount, p.deductible, p.policy_type, staff.name as assigned_staff_name FROM claims c JOIN users u ON c.user_id = u.id JOIN policies p ON c.policy_id = p.id LEFT JOIN users staff ON c.assigned_staff_id = staff.id WHERE c.id = ?'
      : 'SELECT c.*, u.name as customer_name, u.email as customer_email, u.phone as customer_phone, p.policy_number, p.coverage_amount, p.deductible, p.policy_type, staff.name as assigned_staff_name FROM claims c JOIN users u ON c.user_id = u.id JOIN policies p ON c.policy_id = p.id LEFT JOIN users staff ON c.assigned_staff_id = staff.id WHERE c.claim_id = ?';

    const claim = await db.getOne(sql, [claimIdentifier]);

    if (!claim) {
      return res.status(404).json({
        success: false,
        message: 'Claim not found.'
      });
    }

    // Role check: customer can only view own claims
    if (req.user.role === 'CUSTOMER' && claim.user_id !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Access denied: You are not authorized to view this claim.'
      });
    }

    // Fetch documents
    const documents = await db.query(
      `SELECT cd.*, uploader.name as uploader_name, verifier.name as verifier_name
       FROM claim_documents cd
       LEFT JOIN users uploader ON cd.uploaded_by = uploader.id
       LEFT JOIN users verifier ON cd.verified_by = verifier.id
       WHERE cd.claim_id = ?
       ORDER BY cd.id ASC`,
      [claim.id]
    );

    // Fetch status history timeline
    const history = await db.query(
      `SELECT csh.*, u.name as changed_by_name, r.name as changed_by_role
       FROM claim_status_history csh
       LEFT JOIN users u ON csh.changed_by_user_id = u.id
       LEFT JOIN roles r ON u.role_id = r.id
       WHERE csh.claim_id = ?
       ORDER BY csh.created_at ASC`,
      [claim.id]
    );

    // Fetch fraud analysis
    const fraudAnalysis = await db.getOne(
      'SELECT * FROM fraud_analysis WHERE claim_id = ? ORDER BY id DESC LIMIT 1',
      [claim.id]
    );

    // Fetch fraud investigations
    const investigations = await db.query(
      `SELECT fi.*, inv.name as investigator_name, inv.email as investigator_email
       FROM fraud_investigations fi
       LEFT JOIN users inv ON fi.investigator_id = inv.id
       WHERE fi.claim_id = ?
       ORDER BY fi.id DESC`,
      [claim.id]
    );

    // Parse JSON fields
    let parsedFraudAnalysis = null;
    if (fraudAnalysis) {
      try {
        parsedFraudAnalysis = {
          ...fraudAnalysis,
          triggered_rules: typeof fraudAnalysis.triggered_rules === 'string'
            ? JSON.parse(fraudAnalysis.triggered_rules)
            : fraudAnalysis.triggered_rules,
          analysis_details: typeof fraudAnalysis.analysis_details === 'string'
            ? JSON.parse(fraudAnalysis.analysis_details)
            : fraudAnalysis.analysis_details
        };
      } catch (e) {
        parsedFraudAnalysis = fraudAnalysis;
      }
    }

    // Prepare response based on role
    const responsePayload = {
      ...claim,
      documents,
      history
    };

    if (req.user.role === 'CUSTOMER') {
      // Customer gets safe summary
      responsePayload.fraud_summary = {
        status: claim.fraud_risk_level === 'HIGH' ? 'Under Routine Verification' : 'Standard Verification Passed'
      };
      delete responsePayload.fraud_risk_score;
    } else {
      // Staff, Investigator, Admin, Manager get complete transparency
      responsePayload.fraud_analysis = parsedFraudAnalysis;
      responsePayload.investigations = investigations;
    }

    return res.status(200).json({
      success: true,
      claim: responsePayload
    });
  } catch (error) {
    console.error('GetClaimById Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve claim details.'
    });
  }
};

/**
 * Update claim status / adjudication decision
 * Roles: INSURANCE_STAFF, ADMIN
 */
const updateClaimStatus = async (req, res) => {
  try {
    const claimId = req.params.id;
    const { status, action, payoutAmount, decisionReason, assignedStaffId } = req.body;
    const targetStatus = status || action;

    const claim = await db.getOne('SELECT * FROM claims WHERE id = ?', [claimId]);
    if (!claim) {
      return res.status(404).json({
        success: false,
        message: 'Claim not found.'
      });
    }

    const previousStatus = claim.current_status;
    let newStatus = targetStatus;
    let finalPayout = claim.payout_amount;
    let reason = decisionReason || null;

    // Staff Assignment
    if (assignedStaffId) {
      await db.query('UPDATE claims SET assigned_staff_id = ? WHERE id = ?', [assignedStaffId, claimId]);
      await logAudit({
        userId: req.user.id,
        action: 'CLAIM_ASSIGNED',
        entityType: 'CLAIM',
        entityId: claim.claim_id,
        req,
        details: { assignedStaffId }
      });
    }

    // Business Rules Verification for APPROVAL
    if (targetStatus === 'APPROVED') {
      // Check documents
      const docs = await db.query('SELECT * FROM claim_documents WHERE claim_id = ?', [claimId]);
      if (docs.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Cannot approve claim: No supporting documents uploaded.'
        });
      }

      const hasUnverifiedDocs = docs.some(d => d.verification_status !== 'VERIFIED');
      if (hasUnverifiedDocs) {
        return res.status(400).json({
          success: false,
          message: 'Cannot approve claim: All uploaded documents must be verified by claims staff prior to final approval.'
        });
      }

      // Check Fraud clearance if flagged HIGH
      if (claim.fraud_risk_level === 'HIGH') {
        const clearedInvestigation = await db.getOne(
          "SELECT id FROM fraud_investigations WHERE claim_id = ? AND status = 'CLEARED'",
          [claimId]
        );

        if (!clearedInvestigation) {
          return res.status(400).json({
            success: false,
            message: 'Cannot approve claim: Claim was flagged as HIGH fraud risk and requires clearance from a Fraud Investigation Officer before approval.'
          });
        }
      }

      finalPayout = parseFloat(payoutAmount) || claim.claim_amount;
      newStatus = 'APPROVED';
      reason = reason || 'Claim meets all underwriting guidelines and document verifications.';

      // Notify customer
      await createNotification({
        userId: claim.user_id,
        claimId: claim.id,
        title: 'Claim Approved',
        message: `Your claim ${claim.claim_id} has been APPROVED! Settlement amount: $${finalPayout.toLocaleString()}.`,
        type: 'SUCCESS'
      });
    } else if (targetStatus === 'REJECTED') {
      newStatus = 'REJECTED';
      finalPayout = 0;
      reason = reason || 'Claim does not satisfy eligibility guidelines or documentation failed verification.';

      // Notify customer
      await createNotification({
        userId: claim.user_id,
        claimId: claim.id,
        title: 'Claim Rejected',
        message: `Your claim ${claim.claim_id} has been rejected. Reason: ${reason}`,
        type: 'ALERT'
      });
    } else if (targetStatus === 'DOCS_PENDING' || targetStatus === 'REQUEST_INFO') {
      newStatus = 'DOCS_PENDING';
      reason = reason || 'Additional documentation or clarification required.';

      await createNotification({
        userId: claim.user_id,
        claimId: claim.id,
        title: 'Additional Information Required',
        message: `Claims officer requested additional information for ${claim.claim_id}: ${reason}`,
        type: 'WARNING'
      });
    } else if (targetStatus === 'UNDER_REVIEW') {
      newStatus = 'UNDER_REVIEW';
    }

    // Update claim
    await db.query(
      `UPDATE claims
       SET current_status = ?,
           payout_amount = ?,
           decision_reason = ?,
           assigned_staff_id = COALESCE(?, assigned_staff_id),
           updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [newStatus, finalPayout, reason, req.user.id, claimId]
    );

    // Record status history
    await db.query(
      `INSERT INTO claim_status_history (claim_id, from_status, to_status, changed_by_user_id, notes)
       VALUES (?, ?, ?, ?, ?)`,
      [claimId, previousStatus, newStatus, req.user.id, reason]
    );

    // Audit log
    await logAudit({
      userId: req.user.id,
      action: `CLAIM_STATUS_${newStatus}`,
      entityType: 'CLAIM',
      entityId: claim.claim_id,
      req,
      details: {
        fromStatus: previousStatus,
        toStatus: newStatus,
        payoutAmount: finalPayout,
        reason
      }
    });

    return res.status(200).json({
      success: true,
      message: `Claim status successfully updated to ${newStatus}.`,
      claim: {
        id: claim.id,
        claim_id: claim.claim_id,
        current_status: newStatus,
        payout_amount: finalPayout,
        decision_reason: reason
      }
    });
  } catch (error) {
    console.error('UpdateClaimStatus Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update claim status.'
    });
  }
};

module.exports = {
  createClaim,
  getClaims,
  getClaimById,
  updateClaimStatus
};
