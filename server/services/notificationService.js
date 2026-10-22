const db = require('../config/db');

/**
 * Send notification to a specific user
 */
const createNotification = async ({ userId, claimId = null, title, message, type = 'INFO' }) => {
  try {
    const result = await db.query(
      `INSERT INTO notifications (user_id, claim_id, title, message, type, is_read)
       VALUES (?, ?, ?, ?, ?, 0)`,
      [userId, claimId, title, message, type]
    );
    return result;
  } catch (err) {
    console.error('[NotificationService] Error creating notification:', err.message);
  }
};

/**
 * Send notification to all users with a specific role (e.g. 'FRAUD_INVESTIGATOR', 'INSURANCE_STAFF')
 */
const notifyRole = async ({ roleName, claimId = null, title, message, type = 'INFO' }) => {
  try {
    const users = await db.query(
      `SELECT u.id FROM users u
       JOIN roles r ON u.role_id = r.id
       WHERE r.name = ? AND u.status = 'ACTIVE'`,
      [roleName]
    );

    for (const user of users) {
      await createNotification({
        userId: user.id,
        claimId,
        title,
        message,
        type
      });
    }
  } catch (err) {
    console.error(`[NotificationService] Error notifying role ${roleName}:`, err.message);
  }
};

module.exports = {
  createNotification,
  notifyRole
};
