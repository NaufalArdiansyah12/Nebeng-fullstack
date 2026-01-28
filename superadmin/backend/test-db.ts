import { pool } from './src/db';

async function testDatabaseConnection(): Promise<void> {
  let connection: any;

  try {
    console.log('🔍 Testing database connection...\n');

    connection = await pool.getConnection();
    console.log('✅ Connected to database successfully!');

    // =========================
    // MySQL Version
    // =========================
    const [versionRows] = await connection.query(
      'SELECT VERSION() AS version'
    );

    const version = (versionRows as any[])[0].version;
    console.log(`📊 MySQL Version: ${version}`);

    // =========================
    // List Tables
    // =========================
    const [tables] = await connection.query(`
      SELECT TABLE_NAME
      FROM INFORMATION_SCHEMA.TABLES
      WHERE TABLE_SCHEMA = DATABASE()
      ORDER BY TABLE_NAME
    `);

    const tableList = tables as { TABLE_NAME: string }[];

    const dbName = process.env.DB_NAME ?? 'nebeng-bro';
    console.log(`\n📋 Tables in database "${dbName}":`);

    tableList.forEach((table, index) => {
      console.log(`   ${index + 1}. ${table.TABLE_NAME}`);
    });

    // =========================
    // Row Count Per Table
    // =========================
    console.log('\n📊 Data Summary:');

    for (const { TABLE_NAME } of tableList) {
      const [countResult] = await connection.query(
        `SELECT COUNT(*) AS count FROM \`${TABLE_NAME}\``
      );

      const count = (countResult as any[])[0].count;
      console.log(`   ${TABLE_NAME}: ${count} rows`);
    }

    console.log('\n✅ All tests passed! Database is ready to use.');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Database connection failed:\n', error);
    process.exit(1);
  } finally {
    if (connection) {
      connection.release();
    }
  }
}

testDatabaseConnection();
