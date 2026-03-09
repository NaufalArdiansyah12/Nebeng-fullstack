<?php

namespace App\Http\Controllers\Api\V1\Mitra;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\BookingMobil;
use App\Models\BookingBarang;
use App\Models\BookingTitipBarang;
use Illuminate\Http\Request;

class CompleteTripController extends Controller
{
    /**
     * Complete trip by driver (bypass QR scan)
     */
    public function completeByDriver(Request $request, $bookingType, $bookingId)
    {
        // Debug: Check all headers and token
        $authHeader = $request->header('Authorization');
        \Log::info('Complete trip - Headers debug', [
            'authorization_header' => $authHeader,
            'bearer_token' => $request->bearerToken(),
            'has_user' => $request->user() !== null,
        ]);
        
        // Get the model based on booking type
        $model = $this->getBookingModel($bookingType);
        
        if (!$model) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid booking type',
            ], 400);
        }

        $booking = $model::where('ride_id', $bookingId)->first();
        
        if (!$booking) {
            \Log::info("Booking not found for ride_id: {$bookingId}");
            return response()->json([
                'success' => false,
                'message' => 'Booking not found',
            ], 404);
        }

        \Log::info("Booking found", [
            'booking_id' => $booking->id,
            'ride_id' => $booking->ride_id,
            'driver_id' => $booking->driver_id,
            'status' => $booking->status,
        ]);

        // Verify this booking belongs to the authenticated mitra
        $user = $request->user();
        \Log::info("User info", [
            'user_id' => $user ? $user->id : null,
            'user_role' => $user ? $user->role : null,
        ]);
        
        if (!$user || $booking->driver_id != $user->id) {
            \Log::warning("Unauthorized access", [
                'user_id' => $user ? $user->id : null,
                'booking_driver_id' => $booking->driver_id,
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized',
            ], 403);
        }

        // Check if booking is in correct status
        if ($booking->status !== 'sudah_sampai_tujuan') {
            return response()->json([
                'success' => false,
                'message' => 'Booking status must be "sudah_sampai_tujuan" to complete',
                'current_status' => $booking->status,
            ], 400);
        }

        // Update status to completed
        $booking->status = 'completed';
        $booking->save();

        return response()->json([
            'success' => true,
            'message' => 'Trip completed successfully',
            'data' => [
                'booking_id' => $booking->id,
                'status' => $booking->status,
            ],
        ]);
    }

    /**
     * Get booking model class based on type
     */
    private function getBookingModel($type)
    {
        $models = [
            'motor' => Booking::class,
            'mobil' => BookingMobil::class,
            'barang' => BookingBarang::class,
            'titip-barang' => BookingTitipBarang::class,
        ];

        return $models[$type] ?? null;
    }
}
