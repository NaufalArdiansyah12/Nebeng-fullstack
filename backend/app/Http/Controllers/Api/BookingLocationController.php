<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\ApiToken;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class BookingLocationController extends Controller
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

        $booking = Booking::find($id);
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
            // If booking is paid/confirmed and driver starts moving, set to in_progress
            $booking->status = 'in_progress';
        }
        
        $booking->save();

        // Log location update (realtime broadcasting removed)
        Log::info('booking.location.update', [
            'booking_id' => $booking->id,
            'lat' => $data['lat'],
            'lng' => $data['lng'],
            'timestamp' => $data['timestamp'] ?? now()->toIso8601String(),
            'accuracy' => $data['accuracy'] ?? null,
            'speed' => $data['speed'] ?? null,
            'status' => $booking->status,
        ]);

        // If pickup position exists, compute distance and update status or waiting
        if ($booking->pickup_lat && $booking->pickup_lng) {
            $dist = $this->haversineDistance($booking->pickup_lat, $booking->pickup_lng, $data['lat'], $data['lng']);
            // If within 20m and waiting_start_at not set -> waiting started
            if ($dist <= 20 && !$booking->waiting_start_at) {
                $booking->waiting_start_at = now();
                $booking->save();
                Log::info('booking.waiting.started', ['booking_id' => $booking->id, 'started_at' => $booking->waiting_start_at->toIso8601String()]);
            }

            // If moved >100m from pickup and status is 'menunggu' -> set to 'sedang_dalam_perjalanan'
            if ($dist > 100 && ($booking->status === 'menunggu' || $booking->status === 'pending')) {
                $booking->status = 'sedang_dalam_perjalanan';
                $booking->save();
                Log::info('booking.status.changed', ['booking_id' => $booking->id, 'status' => 'sedang_dalam_perjalanan']);
            }
        }

        return response()->json(['success' => true]);
    }

    /**
     * Return latest known location for a booking.
     * Supports conditional GET via If-Modified-Since and If-None-Match.
     */
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

        $userId = $apiToken->user_id;

        $booking = Booking::find($id);
        if (!$booking) {
            return response()->json(['success' => false, 'message' => 'Booking tidak ditemukan'], 404);
        }

        // Only allow driver or booking owner to view location
        if (!($booking->user_id === $userId || intval($booking->driver_id) === intval($userId))) {
            return response()->json(['success' => false, 'message' => 'Anda tidak berhak melihat lokasi booking ini'], 403);
        }

        if (!$booking->last_location_at || !$booking->last_lat || !$booking->last_lng) {
            return response()->json(['success' => false, 'message' => 'Lokasi belum tersedia'], 204);
        }

        $lastModified = $booking->last_location_at instanceof \Illuminate\Support\Carbon ? $booking->last_location_at : \Carbon\Carbon::parse($booking->last_location_at);

        // ETag based on lat|lng|timestamp
        $etagSource = sprintf('%s|%s|%s', $booking->last_lat, $booking->last_lng, $lastModified->toIso8601String());
        $etag = '"' . md5($etagSource) . '"';

        // Check If-None-Match
        $ifNoneMatch = $request->header('If-None-Match');
        if ($ifNoneMatch && trim($ifNoneMatch) === $etag) {
            return response('', 304)->header('ETag', $etag)->header('Last-Modified', $lastModified->toRfc7231String());
        }

        // Check If-Modified-Since
        $ifModifiedSince = $request->header('If-Modified-Since');
        if ($ifModifiedSince) {
            try {
                $ims = \Carbon\Carbon::parse($ifModifiedSince);
                if ($lastModified->lessThanOrEqualTo($ims)) {
                    return response('', 304)->header('ETag', $etag)->header('Last-Modified', $lastModified->toRfc7231String());
                }
            } catch (\Exception $e) {
                // ignore invalid header
            }
        }

        $payload = [
            'lat' => (float) $booking->last_lat,
            'lng' => (float) $booking->last_lng,
            'timestamp' => $lastModified->toIso8601String(),
            'status' => $booking->status ?? null,
        ];

        // compute tracking activation: tracking window column removed;
        // enable tracking if scheduled time has passed or if no scheduled time provided
        $trackingActive = false;
        if (!$booking->scheduled_at) {
            $trackingActive = true;
        } else {
            try {
                if (now()->greaterThanOrEqualTo($booking->scheduled_at)) {
                    $trackingActive = true;
                }
            } catch (\Exception $e) {
                $trackingActive = false;
            }
        }

        $payload['tracking_active'] = $trackingActive;

        return response()->json(['success' => true, 'data' => $payload])
            ->header('ETag', $etag)
            ->header('Last-Modified', $lastModified->toRfc7231String());
    }

    private function haversineDistance($lat1, $lon1, $lat2, $lon2)
    {
        $earthRadius = 6371000; // meters
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat/2) * sin($dLat/2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon/2) * sin($dLon/2);
        $c = 2 * atan2(sqrt($a), sqrt(1-$a));
        return $earthRadius * $c;
    }
}
