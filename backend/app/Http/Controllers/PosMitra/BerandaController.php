<?php

namespace App\Http\Controllers\PosMitra;

use App\Http\Controllers\Controller;
use App\Models\ApiToken;
use App\Models\User;
use App\Models\PosMitraUser;
use App\Models\Ride;
use App\Models\CarRide;
use App\Enums\UserRole;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class BerandaController extends Controller
{
    /**
     * Return posmitra beranda data (uses custom ApiToken auth)
     */
    public function beranda(Request $request)
    {
        $user = $this->getAuthenticatedUser($request);
        if ($user instanceof \Illuminate\Http\JsonResponse) {
            return $user;
        }

        return response()->json([
            'success' => true,
            'message' => 'Saldo berhasil diambil',
            'data' => [
                'balance' => (float) ($user->balance ?? 0),
            ],
        ]);
    }

    /**
     * Get upcoming rides (tebengan akan datang) untuk pos mitra
     * Menampilkan tebengan yang destination_location_id sama dengan assigned_location_id pos mitra
     */
    public function upcomingRides(Request $request)
    {
        Log::info('PosMitra upcomingRides called', [
            'bearer_token_exists' => $request->bearerToken() ? 'yes' : 'no',
            'authorization_header' => $request->header('Authorization') ? 'exists' : 'missing',
        ]);

        $user = $this->getAuthenticatedUser($request);
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
            ]);
        }

        $rides = [];

        // Get tebengan motor (from rides table)
        $motorRides = Ride::with(['user', 'originLocation', 'destinationLocation'])
            ->where('destination_location_id', $user->location_id)
            ->whereIn('status', ['active', 'full'])
            ->where('departure_date', '>=', now()->toDateString())
            ->orderBy('departure_date')
            ->orderBy('departure_time')
            ->get()
            ->map(function ($ride) {
                return [
                    'id' => $ride->id,
                    'ride_type' => 'motor',
                    'service_type' => $ride->service_type ?? 'tebengan',
                    'date' => $ride->departure_date->format('Y-m-d'),
                    'time' => $ride->departure_time,
                    'origin' => [
                        'id' => $ride->originLocation->id ?? null,
                        'name' => $ride->originLocation->name ?? 'Unknown',
                        'detail' => $ride->originLocation->address ?? '',
                    ],
                    'destination' => [
                        'id' => $ride->destinationLocation->id ?? null,
                        'name' => $ride->destinationLocation->name ?? 'Unknown',
                        'detail' => $ride->destinationLocation->address ?? '',
                    ],
                    'price' => (float) $ride->price,
                    'vehicle' => [
                        'name' => $ride->vehicle_name ?? '',
                        'plate' => $ride->vehicle_plate ?? '',
                        'brand' => $ride->vehicle_brand ?? '',
                        'type' => $ride->vehicle_type ?? '',
                        'color' => $ride->vehicle_color ?? '',
                    ],
                    'available_seats' => $ride->available_seats,
                    'status' => $ride->status,
                    'driver' => [
                        'id' => $ride->user->id ?? null,
                        'name' => $ride->user->name ?? 'Unknown',
                        'phone' => $ride->user->phone ?? '',
                        'photo' => $ride->user->profile_photo ?? null,
                    ],
                ];
            });

        // Get tebengan mobil (from tebengan_mobil table)
        $mobilRides = CarRide::with(['user', 'originLocation', 'destinationLocation', 'kendaraanMitra'])
            ->where('destination_location_id', $user->location_id)
            ->whereIn('status', ['active', 'full'])
            ->where('departure_date', '>=', now()->toDateString())
            ->orderBy('departure_date')
            ->orderBy('departure_time')
            ->get()
            ->map(function ($ride) {
                $vehicle = $ride->kendaraanMitra;
                return [
                    'id' => $ride->id,
                    'ride_type' => 'mobil',
                    'service_type' => 'tebengan',
                    'date' => $ride->departure_date->format('Y-m-d'),
                    'time' => $ride->departure_time,
                    'origin' => [
                        'id' => $ride->originLocation->id ?? null,
                        'name' => $ride->originLocation->name ?? 'Unknown',
                        'detail' => $ride->originLocation->address ?? '',
                    ],
                    'destination' => [
                        'id' => $ride->destinationLocation->id ?? null,
                        'name' => $ride->destinationLocation->name ?? 'Unknown',
                        'detail' => $ride->destinationLocation->address ?? '',
                    ],
                    'price' => (float) $ride->price,
                    'vehicle' => [
                        'name' => $vehicle->nama_kendaraan ?? '',
                        'plate' => $vehicle->plat_nomor ?? '',
                        'brand' => $vehicle->merk ?? '',
                        'type' => $vehicle->jenis_kendaraan ?? '',
                        'color' => $vehicle->warna ?? '',
                    ],
                    'available_seats' => $ride->available_seats,
                    'status' => $ride->status,
                    'driver' => [
                        'id' => $ride->user->id ?? null,
                        'name' => $ride->user->name ?? 'Unknown',
                        'phone' => $ride->user->phone ?? '',
                        'photo' => $ride->user->profile_photo ?? null,
                    ],
                ];
            });

        // Merge and sort all rides
        $rides = $motorRides->concat($mobilRides)->sortBy(function ($ride) {
            return $ride['date'] . ' ' . $ride['time'];
        })->values();

        return response()->json([
            'success' => true,
            'message' => 'Data tebengan akan datang berhasil diambil',
            'data' => $rides,
        ]);
    }

    /**
     * Get statistics untuk pos mitra berdasarkan lokasi
     */
    public function statistics(Request $request)
    {
        $user = $this->getAuthenticatedUser($request);
        if ($user instanceof \Illuminate\Http\JsonResponse) {
            return $user;
        }

        // Cek apakah pos mitra memiliki assigned location
        if (!$user->location_id) {
            return response()->json([
                'success' => true,
                'data' => [
                    'nabung_motor' => 0,
                    'nabung_mobil' => 0,
                    'nabung_barang' => 0,
                    'titip_barang' => 0,
                ],
            ]);
        }

        // Count Nabung Motor (completed rides)
        $nabungMotor = Ride::where('destination_location_id', $user->location_id)
            ->where('status', 'completed')
            ->where('service_type', 'tebengan')
            ->count();

        // Count Nabung Mobil (completed car rides)
        $nabungMobil = CarRide::where('destination_location_id', $user->location_id)
            ->where('status', 'completed')
            ->count();

        // Count Nabung Barang (motor with barang service)
        $nabungBarang = Ride::where('destination_location_id', $user->location_id)
            ->where('status', 'completed')
            ->whereIn('service_type', ['barang', 'both'])
            ->count();

        // Count Titip Barang (from tebengan_titip_barang table)
        $titipBarang = DB::table('tebengan_titip_barang')
            ->where('destination_location_id', $user->location_id)
            ->where('status', 'completed')
            ->count();

        return response()->json([
            'success' => true,
            'data' => [
                'nabung_motor' => $nabungMotor,
                'nabung_mobil' => $nabungMobil,
                'nabung_barang' => $nabungBarang,
                'titip_barang' => $titipBarang,
            ],
        ]);
    }

    /**
     * Authenticate using custom ApiToken (copied from ProfileController)
     */
    private function getAuthenticatedUser(Request $request)
    {
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak ditemukan',
            ], 401);
        }

        $hashed = hash('sha256', $bearer);

        $apiToken = ApiToken::where('token', $hashed)
            ->where('expires_at', '>', now())
            ->first();

        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak valid atau sudah kadaluarsa',
            ], 401);
        }

        Log::info('PosMitra auth - ApiToken found', [
            'user_id' => $apiToken->user_id,
            'posmitra_id' => $apiToken->posmitra_id,
            'user_type' => $apiToken->user_type,
            'expires_at' => $apiToken->expires_at,
        ]);

        // Check first in PosMitraUser table based on user_type
        if ($apiToken->user_type === 'posmitra') {
            if (!$apiToken->posmitra_id) {
                Log::error('PosMitra auth - Token is posmitra type but posmitra_id is null');
                return response()->json([
                    'success' => false,
                    'message' => 'Token posmitra tidak valid',
                ], 401);
            }
            
            $posMitraUser = PosMitraUser::find($apiToken->posmitra_id);
            if ($posMitraUser) {
                Log::info('PosMitra auth - Found in PosMitraUser table', ['posmitra_id' => $posMitraUser->id]);
                return $posMitraUser;
            }
            Log::warning('PosMitra auth - Token is posmitra type but user not found in PosMitraUser table', [
                'posmitra_id' => $apiToken->posmitra_id,
            ]);
        }

        // Fallback to User table for backward compatibility (using user_id)
        if ($apiToken->user_id) {
            $user = User::find($apiToken->user_id);
            if ($user && $user->role === UserRole::POSMITRA) {
                Log::info('PosMitra auth - Found in User table (backward compatibility)', ['user_id' => $user->id]);
                return $user;
            }
        }

        Log::error('PosMitra auth - User not found in both tables', [
            'user_id' => $apiToken->user_id,
            'posmitra_id' => $apiToken->posmitra_id,
        ]);
        return response()->json([
            'success' => false,
            'message' => 'User tidak ditemukan atau bukan posmitra',
        ], 404);
    }
}
