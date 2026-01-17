<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class BookingTitipBarangController extends Controller
{
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'ride_id' => 'required|integer',
            'user_id' => 'required|integer',
            'seats' => 'nullable|integer|min:1',
            'photo' => 'nullable|image|mimes:jpeg,jpg,png|max:5120',
            'weight' => 'nullable|string|max:50',
            'description' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        // locate ride (supports polymorphic ride types)
        $ride = \App\Models\Ride::find($request->ride_id);
        $isBarang = false;
        if (!$ride) {
            $ride = \App\Models\BarangRide::find($request->ride_id);
            if ($ride) $isBarang = true;
        }

        if (!$ride) {
            return response()->json(['success' => false, 'message' => 'Ride not found'], 404);
        }

        // Handle photo upload
        $photoPath = null;
        if ($request->hasFile('photo')) {
            $photo = $request->file('photo');
            $filename = time() . '_' . uniqid() . '.' . $photo->getClientOriginalExtension();
            $photo->storeAs('public/uploads', $filename);
            $photoPath = '/storage/uploads/' . $filename;
        }

        $bookingNumber = 'FT-' . time() . '-' . rand(100, 999);

        $booking = \App\Models\BookingTitipBarang::create([
            'ride_id' => $ride->id,
            'user_id' => $request->user_id,
            'booking_number' => $bookingNumber,
            'seats' => $request->seats ?? 1,
            'status' => 'pending',
            'meta' => null,
            'photo' => $photoPath,
            'weight' => $request->weight,
            'description' => $request->description,
        ]);

        Log::info('BookingTitipBarang created', ['id' => $booking->id, 'booking_number' => $bookingNumber]);

        return response()->json(['success' => true, 'data' => $booking], 201);
    }

    public function show($id)
    {
        $b = \App\Models\BookingTitipBarang::with(['ride', 'user'])->find($id);
        if (!$b) {
            return response()->json(['success' => false, 'message' => 'Booking not found'], 404);
        }
        return response()->json(['success' => true, 'data' => $b]);
    }
}
