import mysql from 'mysql2/promise';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';

dotenv.config();

const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'nebeng-bro',
};

async function seedAdminUser() {
  let connection;
  
  try {
    console.log('🔍 Connecting to database...');
    connection = await mysql.createConnection(dbConfig);
    console.log('✅ Connected to database\n');

    // Check if users table exists
    const [tables] = await connection.query(`
      SELECT TABLE_NAME
      FROM INFORMATION_SCHEMA.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users'
    `);
    
    const tableList = tables as { TABLE_NAME: string }[];
    if (tableList.length === 0) {
      console.log('❌ Users table does not exist!');
      console.log('Please run the database initialization first.');
      process.exit(1);
    }
    
    console.log('✅ Users table exists\n');

    // Check if admin user already exists
    const [existingUsers] = await connection.query(
      'SELECT id, email, name, role FROM users WHERE email = ?',
      ['Abdul000@gmail.com']
    );
    
    const existingList = existingUsers as any[];
    
    if (existingList.length > 0) {
      console.log('⚠️  Admin user already exists:');
      console.log('   ID:', existingList[0].id);
      console.log('   Email:', existingList[0].email);
      console.log('   Name:', existingList[0].name);
      console.log('   Role:', existingList[0].role);
      console.log('');
      
      // Update the role to superadmin if needed
      if (existingList[0].role !== 'superadmin') {
        console.log('🔄 Updating role to superadmin...');
        await connection.execute(
          'UPDATE users SET role = ? WHERE email = ?',
          ['superadmin', 'Abdul000@gmail.com']
        );
        console.log('✅ Role updated to superadmin\n');
      }
    } else {
      console.log('📝 Creating admin user...\n');
      
      // Hash the password
      const password = 'Abdul123'; // Default password
      const hashedPassword = await bcrypt.hash(password, 10);
      
      console.log('Password:', password);
      console.log('Hashed:', hashedPassword);
      console.log('');
      
      // Insert the admin user
      await connection.execute(
        `INSERT INTO users (name, email, password, role, created_at, updated_at) 
         VALUES (?, ?, ?, ?, NOW(), NOW())`,
        ['Muhammad Abdul Kadir', 'Abdul000@gmail.com', hashedPassword, 'superadmin']
      );
      
      console.log('✅ Admin user created successfully!\n');
    }

    // Show all users
    const [allUsers] = await connection.query(
      'SELECT id, name, email, role FROM users'
    );
    
    console.log('📊 All users in database:');
    console.table(allUsers);

    console.log('\n✅ Seed completed successfully!');
    console.log('\n📝 Login credentials:');
    console.log('   Email: Abdul000@gmail.com');
    console.log('   Password: Abdul123');
    console.log('   Role: superadmin');
    
  } catch (error: any) {
    console.error('\n❌ Error:', error.message);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
      console.log('\n🔌 Database connection closed');
    }
  }
}

seedAdminUser();
