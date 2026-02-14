<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\User;
use App\Models\Ride;
use Illuminate\Http\Request;

class PesananController extends Controller
{
    /**
     * Get all pesanan/bookings
     * GET /api/admin/pesanan
     */
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 10);
        $status = $request->input('status'); // pending, accepted, completed, cancelled, rejected
        $search = $request->input('search');

        $query = Booking::with(['user:id,name,email,phone', 'ride.user:id,name']);

        if ($status) {
            $query->where('status', $status);
        }

        if ($search) {
            $query->whereHas('user', function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $bookings = $query->orderBy('created_at', 'desc')
                         ->paginate($perPage);

        $data = $bookings->getCollection()->map(function($booking) {
            return [
                'id' => $booking->id,
                'booking_code' => $booking->booking_code ?? 'N/A',
                'customer' => [
                    'id' => $booking->user->id ?? null,
                    'name' => $booking->user->name ?? 'Unknown',
                    'email' => $booking->user->email ?? '',
                    'phone' => $booking->user->phone ?? '',
                ],
                'mitra' => [
                    'id' => $booking->ride->user->id ?? null,
                    'name' => $booking->ride->user->name ?? 'Unknown',
                ],
                'ride_type' => $booking->ride_type ?? 'motor',
                'pickup_location' => $booking->pickup_location,
                'dropoff_location' => $booking->dropoff_location,
                'seats' => $booking->seats,
                'total_price' => (float) $booking->total_price,
                'status' => $booking->status,
                'created_at' => $booking->created_at->format('d M Y H:i'),
                'updated_at' => $booking->updated_at->format('d M Y H:i'),
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $data,
            'pagination' => [
                'current_page' => $bookings->currentPage(),
                'per_page' => $bookings->perPage(),
                'total' => $bookings->total(),
                'last_page' => $bookings->lastPage(),
            ]
        ], 200);
    }

    /**
     * Get pesanan detail
     * GET /api/admin/pesanan/{id}
     */
    public function show($id)
    {
        $booking = Booking::with([
            'user:id,name,email,phone,profile_photo',
            'ride.user:id,name,email,phone',
            'ride.vehicle:id,vehicle_type,brand,model,license_plate'
        ])->find($id);

        if (!$booking) {
            return response()->json([
                'success' => false,
                'message' => 'Pesanan tidak ditemukan'
            ], 404);
        }

        $data = [
            'id' => $booking->id,
            'booking_code' => $booking->booking_code ?? 'N/A',
            'customer' => [
                'id' => $booking->user->id ?? null,
                'name' => $booking->user->name ?? 'Unknown',
                'email' => $booking->user->email ?? '',
                'phone' => $booking->user->phone ?? '',
                'photo' => $booking->user->profile_photo ? url('storage/' . $booking->user->profile_photo) : null,
            ],
            'mitra' => [
                'id' => $booking->ride->user->id ?? null,
                'name' => $booking->ride->user->name ?? 'Unknown',
                'email' => $booking->ride->user->email ?? '',
                'phone' => $booking->ride->user->phone ?? '',
            ],
            'vehicle' => [
                'type' => $booking->ride->vehicle->vehicle_type ?? 'motor',
                'brand' => $booking->ride->vehicle->brand ?? '',
                'model' => $booking->ride->vehicle->model ?? '',
                'license_plate' => $booking->ride->vehicle->license_plate ?? '',
            ],
            'ride_type' => $booking->ride_type ?? 'motor',
            'pickup_location' => $booking->pickup_location,
            'pickup_lat' => $booking->pickup_lat,
            'pickup_lng' => $booking->pickup_lng,
            'dropoff_location' => $booking->dropoff_location,
            'dropoff_lat' => $booking->dropoff_lat,
            'dropoff_lng' => $booking->dropoff_lng,
            'seats' => $booking->seats,
            'jumlah_bagasi' => $booking->jumlah_bagasi,
            'total_price' => (float) $booking->total_price,
            'payment_method' => $booking->payment_method ?? 'cash',
            'status' => $booking->status,
            'notes' => $booking->notes,
            'photo' => $booking->photo ? url('storage/' . $booking->photo) : null,
            'created_at' => $booking->created_at->format('d M Y H:i'),
            'updated_at' => $booking->updated_at->format('d M Y H:i'),
        ];

        return response()->json([
            'success' => true,
            'data' => $data
        ], 200);
    }

    /**
     * Get statistics
     * GET /api/admin/pesanan/statistics
     */
    public function statistics()
    {
        $total = Booking::count();
        $pending = Booking::where('status', 'pending')->count();
        $accepted = Booking::where('status', 'accepted')->count();
        $completed = Booking::where('status', 'completed')->count();
        $cancelled = Booking::whereIn('status', ['cancelled', 'rejected'])->count();

        // Today
        $today = Booking::whereDate('created_at', today())->count();
        
        // This month
        $thisMonth = Booking::whereMonth('created_at', now()->month)
                           ->whereYear('created_at', now()->year)
                           ->count();

        return response()->json([
            'success' => true,
            'data' => [
                'total' => $total,
                'pending' => $pending,
                'accepted' => $accepted,
                'completed' => $completed,
                'cancelled' => $cancelled,
                'today' => $today,
                'this_month' => $thisMonth,
            ]
        ], 200);
    }
}
