const path = require('path');
const fs = require('fs');
const db = require('../config/db');
const { logAudit } = require('../middleware/auditLogger');
const { createNotification } = require('../services/notificationService');

/**
 * Upload supporting documents for a claim
 */
const uploadDocuments = async (req, res) => {
  try {
    const claimId = req.params.claimId || req.body.claimId;
    const documentType = req.body.documentType || 'Supporting Document';

    if (!claimId) {
      return res.status(400).json({
        success: false,
        message: 'Claim ID is required.'
      });
    }

    const claim = await db.getOne('SELECT * FROM claims WHERE id = ?', [claimId]);
    if (!claim) {
      return res.status(404).json({
        success: false,
        message: 'Claim not found.'
      });
    }

    // Role check: customer can only upload to own claim
    if (req.user.role === 'CUSTOMER' && claim.user_id !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Access denied: You can only upload documents to your own claim.'
      });
    }

    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No files uploaded. Please attach at least one valid document.'
      });
    }

    const savedDocs = [];
    for (const file of req.files) {
      const result = await db.query(
        `INSERT INTO claim_documents (
          claim_id, document_type, file_name, original_name,
          file_path, file_size, mime_type, verification_status, uploaded_by
        ) VALUES (?, ?, ?, ?, ?, ?, ?, 'PENDING', ?)`,
        [
          claim.id,
          documentType,
          file.filename,
          file.originalname,
          `uploads/${file.filename}`,
          file.size,
          file.mimetype,
          req.user.id
        ]
      );

      savedDocs.push({
        id: result.insertId,
        document_type: documentType,
        file_name: file.filename,
        original_name: file.originalname,
        file_size: file.size,
        mime_type: file.mimetype,
        verification_status: 'PENDING'
      });
    }

    // Update claim verification status if it was previously PENDING
    await db.query(
      "UPDATE claims SET verification_status = 'PENDING', updated_at = CURRENT_TIMESTAMP WHERE id = ?",
      [claim.id]
    );

    // Notify staff of new uploads
    if (claim.assigned_staff_id) {
      await createNotification({
        userId: claim.assigned_staff_id,
        claimId: claim.id,
        title: 'New Documents Uploaded',
        message: `${savedDocs.length} new document(s) uploaded for claim ${claim.claim_id}.`,
        type: 'INFO'
      });
    }

    // Audit log
    await logAudit({
      userId: req.user.id,
      action: 'DOCUMENTS_UPLOADED',
      entityType: 'CLAIM_DOCUMENT',
      entityId: claim.claim_id,
      req,
      details: {
        claimId: claim.claim_id,
        uploadedCount: savedDocs.length,
        documentType
      }
    });

    return res.status(201).json({
      success: true,
      message: `${savedDocs.length} document(s) uploaded successfully.`,
      documents: savedDocs
    });
  } catch (error) {
    console.error('UploadDocuments Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to upload documents.'
    });
  }
};

/**
 * Verify or Reject a document
 * Roles: INSURANCE_STAFF, ADMIN
 */
const verifyDocument = async (req, res) => {
  try {
    const documentId = req.params.documentId;
    const { status, notes } = req.body; // status: 'VERIFIED' | 'REJECTED' | 'PENDING'

    if (!['VERIFIED', 'REJECTED', 'PENDING'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Status must be VERIFIED, REJECTED, or PENDING.'
      });
    }

    const doc = await db.getOne('SELECT cd.*, c.user_id as customer_id, c.claim_id as claim_code FROM claim_documents cd JOIN claims c ON cd.claim_id = c.id WHERE cd.id = ?', [documentId]);
    if (!doc) {
      return res.status(404).json({
        success: false,
        message: 'Document not found.'
      });
    }

    // Update document status
    await db.query(
      `UPDATE claim_documents
       SET verification_status = ?,
           verification_notes = ?,
           verified_by = ?,
           verified_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [status, notes || null, req.user.id, documentId]
    );

    // Recompute overall claim verification status
    const allDocs = await db.query('SELECT verification_status FROM claim_documents WHERE claim_id = ?', [doc.claim_id]);
    let overallStatus = 'PENDING';

    const allVerified = allDocs.length > 0 && allDocs.every(d => d.verification_status === 'VERIFIED');
    const hasRejected = allDocs.some(d => d.verification_status === 'REJECTED');
    const hasVerified = allDocs.some(d => d.verification_status === 'VERIFIED');

    if (allVerified) {
      overallStatus = 'VERIFIED';
    } else if (hasRejected) {
      overallStatus = 'REJECTED';
    } else if (hasVerified) {
      overallStatus = 'PARTIAL';
    }

    await db.query(
      'UPDATE claims SET verification_status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [overallStatus, doc.claim_id]
    );

    // If all documents verified, update claim status to DOCS_VERIFIED if currently UNDER_REVIEW
    if (allVerified) {
      const claim = await db.getOne('SELECT current_status FROM claims WHERE id = ?', [doc.claim_id]);
      if (claim && claim.current_status === 'UNDER_REVIEW') {
        await db.query("UPDATE claims SET current_status = 'DOCS_VERIFIED' WHERE id = ?", [doc.claim_id]);
        await db.query(
          `INSERT INTO claim_status_history (claim_id, from_status, to_status, changed_by_user_id, notes)
           VALUES (?, 'UNDER_REVIEW', 'DOCS_VERIFIED', ?, 'All supporting documents successfully verified.')`,
          [doc.claim_id, req.user.id]
        );
      }
    }

    // Notify customer
    await createNotification({
      userId: doc.customer_id,
      claimId: doc.claim_id,
      title: `Document ${status === 'VERIFIED' ? 'Verified' : 'Verification Update'}`,
      message: `Document "${doc.original_name}" for claim ${doc.claim_code} marked as ${status}.${notes ? ` Notes: ${notes}` : ''}`,
      type: status === 'VERIFIED' ? 'SUCCESS' : 'WARNING'
    });

    // Audit log
    await logAudit({
      userId: req.user.id,
      action: `DOCUMENT_${status}`,
      entityType: 'CLAIM_DOCUMENT',
      entityId: doc.id,
      req,
      details: {
        documentName: doc.original_name,
        claimCode: doc.claim_code,
        notes
      }
    });

    return res.status(200).json({
      success: true,
      message: `Document successfully marked as ${status}.`,
      document: {
        id: documentId,
        verification_status: status,
        verification_notes: notes,
        overallClaimVerification: overallStatus
      }
    });
  } catch (error) {
    console.error('VerifyDocument Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update document verification status.'
    });
  }
};

/**
 * Download / view document file
 */
const downloadDocument = async (req, res) => {
  try {
    const documentId = req.params.documentId;
    const doc = await db.getOne('SELECT * FROM claim_documents WHERE id = ?', [documentId]);

    if (!doc) {
      return res.status(404).json({
        success: false,
        message: 'Document record not found.'
      });
    }

    const filePath = path.join(__dirname, '..', doc.file_path);

    // Check file existence on disk
    if (!fs.existsSync(filePath)) {
      // If demo file doesn't exist on disk, send a synthetic mock document buffer for seamless demo
      const mockContent = Buffer.from(
        `%PDF-1.4\n1 0 obj\n<< /Title (${doc.original_name}) /Producer (Insurance Platform Engine) >>\nendobj\ntrailer\n<< /Root 1 0 R >>\n%%EOF`
      );
      res.setHeader('Content-Type', doc.mime_type || 'application/pdf');
      res.setHeader('Content-Disposition', `inline; filename="${doc.original_name}"`);
      return res.send(mockContent);
    }

    res.setHeader('Content-Type', doc.mime_type);
    res.setHeader('Content-Disposition', `inline; filename="${encodeURIComponent(doc.original_name)}"`);
    return res.sendFile(filePath);
  } catch (error) {
    console.error('DownloadDocument Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to download document file.'
    });
  }
};

module.exports = {
  uploadDocuments,
  verifyDocument,
  downloadDocument
};
