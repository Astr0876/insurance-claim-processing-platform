const express = require('express');
const router = express.Router();
const { authenticateToken, requireRoles } = require('../middleware/auth');
const {
  getSummaryMetrics,
  getStatusBreakdown,
  getTypeBreakdown,
  getFraudRiskBreakdown,
  getMonthlyTrends,
  getExportData
} = require('../controllers/reportController');

// All staff, investigators, managers, and admins can view reports
router.get(
  '/summary',
  authenticateToken,
  requireRoles('INSURANCE_STAFF', 'FRAUD_INVESTIGATOR', 'MANAGER', 'ADMIN'),
  getSummaryMetrics
);

router.get(
  '/status',
  authenticateToken,
  requireRoles('INSURANCE_STAFF', 'FRAUD_INVESTIGATOR', 'MANAGER', 'ADMIN'),
  getStatusBreakdown
);

router.get(
  '/types',
  authenticateToken,
  requireRoles('INSURANCE_STAFF', 'FRAUD_INVESTIGATOR', 'MANAGER', 'ADMIN'),
  getTypeBreakdown
);

router.get(
  '/fraud',
  authenticateToken,
  requireRoles('INSURANCE_STAFF', 'FRAUD_INVESTIGATOR', 'MANAGER', 'ADMIN'),
  getFraudRiskBreakdown
);

router.get(
  '/trends',
  authenticateToken,
  requireRoles('INSURANCE_STAFF', 'FRAUD_INVESTIGATOR', 'MANAGER', 'ADMIN'),
  getMonthlyTrends
);

router.get(
  '/export',
  authenticateToken,
  requireRoles('INSURANCE_STAFF', 'FRAUD_INVESTIGATOR', 'MANAGER', 'ADMIN'),
  getExportData
);

module.exports = router;
