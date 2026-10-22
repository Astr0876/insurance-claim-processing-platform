const db = require('../config/db');

/**
 * Log an audit action to audit_logs table
 */
const logAudit = async ({ userId = null, action, entityType, entityId = null, req = null, details = null }) => {
  try {
    let ipAddress = '127.0.0.1';
    if (req) {
      ipAddress = req.headers?.['x-forwarded-for'] || req.socket?.remoteAddress || req.ip || '127.0.0.1';
      if (!userId && req.user) {
        userId = req.user.id;
      }
    }

    const detailsStr = typeof details === 'object' && details !== null
      ? JSON.stringify(details)
      : details;

    await db.query(
      `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, ip_address, details)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [userId, action, entityType, entityId ? String(entityId) : null, ipAddress, detailsStr]
    );
  } catch (err) {
    console.error('[AuditLog] Error writing audit log:', err.message);
  }
};

module.exports = {
  logAudit
};
