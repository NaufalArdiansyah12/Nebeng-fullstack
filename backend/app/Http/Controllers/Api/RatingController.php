<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Rating;
use App\Models\User;
use App\Models\Booking;
use App\Models\BookingMobil;
use App\Models\BookingBarang;
use App\Models\BookingTitipBarang;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class RatingController extends Controller
{
    /**
     * Submit a rating for a driver
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'booking_id' => 'required|integer',
            'booking_type' => 'required|in:motor,mobil,barang,titip_barang',
            'driver_id' => 'required|exists:users,id',
            'rating' => 'required|integer|min:1|max:5',
            'review' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Get authenticated user
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized',
            ], 401);
        }

        $hashed = hash('sha256', $bearer);
        $apiToken = \App\Models\ApiToken::where('token', $hashed)->first();
        
        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid token',
            ], 401);
        }

        // Verify booking belongs to user and is completed
        $booking = $this->getBooking($request->booking_id, $request->booking_type);
        
        if (!$booking) {
            return response()->json([
                'success' => false,
                'message' => 'Booking not found',
            ], 404);
        }

        if ($booking->user_id != $apiToken->user_id) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized - This is not your booking',
            ], 403);
        }

        if ($booking->status != 'completed') {
            return response()->json([
                'success' => false,
                'message' => 'Can only rate completed bookings',
            ], 400);
        }

        // Check if already rated
        $existingRating = Rating::where('booking_id', $request->booking_id)
            ->where('booking_type', $request->booking_type)
            ->where('user_id', $apiToken->user_id)
            ->first();

        if ($existingRating) {
            return response()->json([
                'success' => false,
                'message' => 'You have already rated this booking',
            ], 400);
        }

        try {
            DB::beginTransaction();

            // Create rating
            $rating = Rating::create([
                'booking_id' => $request->booking_id,
                'booking_type' => $request->booking_type,
                'user_id' => $apiToken->user_id,
                'driver_id' => $request->driver_id,
                'rating' => $request->rating,
                'review' => $request->review,
            ]);

            // Update driver's average rating
            $this->updateDriverRating($request->driver_id);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Rating submitted successfully',
                'data' => $rating->load(['user', 'driver']),
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Failed to submit rating: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get rating for a specific booking
     */
    public function show(Request $request, $bookingId)
    {
        $bookingType = $request->query('booking_type', 'motor');

        $rating = Rating::with(['user', 'driver'])
            ->where('booking_id', $bookingId)
            ->where('booking_type', $bookingType)
            ->first();

        if (!$rating) {
            return response()->json([
                'success' => false,
                'message' => 'Rating not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $rating,
        ]);
    }

    /**
     * Get all ratings for a driver
     */
    public function getDriverRatings(Request $request, $driverId)
    {
        $ratings = Rating::with(['user'])
            ->where('driver_id', $driverId)
            ->orderBy('created_at', 'desc')
            ->get();

        $driver = User::find($driverId);

        if (!$driver) {
            return response()->json([
                'success' => false,
                'message' => 'Driver not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'driver' => $driver,
                'ratings' => $ratings,
                'average_rating' => $driver->average_rating,
                'total_ratings' => $driver->total_ratings,
            ],
        ]);
    }

    /**
     * Get booking by ID and type
     */
    private function getBooking($bookingId, $bookingType)
    {
        switch ($bookingType) {
            case 'motor':
                return Booking::find($bookingId);
            case 'mobil':
                return BookingMobil::find($bookingId);
            case 'barang':
                return BookingBarang::find($bookingId);
            case 'titip_barang':
                return BookingTitipBarang::find($bookingId);
            default:
                return null;
        }
    }

    /**
     * Update driver's average rating and total count
     */
    private function updateDriverRating($driverId)
    {
        $ratings = Rating::where('driver_id', $driverId)->get();
        $totalRatings = $ratings->count();
        $averageRating = $totalRatings > 0 ? $ratings->avg('rating') : null;

        User::where('id', $driverId)->update([
            'average_rating' => $averageRating,
            'total_ratings' => $totalRatings,
        ]);
    }
}
