const bcrypt = require('bcryptjs');
const db = require('../config/db');
const { logAudit } = require('../middleware/auditLogger');

/**
 * Get all users with roles
 * Roles: ADMIN, MANAGER
 */
const getUsers = async (req, res) => {
  try {
    const { role, status, search } = req.query;

    let conditions = [];
    let params = [];

    if (role) {
      conditions.push('r.name = ?');
      params.push(role);
    }

    if (status) {
      conditions.push('u.status = ?');
      params.push(status);
    }

    if (search) {
      conditions.push('(u.name LIKE ? OR u.email LIKE ? OR u.phone LIKE ?)');
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const sql = `
      SELECT
        u.id, u.name, u.email, u.phone, u.status, u.created_at, u.updated_at,
        r.id as role_id, r.name as role_name, r.description as role_description,
        (SELECT COUNT(*) FROM claims c WHERE c.user_id = u.id) as claims_count,
        (SELECT COUNT(*) FROM policies p WHERE p.user_id = u.id) as policies_count
      FROM users u
      JOIN roles r ON u.role_id = r.id
      ${whereClause}
      ORDER BY u.id ASC
    `;

    const users = await db.query(sql, params);

    return res.status(200).json({
      success: true,
      count: users.length,
      users
    });
  } catch (error) {
    console.error('GetUsers Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve users.'
    });
  }
};

/**
 * Update user role
 * Roles: ADMIN
 */
const updateUserRole = async (req, res) => {
  try {
    const userId = req.params.id;
    const { roleName, roleId } = req.body;

    let targetRoleId = roleId;
    if (!targetRoleId && roleName) {
      const roleRow = await db.getOne('SELECT id FROM roles WHERE name = ?', [roleName]);
      if (!roleRow) {
        return res.status(400).json({
          success: false,
          message: `Role "${roleName}" not found.`
        });
      }
      targetRoleId = roleRow.id;
    }

    if (!targetRoleId) {
      return res.status(400).json({
        success: false,
        message: 'roleName or roleId is required.'
      });
    }

    const user = await db.getOne('SELECT * FROM users WHERE id = ?', [userId]);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found.'
      });
    }

    // Prevent changing own admin role to lock oneself out
    if (user.id === req.user.id && user.role_id !== targetRoleId) {
      return res.status(400).json({
        success: false,
        message: 'Cannot modify your own administrator role.'
      });
    }

    await db.query('UPDATE users SET role_id = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?', [targetRoleId, userId]);

    const updatedUser = await db.getOne(
      'SELECT u.id, u.name, u.email, r.name as role_name FROM users u JOIN roles r ON u.role_id = r.id WHERE u.id = ?',
      [userId]
    );

    await logAudit({
      userId: req.user.id,
      action: 'USER_ROLE_CHANGED',
      entityType: 'USER',
      entityId: userId,
      req,
      details: {
        targetUser: user.email,
        oldRoleId: user.role_id,
        newRoleId: targetRoleId,
        newRoleName: updatedUser.role_name
      }
    });

    return res.status(200).json({
      success: true,
      message: `User role successfully updated to ${updatedUser.role_name}.`,
      user: updatedUser
    });
  } catch (error) {
    console.error('UpdateUserRole Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update user role.'
    });
  }
};

/**
 * Toggle user status (ACTIVE / SUSPENDED)
 * Roles: ADMIN
 */
const toggleUserStatus = async (req, res) => {
  try {
    const userId = req.params.id;
    const { status } = req.body; // 'ACTIVE' | 'SUSPENDED'

    if (!['ACTIVE', 'SUSPENDED'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Status must be ACTIVE or SUSPENDED.'
      });
    }

    const user = await db.getOne('SELECT * FROM users WHERE id = ?', [userId]);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found.'
      });
    }

    if (user.id === req.user.id) {
      return res.status(400).json({
        success: false,
        message: 'Cannot suspend your own account.'
      });
    }

    await db.query('UPDATE users SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?', [status, userId]);

    await logAudit({
      userId: req.user.id,
      action: `USER_STATUS_${status}`,
      entityType: 'USER',
      entityId: userId,
      req,
      details: { targetUser: user.email, newStatus: status }
    });

    return res.status(200).json({
      success: true,
      message: `User account is now ${status}.`,
      user: { id: userId, status }
    });
  } catch (error) {
    console.error('ToggleUserStatus Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update user status.'
    });
  }
};

/**
 * Create a new user (Staff / Investigator / Manager)
 * Roles: ADMIN
 */
const createUser = async (req, res) => {
  try {
    const { name, email, password, phone, roleName } = req.body;

    if (!name || !email || !password || !roleName) {
      return res.status(400).json({
        success: false,
        message: 'Name, email, password, and role are required.'
      });
    }

    const existing = await db.getOne('SELECT id FROM users WHERE email = ?', [email.toLowerCase().trim()]);
    if (existing) {
      return res.status(409).json({
        success: false,
        message: 'A user with this email address already exists.'
      });
    }

    const role = await db.getOne('SELECT id FROM roles WHERE name = ?', [roleName]);
    if (!role) {
      return res.status(400).json({
        success: false,
        message: `Role "${roleName}" is invalid.`
      });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const result = await db.query(
      `INSERT INTO users (name, email, password_hash, phone, role_id, status)
       VALUES (?, ?, ?, ?, ?, 'ACTIVE')`,
      [name.trim(), email.toLowerCase().trim(), passwordHash, phone || null, role.id]
    );

    await logAudit({
      userId: req.user.id,
      action: 'USER_CREATED_BY_ADMIN',
      entityType: 'USER',
      entityId: result.insertId,
      req,
      details: { email: email.toLowerCase().trim(), role: roleName }
    });

    return res.status(201).json({
      success: true,
      message: `User ${name} created with role ${roleName}.`,
      user: {
        id: result.insertId,
        name: name.trim(),
        email: email.toLowerCase().trim(),
        role: roleName,
        status: 'ACTIVE'
      }
    });
  } catch (error) {
    console.error('CreateUser Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to create user.'
    });
  }
};

module.exports = {
  getUsers,
  updateUserRole,
  toggleUserStatus,
  createUser
};
