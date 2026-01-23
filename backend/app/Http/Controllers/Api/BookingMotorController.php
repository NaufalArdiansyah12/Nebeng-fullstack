<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class BookingMotorController extends Controller
{
    public function store(Request $request, $ride = null)
    {
        // Expect $ride to be an instance of \App\Models\Ride
        if (!$ride) {
            $ride = \App\Models\Ride::find($request->ride_id);
            if (!$ride) {
                return response()->json(['success' => false, 'message' => 'Ride not found'], 404);
            }
        }

        $seats = $request->seats ?? 1;
        $bagasiRequested = intval($request->jumlah_bagasi ?? 0);

        // Handle photo upload for motor bookings
        $photoPath = null;
        if ($request->hasFile('photo')) {
            try {
                $photo = $request->file('photo');
                $filename = 'uploads/' . time() . '_' . uniqid() . '.' . $photo->getClientOriginalExtension();
                Storage::disk('public')->put($filename, file_get_contents($photo));
                $photoPath = '/storage/' . $filename;
            } catch (\Throwable $__e) {
                Log::warning('Failed to store booking photo (motor)', ['error' => $__e->getMessage()]);
            }
        }

        // Create booking record for motor
        $bookingNumber = 'FR-' . time() . '-' . rand(100, 999);
        $booking = \App\Models\Booking::create([
            'ride_id' => $ride->id,
            'user_id' => $request->user_id,
            'booking_number' => $bookingNumber,
            'seats' => $seats,
            'status' => 'pending',
            'meta' => null,
            'photo' => $photoPath,
            'weight' => $request->weight ?? null,
            'description' => $request->description ?? null,
        ]);
    
        // decrement bagasi if requested
        if ($bagasiRequested > 0) {
            try {
                DB::transaction(function () use ($ride, $bagasiRequested) {
                    $ride->refresh();
                    $ride->decrement('jumlah_bagasi', $bagasiRequested);
                    $ride->refresh();
                    if (intval($ride->jumlah_bagasi ?? 0) <= 0) {
                        $ride->status = 'inactive';
                        $ride->save();
                    }
                });
            } catch (\Exception $e) {
                Log::warning('Failed to decrement jumlah_bagasi for motor (controller)', ['error' => $e->getMessage(), 'ride_id' => $ride->id]);
            }
        }

        Log::info('BookingMotor created', ['booking_id' => $booking->id, 'booking_number' => $bookingNumber]);

        return response()->json(['success' => true, 'data' => $booking], 201);
    }
}
