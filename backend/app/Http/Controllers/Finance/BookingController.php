<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BookingController extends Controller
{
    /* =========================
       CHART PESANAN
    ========================= */    
    public function getPesananChart(Request $request)
    {
        try {
            $whereClause = "";
            $params = [];

            // Filter by month if provided (format: YYYY-MM)
            if ($request->has('month')) {
                $month = $request->month;
                $whereClause = "WHERE DATE_FORMAT(created_at, '%Y-%m') = ?";
                $params = [$month, $month, $month, $month];
            }

            $data = DB::select("
                SELECT 'Nebeng Motor' AS label, COUNT(*) AS total 
                FROM booking_motor 
                $whereClause
                UNION ALL
                SELECT 'Nebeng Barang' AS label, COUNT(*) AS total 
                FROM booking_barang 
                " . ($whereClause ? str_replace('?', '?', $whereClause) : '') . "
                UNION ALL
                SELECT 'Nebeng Mobil' AS label, COUNT(*) AS total 
                FROM booking_mobil 
                " . ($whereClause ? str_replace('?', '?', $whereClause) : '') . "
                UNION ALL
                SELECT 'Titip Barang' AS label, COUNT(*) AS total 
                FROM booking_titip_barang 
                " . ($whereClause ? str_replace('?', '?', $whereClause) : '') . "
            ", $params);

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
    public function getAllBookingTransactions(Request $request)
    {
        try {
            $whereClause = "";
            $params = [];

            // Filter by month if provided (format: YYYY-MM)
            if ($request->has('month')) {
                $month = $request->month;
                $whereClause = "WHERE DATE_FORMAT(b.created_at, '%Y-%m') = ?";
                $params = [$month, $month, $month, $month];
            }

            $data = DB::select("
                SELECT 
                    b.id,
                    b.created_at AS tanggal,
                    m.name AS driver,
                    u.name AS customer,
                    b.booking_number,
                    b.status,
                    'Nebeng Motor' AS jenis,
                    t.service_type
                FROM booking_motor b
                JOIN users u ON u.id = b.user_id
                LEFT JOIN tebengan_motor t ON t.id = b.ride_id
                LEFT JOIN users m ON m.id = t.user_id
                $whereClause

                UNION ALL

                SELECT 
                    b.id,
                    b.created_at AS tanggal,
                    m.name AS driver,
                    u.name AS customer,
                    b.booking_number,
                    b.status,
                    'Nebeng Barang' AS jenis,
                    t.service_type
                FROM booking_barang b
                JOIN users u ON u.id = b.user_id
                LEFT JOIN tebengan_barang t ON t.id = b.ride_id
                LEFT JOIN users m ON m.id = t.user_id
                " . ($whereClause ? str_replace('?', '?', $whereClause) : '') . "

                UNION ALL

                SELECT 
                    b.id,
                    b.created_at AS tanggal,
                    m.name AS driver,
                    u.name AS customer,
                    b.booking_number,
                    b.status,
                    'Nebeng Mobil' AS jenis,
                    t.service_type
                FROM booking_mobil b
                JOIN users u ON u.id = b.user_id
                LEFT JOIN tebengan_mobil t ON t.id = b.ride_id
                LEFT JOIN users m ON m.id = t.user_id
                " . ($whereClause ? str_replace('?', '?', $whereClause) : '') . "

                UNION ALL

                SELECT 
                    b.id,
                    b.created_at AS tanggal,
                    m.name AS driver,
                    u.name AS customer,
                    b.booking_number,
                    b.status,
                    'Titip Barang' AS jenis,
                    'barang' AS service_type
                FROM booking_titip_barang b
                JOIN users u ON u.id = b.user_id
                LEFT JOIN tebengan_titip_barang t ON t.id = b.ride_id
                LEFT JOIN users m ON m.id = t.user_id
                " . ($whereClause ? str_replace('?', '?', $whereClause) : '') . "

                ORDER BY tanggal DESC
            ", $params);

            return response()->json($data);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'gagal ambil transaksi booking',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /* =========================
       DETAIL TRANSAKSI
    ========================= */
    public function getTransactionDetail($id)
    {
        try {
            // Try to find in each booking table
            $booking = null;
            $jenis = '';
            $tebengan = null;

            // Check booking_motor
            $booking = DB::table('booking_motor')->where('id', $id)->first();
            if ($booking) {
                $jenis = 'Nebeng Motor';
                $tebengan = DB::table('tebengan_motor')->where('id', $booking->ride_id)->first();
            }

            // Check booking_mobil
            if (!$booking) {
                $booking = DB::table('booking_mobil')->where('id', $id)->first();
                if ($booking) {
                    $jenis = 'Nebeng Mobil';
                    $tebengan = DB::table('tebengan_mobil')->where('id', $booking->ride_id)->first();
                }
            }

            // Check booking_barang
            if (!$booking) {
                $booking = DB::table('booking_barang')->where('id', $id)->first();
                if ($booking) {
                    $jenis = 'Nebeng Barang';
                    $tebengan = DB::table('tebengan_barang')->where('id', $booking->ride_id)->first();
                }
            }

            // Check booking_titip_barang
            if (!$booking) {
                $booking = DB::table('booking_titip_barang')->where('id', $id)->first();
                if ($booking) {
                    $jenis = 'Titip Barang';
                    $tebengan = DB::table('tebengan_titip_barang')->where('id', $booking->ride_id)->first();
                }
            }

            if (!$booking) {
                return response()->json(['message' => 'Booking tidak ditemukan'], 404);
            }

            // Get customer data
            $customer = DB::table('users')->where('id', $booking->user_id)->first();

            // Get mitra data
            $mitra = null;
            $vehicle = null;
            if ($tebengan) {
                $mitra = DB::table('users')->where('id', $tebengan->user_id)->first();
                
                // Get vehicle info if available
                if (isset($tebengan->kendaraan_mitra_id)) {
                    $vehicle = DB::table('kendaraan_mitra')
                        ->where('id', $tebengan->kendaraan_mitra_id)
                        ->first();
                }
            }

            // Get payment data
            $payment = DB::table('payments')
                ->where('booking_number', $booking->booking_number)
                ->first();

            // Get locations
            $originLocation = null;
            $destLocation = null;
            if ($tebengan) {
                $originLocation = DB::table('locations')->where('id', $tebengan->origin_location_id)->first();
                $destLocation = DB::table('locations')->where('id', $tebengan->destination_location_id)->first();
            }

            // Determine service type from tebengan table
            $serviceType = 'Hanya Tebengan'; // default
            if ($tebengan && isset($tebengan->service_type)) {
                $serviceTypeRaw = $tebengan->service_type;
                // Map service_type from database to display format
                if ($serviceTypeRaw === 'barang') {
                    $serviceType = 'Hanya Titip Barang';
                } elseif ($serviceTypeRaw === 'tebengan') {
                    $serviceType = 'Hanya Tebengan';
                } elseif ($serviceTypeRaw === 'both') {
                    $serviceType = 'Tebengan dan Titip Barang';
                }
            } elseif ($jenis === 'Titip Barang') {
                // Fallback for titip barang without tebengan
                $serviceType = 'Hanya Titip Barang';
            }

            // Get passenger data (for motor, mobil, or when service_type includes tebengan)
            $passengers = [];
            $hasTebengan = ($tebengan && isset($tebengan->service_type) && in_array($tebengan->service_type, ['tebengan', 'both']));
            if ($hasTebengan && isset($booking->seats)) {
                $passengers = [
                    'count' => (int) $booking->seats,
                    'weight' => $booking->weight ?? '-',
                ];
            }

            // Get goods data (when service_type includes barang)
            $goods = [];
            $hasBarang = ($tebengan && isset($tebengan->service_type) && in_array($tebengan->service_type, ['barang', 'both'])) || $jenis === 'Titip Barang';
            if ($hasBarang) {
                $goods = [
                    'description' => $booking->description ?? $booking->meta ?? '-',
                    'weight' => $booking->weight ?? '-',
                    'photo' => $booking->photo ?? null,
                ];
            }

            // Get penumpang data for Nebeng Mobil
            $penumpangList = [];
            if ($jenis === 'Nebeng Mobil') {
                $penumpangData = DB::table('penumpang_booking_mobil')
                    ->where('booking_mobil_id', $booking->id)
                    ->get();
                
                foreach ($penumpangData as $p) {
                    $penumpangList[] = [
                        'nama' => $p->nama,
                        'nik' => $p->nik ?? '-',
                        'no_telepon' => $p->no_telepon ?? '-',
                        'jenis_kelamin' => $p->jenis_kelamin ?? '-',
                    ];
                }
            }

            // Build response
            $response = [
                'id' => $booking->id,
                'booking_number' => $booking->booking_number,
                'status' => $booking->status,
                'tanggal' => $booking->created_at,
                'jenis' => $jenis,
                'service_type' => $serviceType,
                'customer' => [
                    'name' => $customer->name ?? '-',
                    'phone' => $customer->phone ?? '-',
                    'photo' => $customer->profile_photo ?? null,
                    'notes' => $booking->description ?? $booking->meta ?? '-',
                ],
                'mitra' => [
                    'id' => $mitra->id ?? '-',
                    'name' => $mitra->name ?? '-',
                    'phone' => $mitra->phone ?? '-',
                    'photo' => $mitra->profile_photo ?? null,
                    'vehicle_type' => $vehicle->type ?? ucfirst(explode(' ', $jenis)[1] ?? 'Motor'),
                    'vehicle_brand' => $vehicle->brand ?? $vehicle->merk ?? 'TOYOTA',
                    'vehicle_plate' => $vehicle->plate_number ?? $vehicle->plat ?? '-',
                ],
                'journey' => [
                    'date' => $tebengan ? date('l, d.m.Y', strtotime($tebengan->departure_date)) : '-',
                    'distance' => '14 km',
                    'duration' => '14 menit',
                    'pickup_location' => $originLocation->name ?? '-',
                    'pickup_time' => $tebengan ? date('H:i', strtotime($tebengan->departure_time)) . ' WIB' : '-',
                    'pickup_address' => $originLocation->address ?? '-',
                    'destination_location' => $destLocation->name ?? '-',
                    'destination_time' => $tebengan ? date('H:i', strtotime($tebengan->departure_time)) . ' WIB' : '-',
                    'destination_address' => $destLocation->address ?? '-',
                ],
                'payment' => [
                    'type' => $payment->payment_method ?? 'QRIS',
                    'date' => $payment ? date('d/m/Y', strtotime($payment->paid_at)) : '-',
                    'transaction_number' => $payment->transaction_id ?? 'INV/' . date('Ymd') . '/123456789',
                    'base_price' => (float) ($payment->amount ?? $tebengan->price ?? 50000),
                    'admin_fee' => (float) ($payment->admin_fee ?? 15000),
                    'total' => (float) ($payment->total_amount ?? 65000),
                    'passengers' => (int) ($booking->seats ?? 2),
                ],
                'passengers' => $passengers,
                'goods' => $goods,
                'penumpang_list' => $penumpangList,
            ];

            return response()->json($response);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'gagal ambil detail transaksi',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
