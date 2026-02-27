import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  port: parseInt(process.env.DB_PORT || '3306'),
  database: process.env.DB_NAME || 'nebeng-bro',
};

const locationsData = [
  {
    name: 'Terminal Blok M - Jakarta',
    city: 'Jakarta',
    address: 'Jl. Blok M No.1',
    latitude: -6.2412430,
    longitude: 106.8001210,
    created_by_role: 'seed'
  },
  {
    name: 'Stasiun Gambir - Jakarta',
    city: 'Jakarta',
    address: 'Jl. Stasiun Gambir',
    latitude: -6.1744650,
    longitude: 106.8271700,
    created_by_role: 'seed'
  },
  {
    name: 'Stasiun Bandung - Bandung',
    city: 'Bandung',
    address: 'Jl. Stasiun Bandung',
    latitude: -6.8964440,
    longitude: 107.6208870,
    created_by_role: 'seed'
  }
];

async function seedLocations() {
  let connection;

  try {
    console.log('📦 Connecting to database...');
    connection = await mysql.createConnection(dbConfig);
    console.log('✅ Connected to database');

    console.log('\n📍 Seeding locations data...\n');

    // Clear existing locations first (optional)
    // await connection.query('DELETE FROM locations WHERE created_by_role = ?', ['seed']);
    
    for (const location of locationsData) {
      try {
        const [result] = await connection.query(
          `INSERT INTO locations (name, city, address, latitude, longitude, created_by_role) 
           VALUES (?, ?, ?, ?, ?, ?)`,
          [location.name, location.city, location.address, location.latitude, location.longitude, location.created_by_role]
        );
        
        const insertResult = result as any;
        console.log(`✅ Added: ${location.name} (ID: ${insertResult.insertId})`);
      } catch (error: any) {
        if (error.code === 'ER_DUP_ENTRY') {
          console.log(`⚠️  Skipped: ${location.name} (Already exists)`);
        } else {
          throw error;
        }
      }
    }

    console.log('\n✅ Locations seeding completed successfully!');
    
    // Show all locations
    const [rows] = await connection.query('SELECT * FROM locations');
    console.log('\n📋 All Locations:');
    console.table(rows);

  } catch (error) {
    console.error('❌ Error seeding locations:', error);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
      console.log('\n🔌 Database connection closed');
    }
  }
}

seedLocations();
