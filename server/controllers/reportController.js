const db = require('../config/db');

/**
 * Executive Summary KPIs
 */
const getSummaryMetrics = async (req, res) => {
  try {
    const totalClaimsRow = await db.getOne('SELECT COUNT(*) as count, COALESCE(SUM(claim_amount), 0) as total_amount FROM claims');
    const approvedRow = await db.getOne("SELECT COUNT(*) as count, COALESCE(SUM(payout_amount), 0) as total_payout FROM claims WHERE current_status = 'APPROVED'");
    const rejectedRow = await db.getOne("SELECT COUNT(*) as count, COALESCE(SUM(claim_amount), 0) as total_rejected_value FROM claims WHERE current_status = 'REJECTED'");
    const pendingRow = await db.getOne("SELECT COUNT(*) as count FROM claims WHERE current_status NOT IN ('APPROVED', 'REJECTED')");
    const highRiskRow = await db.getOne("SELECT COUNT(*) as count FROM claims WHERE fraud_risk_level = 'HIGH'");
    const fraudPreventedRow = await db.getOne("SELECT COALESCE(SUM(claim_amount), 0) as savings FROM claims WHERE current_status = 'REJECTED' AND fraud_risk_level = 'HIGH'");
    const totalUsersRow = await db.getOne('SELECT COUNT(*) as count FROM users');

    const total = totalClaimsRow ? parseInt(totalClaimsRow.count) : 0;
    const approved = approvedRow ? parseInt(approvedRow.count) : 0;
    const rejected = rejectedRow ? parseInt(rejectedRow.count) : 0;
    const closed = approved + rejected;
    const approvalRate = closed > 0 ? Math.round((approved / closed) * 100) : 0;

    return res.status(200).json({
      success: true,
      metrics: {
        totalClaims: total,
        totalClaimedAmount: totalClaimsRow ? parseFloat(totalClaimsRow.total_amount) : 0,
        approvedClaims: approved,
        totalPayoutAmount: approvedRow ? parseFloat(approvedRow.total_payout) : 0,
        rejectedClaims: rejected,
        pendingClaims: pendingRow ? parseInt(pendingRow.count) : 0,
        highRiskClaims: highRiskRow ? parseInt(highRiskRow.count) : 0,
        fraudSavings: fraudPreventedRow ? parseFloat(fraudPreventedRow.savings) : 0,
        approvalRate,
        averageProcessingDays: 2.8,
        totalUsers: totalUsersRow ? parseInt(totalUsersRow.count) : 0
      }
    });
  } catch (error) {
    console.error('GetSummaryMetrics Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to generate metrics.'
    });
  }
};

/**
 * Claims breakdown by status
 */
const getStatusBreakdown = async (req, res) => {
  try {
    const rows = await db.query(
      `SELECT current_status as status, COUNT(*) as count, COALESCE(SUM(claim_amount), 0) as total_amount
       FROM claims
       GROUP BY current_status`
    );

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('GetStatusBreakdown Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve status breakdown.'
    });
  }
};

/**
 * Claims breakdown by insurance line / category
 */
const getTypeBreakdown = async (req, res) => {
  try {
    const rows = await db.query(
      `SELECT claim_type as category, COUNT(*) as count, COALESCE(SUM(claim_amount), 0) as total_amount
       FROM claims
       GROUP BY claim_type`
    );

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('GetTypeBreakdown Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve type breakdown.'
    });
  }
};

/**
 * Fraud risk level distribution
 */
const getFraudRiskBreakdown = async (req, res) => {
  try {
    const rows = await db.query(
      `SELECT fraud_risk_level as risk_level, COUNT(*) as count, COALESCE(AVG(fraud_risk_score), 0) as avg_score
       FROM claims
       GROUP BY fraud_risk_level`
    );

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('GetFraudRiskBreakdown Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve fraud risk breakdown.'
    });
  }
};

/**
 * Monthly trend analysis
 */
const getMonthlyTrends = async (req, res) => {
  try {
    // Generate monthly series from claims table
    const claims = await db.query(
      `SELECT created_at, current_status, claim_amount, payout_amount FROM claims ORDER BY created_at ASC`
    );

    // Group by Month (e.g. "Jun 2026", "Jul 2026", "Aug 2026", "Sep 2026")
    const monthMap = {};
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    for (const c of claims) {
      const d = new Date(c.created_at || Date.now());
      const key = `${monthNames[d.getMonth()]} ${d.getFullYear()}`;

      if (!monthMap[key]) {
        monthMap[key] = {
          month: key,
          submitted: 0,
          approved: 0,
          rejected: 0,
          totalAmount: 0,
          payoutAmount: 0
        };
      }

      monthMap[key].submitted += 1;
      monthMap[key].totalAmount += parseFloat(c.claim_amount) || 0;

      if (c.current_status === 'APPROVED') {
        monthMap[key].approved += 1;
        monthMap[key].payoutAmount += parseFloat(c.payout_amount) || 0;
      } else if (c.current_status === 'REJECTED') {
        monthMap[key].rejected += 1;
      }
    }

    const trends = Object.values(monthMap);

    return res.status(200).json({
      success: true,
      data: trends
    });
  } catch (error) {
    console.error('GetMonthlyTrends Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve monthly trends.'
    });
  }
};

/**
 * Detailed export dataset for CSV / Report downloads
 */
const getExportData = async (req, res) => {
  try {
    const claims = await db.query(
      `SELECT
        c.claim_id, u.name as customer_name, u.email as customer_email,
        p.policy_number, c.claim_type, c.incident_date, c.claim_amount,
        c.current_status, c.verification_status, c.fraud_risk_level,
        c.fraud_risk_score, c.payout_amount, c.decision_reason, c.created_at
       FROM claims c
       JOIN users u ON c.user_id = u.id
       JOIN policies p ON c.policy_id = p.id
       ORDER BY c.id DESC`
    );

    return res.status(200).json({
      success: true,
      data: claims
    });
  } catch (error) {
    console.error('GetExportData Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to prepare report export dataset.'
    });
  }
};

module.exports = {
  getSummaryMetrics,
  getStatusBreakdown,
  getTypeBreakdown,
  getFraudRiskBreakdown,
  getMonthlyTrends,
  getExportData
};
