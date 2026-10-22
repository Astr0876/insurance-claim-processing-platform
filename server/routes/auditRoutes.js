const express = require('express');
const router = express.Router();
const { authenticateToken, requireRoles } = require('../middleware/auth');
const { getAuditLogs } = require('../controllers/auditController');

router.get('/', authenticateToken, requireRoles('ADMIN', 'MANAGER'), getAuditLogs);

module.exports = router;
