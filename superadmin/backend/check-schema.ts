import { pool } from './src/db.ts';

async function checkSchema() {
  try {
    const connection = await pool.getConnection();
    
    // Check users table
    console.log('\n=== USERS TABLE ===');
    const [usersColumns] = await connection.query('DESCRIBE users');
    console.table(usersColumns);

    // Check verifikasi_ktp_customers
    console.log('\n=== VERIFIKASI_KTP_CUSTOMERS TABLE ===');
    try {
      const [custColumns] = await connection.query('DESCRIBE verifikasi_ktp_customers');
      console.table(custColumns);
    } catch (e) {
      console.log('Table verifikasi_ktp_customers does not exist');
    }

    // Check verifikasi_ktp_mitras
    console.log('\n=== VERIFIKASI_KTP_MITRAS TABLE ===');
    try {
      const [mitraColumns] = await connection.query('DESCRIBE verifikasi_ktp_mitras');
      console.table(mitraColumns);
    } catch (e) {
      console.log('Table verifikasi_ktp_mitras does not exist');
    }

    // Check available booking tables
    console.log('\n=== AVAILABLE TABLES ===');
    const [tables] = await connection.query(
      'SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = "nebeng-bro"'
    );
    console.table(tables);

    connection.release();
  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
}

checkSchema();
