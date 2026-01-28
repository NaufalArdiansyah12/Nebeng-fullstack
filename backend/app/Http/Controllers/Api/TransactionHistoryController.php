<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\ApiToken;

class TransactionHistoryController extends Controller
{
    public function index(Request $request)
    {
        try {
            // Get user from bearer token (using custom ApiToken model)
            $token = $request->bearerToken();
            if (!$token) {
                return response()->json([
                    'success' => false,
                    'message' => 'Token tidak ditemukan'
                ], 401);
            }

            // Hash the token for lookup (same as other controllers)
            $hashedToken = hash('sha256', $token);
            $apiToken = ApiToken::where('token', $hashedToken)->first();
            
            if (!$apiToken) {
                return response()->json([
                    'success' => false,
                    'message' => 'Token tidak valid'
                ], 401);
            }

            $userId = $apiToken->user_id;
            $status = $request->query('status'); // completed, cancelled, all

            // Get all transactions from different booking types
            $transactions = [];

            // Booking Motor
            $motorBookings = DB::table('booking_motor')
                ->join('tebengan_motor', 'booking_motor.ride_id', '=', 'tebengan_motor.id')
                ->leftJoin('locations as origin', 'tebengan_motor.origin_location_id', '=', 'origin.id')
                ->leftJoin('locations as destination', 'tebengan_motor.destination_location_id', '=', 'destination.id')
                ->leftJoin('payments', 'booking_motor.id', '=', 'payments.booking_id')
                ->where('booking_motor.user_id', $userId)
                ->select(
                    'booking_motor.id',
                    'booking_motor.booking_number',
                    'booking_motor.created_at',
                    'booking_motor.status',
                    'origin.name as departure_location',
                    'destination.name as arrival_location',
                    'tebengan_motor.price',
                    DB::raw("'motor' as type"),
                    'payments.payment_method',
                    'payments.amount',
                    'payments.admin_fee',
                    'payments.total_amount',
                    'payments.status as payment_status'
                )
                ->get();

            // Booking Mobil
            $mobilBookings = DB::table('booking_mobil')
                ->join('tebengan_mobil', 'booking_mobil.ride_id', '=', 'tebengan_mobil.id')
                ->leftJoin('locations as origin', 'tebengan_mobil.origin_location_id', '=', 'origin.id')
                ->leftJoin('locations as destination', 'tebengan_mobil.destination_location_id', '=', 'destination.id')
                ->leftJoin('payments', 'booking_mobil.id', '=', 'payments.booking_id')
                ->where('booking_mobil.user_id', $userId)
                ->select(
                    'booking_mobil.id',
                    'booking_mobil.booking_number',
                    'booking_mobil.created_at',
                    'booking_mobil.status',
                    'origin.name as departure_location',
                    'destination.name as arrival_location',
                    'tebengan_mobil.price',
                    DB::raw("'mobil' as type"),
                    'payments.payment_method',
                    'payments.amount',
                    'payments.admin_fee',
                    'payments.total_amount',
                    'payments.status as payment_status'
                )
                ->get();

            // Booking Barang
            $barangBookings = DB::table('booking_barang')
                ->join('tebengan_barang', 'booking_barang.ride_id', '=', 'tebengan_barang.id')
                ->leftJoin('locations as origin', 'tebengan_barang.origin_location_id', '=', 'origin.id')
                ->leftJoin('locations as destination', 'tebengan_barang.destination_location_id', '=', 'destination.id')
                ->leftJoin('payments', 'booking_barang.id', '=', 'payments.booking_id')
                ->where('booking_barang.user_id', $userId)
                ->select(
                    'booking_barang.id',
                    'booking_barang.booking_number',
                    'booking_barang.created_at',
                    'booking_barang.status',
                    'origin.name as departure_location',
                    'destination.name as arrival_location',
                    'tebengan_barang.price',
                    DB::raw("'barang' as type"),
                    'payments.payment_method',
                    'payments.amount',
                    'payments.admin_fee',
                    'payments.total_amount',
                    'payments.status as payment_status'
                )
                ->get();

            // Booking Titip Barang
            $titipBookings = DB::table('booking_titip_barang')
                ->join('tebengan_titip_barang', 'booking_titip_barang.ride_id', '=', 'tebengan_titip_barang.id')
                ->leftJoin('locations as origin', 'tebengan_titip_barang.origin_location_id', '=', 'origin.id')
                ->leftJoin('locations as destination', 'tebengan_titip_barang.destination_location_id', '=', 'destination.id')
                ->leftJoin('payments', 'booking_titip_barang.id', '=', 'payments.booking_id')
                ->where('booking_titip_barang.user_id', $userId)
                ->select(
                    'booking_titip_barang.id',
                    'booking_titip_barang.booking_number',
                    'booking_titip_barang.created_at',
                    'booking_titip_barang.status',
                    'origin.name as departure_location',
                    'destination.name as arrival_location',
                    'tebengan_titip_barang.price',
                    DB::raw("'titip' as type"),
                    'payments.payment_method',
                    'payments.amount',
                    'payments.admin_fee',
                    'payments.total_amount',
                    'payments.status as payment_status'
                )
                ->get();

            // Merge all bookings
            $allBookings = collect($motorBookings)
                ->merge($mobilBookings)
                ->merge($barangBookings)
                ->merge($titipBookings);

            // Format transactions
            foreach ($allBookings as $booking) {
                $transactionStatus = $this->determineStatus($booking->status, $booking->payment_status);
                
                // Filter by status if requested
                if ($status && $status !== 'all') {
                    if ($status === 'completed' && $transactionStatus !== 'completed') continue;
                    if ($status === 'cancelled' && $transactionStatus !== 'cancelled') continue;
                }

                $transactions[] = [
                    'id' => $booking->id,
                    'booking_number' => $booking->booking_number,
                    'type' => $this->getTypeName($booking->type),
                    'type_code' => $booking->type,
                    'date' => date('d M Y', strtotime($booking->created_at)),
                    'route' => $booking->departure_location . ' → ' . $booking->arrival_location,
                    'departure' => $booking->departure_location,
                    'arrival' => $booking->arrival_location,
                    'amount' => (float) ($booking->total_amount ?? $booking->price ?? 0),
                    'base_price' => (float) ($booking->amount ?? $booking->price ?? 0),
                    'admin_fee' => (float) ($booking->admin_fee ?? 0),
                    'status' => $transactionStatus,
                    'payment_method' => $this->formatPaymentMethod($booking->payment_method),
                    'payment_status' => $booking->payment_status,
                    'created_at' => $booking->created_at,
                ];
            }

            // Sort by created_at descending
            usort($transactions, function($a, $b) {
                return strtotime($b['created_at']) - strtotime($a['created_at']);
            });

            return response()->json([
                'success' => true,
                'data' => $transactions
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil riwayat transaksi',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    private function determineStatus($bookingStatus, $paymentStatus)
    {
        // Map booking status to transaction status
        if (in_array($bookingStatus, ['completed', 'finished', 'done'])) {
            return 'completed';
        }
        
        if (in_array($bookingStatus, ['cancelled', 'canceled', 'rejected'])) {
            return 'cancelled';
        }

        if ($paymentStatus === 'paid' || $paymentStatus === 'success') {
            return 'completed';
        }

        if ($paymentStatus === 'failed' || $paymentStatus === 'expired') {
            return 'cancelled';
        }

        return 'pending';
    }

    private function getTypeName($type)
    {
        $names = [
            'motor' => 'Nebeng Motor',
            'mobil' => 'Nebeng Mobil',
            'barang' => 'Nebeng Barang',
            'titip' => 'Nebeng Titip',
        ];

        return $names[$type] ?? ucfirst($type);
    }

    private function formatPaymentMethod($method)
    {
        if (!$method) return 'Tunai';

        $methods = [
            'cash' => 'Tunai',
            'bri' => 'BRI Virtual Account',
            'bca' => 'BCA Virtual Account',
            'bni' => 'BNI Virtual Account',
            'mandiri' => 'Mandiri Virtual Account',
            'qris' => 'QRIS',
            'dana' => 'Dana',
        ];

        return $methods[strtolower($method)] ?? ucfirst($method);
    }
}
