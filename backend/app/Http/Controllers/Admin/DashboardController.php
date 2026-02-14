<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Booking;
use App\Models\Ride;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DashboardController extends Controller
{
    /**
     * Get dashboard statistics
     * GET /api/admin/dashboard?month=2&year=2026
     */
    public function index(Request $request)
    {

        try {
            // Get month and year from request, default to current month/year
            $month = $request->input('month', now()->month);
            $year = $request->input('year', now()->year);

            // Validate month and year
            if ($month < 1 || $month > 12) {
                $month = now()->month;
            }

            // Don't allow future dates
            $requestDate = \Carbon\Carbon::create($year, $month, 1);
            if ($requestDate->isFuture()) {
                $month = now()->month;
                $year = now()->year;
            }

            // Total Users (Customer)
            $totalCustomer = User::where('role', 'customer')->count();

            // Total Mitra
            $totalMitra = User::where('role', 'mitra')->count();

            // Total Pesanan - check if table exists
            $totalPesanan = 0;
            $pesananSelesai = 0;
            $pesananDibatalkan = 0;
            $pesananHariIni = 0;
            $totalPendapatan = 0;
            $pendapatanHariIni = 0;
            $pesananGrafik = [];
            $pesananTerbaru = [];

            try {
                $totalPesanan = Booking::count();
                $pesananSelesai = Booking::where('status', 'completed')->count();
                $pesananDibatalkan = Booking::whereIn('status', ['cancelled', 'rejected'])->count();
                $pesananHariIni = Booking::whereDate('created_at', today())->count();
                $totalPendapatan = Booking::where('status', 'completed')->sum('total_price');
                $pendapatanHariIni = Booking::where('status', 'completed')
                    ->whereDate('created_at', today())
                    ->sum('total_price');

                // Grafik Pesanan per Bulan (12 bulan terakhir dari bulan yang dipilih)
                $pesananGrafik = [];
                for ($i = 11; $i >= 0; $i--) {
                    $targetDate = \Carbon\Carbon::create($year, $month, 1)->subMonths($i);
                    $count = Booking::whereYear('created_at', $targetDate->year)
                        ->whereMonth('created_at', $targetDate->month)
                        ->count();
                    $pesananGrafik[] = [
                        'date' => $targetDate->format('M Y'),
                        'month' => $targetDate->format('F Y'), // Full month name
                        'count' => $count,
                        'year' => $targetDate->year,
                        'monthNumber' => $targetDate->month,
                    ];
                }

                // Pesanan Terbaru bulan ini (5 terakhir)
                $pesananTerbaru = Booking::with(['user:id,name,email'])
                    ->whereYear('created_at', $year)
                    ->whereMonth('created_at', $month)
                    ->orderBy('created_at', 'desc')
                    ->limit(5)
                    ->get()
                    ->map(function ($booking) {
                        return [
                            'id' => $booking->id,
                            'customer_name' => $booking->user->name ?? 'Unknown',
                            'mitra_name' => 'Unknown',
                            'total_price' => $booking->total_price ?? 0,
                            'status' => $booking->status,
                            'created_at' => $booking->created_at->format('d M Y H:i'),
                        ];
                    })
                    ->values()
                    ->toArray();
            } catch (\Exception $e) {
                // If booking table doesn't exist, return zero data
                for ($i = 11; $i >= 0; $i--) {
                    $targetDate = \Carbon\Carbon::create($year, $month, 1)->subMonths($i);
                    $pesananGrafik[] = [
                        'date' => $targetDate->format('M Y'),
                        'month' => $targetDate->format('F Y'),
                        'count' => 0,
                        'year' => $targetDate->year,
                        'monthNumber' => $targetDate->month,
                    ];
                }
                
                // Set pesananTerbaru sebagai array kosong
                $pesananTerbaru = [];

                // Log error untuk debugging
                Log::warning('Booking table error: ' . $e->getMessage());
            }

            // Customer Baru Bulan Ini
            $customerBaruBulanIni = User::where('role', 'customer')
                ->whereMonth('created_at', now()->month)
                ->whereYear('created_at', now()->year)
                ->count();

            // Mitra Baru Bulan Ini
            $mitraBaruBulanIni = User::where('role', 'mitra')
                ->whereMonth('created_at', now()->month)
                ->whereYear('created_at', now()->year)
                ->count();

            // Pending Verifikasi
            $pendingVerifikasiMitra = User::where('role', 'mitra')
                ->where('status', 'pending')
                ->count();

            $pendingVerifikasiCustomer = User::where('role', 'customer')
                ->where('phone_verified', false)
                ->count();

            return response()->json([
                'success' => true,
                'data' => [
                    'currentMonth' => $month,
                    'currentYear' => $year,
                    'currentMonthName' => \Carbon\Carbon::create($year, $month, 1)->format('F Y'),
                    'statistics' => [
                        'totalCustomer' => (int) $totalCustomer,
                        'totalMitra' => (int) $totalMitra,
                        'totalPesanan' => (int) $totalPesanan,
                        'pesananSelesai' => (int) $pesananSelesai,
                        'pesananDibatalkan' => (int) $pesananDibatalkan,
                        'pesananHariIni' => (int) $pesananHariIni,
                        'totalPendapatan' => (float) $totalPendapatan,
                        'pendapatanHariIni' => (float) $pendapatanHariIni,
                        'customerBaruBulanIni' => (int) $customerBaruBulanIni,
                        'mitraBaruBulanIni' => (int) $mitraBaruBulanIni,
                        'pendingVerifikasiMitra' => (int) $pendingVerifikasiMitra,
                        'pendingVerifikasiCustomer' => (int) $pendingVerifikasiCustomer,
                    ],
                    'grafik' => $pesananGrafik,
                    'pesananTerbaru' => $pesananTerbaru,
                ]
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error mengambil data dashboard',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
