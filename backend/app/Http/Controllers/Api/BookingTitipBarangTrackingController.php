<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BookingTitipBarang;
use App\Models\ApiToken;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class BookingTitipBarangTrackingController extends Controller
{
    public function show(Request $request, $id)
    {
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json(['success' => false, 'message' => 'Token tidak ditemukan'], 401);
        }

        $apiToken = ApiToken::where('token', hash('sha256', $bearer))
            ->where('expires_at', '>', now())
            ->first();
            
        if (!$apiToken) {
            return response()->json(['success' => false, 'message' => 'Token tidak valid atau sudah kadaluarsa'], 401);
        }

        $booking = BookingTitipBarang::with(['ride.originLocation', 'ride.destinationLocation', 'user'])
            ->find($id);
        
        if (!$booking) {
            return response()->json(['success' => false, 'message' => 'Booking tidak ditemukan'], 404);
        }

        $trackingData = [
            'booking_id' => $booking->id,
            'booking_number' => $booking->booking_number,
            'status' => $booking->status,
            'last_location' => [
                'lat' => $booking->last_lat,
                'lng' => $booking->last_lng,
                'timestamp' => $booking->last_location_at,
            ],
            'customer' => [
                'id' => $booking->user->id ?? null,
                'name' => $booking->user->name ?? null,
            ],
        ];

        if ($booking->ride) {
            $trackingData['ride'] = [
                'id' => $booking->ride->id,
                'origin' => $booking->ride->originLocation ? [
                    'name' => $booking->ride->originLocation->name,
                    'lat' => $booking->ride->originLocation->latitude,
                    'lng' => $booking->ride->originLocation->longitude,
                ] : null,
                'destination' => $booking->ride->destinationLocation ? [
                    'name' => $booking->ride->destinationLocation->name,
                    'lat' => $booking->ride->destinationLocation->latitude,
                    'lng' => $booking->ride->destinationLocation->longitude,
                ] : null,
                'departure_date' => $booking->ride->departure_date,
                'departure_time' => $booking->ride->departure_time,
            ];
        }

        return response()->json([
            'success' => true,
            'data' => $trackingData,
        ], 200);
    }

    public function startTrip(Request $request, $id)
    {
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json(['success' => false, 'message' => 'Token tidak ditemukan'], 401);
        }

        $apiToken = ApiToken::where('token', hash('sha256', $bearer))->where('expires_at', '>', now())->first();
        if (!$apiToken) {
            return response()->json(['success' => false, 'message' => 'Token tidak valid'], 401);
        }

        $booking = BookingTitipBarang::find($id);
        if (!$booking) {
            return response()->json(['success' => false, 'message' => 'Booking tidak ditemukan'], 404);
        }

        if ($booking->status !== 'sudah_di_penjemputan') {
            return response()->json(['success' => false, 'message' => 'Status tidak valid untuk memulai perjalanan'], 400);
        }

        $booking->status = 'menuju_tujuan';
        $booking->save();

        return response()->json([
            'success' => true,
            'message' => 'Perjalanan dimulai',
            'data' => ['status' => $booking->status]
        ], 200);
    }

    public function completeTrip(Request $request, $id)
    {
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json(['success' => false, 'message' => 'Token tidak ditemukan'], 401);
        }

        $apiToken = ApiToken::where('token', hash('sha256', $bearer))->where('expires_at', '>', now())->first();
        if (!$apiToken) {
            return response()->json(['success' => false, 'message' => 'Token tidak valid'], 401);
        }

        $booking = BookingTitipBarang::find($id);
        if (!$booking) {
            return response()->json(['success' => false, 'message' => 'Booking tidak ditemukan'], 404);
        }

        if ($booking->status !== 'menuju_tujuan' && $booking->status !== 'sudah_sampai_tujuan') {
            return response()->json(['success' => false, 'message' => 'Status tidak valid untuk menyelesaikan perjalanan'], 400);
        }

        $booking->status = 'selesai';
        $booking->save();

        return response()->json([
            'success' => true,
            'message' => 'Perjalanan selesai',
            'data' => ['status' => $booking->status]
        ], 200);
    }
}
