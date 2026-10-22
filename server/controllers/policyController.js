const db = require('../config/db');

/**
 * Get policies for current customer or all policies for staff/admin
 */
const getPolicies = async (req, res) => {
  try {
    let sql;
    let params = [];

    if (req.user.role === 'CUSTOMER') {
      sql = `SELECT p.*, u.name as customer_name, u.email as customer_email
             FROM policies p
             JOIN users u ON p.user_id = u.id
             WHERE p.user_id = ?
             ORDER BY p.id DESC`;
      params = [req.user.id];
    } else {
      sql = `SELECT p.*, u.name as customer_name, u.email as customer_email
             FROM policies p
             JOIN users u ON p.user_id = u.id
             ORDER BY p.id DESC`;
    }

    const policies = await db.query(sql, params);

    return res.status(200).json({
      success: true,
      policies
    });
  } catch (error) {
    console.error('GetPolicies Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve policies.'
    });
  }
};

/**
 * Create a new policy
 */
const createPolicy = async (req, res) => {
  try {
    const { userId, policyType, coverageAmount, deductible = 500, startDate, endDate } = req.body;
    const targetUserId = req.user.role === 'CUSTOMER' ? req.user.id : (userId || req.user.id);

    const policyNumber = `POL-${new Date().getFullYear()}-${policyType.substring(0, 4).toUpperCase()}-${Math.floor(100 + Math.random() * 900)}`;
    const start = startDate || new Date().toISOString().split('T')[0];
    const end = endDate || new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

    const result = await db.query(
      `INSERT INTO policies (policy_number, user_id, policy_type, coverage_amount, deductible, start_date, end_date, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'ACTIVE')`,
      [policyNumber, targetUserId, policyType, parseFloat(coverageAmount) || 25000, parseFloat(deductible) || 500, start, end]
    );

    return res.status(201).json({
      success: true,
      message: 'Policy created successfully.',
      policy: {
        id: result.insertId,
        policy_number: policyNumber,
        policy_type: policyType,
        coverage_amount: coverageAmount,
        status: 'ACTIVE'
      }
    });
  } catch (error) {
    console.error('CreatePolicy Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to create policy.'
    });
  }
};

module.exports = {
  getPolicies,
  createPolicy
};
