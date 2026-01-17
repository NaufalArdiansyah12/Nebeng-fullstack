<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Ride;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class BookingController extends Controller
{
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'ride_id' => 'required|integer',
            // Relax exists:users,id to avoid validation 422 when frontend supplies user_id
            // Backend will still accept integer user_id and proceed.
            'user_id' => 'required|integer',
            'ride_type' => 'nullable|string|in:motor,mobil,barang,titip',
            'seats' => 'nullable|integer|min:1',
            'photo' => 'nullable|image|mimes:jpeg,jpg,png|max:5120',
            'weight' => 'nullable|string|max:50',
            'description' => 'nullable|string|max:1000',
            'penumpang' => 'nullable|array', // Array of passenger data
            'penumpang.*.nama' => 'required|string|max:255',
            'penumpang.*.nik' => 'nullable|string|max:20',
            'penumpang.*.no_telepon' => 'nullable|string|max:20',
            'penumpang.*.jenis_kelamin' => 'nullable|string|in:Laki-laki,Perempuan',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Ensure ride exists and has enough seats (basic check)
        // Rides may live in `tebengan_motor` (Ride) or `tebengan_mobil` (CarRide) or `tebengan_barang` (BarangRide) or `tebengan_titip_barang` (TebenganTitipBarang).
        // Use ride_type parameter to search in correct table first
        $rideType = $request->ride_type;
        $ride = null;
        $isCar = false;
        $isBarang = false;
        $isTitipBarang = false;
        
        // Search based on ride_type parameter
        if ($rideType === 'mobil') {
            $ride = \App\Models\CarRide::find($request->ride_id);
            if ($ride) {
                $isCar = true;
            }
        } elseif ($rideType === 'barang') {
            $ride = \App\Models\BarangRide::find($request->ride_id);
            if ($ride) {
                $isBarang = true;
            }
        } elseif ($rideType === 'titip') {
            $ride = \App\Models\TebenganTitipBarang::find($request->ride_id);
            if ($ride) {
                $isTitipBarang = true;
            }
        } else {
            // Default to motor (Ride table)
            $ride = Ride::find($request->ride_id);
        }
        
        // Fallback: if not found and no ride_type specified, search all tables.
        // Important: check `TebenganTitipBarang` before `BarangRide` to avoid
        // collisions where ids overlap across tables (titip should map to booking_titip_barang).
        if (!$ride && !$rideType) {
            $ride = Ride::find($request->ride_id);

            if (!$ride) {
                $ride = \App\Models\CarRide::find($request->ride_id);
                if ($ride) {
                    $isCar = true;
                }
            }

            if (!$ride) {
                $ride = \App\Models\TebenganTitipBarang::find($request->ride_id);
                if ($ride) {
                    $isTitipBarang = true;
                }
            }

            if (!$ride) {
                $ride = \App\Models\BarangRide::find($request->ride_id);
                if ($ride) {
                    $isBarang = true;
                }
            }
        }

        if (!$ride) {
            return response()->json(['success' => false, 'message' => 'Ride not found'], 404);
        }

        $seats = $request->seats ?? 1;

        // If this is a car ride, ensure there are enough available seats
        if ($isCar) {
            $available = intval($ride->available_seats ?? 0);
            if ($available < $seats) {
                return response()->json([
                    'success' => false,
                    'message' => 'Not enough seats available',
                    'available_seats' => $available,
                ], 409);
            }
        }

        // Handle photo upload for barang bookings (including titip barang)
        $photoPath = null;
        if (($isBarang || $isTitipBarang) && $request->hasFile('photo')) {
            $photo = $request->file('photo');
            $filename = time() . '_' . uniqid() . '.' . $photo->getClientOriginalExtension();
            $photo->storeAs('public/uploads', $filename);
            $photoPath = '/storage/uploads/' . $filename;
        }

        // Create booking number
        $bookingNumber = 'FR-' . time() . '-' . rand(100, 999);

        // Create booking into appropriate bookings table depending on detected ride type.
        // Prioritize car -> titip barang -> barang -> motor
        if ($isCar) {
            $booking = \App\Models\BookingMobil::create([
                'ride_id' => $ride->id,
                'user_id' => $request->user_id,
                'booking_number' => $bookingNumber,
                'seats' => $seats,
                'status' => 'pending',
                'meta' => null,
            ]);

            // Save passengers if provided
            if ($request->has('penumpang') && is_array($request->penumpang)) {
                foreach ($request->penumpang as $penumpangData) {
                    \App\Models\PenumpangBookingMobil::create([
                        'booking_mobil_id' => $booking->id,
                        'nama' => $penumpangData['nama'],
                        'nik' => $penumpangData['nik'] ?? null,
                        'no_telepon' => $penumpangData['no_telepon'] ?? null,
                        'jenis_kelamin' => $penumpangData['jenis_kelamin'] ?? null,
                    ]);
                }
            }

            // decrement available seats atomically
            try {
                $ride->refresh();
                $ride->decrement('available_seats', $seats);
                // reload to check remaining seats
                $ride->refresh();
                if (intval($ride->available_seats ?? 0) <= 0) {
                    $ride->status = 'inactive';
                    $ride->save();
                }
            } catch (\Exception $e) {
                Log::warning('Failed to decrement available_seats', ['error' => $e->getMessage(), 'ride_id' => $ride->id]);
            }
        } elseif ($isTitipBarang) {
            $booking = \App\Models\BookingTitipBarang::create([
                'ride_id' => $ride->id,
                'user_id' => $request->user_id,
                'booking_number' => $bookingNumber,
                'seats' => $seats,
                'status' => 'pending',
                'meta' => null,
                'photo' => $photoPath,
                'weight' => $request->weight,
                'description' => $request->description,
            ]);
        } elseif ($isBarang) {
            $booking = \App\Models\BookingBarang::create([
                'ride_id' => $ride->id,
                'user_id' => $request->user_id,
                'booking_number' => $bookingNumber,
                'seats' => $seats,
                'status' => 'pending',
                'meta' => null,
                'photo' => $photoPath,
                'weight' => $request->weight,
                'description' => $request->description,
            ]);
        } else {
            $booking = Booking::create([
                'ride_id' => $ride->id,
                'user_id' => $request->user_id,
                'booking_number' => $bookingNumber,
                'seats' => $seats,
                'status' => 'pending',
                'meta' => null,
            ]);
        }

        Log::info('Booking created', ['booking_id' => $booking->id, 'booking_number' => $bookingNumber]);

        return response()->json([
            'success' => true,
            'data' => $booking,
        ], 201);
    }

    public function show($id)
    {
        // Try booking_motor first, then booking_mobil, then booking_barang, then booking_titip_barang
        $b = Booking::with(['ride', 'user'])->find($id);
        if ($b) {
            return response()->json(['success' => true, 'data' => $b]);
        }

        $bm = \App\Models\BookingMobil::with(['ride', 'user', 'penumpang'])->find($id);
        if ($bm) {
            return response()->json(['success' => true, 'data' => $bm]);
        }

        $bb = \App\Models\BookingBarang::with(['ride', 'user'])->find($id);
        if ($bb) {
            return response()->json(['success' => true, 'data' => $bb]);
        }

        $bt = \App\Models\BookingTitipBarang::with(['ride', 'user'])->find($id);
        if ($bt) {
            return response()->json(['success' => true, 'data' => $bt]);
        }

        return response()->json(['success' => false, 'message' => 'Booking not found'], 404);
    }

    /**
     * List bookings for the authenticated user.
     * Optional query param `type` accepts: semua|motor|mobil|barang|titip
     */
    public function myBookings(Request $request)
    {
        // Get authenticated user from bearer token (project uses custom ApiToken)
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json(['success' => false, 'message' => 'Token tidak ditemukan'], 401);
        }

        $hashed = hash('sha256', $bearer);
        $apiToken = \App\Models\ApiToken::where('token', $hashed)
            ->where('expires_at', '>', now())
            ->first();

        if (!$apiToken) {
            return response()->json(['success' => false, 'message' => 'Token tidak valid atau sudah kadaluarsa'], 401);
        }

        $user = \App\Models\User::find($apiToken->user_id);
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'User tidak ditemukan'], 404);
        }

        $type = $request->query('type', 'semua');

        $results = [];

        if ($type === 'motor' || $type === 'semua') {
            $motor = \App\Models\Booking::with([
                'ride.originLocation',
                'ride.destinationLocation',
                'ride.kendaraanMitra',
                'user'
            ])
                ->where('user_id', $user->id)
                ->get()
                ->map(function ($b) {
                    $arr = $b->toArray();
                    $arr['booking_type'] = 'motor';
                    return $arr;
                })->toArray();
            $results = array_merge($results, $motor);
        }

        if ($type === 'mobil' || $type === 'semua') {
            $mobil = \App\Models\BookingMobil::with([
                'ride.originLocation',
                'ride.destinationLocation',
                'ride.kendaraanMitra',
                'user'
            ])
                ->where('user_id', $user->id)
                ->get()
                ->map(function ($b) {
                    $arr = $b->toArray();
                    $arr['booking_type'] = 'mobil';
                    return $arr;
                })->toArray();
            $results = array_merge($results, $mobil);
        }

        if ($type === 'barang' || $type === 'semua') {
            $barang = \App\Models\BookingBarang::with([
                'ride.originLocation',
                'ride.destinationLocation',
                'ride.kendaraanMitra',
                'user'
            ])
                ->where('user_id', $user->id)
                ->get()
                ->map(function ($b) {
                    $arr = $b->toArray();
                    $arr['booking_type'] = 'barang';
                    return $arr;
                })->toArray();
            $results = array_merge($results, $barang);
        }

        if ($type === 'titip' || $type === 'semua' || $type === 'titip barang') {
            $titip = \App\Models\BookingTitipBarang::with([
                'ride.originLocation',
                'ride.destinationLocation',
                'ride.kendaraanMitra',
                'user'
            ])
                ->where('user_id', $user->id)
                ->get()
                ->map(function ($b) {
                    $arr = $b->toArray();
                    $arr['booking_type'] = 'titip';
                    return $arr;
                })->toArray();
            $results = array_merge($results, $titip);
        }

        // sort by created_at desc if available
        usort($results, function ($a, $b) {
            $ta = isset($a['created_at']) ? strtotime($a['created_at']) : 0;
            $tb = isset($b['created_at']) ? strtotime($b['created_at']) : 0;
            return $tb <=> $ta;
        });

        return response()->json(['success' => true, 'data' => $results]);
    }
}
