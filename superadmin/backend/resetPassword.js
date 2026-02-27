// resetPassword.js - Reset password admin
import mysql from 'mysql2/promise';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';

dotenv.config();

async function resetPassword() {
  console.log('🔐 Resetting admin password...\n');
  
  const email = 'admin@nebeng.com'; // Ganti dengan email admin yang mau direset
  const newPassword = 'admin123'; // Password baru yang mau diset
  
  try {
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'nebeng-bro'
    });

    console.log('✅ Connected to database');

    // Hash password baru
    console.log('🔄 Hashing new password...');
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    console.log('✅ Password hashed:', hashedPassword.substring(0, 30) + '...');

    // Update password di database
    const [result] = await connection.execute(
      'UPDATE users SET password = ? WHERE email = ?',
      [hashedPassword, email]
    );

    if (result.affectedRows > 0) {
      console.log('\n✅ Password updated successfully!');
      console.log('\n📝 Login credentials:');
      console.log('   Email:', email);
      console.log('   Password:', newPassword);
      console.log('\n💡 You can now login with these credentials');
    } else {
      console.log('\n❌ User not found with email:', email);
    }

    await connection.end();
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

resetPassword();