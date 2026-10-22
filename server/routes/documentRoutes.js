const express = require('express');
const router = express.Router();
const upload = require('../middleware/upload');
const { authenticateToken, requireRoles } = require('../middleware/auth');
const {
  uploadDocuments,
  verifyDocument,
  downloadDocument
} = require('../controllers/documentController');

// Upload documents to existing claim
router.post(
  '/:claimId/upload',
  authenticateToken,
  upload.array('documents', 5),
  uploadDocuments
);

// Verify document (Staff, Admin)
router.put(
  '/:documentId/verify',
  authenticateToken,
  requireRoles('INSURANCE_STAFF', 'ADMIN'),
  verifyDocument
);

// Download / stream document
router.get(
  '/:documentId/download',
  authenticateToken,
  downloadDocument
);

module.exports = router;
