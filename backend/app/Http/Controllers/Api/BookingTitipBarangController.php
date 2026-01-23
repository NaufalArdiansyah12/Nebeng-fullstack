<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class BookingTitipBarangController extends Controller
{
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'ride_id' => 'required|integer',
            'user_id' => 'required|integer',
            'seats' => 'nullable|integer|min:1',
            'jumlah_bagasi' => 'nullable|integer|min:0',
            'photo' => 'nullable|image|mimes:jpeg,jpg,png|max:5120',
            'weight' => 'nullable|string|max:50',
            'description' => 'nullable|string|max:1000',
            'penerima' => 'nullable|string|max:255',
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
            $filename = 'uploads/' . time() . '_' . uniqid() . '.' . $photo->getClientOriginalExtension();
            Storage::disk('public')->put($filename, file_get_contents($photo));
            $photoPath = '/storage/' . $filename;
        }

        $bookingNumber = 'FT-' . time() . '-' . rand(100, 999);

        $bagasiRequested = intval($request->jumlah_bagasi ?? 0);

        // Check bagasi availability before creating booking
        if ($bagasiRequested > 0) {
            $availableBagasi = intval($ride->jumlah_bagasi ?? 0);
            if ($availableBagasi < $bagasiRequested) {
                return response()->json([
                    'success' => false,
                    'message' => 'Not enough bagasi available',
                    'available_bagasi' => $availableBagasi,
                ], 409);
            }
        }

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
            'penerima' => $request->penerima,
        ]);

        // decrement bagasi for titip booking
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
                Log::warning('Failed to decrement jumlah_bagasi for titip (separate controller)', ['error' => $e->getMessage(), 'ride_id' => $ride->id]);
            }
        }

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
