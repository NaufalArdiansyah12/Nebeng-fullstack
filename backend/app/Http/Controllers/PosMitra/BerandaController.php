<?php

namespace App\Http\Controllers\PosMitra;

use App\Http\Controllers\Controller;
use App\Models\ApiToken;
use App\Models\PosMitraUser;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BerandaController extends Controller
{
    /**
     * Return posmitra beranda data
     */
    public function beranda(Request $request)
    {
        $user = $this->getAuthenticatedUser($request);
        if ($user instanceof \Illuminate\Http\JsonResponse) return $user;

        return response()->json([
            'success' => true,
            'data' => [
                'name' => $user->name,
                'balance' => $user->balance ?? 0,
                'role' => 'posmitra',
                'profile_photo' => $user->profile_photo ?? null,
                'location_id' => $user->location_id ?? null,
            ],
        ]);
    }

    /**
     * Get upcoming rides (tebengan akan datang)
     * ✅ DIPERBAIKI: Tidak mengambil data kendaraan untuk menghindari error
     */
    public function upcomingRides(Request $request)
    {
        $user = $this->getAuthenticatedUser($request);
        if ($user instanceof \Illuminate\Http\JsonResponse) return $user;

        if (!$user->location_id) {
            return response()->json([
                'success' => true,
                'message' => 'Pos mitra belum memiliki lokasi yang ditugaskan',
                'data' => [],
            ]);
        }

        // ✅ Motor rides - TANPA JOIN ke kendaraan_mitra
        $motorRides = DB::table('tebengan_motor as tm')
            ->leftJoin('users as u', 'tm.user_id', '=', 'u.id')
            ->leftJoin('locations as origin', 'tm.origin_location_id', '=', 'origin.id')
            ->leftJoin('locations as dest', 'tm.destination_location_id', '=', 'dest.id')
            ->where('tm.destination_location_id', $user->location_id)
            ->whereIn('tm.status', ['active', 'full'])
            ->where('tm.departure_date', '>=', now()->toDateString())
            ->orderBy('tm.departure_date')
            ->orderBy('tm.departure_time')
            ->select(
                'tm.id',
                'tm.departure_date',
                'tm.departure_time',
                'tm.price',
                'tm.available_seats',
                'tm.status',
                'tm.service_type',
                'tm.ride_type',
                // Origin
                'origin.id as origin_id',
                'origin.name as origin_name',
                'origin.address as origin_address',
                // Destination
                'dest.id as dest_id',
                'dest.name as dest_name',
                'dest.address as dest_address',
                // Driver
                'u.id as driver_id',
                'u.name as driver_name',
                'u.phone as driver_phone',
                'u.profile_photo as driver_photo'
            )
            ->get()
            ->map(function ($ride) {
                return [
                    'id' => $ride->id,
                    'ride_type' => $ride->ride_type ?? 'motor',
                    'service_type' => $ride->service_type ?? 'tebengan',
                    'date' => $ride->departure_date,
                    'time' => $ride->departure_time,
                    'origin' => [
                        'id' => $ride->origin_id,
                        'name' => $ride->origin_name ?? 'Unknown',
                        'detail' => $ride->origin_address ?? '',
                    ],
                    'destination' => [
                        'id' => $ride->dest_id,
                        'name' => $ride->dest_name ?? 'Unknown',
                        'detail' => $ride->dest_address ?? '',
                    ],
                    'price' => (float) $ride->price,
                    'vehicle' => [
                        'name' => '',
                        'plate' => '',
                        'brand' => '',
                        'type' => 'Motor',
                        'color' => '',
                    ],
                    'available_seats' => $ride->available_seats,
                    'status' => $ride->status,
                    'driver' => [
                        'id' => $ride->driver_id,
                        'name' => $ride->driver_name ?? 'Unknown',
                        'phone' => $ride->driver_phone ?? '',
                        'photo' => $ride->driver_photo ?? null,
                    ],
                ];
            });

        // ✅ Mobil rides - TANPA JOIN ke kendaraan_mitra
        $mobilRides = DB::table('tebengan_mobil as tmb')
            ->leftJoin('users as u', 'tmb.user_id', '=', 'u.id')
            ->leftJoin('locations as origin', 'tmb.origin_location_id', '=', 'origin.id')
            ->leftJoin('locations as dest', 'tmb.destination_location_id', '=', 'dest.id')
            ->where('tmb.destination_location_id', $user->location_id)
            ->whereIn('tmb.status', ['active', 'full'])
            ->where('tmb.departure_date', '>=', now()->toDateString())
            ->orderBy('tmb.departure_date')
            ->orderBy('tmb.departure_time')
            ->select(
                'tmb.id',
                'tmb.departure_date',
                'tmb.departure_time',
                'tmb.price',
                'tmb.available_seats',
                'tmb.status',
                'tmb.ride_type',
                'tmb.service_type',
                // Origin
                'origin.id as origin_id',
                'origin.name as origin_name',
                'origin.address as origin_address',
                // Destination
                'dest.id as dest_id',
                'dest.name as dest_name',
                'dest.address as dest_address',
                // Driver
                'u.id as driver_id',
                'u.name as driver_name',
                'u.phone as driver_phone',
                'u.profile_photo as driver_photo'
            )
            ->get()
            ->map(function ($ride) {
                return [
                    'id' => $ride->id,
                    'ride_type' => $ride->ride_type ?? 'mobil',
                    'service_type' => $ride->service_type ?? 'tebengan',
                    'date' => $ride->departure_date,
                    'time' => $ride->departure_time,
                    'origin' => [
                        'id' => $ride->origin_id,
                        'name' => $ride->origin_name ?? 'Unknown',
                        'detail' => $ride->origin_address ?? '',
                    ],
                    'destination' => [
                        'id' => $ride->dest_id,
                        'name' => $ride->dest_name ?? 'Unknown',
                        'detail' => $ride->dest_address ?? '',
                    ],
                    'price' => (float) $ride->price,
                    'vehicle' => [
                        'name' => '',
                        'plate' => '',
                        'brand' => '',
                        'type' => 'Mobil',
                        'color' => '',
                    ],
                    'available_seats' => $ride->available_seats,
                    'status' => $ride->status,
                    'driver' => [
                        'id' => $ride->driver_id,
                        'name' => $ride->driver_name ?? 'Unknown',
                        'phone' => $ride->driver_phone ?? '',
                        'photo' => $ride->driver_photo ?? null,
                    ],
                ];
            });

        // Merge & sort
        $rides = $motorRides->concat($mobilRides)
            ->sortBy(function($r) {
                return $r['date'] . ' ' . $r['time'];
            })
            ->values()
            ->toArray();

        return response()->json([
            'success' => true,
            'message' => 'Data tebengan berhasil diambil',
            'data' => $rides,
        ]);
    }

    

    /**
     * Get statistics untuk pos mitra
     */
    public function statistics(Request $request)
    {
        $user = $this->getAuthenticatedUser($request);
        if ($user instanceof \Illuminate\Http\JsonResponse) return $user;

        if (!$user->location_id) {
            return response()->json([
                'success' => true,
                'data' => [
                    'nebeng_motor' => 0,
                    'nebeng_mobil' => 0,
                    'nebeng_barang' => 0,
                    'titip_barang' => 0,
                ],
            ]);
        }

        // Nebeng Motor
        $nebengMotor = DB::table('tebengan_motor')
            ->where('destination_location_id', $user->location_id)
            ->where('status', 'completed')
            ->where('service_type', 'tebengan')
            ->count();

        // Nebeng Mobil
        $nebengMobil = DB::table('tebengan_mobil')
            ->where('destination_location_id', $user->location_id)
            ->where('status', 'completed')
            ->count();

        // Nebeng Barang
        $nebengBarang = DB::table('tebengan_barang')
            ->where('destination_location_id', $user->location_id)
            ->where('status', 'completed')
            ->count();

        // Titip Barang
        $titipBarang = DB::table('tebengan_titip_barang')
            ->where('destination_location_id', $user->location_id)
            ->where('status', 'completed')
            ->count();

        return response()->json([
            'success' => true,
            'data' => [
                'nebeng_motor' => $nebengMotor,
                'nebeng_mobil' => $nebengMobil,
                'nebeng_barang' => $nebengBarang,
                'titip_barang' => $titipBarang,
            ],
        ]);
    }

    /**
     * Custom token auth
     */
    private function getAuthenticatedUser(Request $request)
    {
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json(['success' => false, 'message' => 'Token tidak ditemukan'], 401);
        }

        $hashed = hash('sha256', $bearer);

        $apiToken = ApiToken::where('token', $hashed)
            ->where('expires_at', '>', now())
            ->first();

        if (!$apiToken) {
            return response()->json(['success' => false, 'message' => 'Token tidak valid atau sudah kadaluarsa'], 401);
        }

        $posMitraUser = PosMitraUser::find($apiToken->posmitra_id);
        
        if ($posMitraUser) {
            return $posMitraUser;
        }
        
        return response()->json([
            'success' => false, 
            'message' => 'User pos mitra tidak ditemukan'
        ], 404);
    }

    /**
 * Get completed rides (tebengan selesai)
 * 🔥 TAMBAHKAN METHOD INI!
 */
public function completedRides(Request $request)
{
    $user = $this->getAuthenticatedUser($request);
    if ($user instanceof \Illuminate\Http\JsonResponse) return $user;

    if (!$user->location_id) {
        return response()->json([
            'success' => true,
            'message' => 'Pos mitra belum memiliki lokasi yang ditugaskan',
            'data' => [],
        ]);
    }

    // ✅ AMBIL MOTOR YANG SUDAH COMPLETED
    $motorRides = DB::table('tebengan_motor as tm')
        ->leftJoin('users as u', 'tm.user_id', '=', 'u.id')
        ->leftJoin('locations as origin', 'tm.origin_location_id', '=', 'origin.id')
        ->leftJoin('locations as dest', 'tm.destination_location_id', '=', 'dest.id')
        ->where('tm.destination_location_id', $user->location_id)
        ->where('tm.status', 'completed')  // 🔥 FILTER COMPLETED!
        ->orderBy('tm.departure_date', 'desc')
        ->orderBy('tm.departure_time', 'desc')
        ->select(
            'tm.id',
            'tm.departure_date',
            'tm.departure_time',
            'tm.price',
            'tm.available_seats',
            'tm.status',
            'tm.service_type',
            'tm.ride_type',
            'origin.id as origin_id',
            'origin.name as origin_name',
            'origin.address as origin_address',
            'dest.id as dest_id',
            'dest.name as dest_name',
            'dest.address as dest_address',
            'u.id as driver_id',
            'u.name as driver_name',
            'u.phone as driver_phone',
            'u.profile_photo as driver_photo'
        )
        ->get()
        ->map(function ($ride) {
            return [
                'id' => $ride->id,
                'ride_type' => $ride->ride_type ?? 'motor',
                'service_type' => $ride->service_type ?? 'tebengan',
                'date' => $ride->departure_date,
                'time' => $ride->departure_time,
                'origin' => [
                    'id' => $ride->origin_id,
                    'name' => $ride->origin_name ?? 'Unknown',
                    'detail' => $ride->origin_address ?? '',
                ],
                'destination' => [
                    'id' => $ride->dest_id,
                    'name' => $ride->dest_name ?? 'Unknown',
                    'detail' => $ride->dest_address ?? '',
                ],
                'price' => (float) $ride->price,
                'vehicle' => [
                    'name' => '',
                    'plate' => '',
                    'brand' => '',
                    'type' => 'Motor',
                    'color' => '',
                ],
                'available_seats' => $ride->available_seats,
                'status' => $ride->status,
                'driver' => [
                    'id' => $ride->driver_id,
                    'name' => $ride->driver_name ?? 'Unknown',
                    'phone' => $ride->driver_phone ?? '',
                    'photo' => $ride->driver_photo ?? null,
                ],
            ];
        });

    // ✅ AMBIL MOBIL YANG SUDAH COMPLETED
    $mobilRides = DB::table('tebengan_mobil as tmb')
        ->leftJoin('users as u', 'tmb.user_id', '=', 'u.id')
        ->leftJoin('locations as origin', 'tmb.origin_location_id', '=', 'origin.id')
        ->leftJoin('locations as dest', 'tmb.destination_location_id', '=', 'dest.id')
        ->where('tmb.destination_location_id', $user->location_id)
        ->where('tmb.status', 'completed')  // 🔥 FILTER COMPLETED!
        ->orderBy('tmb.departure_date', 'desc')
        ->orderBy('tmb.departure_time', 'desc')
        ->select(
            'tmb.id',
            'tmb.departure_date',
            'tmb.departure_time',
            'tmb.price',
            'tmb.available_seats',
            'tmb.status',
            'tmb.ride_type',
            'tmb.service_type',
            'origin.id as origin_id',
            'origin.name as origin_name',
            'origin.address as origin_address',
            'dest.id as dest_id',
            'dest.name as dest_name',
            'dest.address as dest_address',
            'u.id as driver_id',
            'u.name as driver_name',
            'u.phone as driver_phone',
            'u.profile_photo as driver_photo'
        )
        ->get()
        ->map(function ($ride) {
            return [
                'id' => $ride->id,
                'ride_type' => $ride->ride_type ?? 'mobil',
                'service_type' => $ride->service_type ?? 'tebengan',
                'date' => $ride->departure_date,
                'time' => $ride->departure_time,
                'origin' => [
                    'id' => $ride->origin_id,
                    'name' => $ride->origin_name ?? 'Unknown',
                    'detail' => $ride->origin_address ?? '',
                ],
                'destination' => [
                    'id' => $ride->dest_id,
                    'name' => $ride->dest_name ?? 'Unknown',
                    'detail' => $ride->dest_address ?? '',
                ],
                'price' => (float) $ride->price,
                'vehicle' => [
                    'name' => '',
                    'plate' => '',
                    'brand' => '',
                    'type' => 'Mobil',
                    'color' => '',
                ],
                'available_seats' => $ride->available_seats,
                'status' => $ride->status,
                'driver' => [
                    'id' => $ride->driver_id,
                    'name' => $ride->driver_name ?? 'Unknown',
                    'phone' => $ride->driver_phone ?? '',
                    'photo' => $ride->driver_photo ?? null,
                ],
            ];
        });

    // ✅ GABUNG & URUTKAN (TERBARU)
    $rides = $motorRides->concat($mobilRides)
        ->sortByDesc(function($r) {
            return $r['date'] . ' ' . $r['time'];
        })
        ->values()
        ->toArray();

    return response()->json([
        'success' => true,
        'message' => 'Data tebengan selesai berhasil diambil',
        'data' => $rides,
    ]);
}
}