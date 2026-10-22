const express = require('express');
const router = express.Router();
const upload = require('../middleware/upload');
const { authenticateToken, requireRoles } = require('../middleware/auth');
const {
  createClaim,
  getClaims,
  getClaimById,
  updateClaimStatus
} = require('../controllers/claimController');

// Submit new claim (Customer or Staff)
router.post(
  '/',
  authenticateToken,
  upload.array('documents', 5),
  createClaim
);

// Get claims list (Role-scoped)
router.get('/', authenticateToken, getClaims);

// Get single claim details
router.get('/:id', authenticateToken, getClaimById);

// Update claim status / adjudication (Staff, Admin)
router.put(
  '/:id/status',
  authenticateToken,
  requireRoles('INSURANCE_STAFF', 'ADMIN'),
  updateClaimStatus
);

module.exports = router;
