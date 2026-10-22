const db = require('../config/db');

async function main() {
  const tableArg = process.argv[2] ? process.argv[2].toLowerCase() : null;

  try {
    const driver = await db.connectDb();
    console.log(`\n======================================================`);
    console.log(`📊 LIVE DATABASE INSPECTOR (Active Engine: ${driver.toUpperCase()})`);
    console.log(`======================================================\n`);

    const validTables = [
      'claims',
      'claim_documents',
      'fraud_analysis',
      'fraud_investigations',
      'claim_status_history',
      'users',
      'policies',
      'roles',
      'audit_logs',
      'notifications',
      'system_settings'
    ];

    if (!tableArg || tableArg === 'summary' || tableArg === 'all') {
      console.log('📋 SUMMARY OF ALL TABLES & RECORD COUNTS:\n');
      const counts = [];
      for (const t of validTables) {
        try {
          const row = await db.getOne(`SELECT COUNT(*) as count FROM ${t}`);
          counts.push({ 'Table Name': t, 'Total Records': row ? row.count : 0 });
        } catch (e) {
          counts.push({ 'Table Name': t, 'Total Records': 'Error / Not Found' });
        }
      }
      console.table(counts);

      console.log('\n💡 VIVA DEMONSTRATION TIP:');
      console.log('   Run: node scripts/viewDb.js claims           -> to inspect all claims');
      console.log('   Run: node scripts/viewDb.js documents        -> to inspect uploaded file records');
      console.log('   Run: node scripts/viewDb.js fraud            -> to view fraud analysis & scores');
      console.log('   Run: node scripts/viewDb.js audit            -> to view latest audit trail entries');
      console.log('   Run: node scripts/viewDb.js history          -> to view claim status transitions\n');
      process.exit(0);
    }

    let queryTable = tableArg;
    if (tableArg === 'documents' || tableArg === 'docs') queryTable = 'claim_documents';
    if (tableArg === 'fraud') queryTable = 'fraud_analysis';
    if (tableArg === 'investigations' || tableArg === 'siu') queryTable = 'fraud_investigations';
    if (tableArg === 'history' || tableArg === 'timeline') queryTable = 'claim_status_history';
    if (tableArg === 'audit' || tableArg === 'logs') queryTable = 'audit_logs';
    if (tableArg === 'settings') queryTable = 'system_settings';

    if (!validTables.includes(queryTable)) {
      console.log(`❌ Table "${tableArg}" not recognized.`);
      console.log(`Available tables: ${validTables.join(', ')}\n`);
      process.exit(1);
    }

    console.log(`🔍 Inspecting Table: [${queryTable}] (Latest entries first):\n`);

    let rows = [];
    if (queryTable === 'claims') {
      rows = await db.query(`
        SELECT id, claim_id, claim_type, claim_amount, current_status, fraud_risk_score, fraud_risk_level, created_at 
        FROM claims 
        ORDER BY id DESC 
        LIMIT 10
      `);
    } else if (queryTable === 'claim_documents') {
      rows = await db.query(`
        SELECT id, claim_id, document_type, file_name, file_size, verification_status, uploaded_at 
        FROM claim_documents 
        ORDER BY id DESC 
        LIMIT 10
      `);
    } else if (queryTable === 'fraud_analysis') {
      rows = await db.query(`
        SELECT id, claim_id, risk_score, risk_level, SUBSTR(triggered_rules, 1, 60) as rules_snippet, analyzed_at 
        FROM fraud_analysis 
        ORDER BY id DESC 
        LIMIT 10
      `);
    } else if (queryTable === 'fraud_investigations') {
      rows = await db.query(`
        SELECT id, claim_id, investigator_id, status, recommended_action, SUBSTR(findings, 1, 40) as notes 
        FROM fraud_investigations 
        ORDER BY id DESC 
        LIMIT 10
      `);
    } else if (queryTable === 'claim_status_history') {
      rows = await db.query(`
        SELECT id, claim_id, from_status, to_status, changed_by_user_id, notes, created_at 
        FROM claim_status_history 
        ORDER BY id DESC 
        LIMIT 10
      `);
    } else if (queryTable === 'audit_logs') {
      rows = await db.query(`
        SELECT id, user_id, action, entity_type, entity_id, ip_address, created_at 
        FROM audit_logs 
        ORDER BY id DESC 
        LIMIT 10
      `);
    } else {
      rows = await db.query(`SELECT * FROM ${queryTable} LIMIT 10`);
    }

    if (rows.length === 0) {
      console.log(`(No records found in table "${queryTable}")\n`);
    } else {
      console.table(rows);
    }

    console.log(`\n✅ Total displayed: ${rows.length} rows.`);
    process.exit(0);
  } catch (err) {
    console.error('Error querying database:', err);
    process.exit(1);
  }
}

main();
