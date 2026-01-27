<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BookingBarang;
use App\Models\ApiToken;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class BookingBarangLocationController extends Controller
{
    public function store(Request $request, $id)
    {
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json(['success' => false, 'message' => 'Token tidak ditemukan'], 401);
        }

        $apiToken = ApiToken::where('token', hash('sha256', $bearer))->where('expires_at', '>', now())->first();
        if (!$apiToken) {
            return response()->json(['success' => false, 'message' => 'Token tidak valid atau sudah kadaluarsa'], 401);
        }

        $userId = $apiToken->user_id;

        $data = $request->validate([
            'lat' => 'required|numeric',
            'lng' => 'required|numeric',
            'timestamp' => 'nullable|date',
            'accuracy' => 'nullable|numeric',
            'speed' => 'nullable|numeric',
        ]);

        $booking = BookingBarang::find($id);
        if (!$booking) {
            return response()->json(['success' => false, 'message' => 'Booking tidak ditemukan'], 404);
        }

        // Basic driver check: if driver_id is set ensure it matches; otherwise assign driver
        if ($booking->driver_id && intval($booking->driver_id) !== intval($userId)) {
            return response()->json(['success' => false, 'message' => 'Anda bukan driver booking ini'], 403);
        }

        if (!$booking->driver_id) {
            $booking->driver_id = $userId;
        }

        // Update last known location
        $booking->last_lat = $data['lat'];
        $booking->last_lng = $data['lng'];
        $booking->last_location_at = $data['timestamp'] ?? now();
        
        // Auto-update status based on location and time
        if ($booking->status === 'paid' || $booking->status === 'confirmed') {
            // If booking is paid/confirmed and driver starts moving, set to menuju_penjemputan
            $booking->status = 'menuju_penjemputan';
        }
        
        $booking->save();

        // Log location update
        Log::info('booking_barang.location.update', [
            'booking_id' => $booking->id,
            'lat' => $data['lat'],
            'lng' => $data['lng'],
            'timestamp' => $data['timestamp'] ?? now()->toIso8601String(),
            'accuracy' => $data['accuracy'] ?? null,
            'speed' => $data['speed'] ?? null,
            'status' => $booking->status,
        ]);

        // Get pickup coordinates from ride's origin location
        $pickupLat = null;
        $pickupLng = null;
        
        $booking->load('ride.originLocation');
        if ($booking->ride && $booking->ride->originLocation) {
            $pickupLat = $booking->ride->originLocation->latitude;
            $pickupLng = $booking->ride->originLocation->longitude;
        }

        // If pickup position exists, compute distance and update status
        if ($pickupLat && $pickupLng) {
            $dist = $this->haversineDistance($pickupLat, $pickupLng, $data['lat'], $data['lng']);
            
            Log::info('booking_barang.location.distance_check', [
                'booking_id' => $booking->id,
                'distance_meters' => round($dist, 2),
                'status' => $booking->status,
                'pickup_lat' => $pickupLat,
                'pickup_lng' => $pickupLng,
                'driver_lat' => $data['lat'],
                'driver_lng' => $data['lng']
            ]);
            
            // Auto-update status to 'sudah_di_penjemputan' if driver arrives at pickup location (within 10m)
            if ($booking->status === 'menuju_penjemputan' && $dist <= 10) {
                $booking->status = 'sudah_di_penjemputan';
                $booking->save();
                
                Log::info('booking_barang.status.auto_update', [
                    'booking_id' => $booking->id,
                    'new_status' => 'sudah_di_penjemputan',
                    'reason' => 'driver_arrived_at_pickup',
                    'distance' => round($dist, 2)
                ]);
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Lokasi berhasil diupdate',
            'data' => [
                'booking_id' => $booking->id,
                'status' => $booking->status,
                'last_location' => [
                    'lat' => $booking->last_lat,
                    'lng' => $booking->last_lng,
                    'timestamp' => $booking->last_location_at,
                ]
            ]
        ], 200);
    }

    public function show(Request $request, $id)
    {
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json(['success' => false, 'message' => 'Token tidak ditemukan'], 401);
        }

        $apiToken = ApiToken::where('token', hash('sha256', $bearer))->where('expires_at', '>', now())->first();
        if (!$apiToken) {
            return response()->json(['success' => false, 'message' => 'Token tidak valid atau sudah kadaluarsa'], 401);
        }

        $booking = BookingBarang::find($id);
        if (!$booking) {
            return response()->json(['success' => false, 'message' => 'Booking tidak ditemukan'], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'booking_id' => $booking->id,
                'status' => $booking->status,
                'last_location' => [
                    'lat' => $booking->last_lat,
                    'lng' => $booking->last_lng,
                    'timestamp' => $booking->last_location_at,
                ]
            ]
        ], 200);
    }

    private function haversineDistance($lat1, $lon1, $lat2, $lon2)
    {
        $earthRadius = 6371000; // meters
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat / 2) * sin($dLat / 2) +
            cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
            sin($dLon / 2) * sin($dLon / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return $earthRadius * $c;
    }
}
