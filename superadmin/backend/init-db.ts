import mysql from 'mysql2/promise';
import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';

dotenv.config();

const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  port: parseInt(process.env.DB_PORT || '3306'),
};

const dbName = process.env.DB_NAME || 'nebeng-bro';

async function initializeDatabase() {
  let connection;
  
  try {
    // Connect without specifying database
    console.log('📦 Connecting to MySQL server...');
    connection = await mysql.createConnection(dbConfig);
    console.log('✅ Connected to MySQL server');

    // Read schema file
    const schemaPath = path.join(__dirname, 'database', 'schema.sql');
    console.log(`📄 Reading schema from: ${schemaPath}`);
    
    if (!fs.existsSync(schemaPath)) {
      throw new Error(`Schema file not found at ${schemaPath}`);
    }

    const schema = fs.readFileSync(schemaPath, 'utf-8');
    
    // Split and execute SQL statements
    const statements = schema
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));

    console.log(`\n🚀 Executing ${statements.length} SQL statements...\n`);

    for (let i = 0; i < statements.length; i++) {
      try {
        await connection.query(statements[i]);
        const action = statements[i].substring(0, 50).toUpperCase();
        console.log(`✅ [${i + 1}/${statements.length}] ${action}...`);
      } catch (error: any) {
        if (error.code === 'ER_DB_CREATE_EXISTS' || error.code === 'ER_TABLE_EXISTS_ERROR') {
          const action = statements[i].substring(0, 50).toUpperCase();
          console.log(`⚠️  [${i + 1}/${statements.length}] ${action}... (Already exists)`);
        } else {
          throw error;
        }
      }
    }

    console.log('\n✅ Database initialization completed successfully!');
    console.log(`📊 Database: ${dbName}`);
    console.log('📋 Tables created:');
    console.log('   - users');
    console.log('   - admin');
    console.log('   - kendaraan_mitra');
    console.log('   - verifikasi_ktp_mitras');
    console.log('   - verifikasi_ktp_customers');
    console.log('   - pesanan');
    console.log('   - laporan');
    console.log('   - refund');
    
  } catch (error) {
    console.error('❌ Error initializing database:', error);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
      console.log('\n🔌 Database connection closed');
    }
  }
}

// Run initialization
initializeDatabase();
