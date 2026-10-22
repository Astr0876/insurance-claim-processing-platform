const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { getPolicies, createPolicy } = require('../controllers/policyController');

router.get('/', authenticateToken, getPolicies);
router.post('/', authenticateToken, createPolicy);

module.exports = router;
