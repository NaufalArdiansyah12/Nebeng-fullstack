import { pool } from './src/db.ts';

async function checkAllTables() {
  try {
    const connection = await pool.getConnection();
    
    // Get all tables
    const [tables] = await connection.query(
      'SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = "nebeng-bro"'
    );
    
    console.log('=== TABLES IN nebeng-bro ===');
    console.table(tables);
    
    if (Array.isArray(tables) && tables.length > 0) {
      for (const table of tables) {
        console.log(`\n=== ${table.TABLE_NAME} STRUCTURE ===`);
        const [columns] = await connection.query(`DESCRIBE ${table.TABLE_NAME}`);
        console.table(columns);
      }
    } else {
      console.log('\n❌ Database "nebeng-bro" exists but has no tables!');
      console.log('📝 You need to import the schema.sql file first.');
      console.log('\nTo set up the database:');
      console.log('1. Open MySQL CLI or PhpMyAdmin');
      console.log('2. Run: SOURCE backend/database/schema.sql;');
    }
    
    connection.release();
  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
}

checkAllTables();
