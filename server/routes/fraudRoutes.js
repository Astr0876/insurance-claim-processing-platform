const express = require('express');
const router = express.Router();
const { authenticateToken, requireRoles } = require('../middleware/auth');
const {
  getFraudQueue,
  getFraudDetails,
  updateInvestigation
} = require('../controllers/fraudController');

// Get suspicious claims queue
router.get(
  '/queue',
  authenticateToken,
  requireRoles('FRAUD_INVESTIGATOR', 'ADMIN', 'MANAGER', 'INSURANCE_STAFF'),
  getFraudQueue
);

// Get detailed fraud metrics for a claim
router.get(
  '/:claimId',
  authenticateToken,
  requireRoles('FRAUD_INVESTIGATOR', 'ADMIN', 'MANAGER', 'INSURANCE_STAFF'),
  getFraudDetails
);

// Update investigation findings & verdict
router.put(
  '/:claimId/investigate',
  authenticateToken,
  requireRoles('FRAUD_INVESTIGATOR', 'ADMIN'),
  updateInvestigation
);

module.exports = router;
