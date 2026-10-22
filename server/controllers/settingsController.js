const db = require('../config/db');
const { logAudit } = require('../middleware/auditLogger');

/**
 * Get all system settings
 * Roles: ADMIN, MANAGER
 */
const getSettings = async (req, res) => {
  try {
    const settings = await db.query('SELECT * FROM system_settings ORDER BY id ASC');
    return res.status(200).json({
      success: true,
      settings
    });
  } catch (error) {
    console.error('GetSettings Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve system settings.'
    });
  }
};

/**
 * Update system setting
 * Roles: ADMIN
 */
const updateSetting = async (req, res) => {
  try {
    const { key, value } = req.body;

    if (!key || value === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Setting key and value are required.'
      });
    }

    const existing = await db.getOne('SELECT * FROM system_settings WHERE key_name = ?', [key]);
    if (!existing) {
      return res.status(404).json({
        success: false,
        message: `Setting "${key}" not found.`
      });
    }

    await db.query(
      'UPDATE system_settings SET value_data = ?, updated_at = CURRENT_TIMESTAMP WHERE key_name = ?',
      [String(value), key]
    );

    await logAudit({
      userId: req.user.id,
      action: 'SYSTEM_SETTING_CHANGED',
      entityType: 'SETTING',
      entityId: key,
      req,
      details: { key, oldValue: existing.value_data, newValue: value }
    });

    return res.status(200).json({
      success: true,
      message: `Setting "${key}" updated successfully.`,
      setting: { key, value }
    });
  } catch (error) {
    console.error('UpdateSetting Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update system setting.'
    });
  }
};

module.exports = {
  getSettings,
  updateSetting
};
