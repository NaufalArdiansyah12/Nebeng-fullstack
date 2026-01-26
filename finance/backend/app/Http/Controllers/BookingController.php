<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\DB;

class BookingController extends Controller
{
    /* =========================
       CHART PESANAN
    ========================= */    
    public function getPesananChart()
    {
        try {
            $data = DB::select("
                SELECT 'Nebeng Motor' AS label, COUNT(*) AS total FROM booking_motor
                UNION ALL
                SELECT 'Nebeng Barang' AS label, COUNT(*) AS total FROM booking_barang
                UNION ALL
                SELECT 'Nebeng Mobil' AS label, COUNT(*) AS total FROM booking_mobil
                UNION ALL
                SELECT 'Titip Barang' AS label, COUNT(*) AS total FROM booking_titip_barang
            ");

            return response()->json($data);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'gagal ambil data pesanan',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    
    /* =========================
       TRANSAKSI (SEMUA BOOKING)
    ========================= */
    public function getAllBookingTransactions()
    {
        try {
            $data = DB::select("
                SELECT 
                    b.id,
                    b.created_at AS tanggal,
                    NULL AS driver,
                    u.name AS customer,
                    b.booking_number,
                    b.status,
                    'Nebeng Motor' AS jenis
                FROM booking_motor b
                JOIN users u ON u.id = b.user_id

                UNION ALL

                SELECT 
                    b.id,
                    b.created_at AS tanggal,
                    NULL AS driver,
                    u.name AS customer,
                    b.booking_number,
                    b.status,
                    'Nebeng Barang' AS jenis
                FROM booking_barang b
                JOIN users u ON u.id = b.user_id

                UNION ALL

                SELECT 
                    b.id,
                    b.created_at AS tanggal,
                    NULL AS driver,
                    u.name AS customer,
                    b.booking_number,
                    b.status,
                    'Nebeng Mobil' AS jenis
                FROM booking_mobil b
                JOIN users u ON u.id = b.user_id

                UNION ALL

                SELECT 
                    b.id,
                    b.created_at AS tanggal,
                    NULL AS driver,
                    u.name AS customer,
                    b.booking_number,
                    b.status,
                    'Titip Barang' AS jenis
                FROM booking_titip_barang b
                JOIN users u ON u.id = b.user_id

                ORDER BY tanggal DESC
            ");

            return response()->json($data);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'gagal ambil transaksi booking',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
