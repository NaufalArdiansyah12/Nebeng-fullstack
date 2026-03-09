<?php

namespace App\Http\Controllers\PosMitra;

use App\Http\Controllers\Controller;
use App\Models\ApiToken;
use App\Models\PosMitraUser;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
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
     * ✅ DIPERBAIKI: Mengambil data kendaraan dari tabel kendaraan_mitra
     */
    public function upcomingRides(Request $request)
    {
        Log::info('PosMitra upcomingRides called', [
            'bearer_token_exists' => $request->bearerToken() ? 'yes' : 'no',
            'authorization_header' => $request->header('Authorization') ? 'exists' : 'missing',
        ]);

        $user = $this->getAuthenticatedUser($request);
        if ($user instanceof \Illuminate\Http\JsonResponse) return $user;
        if ($user instanceof \Illuminate\Http\JsonResponse) {
            Log::error('PosMitra upcomingRides auth failed', [
                'response' => $user->getData(),
            ]);
            return $user;
        }

        Log::info('PosMitra upcomingRides authenticated', [
            'user_id' => $user->id,
            'user_type' => get_class($user),
            'location_id' => $user->location_id,
        ]);

        // Cek apakah pos mitra memiliki assigned location
        if (!$user->location_id) {
            return response()->json([
                'success' => true,
                'message' => 'Pos mitra belum memiliki lokasi yang ditugaskan',
                'data' => [],
                'debug' => [
                    'user_id' => $user->id,
                    'user_location_id' => $user->location_id,
                    'note' => 'PosMitra tidak memiliki location_id'
                ],
            ]);
        }

        // Debug: Log query yang akan dijalankan
        Log::info('PosMitra upcomingRides - Query params', [
            'destination_location_id' => $user->location_id,
            'today' => now()->toDateString(),
        ]);

        // ✅ Motor rides - DENGAN JOIN ke kendaraan_mitra DAN passengers
        $motorRides = DB::table('tebengan_motor as tm')
            ->leftJoin('users as u', 'tm.user_id', '=', 'u.id')
            ->leftJoin('kendaraan_mitra as km', 'tm.kendaraan_mitra_id', '=', 'km.id')
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
                // Vehicle from kendaraan_mitra
                'km.name as vehicle_name',
                'km.plate_number as vehicle_plate',
                'km.brand as vehicle_brand',
                'km.model as vehicle_model',
                'km.color as vehicle_color',
                'km.vehicle_type as vehicle_type',
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
                // Ambil data passengers dari tabel booking_motor (tanpa filter status)
                $passengers = DB::table('booking_motor as bmot')
                    ->join('users as passenger', 'bmot.user_id', '=', 'passenger.id')
                    ->where('bmot.ride_id', $ride->id)
                    ->select(
                        'passenger.id',
                        'passenger.name',
                        'passenger.phone',
                        'bmot.seats'
                    )
                    ->get()
                    ->map(function ($p) {
                        return [
                            'id' => $p->id,
                            'name' => $p->name ?? 'Unknown',
                            'nik' => '',
                            'phone' => $p->phone ?? '',
                            'gender' => '',
                            'seats' => $p->seats ?? 1,
                        ];
                    })
                    ->toArray();

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
                        'name' => $ride->vehicle_name ?? '',
                        'plate' => $ride->vehicle_plate ?? '',
                        'brand' => $ride->vehicle_brand ?? '',
                        'type' => $ride->vehicle_type ?? 'Motor',
                        'color' => $ride->vehicle_color ?? '',
                        'model' => $ride->vehicle_model ?? '',
                    ],
                    'available_seats' => $ride->available_seats,
                    'status' => $ride->status,
                    'driver' => [
                        'id' => $ride->driver_id,
                        'name' => $ride->driver_name ?? 'Unknown',
                        'phone' => $ride->driver_phone ?? '',
                        'photo' => $ride->driver_photo ?? null,
                    ],
                    'passengers' => $passengers,
                ];
            });
        // ✅ Mobil rides - DENGAN JOIN ke kendaraan_mitra DAN passenger
        $mobilRides = DB::table('tebengan_mobil as tmb')
            ->leftJoin('users as u', 'tmb.user_id', '=', 'u.id')
            ->leftJoin('kendaraan_mitra as km', 'tmb.kendaraan_mitra_id', '=', 'km.id')
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
                // Vehicle from kendaraan_mitra
                'km.name as vehicle_name',
                'km.plate_number as vehicle_plate',
                'km.brand as vehicle_brand',
                'km.model as vehicle_model',
                'km.color as vehicle_color',
                'km.vehicle_type as vehicle_type',
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
                // Ambil data passengers dari tabel penumpang_booking_mobil
                $passengers = DB::table('penumpang_booking_mobil as pbm')
                    ->join('booking_mobil as bm', 'pbm.booking_mobil_id', '=', 'bm.id')
                    ->where('bm.ride_id', $ride->id)
                    ->whereIn('bm.status', ['paid', 'selesai'])
                    ->select(
                        'pbm.id',
                        'pbm.nama',
                        'pbm.nik',
                        'pbm.no_telepon',
                        'pbm.jenis_kelamin'
                    )
                    ->get()
                    ->map(function ($p) {
                        return [
                            'id' => $p->id,
                            'name' => $p->nama ?? 'Unknown',
                            'nik' => $p->nik ?? '',
                            'phone' => $p->no_telepon ?? '',
                            'gender' => $p->jenis_kelamin ?? '',
                        ];
                    })
                    ->toArray();

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
                        'name' => $ride->vehicle_name ?? '',
                        'plate' => $ride->vehicle_plate ?? '',
                        'brand' => $ride->vehicle_brand ?? '',
                        'type' => $ride->vehicle_type ?? 'Mobil',
                        'color' => $ride->vehicle_color ?? '',
                        'model' => $ride->vehicle_model ?? '',
                    ],
                    'available_seats' => $ride->available_seats,
                    'status' => $ride->status,
                    'driver' => [
                        'id' => $ride->driver_id,
                        'name' => $ride->driver_name ?? 'Unknown',
                        'phone' => $ride->driver_phone ?? '',
                        'photo' => $ride->driver_photo ?? null,
                    ],
                    'passengers' => $passengers,
                ];
            });

        // ✅ Barang rides - NEBENG BARANG
        $barangRides = DB::table('tebengan_barang as tb')
            ->leftJoin('users as u', 'tb.user_id', '=', 'u.id')
            ->leftJoin('locations as origin', 'tb.origin_location_id', '=', 'origin.id')
            ->leftJoin('locations as dest', 'tb.destination_location_id', '=', 'dest.id')
            ->where('tb.destination_location_id', $user->location_id)
            ->whereIn('tb.status', ['active', 'full'])
            ->where('tb.departure_date', '>=', now()->toDateString())
            ->orderBy('tb.departure_date')
            ->orderBy('tb.departure_time')
            ->select(
                'tb.id',
                'tb.departure_date',
                'tb.departure_time',
                'tb.price',
                'tb.status',
                'tb.service_type',
                'tb.ride_type',
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
                    'ride_type' => 'barang',
                    'service_type' => 'barang',
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
                    'available_seats' => 0,
                    'status' => $ride->status,
                    'driver' => [
                        'id' => $ride->driver_id,
                        'name' => $ride->driver_name ?? 'Unknown',
                        'phone' => $ride->driver_phone ?? '',
                        'photo' => $ride->driver_photo ?? null,
                    ],
                ];
            });

        // ✅ Titip Barang rides (tabel ini menggunakan transportation_type, bukan service_type/ride_type)
        $titipBarangRides = DB::table('tebengan_titip_barang as ttb')
            ->leftJoin('users as u', 'ttb.user_id', '=', 'u.id')
            ->leftJoin('locations as origin', 'ttb.origin_location_id', '=', 'origin.id')
            ->leftJoin('locations as dest', 'ttb.destination_location_id', '=', 'dest.id')
            ->where('ttb.destination_location_id', $user->location_id)
            ->whereIn('ttb.status', ['active', 'full'])
            ->where('ttb.departure_date', '>=', now()->toDateString())
            ->orderBy('ttb.departure_date')
            ->orderBy('ttb.departure_time')
            ->select(
                'ttb.id',
                'ttb.departure_date',
                'ttb.departure_time',
                'ttb.price',
                'ttb.status',
                'ttb.transportation_type',
                'ttb.bagasi_capacity',
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
                    'ride_type' => $ride->transportation_type ?? 'bus',
                    'service_type' => 'titip_barang',
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
                        'type' => 'Titip Barang',
                        'color' => '',
                    ],
                    'available_seats' => 0,
                    'bagasi_capacity' => $ride->bagasi_capacity ?? 0,
                    'status' => $ride->status,
                    'driver' => [
                        'id' => $ride->driver_id,
                        'name' => $ride->driver_name ?? 'Unknown',
                        'phone' => $ride->driver_phone ?? '',
                        'photo' => $ride->driver_photo ?? null,
                    ],
                ];
            });

        // Merge & sort all rides
        $rides = $motorRides
            ->concat($mobilRides)
            ->concat($barangRides)
            ->concat($titipBarangRides)
            ->sortBy(function($r) {
                return $r['date'] . ' ' . $r['time'];
            })
            ->values()
            ->toArray();

        return response()->json([
            'success' => true,
            'message' => 'Data tebengan berhasil diambil',
            'data' => $rides,
            'debug' => [
                'user_location_id' => $user->location_id,
                'motor_rides_count' => $motorRides->count(),
                'mobil_rides_count' => $mobilRides->count(),
                'barang_rides_count' => $barangRides->count(),
                'titip_barang_rides_count' => $titipBarangRides->count(),
            ],
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
        // Count Titip Barang (from tebengan_titip_barang table)
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
        return response()->json([
            'success' => false,
            'message' => 'Token tidak ditemukan'
        ], 401);
    }

    $hashed = hash('sha256', $bearer);

    $apiToken = ApiToken::where('token', $hashed)
        ->where('expires_at', '>', now())
        ->first();

    if (!$apiToken) {
        return response()->json([
            'success' => false,
            'message' => 'Token tidak valid atau sudah kadaluarsa'
        ], 401);
    }

    Log::info('PosMitra auth - ApiToken found', [
        'user_id' => $apiToken->user_id,
        'posmitra_id' => $apiToken->posmitra_id,
        'user_type' => $apiToken->user_type,
        'expires_at' => $apiToken->expires_at,
    ]);

    if ($apiToken->user_type === 'posmitra') {
        $posMitraUser = PosMitraUser::find($apiToken->posmitra_id);

        if ($posMitraUser) {
            return $posMitraUser;
        }

        return response()->json([
            'success' => false,
            'message' => 'User pos mitra tidak ditemukan'
        ], 404);
    }

    return response()->json([
        'success' => false,
        'message' => 'User tidak valid'
    ], 401);
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

    // ✅ AMBIL MOTOR YANG SUDAH COMPLETED - DENGAN JOIN kendaraan_mitra
    $motorRides = DB::table('tebengan_motor as tm')
        ->leftJoin('users as u', 'tm.user_id', '=', 'u.id')
        ->leftJoin('kendaraan_mitra as km', 'tm.kendaraan_mitra_id', '=', 'km.id')
        ->leftJoin('locations as origin', 'tm.origin_location_id', '=', 'origin.id')
        ->leftJoin('locations as dest', 'tm.destination_location_id', '=', 'dest.id')
        ->where('tm.destination_location_id', $user->location_id)
        ->where('tm.status', 'completed')  // FILTER COMPLETED!
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
            // Vehicle from kendaraan_mitra
            'km.name as vehicle_name',
            'km.plate_number as vehicle_plate',
            'km.brand as vehicle_brand',
            'km.model as vehicle_model',
            'km.color as vehicle_color',
            'km.vehicle_type as vehicle_type',
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
                    'name' => $ride->vehicle_name ?? '',
                    'plate' => $ride->vehicle_plate ?? '',
                    'brand' => $ride->vehicle_brand ?? '',
                    'type' => $ride->vehicle_type ?? 'Motor',
                    'color' => $ride->vehicle_color ?? '',
                    'model' => $ride->vehicle_model ?? '',
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

    // ✅ AMBIL MOBIL YANG SUDAH COMPLETED - DENGAN JOIN kendaraan_mitra DAN passenger
    $mobilRides = DB::table('tebengan_mobil as tmb')
        ->leftJoin('users as u', 'tmb.user_id', '=', 'u.id')
        ->leftJoin('kendaraan_mitra as km', 'tmb.kendaraan_mitra_id', '=', 'km.id')
        ->leftJoin('locations as origin', 'tmb.origin_location_id', '=', 'origin.id')
        ->leftJoin('locations as dest', 'tmb.destination_location_id', '=', 'dest.id')
        ->where('tmb.destination_location_id', $user->location_id)
        ->where('tmb.status', 'completed')  // FILTER COMPLETED!
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
            // Vehicle from kendaraan_mitra
            'km.name as vehicle_name',
            'km.plate_number as vehicle_plate',
            'km.brand as vehicle_brand',
            'km.model as vehicle_model',
            'km.color as vehicle_color',
            'km.vehicle_type as vehicle_type',
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
            // Ambil data passengers dari tabel penumpang_booking_mobil
            $passengers = DB::table('penumpang_booking_mobil as pbm')
                ->join('booking_mobil as bm', 'pbm.booking_mobil_id', '=', 'bm.id')
                ->where('bm.ride_id', $ride->id)
                ->whereIn('bm.status', ['paid', 'selesai'])
                ->select(
                    'pbm.id',
                    'pbm.nama',
                    'pbm.nik',
                    'pbm.no_telepon',
                    'pbm.jenis_kelamin'
                )
                ->get()
                ->map(function ($p) {
                    return [
                        'id' => $p->id,
                        'name' => $p->nama ?? 'Unknown',
                        'nik' => $p->nik ?? '',
                        'phone' => $p->no_telepon ?? '',
                        'gender' => $p->jenis_kelamin ?? '',
                    ];
                })
                ->toArray();

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
                    'name' => $ride->vehicle_name ?? '',
                    'plate' => $ride->vehicle_plate ?? '',
                    'brand' => $ride->vehicle_brand ?? '',
                    'type' => $ride->vehicle_type ?? 'Mobil',
                    'color' => $ride->vehicle_color ?? '',
                    'model' => $ride->vehicle_model ?? '',
                ],
                'available_seats' => $ride->available_seats,
                'status' => $ride->status,
                'driver' => [
                    'id' => $ride->driver_id,
                    'name' => $ride->driver_name ?? 'Unknown',
                    'phone' => $ride->driver_phone ?? '',
                    'photo' => $ride->driver_photo ?? null,
                ],
                'passengers' => $passengers,
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