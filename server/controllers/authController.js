const bcrypt = require('bcryptjs');
const db = require('../config/db');
const { generateToken } = require('../config/jwt');
const { logAudit } = require('../middleware/auditLogger');
const { createNotification } = require('../services/notificationService');

/**
 * Register a new customer
 */
const register = async (req, res) => {
  try {
    const { name, email, password, phone, policyType = 'AUTO', coverageAmount = 50000 } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Name, email, and password are required.'
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters long.'
      });
    }

    // Check if user already exists
    const existing = await db.getOne('SELECT id FROM users WHERE email = ?', [email.toLowerCase().trim()]);
    if (existing) {
      return res.status(409).json({
        success: false,
        message: 'An account with this email address already exists.'
      });
    }

    // Hash password
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Default role is CUSTOMER (id = 1)
    const customerRole = await db.getOne("SELECT id FROM roles WHERE name = 'CUSTOMER'");
    const roleId = customerRole ? customerRole.id : 1;

    // Insert user
    const userResult = await db.query(
      `INSERT INTO users (name, email, password_hash, phone, role_id, status)
       VALUES (?, ?, ?, ?, ?, 'ACTIVE')`,
      [name.trim(), email.toLowerCase().trim(), passwordHash, phone || null, roleId]
    );

    const userId = userResult.insertId;

    // Automatically provision an active policy for the new customer so they can submit claims immediately
    const policyNum = `POL-${new Date().getFullYear()}-${policyType.substring(0, 4).toUpperCase()}-${Math.floor(100 + Math.random() * 900)}`;
    const today = new Date().toISOString().split('T')[0];
    const nextYear = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

    await db.query(
      `INSERT INTO policies (policy_number, user_id, policy_type, coverage_amount, deductible, start_date, end_date, status)
       VALUES (?, ?, ?, ?, 500.00, ?, ?, 'ACTIVE')`,
      [policyNum, userId, policyType, parseFloat(coverageAmount) || 50000.00, today, nextYear]
    );

    // Welcome notification
    await createNotification({
      userId,
      title: 'Welcome to the Insurance Platform',
      message: `Your account and default policy ${policyNum} (${policyType}) have been activated successfully.`,
      type: 'SUCCESS'
    });

    // Audit log
    await logAudit({
      userId,
      action: 'USER_REGISTERED',
      entityType: 'USER',
      entityId: userId,
      req,
      details: { email: email.toLowerCase().trim(), initialPolicy: policyNum }
    });

    // Generate JWT
    const token = generateToken({
      id: userId,
      name: name.trim(),
      email: email.toLowerCase().trim(),
      role: 'CUSTOMER'
    });

    return res.status(201).json({
      success: true,
      message: 'Account registered successfully.',
      token,
      user: {
        id: userId,
        name: name.trim(),
        email: email.toLowerCase().trim(),
        phone: phone || null,
        role: 'CUSTOMER',
        initialPolicy: policyNum
      }
    });
  } catch (error) {
    console.error('Registration Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error while creating user account.'
    });
  }
};

/**
 * Login user
 */
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required.'
      });
    }

    const user = await db.getOne(
      `SELECT u.id, u.name, u.email, u.password_hash, u.phone, u.status, r.name as role
       FROM users u
       JOIN roles r ON u.role_id = r.id
       WHERE u.email = ?`,
      [email.toLowerCase().trim()]
    );

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.'
      });
    }

    if (user.status !== 'ACTIVE') {
      return res.status(403).json({
        success: false,
        message: `Account is ${user.status.toLowerCase()}. Access prohibited.`
      });
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      await logAudit({
        userId: user.id,
        action: 'LOGIN_FAILED',
        entityType: 'USER',
        entityId: user.id,
        req,
        details: { reason: 'Incorrect password' }
      });

      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.'
      });
    }

    // Successful login
    const token = generateToken(user);

    await logAudit({
      userId: user.id,
      action: 'LOGIN_SUCCESS',
      entityType: 'USER',
      entityId: user.id,
      req,
      details: { role: user.role }
    });

    return res.status(200).json({
      success: true,
      message: 'Login successful.',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Login Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error during authentication.'
    });
  }
};

/**
 * Get current authenticated user details
 */
const getMe = async (req, res) => {
  try {
    const user = await db.getOne(
      `SELECT u.id, u.name, u.email, u.phone, u.status, u.created_at, r.name as role
       FROM users u
       JOIN roles r ON u.role_id = r.id
       WHERE u.id = ?`,
      [req.user.id]
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User profile not found.'
      });
    }

    // Fetch policies if customer
    let policies = [];
    if (user.role === 'CUSTOMER') {
      policies = await db.query(
        `SELECT id, policy_number, policy_type, coverage_amount, deductible, start_date, end_date, status
         FROM policies
         WHERE user_id = ?
         ORDER BY id DESC`,
        [user.id]
      );
    }

    // Fetch unread notifications count
    const notifCount = await db.getOne(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0',
      [user.id]
    );

    return res.status(200).json({
      success: true,
      user: {
        ...user,
        policies,
        unreadNotifications: notifCount ? notifCount.count : 0
      }
    });
  } catch (error) {
    console.error('GetMe Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve user profile.'
    });
  }
};

module.exports = {
  register,
  login,
  getMe
};
