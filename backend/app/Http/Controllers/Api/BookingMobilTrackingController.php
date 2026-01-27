<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\BookingMobil;
use App\Models\BookingBarang;
use App\Models\BookingTitipBarang;
use App\Models\ApiToken;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class BookingMobilTrackingController extends Controller
{
    /**
     * Get comprehensive tracking info for a booking
     * Includes: location, status, estimated times, driver info
     */
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

        $userId = $apiToken->user_id;

        // Try to find booking in all tables
        $booking = $this->findBooking($id, $userId);
        
        if (!$booking) {
            return response()->json(['success' => false, 'message' => 'Booking tidak ditemukan'], 404);
        }

        // Auto-transition to in_progress when departure time has passed
        try {
            if ($booking->ride) {
                $ride = $booking->ride;
                $departureDate = $ride->departure_date ?? null;
                $departureTime = $ride->departure_time ?? null;

                if ($departureDate && $departureTime) {
                    $dtString = $departureDate . ' ' . $departureTime;
                    $departureDT = \Carbon\Carbon::parse($dtString);
                    if ($departureDT->lte(now())) {
                        $current = strtolower((string) ($booking->status ?? ''));
                        if (in_array($current, ['paid', 'confirmed', 'pending'])) {
                            $booking->status = 'menuju_penjemputan';
                            $booking->trip_started_at = $booking->trip_started_at ?? now();
                            $booking->save();
                            Log::info('Auto set booking to menuju_penjemputan based on departure time', ['booking_id' => $booking->id]);
                        }
                    }
                }
            }
        } catch (\Exception $e) {
            Log::warning('Failed to auto-update booking status based on departure', ['error' => $e->getMessage(), 'booking_id' => $booking->id]);
        }

        // Build tracking response
        $trackingData = [
            'booking_id' => $booking->id,
            'booking_number' => $booking->booking_number ?? null,
            'status' => $booking->status ?? 'pending',
        ];

        // Location data
        if ($booking->last_lat && $booking->last_lng) {
            $trackingData['location'] = [
                'lat' => (float) $booking->last_lat,
                'lng' => (float) $booking->last_lng,
                'timestamp' => $booking->last_location_at,
                'accuracy' => $booking->location_accuracy ?? null,
            ];
        } else {
            $trackingData['location'] = null;
        }

        // Ride and route information
        if ($booking->ride) {
            $ride = $booking->ride;
            
            $trackingData['ride'] = [
                'id' => $ride->id,
                'departure_date' => $ride->departure_date,
                'departure_time' => $ride->departure_time,
                'arrival_time' => $ride->arrival_time ?? null,
                'origin' => $ride->originLocation ? [
                    'id' => $ride->originLocation->id,
                    'name' => $ride->originLocation->name,
                    'address' => $ride->originLocation->address ?? null,
                    'lat' => $ride->originLocation->lat ?? null,
                    'lng' => $ride->originLocation->lng ?? null,
                ] : null,
                'destination' => $ride->destinationLocation ? [
                    'id' => $ride->destinationLocation->id,
                    'name' => $ride->destinationLocation->name,
                    'address' => $ride->destinationLocation->address ?? null,
                    'lat' => $ride->destinationLocation->lat ?? null,
                    'lng' => $ride->destinationLocation->lng ?? null,
                ] : null,
            ];

            // Driver information
            if ($ride->user) {
                $driver = $ride->user;
                $trackingData['driver'] = [
                    'id' => $driver->id,
                    'name' => $driver->name,
                    'phone' => $driver->phone ?? $driver->no_telepon ?? null,
                    'photo_url' => $driver->photo_url ?? null,
                    'rating' => $driver->rating ?? null,
                ];
            }

            // Vehicle information
            if ($ride->kendaraanMitra) {
                $vehicle = $ride->kendaraanMitra;
                $trackingData['vehicle'] = [
                    'id' => $vehicle->id,
                    'type' => $vehicle->vehicle_type ?? 'mobil',
                    'brand' => $vehicle->brand ?? null,
                    'model' => $vehicle->model ?? null,
                    'color' => $vehicle->color ?? null,
                    'plate_number' => $vehicle->plate_number ?? null,
                ];
            }

            // Calculate tracking status based on time
            try {
                $departureDateTime = \Carbon\Carbon::parse($ride->departure_date . ' ' . $ride->departure_time);
                $now = \Carbon\Carbon::now();
                
                if ($booking->status === 'completed' || $booking->status === 'done') {
                    $trackingData['tracking_status'] = 'completed';
                } elseif ($booking->status === 'cancelled') {
                    $trackingData['tracking_status'] = 'cancelled';
                } elseif (in_array($booking->status, ['menuju_penjemputan', 'sudah_di_penjemputan', 'menuju_tujuan', 'sudah_sampai_tujuan'])) {
                    $trackingData['tracking_status'] = $booking->status;
                    $trackingData['elapsed_minutes'] = $now->diffInMinutes($departureDateTime);
                } elseif ($departureDateTime->diffInHours($now) <= 1) {
                    $trackingData['tracking_status'] = 'waiting';
                    $trackingData['countdown'] = [
                        'total_seconds' => $departureDateTime->diffInSeconds($now),
                        'hours' => floor($departureDateTime->diffInMinutes($now) / 60),
                        'minutes' => $departureDateTime->diffInMinutes($now) % 60,
                    ];
                } else {
                    $trackingData['tracking_status'] = 'scheduled';
                    $trackingData['countdown'] = [
                        'days' => $departureDateTime->diffInDays($now),
                        'hours' => $departureDateTime->diffInHours($now) % 24,
                        'minutes' => $departureDateTime->diffInMinutes($now) % 60,
                        'total_seconds' => $departureDateTime->diffInSeconds($now),
                    ];
                }
            } catch (\Exception $e) {
                Log::warning('Failed to calculate tracking status', ['error' => $e->getMessage()]);
                $trackingData['tracking_status'] = 'unknown';
            }
        }

        // Waiting time information

        return response()->json(['success' => true, 'data' => $trackingData]);
    }

    /**
     * Start trip - driver marks as started
     */
    public function startTrip(Request $request, $id)
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

        $userId = $apiToken->user_id;
        $booking = $this->findBooking($id, $userId);
        
        if (!$booking) {
            return response()->json(['success' => false, 'message' => 'Booking tidak ditemukan'], 404);
        }

        // Verify user is the driver
        if ($booking->ride && $booking->ride->user_id !== $userId) {
            return response()->json(['success' => false, 'message' => 'Anda bukan driver untuk booking ini'], 403);
        }

        $booking->status = 'menuju_penjemputan';
        $booking->trip_started_at = now();
        $booking->save();

        Log::info('Trip started (menuju_penjemputan)', ['booking_id' => $booking->id, 'driver_id' => $userId]);

        return response()->json(['success' => true, 'data' => $booking]);
    }

    /**
     * Complete trip - driver marks as completed
     */
    public function completeTrip(Request $request, $id)
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

        $userId = $apiToken->user_id;
        $booking = $this->findBooking($id, $userId);
        
        if (!$booking) {
            return response()->json(['success' => false, 'message' => 'Booking tidak ditemukan'], 404);
        }

        // Verify user is the driver
        if ($booking->ride && $booking->ride->user_id !== $userId) {
            return response()->json(['success' => false, 'message' => 'Anda bukan driver untuk booking ini'], 403);
        }

        $booking->status = 'completed';
        $booking->trip_completed_at = now();
        $booking->save();

        Log::info('Trip completed', ['booking_id' => $booking->id, 'driver_id' => $userId]);

        return response()->json(['success' => true, 'data' => $booking]);
    }

    /**
     * Helper to find booking across all tables
     */
    private function findBooking($id, $userId)
    {
        // Try motor booking
        $booking = BookingMobil::with(['ride.originLocation', 'ride.destinationLocation', 'ride.kendaraanMitra', 'ride.user'])
            ->find($id);
        if ($booking && ($booking->user_id === $userId || ($booking->ride && $booking->ride->user_id === $userId))) {
            return $booking;
        }

        // Try mobil booking
        $booking = BookingMobil::with(['ride.originLocation', 'ride.destinationLocation', 'ride.kendaraanMitra', 'ride.user'])
            ->find($id);
        if ($booking && ($booking->user_id === $userId || ($booking->ride && $booking->ride->user_id === $userId))) {
            return $booking;
        }

        // Try barang booking
        $booking = BookingBarang::with(['ride.originLocation', 'ride.destinationLocation', 'ride.kendaraanMitra', 'ride.user'])
            ->find($id);
        if ($booking && ($booking->user_id === $userId || ($booking->ride && $booking->ride->user_id === $userId))) {
            return $booking;
        }

        // Try titip booking
        $booking = BookingTitipBarang::with(['ride.originLocation', 'ride.destinationLocation', 'ride.kendaraanMitra', 'ride.user'])
            ->find($id);
        if ($booking && ($booking->user_id === $userId || ($booking->ride && $booking->ride->user_id === $userId))) {
            return $booking;
        }

        return null;
    }
}
