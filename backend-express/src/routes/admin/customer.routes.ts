import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../../db.ts';

const router = express.Router();

// Get all customers from users table (role = 'customer')
router.get('/', async (req: Request, res: Response) => {
  try { 
    const connection = await pool.getConnection();
    
    const [rows] = await connection.query(
      `SELECT   
        u.id,   
        v.nama_lengkap as nama,     
        u.email,    
        u.phone as no_tlp,  
        v.status,   
        u.created_at as tanggal_daftar  
       FROM users u 
       LEFT JOIN verifikasi_ktp_customers v ON u.id = v.user_id
       WHERE u.role = 'customer' 
       ORDER BY u.created_at DESC`
    );
    connection.release();

    res.json(rows);
  } catch (error) {
    console.error('❌ GET /api/customers error:', error);
    res.status(500).json({ error: 'Failed to fetch customers', message: error instanceof Error ? error.message : '' });
  }
});

// Get customer by ID
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    
    // ✅ Removed u.gender — ambil jenis_kelamin dari verifikasi_ktp_customers
    const [rows] = await connection.query(
      `SELECT 
        u.id, 
        v.nama_lengkap as nama,
        u.email, 
        u.phone as no_tlp, 
        v.jenis_kelamin,
        v.alamat,
        v.tanggal_lahir,
        v.id as verifikasi_id,
        v.status,
        v.nama_lengkap as nama_lengkap_ktp,
        v.nik,
        v.jenis_kelamin as jenis_kelamin_ktp,
        v.photo_wajah,
        v.photo_ktp,
        u.created_at as tanggal_daftar 
       FROM users u
       LEFT JOIN verifikasi_ktp_customers v ON u.id = v.user_id
       WHERE u.role = 'customer' AND u.id = ?`,
      [id]
    );
    connection.release();

    if (Array.isArray(rows) && rows.length > 0) {
      res.json(rows[0]);
    } else {
      res.status(404).json({ error: 'Customer not found' });
    }
  } catch (error) {
    console.error('❌ GET /api/customers/:id error:', error);
    res.status(500).json({ error: 'Failed to fetch customer', message: error instanceof Error ? error.message : '' });
  }
});

// Update customer
router.put('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { 
    // Data dari Info Pribadi
    nama,           // nama_lengkap di verifikasi_ktp_customers
    email,          // email di users
    noTlp,          // phone di users
    jenisKelamin,   // jenis_kelamin di verifikasi_ktp_customers
    tanggalLahir,   // tanggal_lahir di verifikasi_ktp_customers
    alamat,         // alamat di verifikasi_ktp_customers
    
    // Data dari Info KTP
    nik,                  // nik di verifikasi_ktp_customers
    namaLengkapKtp,       // nama_lengkap di verifikasi_ktp_customers (sama dengan nama)
    jenisKelaminKtp,      // jenis_kelamin di verifikasi_ktp_customers (sama dengan jenisKelamin)
    
    // Data foto
    photoWajah,     // photo_wajah di verifikasi_ktp_customers
    photoKtp        // photo_ktp di verifikasi_ktp_customers
  } = req.body;

  let connection;
  try {
    connection = await pool.getConnection();
    
    // Start transaction
    await connection.beginTransaction();
    
    console.log(`📝 Updating customer ${id}:`, req.body);
    
    // ✅ Update data di tabel users (email, phone only — tanpa gender)
    const userUpdateFields = [];
    const userUpdateValues = [];
    
    if (email !== undefined) {
      userUpdateFields.push('email = ?');
      userUpdateValues.push(email);
    }
    if (noTlp !== undefined) {
      userUpdateFields.push('phone = ?');
      userUpdateValues.push(noTlp);
    }
    
    // Hanya update jika ada field yang diubah
    if (userUpdateFields.length > 0) {
      userUpdateValues.push(id);
      await connection.execute(
        `UPDATE users 
         SET ${userUpdateFields.join(', ')}
         WHERE id = ? AND role = 'customer'`,
        userUpdateValues
      );
    }
    
    // Update data di tabel verifikasi_ktp_customers
    // Check if KTP data exists
    const [ktpCheck] = await connection.query(
      'SELECT id FROM verifikasi_ktp_customers WHERE user_id = ?',
      [id]
    );
    
    const ktpUpdateFields = [];
    const ktpUpdateValues = [];
    
    // Nama lengkap bisa dari nama atau namaLengkapKtp
    if (nama !== undefined || namaLengkapKtp !== undefined) {
      ktpUpdateFields.push('nama_lengkap = ?');
      ktpUpdateValues.push(nama || namaLengkapKtp);
    }
    if (nik !== undefined) {
      ktpUpdateFields.push('nik = ?');
      ktpUpdateValues.push(nik);
    }
    if (alamat !== undefined) {
      ktpUpdateFields.push('alamat = ?');
      ktpUpdateValues.push(alamat);
    }
    if (tanggalLahir !== undefined) {
      ktpUpdateFields.push('tanggal_lahir = ?');
      ktpUpdateValues.push(tanggalLahir);
    }
    if (photoWajah !== undefined) {
      ktpUpdateFields.push('photo_wajah = ?');
      ktpUpdateValues.push(photoWajah);
    }
    if (photoKtp !== undefined) {
      ktpUpdateFields.push('photo_ktp = ?');
      ktpUpdateValues.push(photoKtp);
    }
    // ✅ jenis_kelamin sekarang di verifikasi_ktp_customers
    if (jenisKelamin !== undefined || jenisKelaminKtp !== undefined) {
      ktpUpdateFields.push('jenis_kelamin = ?');
      ktpUpdateValues.push(jenisKelamin || jenisKelaminKtp);
    }
    
    if (ktpUpdateFields.length > 0) {
      if (Array.isArray(ktpCheck) && ktpCheck.length > 0) {
        // Update existing KTP data
        ktpUpdateValues.push(id);
        await connection.execute(
          `UPDATE verifikasi_ktp_customers 
           SET ${ktpUpdateFields.join(', ')}
           WHERE user_id = ?`,
          ktpUpdateValues
        );
      } else {
        // ✅ Insert new KTP data — tambahkan jenis_kelamin
        await connection.execute(
          `INSERT INTO verifikasi_ktp_customers 
           (user_id, nama_lengkap, nik, alamat, tanggal_lahir, photo_wajah, photo_ktp, jenis_kelamin, status)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')`,
          [
            id, 
            nama || namaLengkapKtp || null, 
            nik || null, 
            alamat || null, 
            tanggalLahir || null,
            photoWajah || null,
            photoKtp || null,
            jenisKelamin || jenisKelaminKtp || null
          ]
        );
      }
    }
    
    // Commit transaction
    await connection.commit();
    connection.release();

    console.log(`✅ Customer ${id} updated successfully`);
    res.json({ 
      message: 'Customer updated successfully',
      success: true 
    });
  } catch (error) {
    // Rollback on error
    if (connection) {
      await connection.rollback();
      connection.release();
    }
    
    console.error('❌ PUT /api/customers/:id error:', error);
    res.status(500).json({ 
      error: 'Failed to update customer', 
      message: error instanceof Error ? error.message : '',
      success: false
    });
  }
});

// Update customer status
router.patch('/:id/status', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { status } = req.body;

  // ✅ Map frontend status to database status
  const statusMap: Record<string, string> = {
    'PENGAJUAN': 'pending',
    'TERVERIFIKASI': 'approved',
    'DITOLAK': 'rejected',
    'DIBLOCK': 'blocked'
  };

  const dbStatus = statusMap[status] || status.toLowerCase();

  try {
    const connection = await pool.getConnection();
    
    // Check if verification record exists
    const [checkRows] = await connection.query(
      'SELECT id FROM verifikasi_ktp_customers WHERE user_id = ?',
      [id]
    );

    if (Array.isArray(checkRows) && checkRows.length > 0) {
      // Update existing record
      await connection.execute(
        'UPDATE verifikasi_ktp_customers SET status = ? WHERE user_id = ?', 
        [dbStatus, id]
      );
    } else {
      // Create new verification record
      await connection.execute(
        'INSERT INTO verifikasi_ktp_customers (user_id, status) VALUES (?, ?)',
        [id, dbStatus]
      );
    }
    
    connection.release();

    console.log(`✅ Customer ${id} status updated to ${dbStatus} (${status})`);
    res.json({ message: 'Customer status updated successfully', success: true });
  } catch (error) {
    console.error('❌ PATCH /api/customers/:id/status error:', error);
    res.status(500).json({ error: 'Failed to update customer status', message: error instanceof Error ? error.message : '', success: false });
  }
});

// Update specific fields (untuk update individual field dari frontend)
router.patch('/:id/fields', async (req: Request, res: Response) => {
  const { id } = req.params;
  const updates = req.body;

  let connection;
  try {
    connection = await pool.getConnection();
    await connection.beginTransaction();

    console.log(`📝 Updating customer ${id} fields:`, updates);

    // ✅ Mapping field frontend ke database — gender dipindahkan ke ktpFields
    const userFields: Record<string, string> = {
      'email': 'email',
      'noTlp': 'phone',
      'no_tlp': 'phone'
    };

    const ktpFields: Record<string, string> = {
      'nama': 'nama_lengkap',
      'namaLengkap': 'nama_lengkap',
      'nama_lengkap': 'nama_lengkap',
      'namaLengkapKtp': 'nama_lengkap',
      'nama_lengkap_ktp': 'nama_lengkap',
      'nik': 'nik',
      'alamat': 'alamat',
      'tanggalLahir': 'tanggal_lahir',
      'tanggal_lahir': 'tanggal_lahir',
      'photoWajah': 'photo_wajah',
      'photo_wajah': 'photo_wajah',
      'photoKtp': 'photo_ktp',
      'photo_ktp': 'photo_ktp',
      'jenisKelamin': 'jenis_kelamin',
      'jenis_kelamin': 'jenis_kelamin',
      'jenisKelaminKtp': 'jenis_kelamin',
      'jenis_kelamin_ktp': 'jenis_kelamin'
    };

    // Update users table
    const userUpdateFields = [];
    const userUpdateValues = [];

    for (const [key, value] of Object.entries(updates)) {
      if (userFields[key]) {
        userUpdateFields.push(`${userFields[key]} = ?`);
        userUpdateValues.push(value);
      }
    }

    if (userUpdateFields.length > 0) {
      userUpdateValues.push(id);
      await connection.execute(
        `UPDATE users SET ${userUpdateFields.join(', ')} WHERE id = ? AND role = 'customer'`,
        userUpdateValues
      );
    }

    // Update verifikasi_ktp_customers table
    const ktpUpdateFields = [];
    const ktpUpdateValues = [];

    for (const [key, value] of Object.entries(updates)) {
      if (ktpFields[key]) {
        ktpUpdateFields.push(`${ktpFields[key]} = ?`);
        ktpUpdateValues.push(value);
      }
    }

    if (ktpUpdateFields.length > 0) {
      // Check if KTP record exists
      const [ktpCheck] = await connection.query(
        'SELECT id FROM verifikasi_ktp_customers WHERE user_id = ?',
        [id]
      );

      if (Array.isArray(ktpCheck) && ktpCheck.length > 0) {
        ktpUpdateValues.push(id);
        await connection.execute(
          `UPDATE verifikasi_ktp_customers SET ${ktpUpdateFields.join(', ')} WHERE user_id = ?`,
          ktpUpdateValues
        );
      } else {
        // Create new record if doesn't exist
        const insertFields: string[] = ['user_id', 'status'];
        const insertValues: any[] = [id, 'pending'];
        
        for (const [key, value] of Object.entries(updates)) {
          if (ktpFields[key]) {
            insertFields.push(ktpFields[key]);
            insertValues.push(value);
          }
        }
        
        const placeholders = insertFields.map(() => '?').join(', ');
        await connection.execute(
          `INSERT INTO verifikasi_ktp_customers (${insertFields.join(', ')}) VALUES (${placeholders})`,
          insertValues
        );
      }
    }

    await connection.commit();
    connection.release();

    console.log(`✅ Customer ${id} fields updated successfully`);
    res.json({ 
      message: 'Customer fields updated successfully',
      success: true,
      updated: Object.keys(updates)
    });
  } catch (error) {
    if (connection) {
      await connection.rollback();
      connection.release();
    }
    
    console.error('❌ PATCH /api/customers/:id/fields error:', error);
    res.status(500).json({ 
      error: 'Failed to update customer fields', 
      message: error instanceof Error ? error.message : '',
      success: false
    });
  }
});

// Block customer
router.post('/:id/block', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    
    // Check if verification record exists
    const [checkRows] = await connection.query(
      'SELECT id FROM verifikasi_ktp_customers WHERE user_id = ?',
      [id]
    );

    if (Array.isArray(checkRows) && checkRows.length > 0) {
      await connection.execute(
        'UPDATE verifikasi_ktp_customers SET status = ? WHERE user_id = ?', 
        ['blocked', id]
      );
    } else {
      await connection.execute(
        'INSERT INTO verifikasi_ktp_customers (user_id, status) VALUES (?, ?)',
        [id, 'blocked']
      );
    }
    
    // Fetch the updated customer data to return to frontend
    const [customerRows] = await connection.query(
      `SELECT   
        u.id,   
        v.nama_lengkap as nama,     
        u.email,    
        u.phone as no_tlp,  
        v.status,   
        u.created_at as tanggal_daftar  
       FROM users u 
       LEFT JOIN verifikasi_ktp_customers v ON u.id = v.user_id
       WHERE u.role = 'customer' AND u.id = ?`,
      [id]
    );
    
    connection.release();

    console.log(`✅ Customer ${id} blocked`);
    
    if (Array.isArray(customerRows) && customerRows.length > 0) {
      res.json(customerRows[0]);
    } else {
      res.json({ message: 'Customer blocked successfully' });
    }
  } catch (error) {
    console.error('❌ POST /api/customers/:id/block error:', error);
    res.status(500).json({ error: 'Failed to block customer', message: error instanceof Error ? error.message : '' });
  }
});

// Unblock customer
router.post('/:id/unblock', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    
    await connection.execute(
      'UPDATE verifikasi_ktp_customers SET status = ? WHERE user_id = ?', 
      ['approved', id]
    );
    
    // Fetch the updated customer data to return to frontend
    const [customerRows] = await connection.query(
      `SELECT   
        u.id,   
        v.nama_lengkap as nama,     
        u.email,    
        u.phone as no_tlp,  
        v.status,   
        u.created_at as tanggal_daftar  
       FROM users u 
       LEFT JOIN verifikasi_ktp_customers v ON u.id = v.user_id
       WHERE u.role = 'customer' AND u.id = ?`,
      [id]
    );
    
    connection.release();

    console.log(`✅ Customer ${id} unblocked (approved)`);
    
    if (Array.isArray(customerRows) && customerRows.length > 0) {
      res.json(customerRows[0]);
    } else {
      res.json({ message: 'Customer unblocked successfully' });
    }
  } catch (error) {
    console.error('❌ POST /api/customers/:id/unblock error:', error);
    res.status(500).json({ error: 'Failed to unblock customer', message: error instanceof Error ? error.message : '' });
  }
});

export default router;