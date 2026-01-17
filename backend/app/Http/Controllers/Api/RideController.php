<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ride;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class RideController extends Controller
{
    public function index(Request $request)
    {
        // If client requests mobil rides, fetch from CarRide (tebengan_mobil)
        if ($request->has('ride_type') && $request->ride_type === 'mobil') {
            $carQuery = \App\Models\CarRide::with(['user', 'originLocation', 'destinationLocation', 'kendaraanMitra'])
                ->where('status', 'active');

            // apply origin/destination/date filters if provided
            if ($request->has('origin_location_id')) {
                $carQuery->where('origin_location_id', $request->origin_location_id);
            }
            if ($request->has('destination_location_id')) {
                $carQuery->where('destination_location_id', $request->destination_location_id);
            }
            if ($request->has('date')) {
                $carQuery->whereDate('departure_date', $request->date);
            }

            $rides = $carQuery->orderBy('departure_date')
                ->orderBy('departure_time')
                ->get();

            // Log count to help debug missing mobil entries
            try {
                \Illuminate\Support\Facades\Log::info('Return mobil rides', ['count' => $rides->count()]);
            } catch (\Throwable $__e) {
                // ignore
            }

            return response()->json([
                'success' => true,
                'data' => $rides,
            ]);
        }

        // If client requests barang rides, fetch from BarangRide (tebengan_barang)
        if ($request->has('ride_type') && $request->ride_type === 'barang') {
            $barangQuery = \App\Models\BarangRide::with(['user', 'originLocation', 'destinationLocation', 'kendaraanMitra'])
                ->where('status', 'active');

            if ($request->has('origin_location_id')) {
                $barangQuery->where('origin_location_id', $request->origin_location_id);
            }
            if ($request->has('destination_location_id')) {
                $barangQuery->where('destination_location_id', $request->destination_location_id);
            }
            if ($request->has('date')) {
                $barangQuery->whereDate('departure_date', $request->date);
            }

            $rides = $barangQuery->orderBy('departure_date')
                ->orderBy('departure_time')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $rides,
            ]);
        }

        $query = Ride::with(['user', 'originLocation', 'destinationLocation', 'carRide'])
            ->where('status', 'active');

        // Filter by origin location
        if ($request->has('origin_location_id')) {
            $query->where('origin_location_id', $request->origin_location_id);
        }

        // Filter by destination location
        if ($request->has('destination_location_id')) {
            $query->where('destination_location_id', $request->destination_location_id);
        }

        // Filter by date
        if ($request->has('date')) {
            $query->whereDate('departure_date', $request->date);
        }

        // Filter by ride type (motor/mobil)
        if ($request->has('ride_type')) {
            $query->where('ride_type', $request->ride_type);
        }

        // If user_id is provided, exclude rides already booked by that user (unless booking was cancelled)
        if ($request->has('user_id')) {
            $userId = $request->user_id;
            $query->whereDoesntHave('bookings', function ($q) use ($userId) {
                $q->where('user_id', $userId)
                  ->where('status', '!=', 'cancelled');
            });
        }

        $rides = $query->orderBy('departure_date')
            ->orderBy('departure_time')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $rides,
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'origin_location_id' => 'required|exists:locations,id',
            'destination_location_id' => 'required|exists:locations,id',
            'departure_date' => 'required|date|after_or_equal:today',
            'departure_time' => 'required',
            'ride_type' => 'required|in:motor,mobil,barang',
            'service_type' => 'required|in:tebengan,barang,both',
            'price' => 'required|numeric|min:0',
            'bagasi_capacity' => 'nullable|integer|min:0',
            'kendaraan_mitra_id' => 'nullable|exists:kendaraan_mitra,id',
            'available_seats' => 'nullable|integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Get authenticated user ID from bearer token
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

        Log::info('Ride create requested', ['payload' => $request->all(), 'user_id' => $apiToken->user_id]);

        try {
            $ride = DB::transaction(function () use ($request, $apiToken) {
                // For motor rides we keep using the Ride model (tebengan_motor).
                if ($request->ride_type === 'motor') {
                    $r = Ride::create([
                        'user_id' => $apiToken->user_id,
                        'origin_location_id' => $request->origin_location_id,
                        'destination_location_id' => $request->destination_location_id,
                        'departure_date' => $request->departure_date,
                        'departure_time' => $request->departure_time,
                        'ride_type' => $request->ride_type,
                        'service_type' => $request->service_type,
                        'price' => $request->price,
                        'kendaraan_mitra_id' => $request->kendaraan_mitra_id ?? null,
                        'available_seats' => $request->available_seats ?? 1,
                        'bagasi_capacity' => $request->bagasi_capacity ?? null,
                        'status' => 'active',
                    ]);

                    return $r;
                }
                // For mobil rides, persist into tebengan_mobil via CarRide model.
                // Note: vehicle-specific columns were removed from `tebengan_mobil`
                // to avoid duplicated data (we store vehicle info in `kendaraan_mitra`).
                // Do NOT attempt to insert vehicle_name/plate/brand/type/color here.
                if ($request->ride_type === 'mobil') {
                    $car = \App\Models\CarRide::create([
                        'user_id' => $apiToken->user_id,
                        'origin_location_id' => $request->origin_location_id,
                        'destination_location_id' => $request->destination_location_id,
                        'departure_date' => $request->departure_date,
                        'departure_time' => $request->departure_time,
                        'ride_type' => $request->ride_type,
                        'service_type' => $request->service_type,
                        'price' => $request->price,
                        'kendaraan_mitra_id' => $request->kendaraan_mitra_id ?? null,
                        'available_seats' => $request->available_seats ?? 1,
                        'bagasi_capacity' => $request->bagasi_capacity ?? null,
                        'status' => 'active',
                    ]);

                    return $car;
                }

                // For barang rides, persist into tebengan_barang via BarangRide model.
                if ($request->ride_type === 'barang') {
                    $barang = \App\Models\BarangRide::create([
                        'user_id' => $apiToken->user_id,
                        'origin_location_id' => $request->origin_location_id,
                        'destination_location_id' => $request->destination_location_id,
                        'departure_date' => $request->departure_date,
                        'departure_time' => $request->departure_time,
                        'ride_type' => $request->ride_type,
                        'service_type' => $request->service_type,
                        'price' => $request->price,
                        'kendaraan_mitra_id' => $request->kendaraan_mitra_id ?? null,
                        'available_seats' => 0,
                        'bagasi_capacity' => $request->bagasi_capacity ?? null,
                        'status' => 'active',
                    ]);

                    // If a photo was uploaded as part of the request, store it and save into extra
                    if ($request->hasFile('photo')) {
                        try {
                            $file = $request->file('photo');
                            $path = $file->store('uploads', 'public');
                            $url = '/storage/' . $path;
                            $barang->extra = array_merge($barang->extra ?? [], ['photo' => $url]);
                            $barang->save();
                        } catch (\Exception $e) {
                            // ignore file save errors but log
                            Log::warning('Failed to store ride photo', ['error' => $e->getMessage()]);
                        }
                    }

                    return $barang;
                }
            });

            // Load relations depending on which model was created
            if ($ride instanceof \App\Models\CarRide) {
                $ride->load(['user', 'originLocation', 'destinationLocation', 'kendaraanMitra']);
                Log::info('CarRide created', ['id' => $ride->id]);
            } elseif ($ride instanceof \App\Models\BarangRide) {
                $ride->load(['user', 'originLocation', 'destinationLocation', 'kendaraanMitra']);
                Log::info('BarangRide created', ['id' => $ride->id]);
            } else {
                // Default: motor Ride
                $ride->load(['user', 'originLocation', 'destinationLocation', 'carRide']);
                Log::info('Ride created', ['ride_id' => $ride->id]);
            }
        } catch (\Exception $e) {
            Log::error('Ride create failed', ['error' => $e->getMessage(), 'payload' => $request->all()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to create ride',
                'error' => $e->getMessage(),
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Ride created successfully',
            'data' => $ride,
        ], 201);
    }

    public function show($id)
    {
        $ride = Ride::with(['user', 'originLocation', 'destinationLocation', 'carRide'])->find($id);

        if (!$ride) {
            return response()->json([
                'success' => false,
                'message' => 'Ride not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $ride,
        ]);
    }

    /**
     * Get all passengers/bookings for a specific ride
     * Used for displaying all passengers in mobil ride details
     */
    public function getRidePassengers(Request $request, $rideId)
    {
        $rideType = $request->query('ride_type', 'motor');

        $bookings = [];

        switch ($rideType) {
            case 'mobil':
                $bookings = \App\Models\BookingMobil::with(['user', 'penumpang'])
                    ->where('ride_id', $rideId)
                    ->get();
                break;
            case 'motor':
                $bookings = \App\Models\Booking::with(['user'])
                    ->where('ride_id', $rideId)
                    ->get();
                break;
            case 'barang':
                $bookings = \App\Models\BookingBarang::with(['user'])
                    ->where('barang_ride_id', $rideId)
                    ->get();
                break;
            case 'titip':
                $bookings = \App\Models\BookingTitipBarang::with(['user'])
                    ->where('tebengan_titip_barang_id', $rideId)
                    ->get();
                break;
        }

        return response()->json([
            'success' => true,
            'data' => $bookings,
        ]);
    }
}
