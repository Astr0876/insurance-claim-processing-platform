const db = require('../config/db');

/**
 * Get notifications for current user
 */
const getNotifications = async (req, res) => {
  try {
    const notifications = await db.query(
      `SELECT n.*, c.claim_id as claim_code
       FROM notifications n
       LEFT JOIN claims c ON n.claim_id = c.id
       WHERE n.user_id = ?
       ORDER BY n.id DESC
       LIMIT 50`,
      [req.user.id]
    );

    const unreadCount = await db.getOne(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0',
      [req.user.id]
    );

    return res.status(200).json({
      success: true,
      unreadCount: unreadCount ? parseInt(unreadCount.count) : 0,
      notifications
    });
  } catch (error) {
    console.error('GetNotifications Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve notifications.'
    });
  }
};

/**
 * Mark a single notification as read
 */
const markAsRead = async (req, res) => {
  try {
    const notifId = req.params.id;

    await db.query(
      'UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?',
      [notifId, req.user.id]
    );

    return res.status(200).json({
      success: true,
      message: 'Notification marked as read.'
    });
  } catch (error) {
    console.error('MarkAsRead Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update notification.'
    });
  }
};

/**
 * Mark all notifications as read
 */
const markAllAsRead = async (req, res) => {
  try {
    await db.query(
      'UPDATE notifications SET is_read = 1 WHERE user_id = ?',
      [req.user.id]
    );

    return res.status(200).json({
      success: true,
      message: 'All notifications marked as read.'
    });
  } catch (error) {
    console.error('MarkAllAsRead Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to mark notifications.'
    });
  }
};

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead
};
