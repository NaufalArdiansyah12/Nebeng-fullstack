<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\CustomerRating;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class CustomerRatingController extends Controller
{
    /**
     * Submit customer rating (mitra rates customer)
     */
    public function store(Request $request)
    {
        // Log incoming request for debugging
        \Log::info('Customer Rating Request', $request->all());

        $validator = Validator::make($request->all(), [
            'booking_id' => 'required|integer',
            'customer_id' => 'required|integer|exists:users,id',
            'mitra_id' => 'required|integer|exists:users,id',
            'rating' => 'required|integer|min:1|max:5',
            'feedback' => 'nullable|string',
            'proof_image' => 'nullable|image|max:2048', // max 2MB
        ]);

        if ($validator->fails()) {
            \Log::error('Customer Rating Validation Failed', [
                'errors' => $validator->errors()->toArray(),
                'input' => $request->all()
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Check if rating already exists for this booking
        $existingRating = CustomerRating::where('booking_id', $request->booking_id)
            ->where('mitra_id', $request->mitra_id)
            ->first();

        if ($existingRating) {
            return response()->json([
                'success' => false,
                'message' => 'Rating sudah pernah diberikan untuk booking ini',
            ], 400);
        }

        // Handle proof image upload
        $proofImagePath = null;
        if ($request->hasFile('proof_image')) {
            $file = $request->file('proof_image');
            $filename = 'customer_rating_' . time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
            $proofImagePath = $file->storeAs('customer_ratings', $filename, 'public');
        }

        // Create rating
        $rating = CustomerRating::create([
            'booking_id' => $request->booking_id,
            'booking_type' => 'motor', // default, could be dynamic
            'mitra_id' => $request->mitra_id,
            'customer_id' => $request->customer_id,
            'rating' => $request->rating,
            'feedback' => $request->feedback,
            'proof_image' => $proofImagePath,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Rating berhasil dikirim',
            'data' => $rating,
        ], 201);
    }

    /**
     * Get customer rating for a booking
     */
    public function getByBooking($bookingId)
    {
        \Log::info('CustomerRating: Getting by booking ID', ['booking_id' => $bookingId]);
        
        $rating = CustomerRating::where('booking_id', $bookingId)
            ->with(['mitra', 'customer'])
            ->first();

        if (!$rating) {
            \Log::info('CustomerRating: Not found for booking ID', ['booking_id' => $bookingId]);
            return response()->json([
                'success' => false,
                'message' => 'Rating tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $rating,
        ]);
    }

    /**
     * Get customer rating by booking number
     */
    public function getByBookingNumber($bookingNumber)
    {
        \Log::info('CustomerRating: Getting by booking number', ['booking_number' => $bookingNumber]);
        
        // Find booking by booking_number first
        $booking = \App\Models\Booking::where('booking_number', $bookingNumber)->first();
        
        if (!$booking) {
            \Log::info('CustomerRating: Booking not found', ['booking_number' => $bookingNumber]);
            return response()->json([
                'success' => false,
                'message' => 'Booking tidak ditemukan',
            ], 404);
        }

        $rating = CustomerRating::where('booking_id', $booking->id)
            ->with(['mitra', 'customer'])
            ->first();

        if (!$rating) {
            \Log::info('CustomerRating: Rating not found for booking', [
                'booking_number' => $bookingNumber,
                'booking_id' => $booking->id
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Rating tidak ditemukan',
            ], 404);
        }

        \Log::info('CustomerRating: Found rating', ['rating_id' => $rating->id]);
        
        return response()->json([
            'success' => true,
            'data' => $rating,
        ]);
    }

    /**
     * Get all ratings for a customer
     */
    public function getByCustomer($customerId)
    {
        $ratings = CustomerRating::where('customer_id', $customerId)
            ->with(['mitra'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $ratings,
        ]);
    }

    /**
     * Get all ratings given by a mitra
     */
    public function getByMitra($mitraId)
    {
        $ratings = CustomerRating::where('mitra_id', $mitraId)
            ->with(['customer'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $ratings,
        ]);
    }
}
