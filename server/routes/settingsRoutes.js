const express = require('express');
const router = express.Router();
const { authenticateToken, requireRoles } = require('../middleware/auth');
const { getSettings, updateSetting } = require('../controllers/settingsController');

router.get('/', authenticateToken, requireRoles('ADMIN', 'MANAGER'), getSettings);
router.put('/', authenticateToken, requireRoles('ADMIN'), updateSetting);

module.exports = router;
