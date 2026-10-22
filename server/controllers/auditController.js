const db = require('../config/db');

/**
 * Get system audit trail logs
 * Roles: ADMIN, MANAGER
 */
const getAuditLogs = async (req, res) => {
  try {
    const { action, entityType, search, limit = 50, offset = 0 } = req.query;

    let conditions = [];
    let params = [];

    if (action) {
      conditions.push('a.action LIKE ?');
      params.push(`%${action}%`);
    }

    if (entityType) {
      conditions.push('a.entity_type = ?');
      params.push(entityType);
    }

    if (search) {
      conditions.push('(a.action LIKE ? OR a.entity_id LIKE ? OR u.name LIKE ? OR a.ip_address LIKE ?)');
      params.push(`%${search}%`, `%${search}%`, `%${search}%`, `%${search}%`);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const sql = `
      SELECT
        a.id, a.user_id, a.action, a.entity_type, a.entity_id,
        a.ip_address, a.details, a.created_at,
        u.name as user_name, u.email as user_email, r.name as user_role
      FROM audit_logs a
      LEFT JOIN users u ON a.user_id = u.id
      LEFT JOIN roles r ON u.role_id = r.id
      ${whereClause}
      ORDER BY a.id DESC
      LIMIT ? OFFSET ?
    `;

    params.push(parseInt(limit), parseInt(offset));

    const logs = await db.query(sql, params);

    const totalCountRow = await db.getOne(
      `SELECT COUNT(*) as total FROM audit_logs a LEFT JOIN users u ON a.user_id = u.id ${whereClause}`,
      params.slice(0, -2)
    );

    const parsedLogs = logs.map(l => {
      let parsedDetails = l.details;
      try {
        if (typeof l.details === 'string') {
          parsedDetails = JSON.parse(l.details);
        }
      } catch (e) {
        parsedDetails = l.details;
      }
      return { ...l, details: parsedDetails };
    });

    return res.status(200).json({
      success: true,
      total: totalCountRow ? parseInt(totalCountRow.total) : 0,
      logs: parsedLogs
    });
  } catch (error) {
    console.error('GetAuditLogs Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve audit logs.'
    });
  }
};

module.exports = {
  getAuditLogs
};
