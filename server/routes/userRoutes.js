const express = require('express');
const router = express.Router();
const { authenticateToken, requireRoles } = require('../middleware/auth');
const {
  getUsers,
  updateUserRole,
  toggleUserStatus,
  createUser
} = require('../controllers/userController');

router.get('/', authenticateToken, requireRoles('ADMIN', 'MANAGER'), getUsers);
router.post('/', authenticateToken, requireRoles('ADMIN'), createUser);
router.put('/:id/role', authenticateToken, requireRoles('ADMIN'), updateUserRole);
router.put('/:id/status', authenticateToken, requireRoles('ADMIN'), toggleUserStatus);

module.exports = router;
