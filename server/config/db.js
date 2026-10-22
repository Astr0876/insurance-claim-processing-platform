const mysql = require('mysql2/promise');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

let dbDriver = null; // 'mysql' | 'sqlite'
let mysqlPool = null;
let sqliteDb = null;

const DB_TYPE = process.env.DB_TYPE || 'auto';
const DB_HOST = process.env.DB_HOST || 'localhost';
const DB_PORT = parseInt(process.env.DB_PORT || '3306', 10);
const DB_USER = process.env.DB_USER || 'root';
const DB_PASSWORD = process.env.DB_PASSWORD || 'root';
const DB_NAME = process.env.DB_NAME || 'insurance_claim_db';

const SQLITE_FILE = path.join(__dirname, '../../database/insurance.sqlite');

/**
 * Initialize SQLite database with complete schema and seed data
 */
async function initSqlite() {
  return new Promise((resolve, reject) => {
    const dbDir = path.dirname(SQLITE_FILE);
    if (!fs.existsSync(dbDir)) {
      fs.mkdirSync(dbDir, { recursive: true });
    }

    const db = new sqlite3.Database(SQLITE_FILE, (err) => {
      if (err) return reject(err);
    });

    db.serialize(() => {
      db.run('PRAGMA foreign_keys = OFF');

      // 1. Roles
      db.run(`CREATE TABLE IF NOT EXISTS roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        description TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);

      // 2. Users
      db.run(`CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        phone TEXT,
        role_id INTEGER NOT NULL,
        status TEXT DEFAULT 'ACTIVE',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);

      // 3. Policies
      db.run(`CREATE TABLE IF NOT EXISTS policies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        policy_number TEXT UNIQUE NOT NULL,
        user_id INTEGER NOT NULL,
        policy_type TEXT NOT NULL,
        coverage_amount REAL NOT NULL,
        deductible REAL DEFAULT 500.00,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        status TEXT DEFAULT 'ACTIVE',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);

      // 4. Claims
      db.run(`CREATE TABLE IF NOT EXISTS claims (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        claim_id TEXT UNIQUE NOT NULL,
        user_id INTEGER NOT NULL,
        policy_id INTEGER NOT NULL,
        claim_type TEXT NOT NULL,
        incident_date TEXT NOT NULL,
        incident_location TEXT,
        claim_amount REAL NOT NULL,
        description TEXT NOT NULL,
        current_status TEXT DEFAULT 'SUBMITTED',
        verification_status TEXT DEFAULT 'PENDING',
        fraud_risk_score INTEGER DEFAULT 0,
        fraud_risk_level TEXT DEFAULT 'LOW',
        assigned_staff_id INTEGER NULL,
        payout_amount REAL DEFAULT 0.00,
        decision_reason TEXT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);

      // 5. Claim Documents
      db.run(`CREATE TABLE IF NOT EXISTS claim_documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        claim_id INTEGER NOT NULL,
        document_type TEXT NOT NULL,
        file_name TEXT NOT NULL,
        original_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        mime_type TEXT NOT NULL,
        verification_status TEXT DEFAULT 'PENDING',
        verification_notes TEXT NULL,
        uploaded_by INTEGER NOT NULL,
        verified_by INTEGER NULL,
        uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        verified_at DATETIME NULL
      )`);

      // 6. Fraud Analysis
      db.run(`CREATE TABLE IF NOT EXISTS fraud_analysis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        claim_id INTEGER NOT NULL,
        risk_score INTEGER NOT NULL,
        risk_level TEXT NOT NULL,
        triggered_rules TEXT NOT NULL,
        analysis_details TEXT NULL,
        analyzed_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);

      // 7. Fraud Investigations
      db.run(`CREATE TABLE IF NOT EXISTS fraud_investigations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        claim_id INTEGER NOT NULL,
        investigator_id INTEGER NULL,
        status TEXT DEFAULT 'OPEN',
        findings TEXT NULL,
        recommended_action TEXT DEFAULT 'FURTHER_REVIEW',
        assigned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        completed_at DATETIME NULL
      )`);

      // 8. Claim Status History
      db.run(`CREATE TABLE IF NOT EXISTS claim_status_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        claim_id INTEGER NOT NULL,
        from_status TEXT NULL,
        to_status TEXT NOT NULL,
        changed_by_user_id INTEGER NOT NULL,
        notes TEXT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);

      // 9. Notifications
      db.run(`CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        claim_id INTEGER NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT DEFAULT 'INFO',
        is_read INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);

      // 10. Audit Logs
      db.run(`CREATE TABLE IF NOT EXISTS audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NULL,
        action TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NULL,
        ip_address TEXT DEFAULT '127.0.0.1',
        details TEXT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);

      // 11. System Settings
      db.run(`CREATE TABLE IF NOT EXISTS system_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key_name TEXT UNIQUE NOT NULL,
        value_data TEXT NOT NULL,
        description TEXT,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);

      // Check if data is already seeded
      db.get('SELECT COUNT(*) as count FROM users', (err, row) => {
        if (err || (row && row.count > 0)) {
          sqliteDb = db;
          return resolve(db);
        }

        const seedSql = `
          INSERT OR IGNORE INTO roles (id, name, description) VALUES
          (1, 'CUSTOMER', 'Policyholder who submits claims'),
          (2, 'INSURANCE_STAFF', 'Claims processing staff'),
          (3, 'FRAUD_INVESTIGATOR', 'Fraud investigation specialist'),
          (4, 'ADMIN', 'System administrator'),
          (5, 'MANAGER', 'Executive supervisor');

          INSERT OR IGNORE INTO users (id, name, email, password_hash, phone, role_id, status) VALUES
          (1, 'Sundar Pichai', 'customer@example.com', '$2a$10$1pyAv0JhTLtERVWyNg0JLutVRw903t16Y53ByPwcnbl6xJFTs1Q8e', '+1-555-0101', 1, 'ACTIVE'),
          (2, 'Elena Rostova', 'customer2@example.com', '$2a$10$1pyAv0JhTLtERVWyNg0JLutVRw903t16Y53ByPwcnbl6xJFTs1Q8e', '+1-555-0102', 1, 'ACTIVE'),
          (3, 'Sarah Jenkins', 'staff@example.com', '$2a$10$1pyAv0JhTLtERVWyNg0JLutVRw903t16Y53ByPwcnbl6xJFTs1Q8e', '+1-555-0201', 2, 'ACTIVE'),
          (4, 'David Miller', 'fraud@example.com', '$2a$10$1pyAv0JhTLtERVWyNg0JLutVRw903t16Y53ByPwcnbl6xJFTs1Q8e', '+1-555-0301', 3, 'ACTIVE'),
          (5, 'Alex Vance', 'admin@example.com', '$2a$10$1pyAv0JhTLtERVWyNg0JLutVRw903t16Y53ByPwcnbl6xJFTs1Q8e', '+1-555-0401', 4, 'ACTIVE'),
          (6, 'Steve Jobs', 'manager@example.com', '$2a$10$1pyAv0JhTLtERVWyNg0JLutVRw903t16Y53ByPwcnbl6xJFTs1Q8e', '+1-555-0501', 5, 'ACTIVE');

          INSERT OR IGNORE INTO policies (id, policy_number, user_id, policy_type, coverage_amount, deductible, start_date, end_date, status) VALUES
          (1, 'POL-2024-AUTO-101', 1, 'AUTO', 50000.00, 500.00, '2024-01-01', '2027-01-01', 'ACTIVE'),
          (2, 'POL-2024-HLTH-202', 1, 'HEALTH', 100000.00, 250.00, '2024-02-15', '2027-02-15', 'ACTIVE'),
          (3, 'POL-2024-HOME-303', 1, 'HOME', 350000.00, 1000.00, '2024-03-01', '2027-03-01', 'ACTIVE'),
          (4, 'POL-2024-AUTO-404', 2, 'AUTO', 30000.00, 500.00, '2025-06-01', '2027-06-01', 'ACTIVE'),
          (5, 'POL-2024-PROP-505', 2, 'PROPERTY', 150000.00, 1500.00, '2025-07-15', '2027-07-15', 'ACTIVE');

          INSERT OR IGNORE INTO claims (id, claim_id, user_id, policy_id, claim_type, incident_date, incident_location, claim_amount, description, current_status, verification_status, fraud_risk_score, fraud_risk_level, assigned_staff_id, payout_amount, decision_reason, created_at) VALUES
          (1, 'CLM-2026-1001', 1, 1, 'AUTO', '2026-08-10', 'Market Street & 4th, San Francisco, CA', 3450.00, 'Rear bumper collision at intersection with minor fender distortion while vehicle was stationary at red light.', 'APPROVED', 'VERIFIED', 12, 'LOW', 3, 3450.00, 'All invoices verified, police incident report validated, within coverage policy guidelines.', '2026-08-12 10:15:00'),
          (2, 'CLM-2026-1002', 1, 2, 'HEALTH', '2026-09-02', 'Stanford Health Center, CA', 8200.00, 'Emergency surgical appendectomy hospitalization and specialist inpatient consult fees.', 'UNDER_REVIEW', 'VERIFIED', 18, 'LOW', 3, 0.00, null, '2026-09-05 14:30:00'),
          (3, 'CLM-2026-1003', 2, 4, 'AUTO', '2026-09-15', 'Highway 101 Milemarker 44, CA', 28500.00, 'Vehicle suffered total loss when striking unattended barrier late at night with no witnesses present.', 'INVESTIGATION_REQUIRED', 'PENDING', 82, 'HIGH', null, 0.00, null, '2026-09-16 09:00:00'),
          (4, 'CLM-2026-1004', 2, 5, 'PROPERTY', '2026-09-20', '742 Evergreen Terrace, Springfield', 48000.00, 'Extensive water damage and structural flooring breakdown due to sudden high-pressure pipe rupture.', 'INVESTIGATION_IN_PROGRESS', 'PENDING', 74, 'HIGH', 3, 0.00, null, '2026-09-22 11:20:00'),
          (5, 'CLM-2026-1005', 1, 3, 'HOME', '2026-09-28', '124 Conch Street, Pacifica, CA', 1850.00, 'Hail storm impact damage resulting in fractured roof tiles and dented rainwater drainage gutters.', 'SUBMITTED', 'PENDING', 22, 'LOW', null, 0.00, null, '2026-09-29 08:45:00'),
          (6, 'CLM-2026-1006', 2, 4, 'AUTO', '2026-07-04', 'Industrial Parkway, Oakland, CA', 15200.00, 'Multiple body panel scratches and electronic mirror detachment in quiet parking lot.', 'REJECTED', 'REJECTED', 88, 'HIGH', 3, 0.00, 'Fabricated repair estimate detected; vendor invoice numbers could not be authenticated during field audit.', '2026-07-06 16:10:00');

          INSERT OR IGNORE INTO claim_documents (id, claim_id, document_type, file_name, original_name, file_path, file_size, mime_type, verification_status, verification_notes, uploaded_by, verified_by, uploaded_at, verified_at) VALUES
          (1, 1, 'Police Report', 'police_report_1001.pdf', 'SFPD_Collision_Report_2026.pdf', 'uploads/police_report_1001.pdf', 342100, 'application/pdf', 'VERIFIED', 'Valid SFPD seal and badge verification confirmed.', 1, 3, '2026-08-12 10:20:00', '2026-08-13 11:00:00'),
          (2, 1, 'Repair Estimate', 'repair_invoice_1001.pdf', 'Apex_BodyShop_Repair_Estimate.pdf', 'uploads/repair_invoice_1001.pdf', 184500, 'application/pdf', 'VERIFIED', 'Labor rates match regional standard schedule.', 1, 3, '2026-08-12 10:22:00', '2026-08-13 11:05:00'),
          (3, 2, 'Medical Discharge Summary', 'discharge_summary_1002.pdf', 'Hospital_Discharge_Summary.pdf', 'uploads/discharge_summary_1002.pdf', 512000, 'application/pdf', 'VERIFIED', 'Authentic physician signature and hospital code.', 1, 3, '2026-09-05 14:35:00', '2026-09-06 09:30:00'),
          (4, 2, 'Pharmacy & Treatment Bill', 'medical_bills_1002.pdf', 'Pharmacy_Itemized_Invoice.pdf', 'uploads/medical_bills_1002.pdf', 248000, 'application/pdf', 'VERIFIED', 'Prescription details verified against hospital order.', 1, 3, '2026-09-05 14:38:00', '2026-09-06 09:35:00'),
          (5, 3, 'Towing Invoice', 'towing_bill_1003.pdf', 'Highway_Towing_Receipt.pdf', 'uploads/towing_bill_1003.pdf', 98000, 'application/pdf', 'PENDING', null, 2, null, '2026-09-16 09:10:00', null),
          (6, 4, 'Plumber Inspection Report', 'plumbing_report_1004.pdf', 'Emergency_Plumbing_Log.pdf', 'uploads/plumbing_report_1004.pdf', 156000, 'application/pdf', 'PENDING', null, 2, null, '2026-09-22 11:25:00', null),
          (7, 6, 'Vendor Estimate', 'forged_estimate_1006.pdf', 'Custom_Autobody_Estimate.pdf', 'uploads/forged_estimate_1006.pdf', 84000, 'application/pdf', 'REJECTED', 'Tax identification number belongs to an inactive business entity.', 2, 3, '2026-07-06 16:15:00', '2026-07-08 14:20:00');

          INSERT OR IGNORE INTO fraud_analysis (id, claim_id, risk_score, risk_level, triggered_rules, analysis_details, analyzed_at) VALUES
          (1, 1, 12, 'LOW', '[{"ruleId":"BASE_SCAN","description":"Standard underwriting profile","weight":12}]', '{"coverageRatio":0.069}', '2026-08-12 10:16:00'),
          (2, 2, 18, 'LOW', '[{"ruleId":"MEDICAL_EXPENSE_AUDIT","description":"Hospital procedural coding confirmed","weight":18}]', '{"coverageRatio":0.082}', '2026-09-05 14:31:00'),
          (3, 3, 82, 'HIGH', '[{"ruleId":"RULE_COVERAGE_EXHAUSTION","category":"Financial","severity":"HIGH","description":"Claim amount is 95% of policy coverage limit ($28,500 / $30,000)","weight":25},{"ruleId":"RULE_HIGH_VALUE_THRESHOLD","category":"Financial","severity":"MEDIUM","description":"High loss claimed in single motor incident","weight":15},{"ruleId":"RULE_SUSPICIOUS_VOCABULARY","category":"Pattern","severity":"MEDIUM","description":"Description contains high-scrutiny keyword indicators: unattended","weight":12},{"ruleId":"RULE_MULTIPLE_RECENT_CLAIMS","category":"Frequency","severity":"HIGH","description":"Customer submitted 2 other claims within the last 6 months","weight":20},{"ruleId":"RULE_PRIOR_SUSPICIOUS_HISTORY","category":"Frequency","severity":"HIGH","description":"Policyholder has prior claims that were rejected or flagged as high risk","weight":25}]', '{"flaggedTerms":["unattended","total loss"],"coverageRatio":0.95}', '2026-09-16 09:02:00'),
          (4, 4, 74, 'HIGH', '[{"ruleId":"RULE_HIGH_VALUE_THRESHOLD","category":"Financial","severity":"MEDIUM","description":"Claim amount ($48,000) exceeds high-risk property review threshold","weight":15},{"ruleId":"RULE_MULTIPLE_RECENT_CLAIMS","category":"Frequency","severity":"HIGH","description":"Repeat claim activity within short window","weight":20},{"ruleId":"RULE_PRIOR_SUSPICIOUS_HISTORY","category":"Frequency","severity":"HIGH","description":"Policyholder account has prior rejected claim records","weight":25}]', '{"coverageRatio":0.32}', '2026-09-22 11:21:00'),
          (5, 5, 22, 'LOW', '[{"ruleId":"WEATHER_CORRELATION","description":"Incident aligns with localized meteorological hail storm advisories","weight":22}]', '{"coverageRatio":0.005}', '2026-09-29 08:46:00'),
          (6, 6, 88, 'HIGH', '[{"ruleId":"RULE_COVERAGE_EXHAUSTION","description":"Claim volume spikes right after policy inception","weight":25},{"ruleId":"RULE_SUSPICIOUS_VOCABULARY","description":"Ambiguous vandalism report without third party details","weight":12}]', '{"coverageRatio":0.506}', '2026-07-06 16:11:00');

          INSERT OR IGNORE INTO fraud_investigations (id, claim_id, investigator_id, status, findings, recommended_action, assigned_at, completed_at) VALUES
          (1, 3, 4, 'OPEN', 'Preliminary check indicates collision occurred in unlit industrial corridor. Telematics data requested from vehicle computer.', 'FURTHER_REVIEW', '2026-09-16 10:00:00', null),
          (2, 4, 4, 'UNDER_INVESTIGATION', 'Physical site inspection scheduled with forensic plumbing consultant. Previous water damage claims noted with prior carrier.', 'FURTHER_REVIEW', '2026-09-22 14:00:00', null),
          (3, 6, 4, 'CONFIRMED_FRAUD', 'Investigator verified autobody shop does not exist at listed premises. Forged invoice stamps and duplicate photos from internet vehicle forum.', 'DENY_CLAIM', '2026-07-06 17:00:00', '2026-07-08 14:00:00');

          INSERT OR IGNORE INTO claim_status_history (id, claim_id, from_status, to_status, changed_by_user_id, notes, created_at) VALUES
          (1, 1, null, 'SUBMITTED', 1, 'Claim submitted online by customer with initial repair bills.', '2026-08-12 10:15:00'),
          (2, 1, 'SUBMITTED', 'UNDER_REVIEW', 3, 'Claim picked up by Claim Processor Sarah Jenkins.', '2026-08-13 09:30:00'),
          (3, 1, 'UNDER_REVIEW', 'DOCS_VERIFIED', 3, 'Supporting documents verified against police department records.', '2026-08-13 11:06:00'),
          (4, 1, 'DOCS_VERIFIED', 'APPROVED', 3, 'Claim approved for full reimbursement of $3,450.00.', '2026-08-14 15:00:00'),
          (5, 2, null, 'SUBMITTED', 1, 'Emergency medical claim submitted online.', '2026-09-05 14:30:00'),
          (6, 2, 'SUBMITTED', 'UNDER_REVIEW', 3, 'Medical invoices sent for standard benefits adjudication.', '2026-09-06 09:36:00'),
          (7, 3, null, 'SUBMITTED', 2, 'Total loss motor collision claim submitted.', '2026-09-16 09:00:00'),
          (8, 3, 'SUBMITTED', 'INVESTIGATION_REQUIRED', 3, 'Automated fraud risk engine flagged score of 82/100. Forwarded to SIU Fraud Unit.', '2026-09-16 09:05:00'),
          (9, 4, null, 'SUBMITTED', 2, 'Property water loss claim submitted.', '2026-09-22 11:20:00'),
          (10, 4, 'SUBMITTED', 'INVESTIGATION_IN_PROGRESS', 4, 'Investigator David Miller opened active case inquiry.', '2026-09-22 14:05:00'),
          (11, 5, null, 'SUBMITTED', 1, 'Hail damage claim lodged with roofing photos.', '2026-09-29 08:45:00'),
          (12, 6, null, 'SUBMITTED', 2, 'Parking lot scratch claim submitted.', '2026-07-06 16:10:00'),
          (13, 6, 'SUBMITTED', 'INVESTIGATION_REQUIRED', 3, 'High fraud index flagged.', '2026-07-06 16:12:00'),
          (14, 6, 'INVESTIGATION_REQUIRED', 'REJECTED', 3, 'Claim formally rejected due to fabricated documentation.', '2026-07-08 14:25:00');

          INSERT OR IGNORE INTO notifications (id, user_id, claim_id, title, message, type, is_read, created_at) VALUES
          (1, 1, 1, 'Claim Approved', 'Your claim CLM-2026-1001 has been approved for payout of $3,450.00.', 'SUCCESS', 1, '2026-08-14 15:01:00'),
          (2, 1, 2, 'Documents Verified', 'All hospital records for claim CLM-2026-1002 have been verified.', 'INFO', 0, '2026-09-06 09:37:00'),
          (3, 1, 5, 'Claim Received', 'Your claim CLM-2026-1005 has been registered and is pending document review.', 'INFO', 0, '2026-09-29 08:46:00'),
          (4, 2, 3, 'Claim Under Special Review', 'Your claim CLM-2026-1003 is undergoing routine verification checks.', 'WARNING', 0, '2026-09-16 09:06:00'),
          (5, 4, 3, 'High Risk Alert', 'Claim CLM-2026-1003 flagged with Fraud Risk Score of 82%. Assigned to your queue.', 'ALERT', 0, '2026-09-16 09:05:00'),
          (6, 4, 4, 'Fraud Investigation Required', 'Claim CLM-2026-1004 flagged with Risk Score 74%. Pending SIU investigation.', 'ALERT', 0, '2026-09-22 11:22:00');

          INSERT OR IGNORE INTO audit_logs (id, user_id, action, entity_type, entity_id, ip_address, details, created_at) VALUES
          (1, 1, 'LOGIN_SUCCESS', 'USER', '1', '192.168.1.101', '{"email":"customer@example.com"}', '2026-08-12 10:00:00'),
          (2, 1, 'CLAIM_SUBMITTED', 'CLAIM', 'CLM-2026-1001', '192.168.1.101', '{"amount":3450.00,"policy":"POL-2024-AUTO-101"}', '2026-08-12 10:15:00'),
          (3, 3, 'DOCUMENT_VERIFIED', 'DOCUMENT', '1', '192.168.1.205', '{"status":"VERIFIED","document":"Police Report"}', '2026-08-13 11:00:00'),
          (4, 3, 'CLAIM_APPROVED', 'CLAIM', 'CLM-2026-1001', '192.168.1.205', '{"payout":3450.00,"reason":"Approved after full review"}', '2026-08-14 15:00:00'),
          (5, 2, 'CLAIM_SUBMITTED', 'CLAIM', 'CLM-2026-1003', '192.168.1.115', '{"amount":28500.00,"policy":"POL-2024-AUTO-404"}', '2026-09-16 09:00:00'),
          (6, 4, 'INVESTIGATION_OPENED', 'INVESTIGATION', '1', '192.168.1.220', '{"claimId":"CLM-2026-1003","initialRisk":82}', '2026-09-16 10:00:00');

          INSERT OR IGNORE INTO system_settings (key_name, value_data, description) VALUES
          ('fraud_high_risk_threshold', '65', 'Score threshold above which claims are automatically routed to Fraud Investigation Unit'),
          ('fraud_medium_risk_threshold', '35', 'Score threshold for supervisor review notification'),
          ('auto_flagging_enabled', 'true', 'Whether claims exceeding threshold automatically lock staff approval until investigator clearance'),
          ('max_file_size_mb', '10', 'Maximum allowed attachment size in Megabytes'),
          ('allowed_mime_types', 'application/pdf,image/jpeg,image/png,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'Allowed upload file MIME types');
        `;

        db.exec(seedSql, (seedErr) => {
          if (seedErr) {
            console.error('[Database] SQLite seed error:', seedErr);
            return reject(seedErr);
          }
          sqliteDb = db;
          resolve(db);
        });
      });
    });
  });
}

/**
 * Initialize connection to database (MySQL if available, otherwise SQLite fallback)
 */
async function connectDb() {
  if (dbDriver) return dbDriver;

  if (DB_TYPE === 'mysql' || DB_TYPE === 'auto') {
    try {
      console.log(`[Database] Attempting connection to MySQL at ${DB_HOST}:${DB_PORT}/${DB_NAME}...`);
      const pool = mysql.createPool({
        host: DB_HOST,
        port: DB_PORT,
        user: DB_USER,
        password: DB_PASSWORD,
        database: DB_NAME,
        waitForConnections: true,
        connectionLimit: 10,
        queueLimit: 0,
        enableKeepAlive: true,
        keepAliveInitialDelay: 0
      });

      // Quick test query
      const conn = await pool.getConnection();
      await conn.query('SELECT 1');
      conn.release();

      mysqlPool = pool;
      dbDriver = 'mysql';
      console.log('[Database] Successfully connected to MySQL database.');
      return 'mysql';
    } catch (err) {
      if (DB_TYPE === 'mysql') {
        console.error('[Database] Failed to connect to required MySQL instance:', err.message);
        throw err;
      }
      console.warn(`[Database] MySQL not reachable (${err.message}). Activating built-in SQLite database engine...`);
    }
  }

  // SQLite fallback
  await initSqlite();
  dbDriver = 'sqlite';
  console.log('[Database] SQLite database initialized and ready with full schema & demo data.');
  return 'sqlite';
}

/**
 * Universal Query Executor
 * Works seamlessly across MySQL and SQLite with identical parameter signature
 * @param {string} sql - SQL query string with ? placeholders
 * @param {Array} params - Query parameters
 * @returns {Promise<Array|Object>} Rows array for SELECT, or { insertId, affectedRows } for mutations
 */
async function query(sql, params = []) {
  if (!dbDriver) {
    await connectDb();
  }

  if (dbDriver === 'mysql') {
    const [result] = await mysqlPool.query(sql, params);
    if (Array.isArray(result)) {
      return result;
    }
    return {
      insertId: result.insertId,
      affectedRows: result.affectedRows
    };
  }

  return new Promise((resolve, reject) => {
    const trimmed = sql.trim().toUpperCase();
    const isSelect = trimmed.startsWith('SELECT') || trimmed.startsWith('PRAGMA');

    if (isSelect) {
      sqliteDb.all(sql, params, (err, rows) => {
        if (err) return reject(err);
        resolve(rows || []);
      });
    } else {
      sqliteDb.run(sql, params, function (err) {
        if (err) return reject(err);
        resolve({
          insertId: this.lastID,
          affectedRows: this.changes
        });
      });
    }
  });
}

/**
 * Helper to fetch a single row
 */
async function getOne(sql, params = []) {
  const rows = await query(sql, params);
  if (Array.isArray(rows)) {
    return rows.length > 0 ? rows[0] : null;
  }
  return rows;
}

module.exports = {
  connectDb,
  query,
  getOne,
  getDriver: () => dbDriver
};
