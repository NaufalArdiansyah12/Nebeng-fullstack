import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../db.ts';

const router = express.Router();

// Complete trip by driver using booking_number (more reliable)
router.post('/:bookingType/complete-by-number', async (req: Request, res: Response) => {
  const { bookingType } = req.params;
  const { booking_number } = req.body;

  if (!booking_number) {
    return res.status(400).json({
      success: false,
      message: 'booking_number is required',
    });
  }
  
  // Map booking type to table name
  const tableMap: { [key: string]: string } = {
    'motor': 'booking_motor',
    'mobil': 'booking_mobil',
    'barang': 'booking_barang',
    'titip-barang': 'booking_titip_barang',
  };

  const tableName = tableMap[bookingType];

  if (!tableName) {
    return res.status(400).json({
      success: false,
      message: 'Invalid booking type',
    });
  }

  let connection;
  try {
    connection = await pool.getConnection();

    console.log(`🟢 POST /api/booking/${bookingType}/complete-by-number - booking_number: ${booking_number}`);

    // Get the booking by booking_number
    const [bookingRows] = await connection.query(
      `SELECT id, driver_id, status, booking_number FROM ${tableName} WHERE booking_number = ?`,
      [booking_number]
    );

    if (!Array.isArray(bookingRows) || bookingRows.length === 0) {
      console.log(`❌ Booking not found with booking_number: ${booking_number}`);
      connection.release();
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
      });
    }

    const booking = bookingRows[0] as any;
    console.log(`✅ Found booking ID: ${booking.id}, Status: ${booking.status}`);

    // Check if booking is in correct status
    if (booking.status !== 'sudah_sampai_tujuan') {
      connection.release();
      return res.status(400).json({
        success: false,
        message: 'Booking status must be "sudah_sampai_tujuan" to complete',
        current_status: booking.status,
      });
    }

    // Update status to completed
    await connection.query(
      `UPDATE ${tableName} 
       SET status = 'selesai', 
           completed_at = NOW(), 
           updated_at = NOW()
       WHERE id = ?`,
      [booking.id]
    );

    // Get updated booking
    const [updatedRows] = await connection.query(
      `SELECT id, status, completed_at FROM ${tableName} WHERE id = ?`,
      [booking.id]
    );

    connection.release();

    const updatedBooking = Array.isArray(updatedRows) && updatedRows.length > 0 
      ? updatedRows[0] 
      : null;

    console.log(`✅ Trip completed successfully for ${bookingType} booking ${booking.id}`);

    res.json({
      success: true,
      message: 'Trip completed successfully',
      data: {
        booking_id: booking.id,
        status: updatedBooking ? (updatedBooking as any).status : 'selesai',
        completed_at: updatedBooking ? (updatedBooking as any).completed_at : null,
      },
    });
  } catch (error) {
    console.error('❌ POST /api/booking/:bookingType/complete-by-number error:', error);
    if (connection) connection.release();
    res.status(500).json({
      success: false,
      error: 'Failed to complete trip',
      message: error instanceof Error ? error.message : '',
    });
  }
});

// Complete trip by driver (bypass QR scan) - using booking ID
router.post('/:bookingType/:bookingId/complete-by-driver', async (req: Request, res: Response) => {
  const { bookingType, bookingId } = req.params;
  
  // Map booking type to table name
  const tableMap: { [key: string]: string } = {
    'motor': 'booking_motor',
    'mobil': 'booking_mobil',
    'barang': 'booking_barang',
    'titip-barang': 'booking_titip_barang',
  };

  const tableName = tableMap[bookingType];

  if (!tableName) {
    return res.status(400).json({
      success: false,
      message: 'Invalid booking type',
    });
  }

  let connection;
  try {
    connection = await pool.getConnection();

    console.log(`🟢 POST /api/booking/${bookingType}/${bookingId}/complete-by-driver`);

    // Get the booking
    const [bookingRows] = await connection.query(
      `SELECT id, driver_id, status FROM ${tableName} WHERE id = ?`,
      [bookingId]
    );

    if (!Array.isArray(bookingRows) || bookingRows.length === 0) {
      connection.release();
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
      });
    }

    const booking = bookingRows[0] as any;

    // Check if booking is in correct status
    if (booking.status !== 'sudah_sampai_tujuan') {
      connection.release();
      return res.status(400).json({
        success: false,
        message: 'Booking status must be "sudah_sampai_tujuan" to complete',
        current_status: booking.status,
      });
    }

    // Update status to completed
    await connection.query(
      `UPDATE ${tableName} 
       SET status = 'selesai', 
           completed_at = NOW(), 
           updated_at = NOW()
       WHERE id = ?`,
      [bookingId]
    );

    // Get updated booking
    const [updatedRows] = await connection.query(
      `SELECT id, status, completed_at FROM ${tableName} WHERE id = ?`,
      [bookingId]
    );

    connection.release();

    const updatedBooking = Array.isArray(updatedRows) && updatedRows.length > 0 
      ? updatedRows[0] 
      : null;

    console.log(`✅ Trip completed successfully for ${bookingType} booking ${bookingId}`);

    res.json({
      success: true,
      message: 'Trip completed successfully',
      data: {
        booking_id: parseInt(bookingId),
        status: updatedBooking ? (updatedBooking as any).status : 'selesai',
        completed_at: updatedBooking ? (updatedBooking as any).completed_at : null,
      },
    });
  } catch (error) {
    console.error('❌ POST /api/booking/:bookingType/:bookingId/complete-by-driver error:', error);
    if (connection) connection.release();
    res.status(500).json({
      success: false,
      error: 'Failed to complete trip',
      message: error instanceof Error ? error.message : '',
    });
  }
});

export default router;
