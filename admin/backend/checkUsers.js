// checkUsers.js - Script untuk cek user admin di database (ES Module)
import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

async function checkUsers() {
  console.log('🔍 Checking users in database...\n');
  
  try {
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'nebeng-bro'
    });

    console.log('✅ Connected to database\n');

    // Cek semua user
    const [allUsers] = await connection.execute('SELECT id, name, email, role FROM users');
    console.log('📊 Total users:', allUsers.length);
    console.log('All users:');
    console.table(allUsers);

    // Cek admin users
    const [adminUsers] = await connection.execute('SELECT id, name, email, role, password FROM users WHERE role = ?', ['admin']);
    console.log('\n👑 Admin users:', adminUsers.length);
    
    if (adminUsers.length > 0) {
      adminUsers.forEach(admin => {
        console.log('\n-------------------');
        console.log('ID:', admin.id);
        console.log('Name:', admin.name);
        console.log('Email:', admin.email);
        console.log('Role:', admin.role);
        console.log('Password:', admin.password.substring(0, 30) + '...');
        console.log('Password is hashed:', admin.password.startsWith('$2') ? '✅ Yes' : '❌ No (plain text)');
        
        if (!admin.password.startsWith('$2')) {
          console.log('💡 Plain text password untuk login:', admin.password);
        }
      });
    } else {
      console.log('⚠️  No admin users found!');
      console.log('\n💡 Suggestion: Ubah role salah satu user menjadi "admin" di database');
      console.log('   SQL Query: UPDATE users SET role = "admin" WHERE email = "your-email@example.com"');
    }

    await connection.end();
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('Stack:', error.stack);
  }
}

checkUsers();