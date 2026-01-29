<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Ride;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use App\Models\Rating;

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
            'jumlah_bagasi' => 'nullable|integer|min:0',
            'photo' => 'nullable|image|mimes:jpeg,jpg,png|max:5120',
            'weight' => 'nullable|string|max:50',
            'description' => 'nullable|string|max:1000',
            'penerima' => 'nullable|string|max:255',
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
        $bagasiRequested = intval($request->jumlah_bagasi ?? 0);

        // If frontend did not provide jumlah_bagasi but the ride has bagasi available,
        // assume a default of 1 bagasi for bookings on rides that support bagasi.
        $effectiveBagasiRequested = $bagasiRequested;
        if ($effectiveBagasiRequested <= 0 && intval($ride->jumlah_bagasi ?? 0) > 0) {
            $effectiveBagasiRequested = 1;
        }

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

        // For any ride that supports bagasi, ensure there's enough remaining bagasi
        if ($effectiveBagasiRequested > 0) {
            $availableBagasi = intval($ride->jumlah_bagasi ?? 0);
            if ($availableBagasi < $effectiveBagasiRequested) {
                return response()->json([
                    'success' => false,
                    'message' => 'Not enough bagasi available',
                    'available_bagasi' => $availableBagasi,
                ], 409);
            }
            // If the original request didn't include jumlah_bagasi, merge the effective value
            if ($bagasiRequested <= 0) {
                try {
                    $request->merge(['jumlah_bagasi' => $effectiveBagasiRequested]);
                    $bagasiRequested = $effectiveBagasiRequested;
                } catch (\Exception $e) {
                    // ignore merge failures; controllers can still read $effectiveBagasiRequested via variable
                    Log::debug('Failed to merge jumlah_bagasi into request: ' . $e->getMessage());
                }
            }
        }

        // Delegate to specific controllers based on detected type (Option A)
        if ($isCar) {
            return app()->call(\App\Http\Controllers\Api\BookingMobilController::class . '@store', ['request' => $request, 'ride' => $ride]);
        }

        if ($isTitipBarang) {
            return app()->call(\App\Http\Controllers\Api\BookingTitipBarangController::class . '@store', ['request' => $request, 'ride' => $ride]);
        }

        if ($isBarang) {
            return app()->call(\App\Http\Controllers\Api\BookingBarangController::class . '@store', ['request' => $request, 'ride' => $ride]);
        }

        // default -> motor
        return app()->call(\App\Http\Controllers\Api\BookingMotorController::class . '@store', ['request' => $request, 'ride' => $ride]);
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

        \Log::info('MyBookings Request', ['user_id' => $user->id, 'type' => $request->query('type', 'semua')]);

        $type = $request->query('type', 'semua');

        $results = [];

        if ($type === 'motor' || $type === 'semua') {
            $motor = \App\Models\Booking::with([
                'ride.originLocation',
                'ride.destinationLocation',
                'ride.kendaraanMitra',
                'ride.user',
                'user'
            ])
                ->where('user_id', $user->id)
                ->get()
                ->map(function ($b) {
                    $arr = $b->toArray();
                    $arr['booking_type'] = 'motor';
                    try {
                        if (isset($arr['ride']['user']['id']) && $arr['ride']['user']['id']) {
                            $driverId = $arr['ride']['user']['id'];
                            $ratings = Rating::where('driver_id', $driverId)->get();
                            $total = $ratings->count();
                            $avg = $total > 0 ? round($ratings->avg('rating'), 2) : null;
                            $arr['ride']['driver_rating_summary'] = [
                                'average_rating' => $avg,
                                'total_ratings' => $total,
                            ];
                        }
                    } catch (\Exception $e) {
                    }
                    return $arr;
                })->toArray();
            $results = array_merge($results, $motor);
        }

        if ($type === 'mobil' || $type === 'semua') {
            $mobil = \App\Models\BookingMobil::with([
                'ride.originLocation',
                'ride.destinationLocation',
                'ride.kendaraanMitra',
                'ride.user',
                'user'
            ])
                ->where('user_id', $user->id)
                ->get()
                ->map(function ($b) {
                    $arr = $b->toArray();
                    $arr['booking_type'] = 'mobil';
                    try {
                        if (isset($arr['ride']['user']['id']) && $arr['ride']['user']['id']) {
                            $driverId = $arr['ride']['user']['id'];
                            $ratings = Rating::where('driver_id', $driverId)->get();
                            $total = $ratings->count();
                            $avg = $total > 0 ? round($ratings->avg('rating'), 2) : null;
                            $arr['ride']['driver_rating_summary'] = [
                                'average_rating' => $avg,
                                'total_ratings' => $total,
                            ];
                        }
                    } catch (\Exception $e) {
                    }
                    return $arr;
                })->toArray();
            $results = array_merge($results, $mobil);
        }

        if ($type === 'barang' || $type === 'semua') {
            $barang = \App\Models\BookingBarang::with([
                'ride.originLocation',
                'ride.destinationLocation',
                'ride.kendaraanMitra',
                'ride.user',
                'user'
            ])
                ->where('user_id', $user->id)
                ->get()
                ->map(function ($b) {
                    $arr = $b->toArray();
                    $arr['booking_type'] = 'barang';
                    try {
                        if (isset($arr['ride']['user']['id']) && $arr['ride']['user']['id']) {
                            $driverId = $arr['ride']['user']['id'];
                            $ratings = Rating::where('driver_id', $driverId)->get();
                            $total = $ratings->count();
                            $avg = $total > 0 ? round($ratings->avg('rating'), 2) : null;
                            $arr['ride']['driver_rating_summary'] = [
                                'average_rating' => $avg,
                                'total_ratings' => $total,
                            ];
                        }
                    } catch (\Exception $e) {
                    }
                    return $arr;
                })->toArray();
            $results = array_merge($results, $barang);
        }

        if ($type === 'titip' || $type === 'semua' || $type === 'titip barang') {
            $titip = \App\Models\BookingTitipBarang::with([
                'ride.originLocation',
                'ride.destinationLocation',
                'ride.kendaraanMitra',
                'ride.user',
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

        \Log::info('MyBookings Response', ['user_id' => $user->id, 'total_results' => count($results)]);

        return response()->json(['success' => true, 'data' => $results]);
    }

    /**
     * Get single booking with tracking status
     */
    public function show(Request $request, $id)
    {
        // Optional authentication - if token provided, verify it
        $user = null;
        $bearer = $request->bearerToken();
        
        if ($bearer) {
            $hashed = hash('sha256', $bearer);
            $apiToken = \App\Models\ApiToken::where('token', $hashed)
                ->where('expires_at', '>', now())
                ->first();

            if ($apiToken) {
                $user = \App\Models\User::find($apiToken->user_id);
            }
        }

        // Try to find booking in all tables
        $booking = null;
        $bookingType = null;

        // Try motor booking
        $booking = \App\Models\Booking::with([
            'ride.originLocation',
            'ride.destinationLocation',
            'ride.kendaraanMitra',
            'ride.user',
            'user'
        ])->find($id);
        if ($booking) {
            // If user is authenticated, verify ownership
            if ($user && $booking->user_id !== $user->id) {
                $booking = null;
            } else {
                $bookingType = 'motor';
            }
        }

        // Try mobil booking
        if (!$booking) {
            $booking = \App\Models\BookingMobil::with([
                'ride.originLocation',
                'ride.destinationLocation',
                'ride.kendaraanMitra',
                'ride.user',
                'user'
            ])->find($id);
            if ($booking) {
                if ($user && $booking->user_id !== $user->id) {
                    $booking = null;
                } else {
                    $bookingType = 'mobil';
                }
            }
        }

        // Try barang booking
        if (!$booking) {
            $booking = \App\Models\BookingBarang::with([
                'ride.originLocation',
                'ride.destinationLocation',
                'ride.kendaraanMitra',
                'ride.user',
                'user'
            ])->find($id);
            if ($booking) {
                if ($user && $booking->user_id !== $user->id) {
                    $booking = null;
                } else {
                    $bookingType = 'barang';
                }
            }
        }

        // Try titip booking
        if (!$booking) {
            $booking = \App\Models\BookingTitipBarang::with([
                'ride.originLocation',
                'ride.destinationLocation',
                'ride.kendaraanMitra',
                'ride.user',
                'user'
            ])->find($id);
            if ($booking) {
                if ($user && $booking->user_id !== $user->id) {
                    $booking = null;
                } else {
                    $bookingType = 'titip';
                }
            }
        }

        if (!$booking) {
            return response()->json(['success' => false, 'message' => 'Booking tidak ditemukan'], 404);
        }

        $data = $booking->toArray();
        $data['booking_type'] = $bookingType;
        // attach driver rating summary if available
        try {
            if (isset($data['ride']['user']['id']) && $data['ride']['user']['id']) {
                $driverId = $data['ride']['user']['id'];
                $ratings = Rating::where('driver_id', $driverId)->get();
                $total = $ratings->count();
                $avg = $total > 0 ? round($ratings->avg('rating'), 2) : null;
                $data['ride']['driver_rating_summary'] = [
                    'average_rating' => $avg,
                    'total_ratings' => $total,
                ];
            }
        } catch (\Exception $e) {
        }
        // Ensure origin/destination include explicit lat/lng keys for clients
        try {
            if (isset($data['ride']) && is_array($data['ride'])) {
                $rideObj = $booking->ride;
                if ($rideObj && $rideObj->originLocation) {
                    if (!isset($data['ride']['origin_location']) || !is_array($data['ride']['origin_location'])) {
                        $data['ride']['origin_location'] = [];
                    }
                    $data['ride']['origin_location']['lat'] = $rideObj->originLocation->latitude ?? $rideObj->originLocation->lat ?? null;
                    $data['ride']['origin_location']['lng'] = $rideObj->originLocation->longitude ?? $rideObj->originLocation->lng ?? null;
                }
                if ($rideObj && $rideObj->destinationLocation) {
                    if (!isset($data['ride']['destination_location']) || !is_array($data['ride']['destination_location'])) {
                        $data['ride']['destination_location'] = [];
                    }
                    $data['ride']['destination_location']['lat'] = $rideObj->destinationLocation->latitude ?? $rideObj->destinationLocation->lat ?? null;
                    $data['ride']['destination_location']['lng'] = $rideObj->destinationLocation->longitude ?? $rideObj->destinationLocation->lng ?? null;
                }
            }
        } catch (\Exception $e) {
            // non-fatal; proceed without blocking response
            Log::debug('Failed to attach lat/lng to ride origin/destination: ' . $e->getMessage());
        }
        
        // Add tracking status based on ride departure time
        if ($booking->ride && $booking->ride->departure_date && $booking->ride->departure_time) {
            try {
                $departureDateTime = \Carbon\Carbon::parse($booking->ride->departure_date . ' ' . $booking->ride->departure_time);
                $now = \Carbon\Carbon::now();
                
                // Determine tracking status from actual booking status
                if (in_array($booking->status, ['menuju_penjemputan', 'sudah_di_penjemputan', 'menuju_tujuan', 'sudah_sampai_tujuan'])) {
                    $data['tracking_status'] = $booking->status;
                } elseif ($departureDateTime->isPast()) {
                    $data['tracking_status'] = 'menuju_penjemputan';
                } elseif ($departureDateTime->diffInHours($now) <= 1) {
                    $data['tracking_status'] = 'waiting';
                    $data['countdown'] = [
                        'days' => $departureDateTime->diffInDays($now),
                        'hours' => $departureDateTime->diffInHours($now) % 24,
                        'minutes' => $departureDateTime->diffInMinutes($now) % 60,
                        'total_seconds' => $departureDateTime->diffInSeconds($now)
                    ];
                } else {
                    $data['tracking_status'] = 'scheduled';
                }
            } catch (\Exception $e) {
                $data['tracking_status'] = 'unknown';
            }
        }
        
        // Add location data if available
        if ($booking->last_lat && $booking->last_lng) {
            $data['last_location'] = [
                'lat' => (float) $booking->last_lat,
                'lng' => (float) $booking->last_lng,
                'timestamp' => $booking->last_location_at,
            ];
        }

        return response()->json(['success' => true, 'data' => $data]);
    }

    /**
     * Update booking status
     */
    public function updateStatus(Request $request, $id)
    {
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

        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
            'status' => 'required|string|in:pending,paid,confirmed,menuju_penjemputan,sudah_di_penjemputan,menuju_tujuan,sudah_sampai_tujuan,completed,cancelled,scheduled',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Try to find and update booking in all tables
        $booking = \App\Models\Booking::find($id);
        if ($booking && ($booking->user_id === $apiToken->user_id || ($booking->ride && $booking->ride->user_id === $apiToken->user_id))) {
            $booking->status = $request->status;
            $booking->save();
            return response()->json(['success' => true, 'data' => $booking]);
        }

        $booking = \App\Models\BookingMobil::find($id);
        if ($booking && ($booking->user_id === $apiToken->user_id || ($booking->ride && $booking->ride->user_id === $apiToken->user_id))) {
            $booking->status = $request->status;
            $booking->save();
            return response()->json(['success' => true, 'data' => $booking]);
        }

        $booking = \App\Models\BookingBarang::find($id);
        if ($booking && ($booking->user_id === $apiToken->user_id || ($booking->ride && $booking->ride->user_id === $apiToken->user_id))) {
            $booking->status = $request->status;
            $booking->save();
            return response()->json(['success' => true, 'data' => $booking]);
        }

        $booking = \App\Models\BookingTitipBarang::find($id);
        if ($booking && ($booking->user_id === $apiToken->user_id || ($booking->ride && $booking->ride->user_id === $apiToken->user_id))) {
            $booking->status = $request->status;
            $booking->save();
            return response()->json(['success' => true, 'data' => $booking]);
        }

        return response()->json(['success' => false, 'message' => 'Booking tidak ditemukan atau tidak memiliki akses'], 404);
    }

    public function cancel(Request $request, $id)
    {
        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
            'cancellation_reason' => 'required|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $reason = $request->cancellation_reason;
        
        // Try to find and cancel booking in all tables
        $booking = \App\Models\Booking::find($id);
        if ($booking) {
            $booking->status = 'cancelled';
            $booking->cancellation_reason = $reason;
            $booking->save();
            return response()->json([
                'success' => true, 
                'message' => 'Booking berhasil dibatalkan',
                'data' => $booking
            ]);
        }

        $booking = \App\Models\BookingMobil::find($id);
        if ($booking) {
            $booking->status = 'cancelled';
            $booking->cancellation_reason = $reason;
            $booking->save();
            return response()->json([
                'success' => true, 
                'message' => 'Booking berhasil dibatalkan',
                'data' => $booking
            ]);
        }

        $booking = \App\Models\BookingBarang::find($id);
        if ($booking) {
            $booking->status = 'cancelled';
            $booking->cancellation_reason = $reason;
            $booking->save();
            return response()->json([
                'success' => true, 
                'message' => 'Booking berhasil dibatalkan',
                'data' => $booking
            ]);
        }

        $booking = \App\Models\BookingTitipBarang::find($id);
        if ($booking) {
            $booking->status = 'cancelled';
            $booking->cancellation_reason = $reason;
            $booking->save();
            return response()->json([
                'success' => true, 
                'message' => 'Booking berhasil dibatalkan',
                'data' => $booking
            ]);
        }

        return response()->json([
            'success' => false, 
            'message' => 'Booking tidak ditemukan'
        ], 404);
    }

    public function getCancellationCount($userId)
    {
        // Get current month start and end
        $startOfMonth = now()->startOfMonth();
        $endOfMonth = now()->endOfMonth();

        // Count cancelled bookings in current month across all booking tables
        $motorCount = \App\Models\Booking::where('user_id', $userId)
            ->where('status', 'cancelled')
            ->whereBetween('updated_at', [$startOfMonth, $endOfMonth])
            ->count();

        $mobilCount = \App\Models\BookingMobil::where('user_id', $userId)
            ->where('status', 'cancelled')
            ->whereBetween('updated_at', [$startOfMonth, $endOfMonth])
            ->count();

        $barangCount = \App\Models\BookingBarang::where('user_id', $userId)
            ->where('status', 'cancelled')
            ->whereBetween('updated_at', [$startOfMonth, $endOfMonth])
            ->count();

        $titipCount = \App\Models\BookingTitipBarang::where('user_id', $userId)
            ->where('status', 'cancelled')
            ->whereBetween('updated_at', [$startOfMonth, $endOfMonth])
            ->count();

        $totalCount = $motorCount + $mobilCount + $barangCount + $titipCount;

        return response()->json([
            'success' => true,
            'data' => [
                'count' => $totalCount,
                'month' => now()->format('Y-m'),
                'breakdown' => [
                    'motor' => $motorCount,
                    'mobil' => $mobilCount,
                    'barang' => $barangCount,
                    'titip' => $titipCount,
                ]
            ]
        ]);
    }
}
