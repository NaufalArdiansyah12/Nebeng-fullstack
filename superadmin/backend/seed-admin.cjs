// seed-admin.js - Script untuk seed admin user ke database (CommonJS)
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
require('dotenv').config();

async function seedAdminUser() {
  let connection;
  
  const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'nebeng-bro',
  };
  
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
    
    const tableList = tables;
    if (tableList.length === 0) {
      console.log('❌ Users table does not exist!');
      console.log('Please run the database initialization first.');
      process.exit(1);
    }
    
    console.log('✅ Users table exists\n');

    // Check if admin user already exists
    const [existingUsers] = await connection.query(
      'SELECT id, email, name, role, password FROM users WHERE email = ?',
      ['Abdul000@gmail.com']
    );
    
    if (existingUsers.length > 0) {
      const user = existingUsers[0];
      console.log('⚠️  Admin user already exists:');
      console.log('   ID:', user.id);
      console.log('   Email:', user.email);
      console.log('   Name:', user.name);
      console.log('   Role:', user.role);
      console.log('   Password hash:', user.password ? user.password.substring(0, 30) + '...' : 'N/A');
      console.log('');
      
      // Update the role to superadmin if needed
      if (user.role !== 'superadmin') {
        console.log('🔄 Updating role to superadmin...');
        await connection.execute(
          'UPDATE users SET role = ? WHERE email = ?',
          ['superadmin', 'Abdul000@gmail.com']
        );
        console.log('✅ Role updated to superadmin\n');
      }
      
      // Check if password is correct
      const testPassword = 'Abdul123';
      const isMatch = await bcrypt.compare(testPassword, user.password);
      if (!isMatch) {
        console.log('⚠️  Password does not match "Abdul123"');
        console.log('🔄 Updating password...');
        const hashedPassword = await bcrypt.hash(testPassword, 10);
        await connection.execute(
          'UPDATE users SET password = ? WHERE email = ?',
          [hashedPassword, 'Abdul000@gmail.com']
        );
        console.log('✅ Password updated\n');
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
    
  } catch (error) {
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
