<?php

namespace App\Http\Controllers\Mitra;

use App\Http\Controllers\Controller;
use App\Models\Ride;
use App\Services\PosMitraConversationService;
use App\Services\MitraNotificationService;
use App\Services\FcmService;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;

class RideController extends Controller
{
    /**
     * Generate unique QR code data for a ride
     * Format: RIDE-{type}-{id}-{random}
     */
    private function generateQrCode($rideType, $rideId)
    {
        $type = strtoupper($rideType);
        $random = Str::upper(Str::random(8));
        return "RIDE-{$type}-{$rideId}-{$random}";
    }

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
        // AND TebenganTitipBarang (tebengan_titip_barang) combined
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

            $barangRides = $barangQuery->orderBy('departure_date')
                ->orderBy('departure_time')
                ->get();

            // Also fetch from TebenganTitipBarang
            $titipQuery = \App\Models\TebenganTitipBarang::with(['user', 'originLocation', 'destinationLocation', 'kendaraanMitra'])
                ->where('status', 'active');

            if ($request->has('origin_location_id')) {
                $titipQuery->where('origin_location_id', $request->origin_location_id);
            }
            if ($request->has('destination_location_id')) {
                $titipQuery->where('destination_location_id', $request->destination_location_id);
            }
            if ($request->has('date')) {
                $titipQuery->whereDate('departure_date', $request->date);
            }

            $titipRides = $titipQuery->orderBy('departure_date')
                ->orderBy('departure_time')
                ->get();

            // Combine both collections and sort
            $rides = $barangRides->concat($titipRides)->sortBy([
                ['departure_date', 'asc'],
                ['departure_time', 'asc']
            ])->values();

            return response()->json([
                'success' => true,
                'data' => $rides,
            ]);
        }

        $query = Ride::with(['user', 'originLocation', 'destinationLocation', 'carRide'])
            ->where('status', 'active')
            ->where('available_seats', '>', 0); // Only show rides with available seats

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
            'jumlah_bagasi' => 'nullable|integer|min:0',
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
                    $data = [
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
                        'status' => 'active',
                        'jumlah_bagasi' => $request->jumlah_bagasi ?? 0, // Always set default value
                    ];

                    // Store bagasi_capacity (max capacity per bagasi in kg)
                    if ($request->has('bagasi_capacity') && Schema::hasColumn('tebengan_motor', 'bagasi_capacity')) {
                        $data['bagasi_capacity'] = $request->bagasi_capacity;
                    }

                    $r = Ride::create($data);

                    // Generate and save QR code
                    $qrCode = $this->generateQrCode('motor', $r->id);
                    $r->qr_code_data = $qrCode;
                    $r->save();

                    // Create conversations with pos mitra (origin & destination)
                    try {
                        // Only create conversation if Firebase is configured
                        if (config('firebase.credentials') && file_exists(config('firebase.credentials'))) {
                            try {
                                $conversationService = app(PosMitraConversationService::class);
                                $conversations = $conversationService->createTebenganConversations(
                                    $apiToken->user_id,
                                    $request->origin_location_id,
                                    $request->destination_location_id,
                                    'motor'
                                );

                                // Save conversation IDs to ride
                                if ($conversations['origin_conversation_id']) {
                                    $r->origin_pos_conversation_id = $conversations['origin_conversation_id'];
                                }
                                if ($conversations['destination_conversation_id']) {
                                    $r->destination_pos_conversation_id = $conversations['destination_conversation_id'];
                                }
                                $r->save();
                            } catch (\Throwable $firebaseError) {
                                Log::warning('Firebase service initialization failed, continuing without conversation: ' . $firebaseError->getMessage());
                            }
                        } else {
                            Log::info('Firebase credentials not configured, skipping conversation creation');
                        }
                    } catch (\Exception $e) {
                        Log::error('Failed to create pos mitra conversations for motor ride: ' . $e->getMessage());
                    }

                    // If mitra provided kendaraan_mitra_id and jumlah_bagasi, persist jumlah_bagasi into kendaraan_mitra
                    try {
                        $kmId = $request->kendaraan_mitra_id ?? null;
                        $bagasi = $request->jumlah_bagasi ?? null;
                        if ($kmId && $bagasi !== null && Schema::hasColumn('kendaraan_mitra', 'jumlah_bagasi')) {
                            \App\Models\KendaraanMitra::where('id', $kmId)->update(['jumlah_bagasi' => intval($bagasi)]);
                        }
                    } catch (\Throwable $__e) {
                        // ignore update failures but log
                        Log::warning('Failed to update kendaraan_mitra.jumlah_bagasi', ['error' => $__e->getMessage()]);
                    }

                    return $r;
                }
                // For mobil rides, persist into tebengan_mobil via CarRide model.
                // Note: vehicle-specific columns were removed from `tebengan_mobil`
                // to avoid duplicated data (we store vehicle info in `kendaraan_mitra`).
                // Do NOT attempt to insert vehicle_name/plate/brand/type/color here.
                if ($request->ride_type === 'mobil') {
                    // For mobil rides, if mitra selects 'barang' (titip barang) as service_type,
                    // this should be treated as cargo-only: there are no passenger seats.
                    $availableSeats = ($request->service_type === 'barang') ? 0 : ($request->available_seats ?? 1);

                    $data = [
                        'user_id' => $apiToken->user_id,
                        'origin_location_id' => $request->origin_location_id,
                        'destination_location_id' => $request->destination_location_id,
                        'departure_date' => $request->departure_date,
                        'departure_time' => $request->departure_time,
                        'ride_type' => $request->ride_type,
                        'service_type' => $request->service_type,
                        'price' => $request->price,
                        'kendaraan_mitra_id' => $request->kendaraan_mitra_id ?? null,
                        'available_seats' => $availableSeats,
                        'status' => 'active',
                        'jumlah_bagasi' => $request->jumlah_bagasi ?? 0, // Always set default value
                    ];

                    // Store bagasi_capacity (max capacity per bagasi in kg)
                    if ($request->has('bagasi_capacity') && Schema::hasColumn('tebengan_mobil', 'bagasi_capacity')) {
                        $data['bagasi_capacity'] = $request->bagasi_capacity;
                    }

                    $car = \App\Models\CarRide::create($data);

                    // Generate and save QR code
                    $qrCode = $this->generateQrCode('mobil', $car->id);
                    $car->qr_code_data = $qrCode;
                    $car->save();

                    // Create conversations with pos mitra (origin & destination)
                    try {
                        // Only create conversation if Firebase is configured
                        if (config('firebase.credentials') && file_exists(config('firebase.credentials'))) {
                            try {
                                $conversationService = app(PosMitraConversationService::class);
                                $conversations = $conversationService->createTebenganConversations(
                                    $apiToken->user_id,
                                    $request->origin_location_id,
                                    $request->destination_location_id,
                                    'mobil'
                                );

                                // Save conversation IDs to ride
                                if ($conversations['origin_conversation_id']) {
                                    $car->origin_pos_conversation_id = $conversations['origin_conversation_id'];
                                }
                                if ($conversations['destination_conversation_id']) {
                                    $car->destination_pos_conversation_id = $conversations['destination_conversation_id'];
                                }
                                $car->save();
                            } catch (\Throwable $firebaseError) {
                                Log::warning('Firebase service initialization failed, continuing without conversation: ' . $firebaseError->getMessage());
                            }
                        } else {
                            Log::info('Firebase credentials not configured, skipping conversation creation');
                        }
                    } catch (\Exception $e) {
                        Log::error('Failed to create pos mitra conversations for mobil ride: ' . $e->getMessage());
                    }

                    // persist jumlah_bagasi into kendaraan_mitra if provided
                    try {
                        $kmId = $request->kendaraan_mitra_id ?? null;
                        $bagasi = $request->jumlah_bagasi ?? null;
                        if ($kmId && $bagasi !== null && Schema::hasColumn('kendaraan_mitra', 'jumlah_bagasi')) {
                            \App\Models\KendaraanMitra::where('id', $kmId)->update(['jumlah_bagasi' => intval($bagasi)]);
                        }
                    } catch (\Throwable $__e) {
                        Log::warning('Failed to update kendaraan_mitra.jumlah_bagasi', ['error' => $__e->getMessage()]);
                    }

                    return $car;
                }

                // For barang rides, persist into tebengan_barang via BarangRide model.
                if ($request->ride_type === 'barang') {
                    $data = [
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
                        'status' => 'active',
                        'jumlah_bagasi' => $request->jumlah_bagasi ?? 0, // Always set default value
                    ];

                    // Store bagasi_capacity (max capacity per bagasi in kg)
                    if ($request->has('bagasi_capacity') && Schema::hasColumn('tebengan_barang', 'bagasi_capacity')) {
                        $data['bagasi_capacity'] = $request->bagasi_capacity;
                    }

                    $barang = \App\Models\BarangRide::create($data);

                    // Generate and save QR code
                    $qrCode = $this->generateQrCode('barang', $barang->id);
                    $barang->qr_code_data = $qrCode;
                    $barang->save();

                    // persist jumlah_bagasi into kendaraan_mitra if provided
                    try {
                        $kmId = $request->kendaraan_mitra_id ?? null;
                        if ($kmId && $request->has('jumlah_bagasi') && Schema::hasColumn('kendaraan_mitra', 'jumlah_bagasi')) {
                            \App\Models\KendaraanMitra::where('id', $kmId)->update(['jumlah_bagasi' => intval($request->jumlah_bagasi)]);
                        }
                    } catch (\Throwable $__e) {
                        Log::warning('Failed to update kendaraan_mitra.jumlah_bagasi', ['error' => $__e->getMessage()]);
                    }

                    // If a photo was uploaded as part of the request, store it and save into extra
                    if ($request->hasFile('photo')) {
                        try {
                            $file = $request->file('photo');
                            $filename = 'uploads/' . time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
                            Storage::disk('public')->put($filename, file_get_contents($file));
                            $url = '/storage' . $filename;
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

        // 🔔 KIRIM PUSH NOTIFICATION KE POS MITRA
        // Setelah ride dibuat, kirim notifikasi ke PosMitra terkait lokasi origin dan destination
        try {
            self::sendNewRideNotifications($ride, $apiToken->user_id);
        } catch (\Exception $e) {
            Log::warning('Failed to send new ride notifications: ' . $e->getMessage());
        }

        return response()->json([
            'success' => true,
            'message' => 'Ride created successfully',
            'data' => $ride,
        ], 201);
    }

    /**
     * Send push notifications to PosMitra when new ride is created
     * Notifies PosMitra at origin and destination locations
     */
    private static function sendNewRideNotifications($ride, $driverUserId)
    {
        // Get origin and destination location IDs
        $originLocationId = $ride->origin_location_id;
        $destinationLocationId = $ride->destination_location_id;

        // Get location names for notification
        $originName = $ride->originLocation->name ?? 'Unknown';
        $destinationName = $ride->destinationLocation->name ?? 'Unknown';
        $departureDate = date('d M Y', strtotime($ride->departure_date));
        $departureTime = $ride->departure_time ?? '';
        $price = number_format($ride->price, 0, ',', '.');

        switch ($ride->ride_type) {
            case 'motor':
                $rideTypeLabel = 'Nebeng Motor';
                break;
            case 'mobil':
                $rideTypeLabel = 'Nebeng Mobil';
                break;
            case 'barang':
                $rideTypeLabel = 'Nebeng Barang';
                break;
            default:
                $rideTypeLabel = 'Tebengan';
        }

        // Title and body for notification
        $title = "🚗 Tebengan Baru Available!";
        $body = "{$rideTypeLabel} dari {$originName} ke {$destinationName} pada {$departureDate} {$departureTime}. Harga: Rp {$price}";

        $data = [
            'ride_id' => (string) $ride->id,
            'ride_type' => $ride->ride_type,
            'origin' => $originName,
            'destination' => $destinationName,
            'departure_date' => $ride->departure_date,
            'departure_time' => $ride->departure_time,
            'price' => (string) $ride->price,
            'type' => 'new_ride_available',
        ];

        // Find PosMitra users at origin and destination locations and send notification
        $locationIds = array_unique([$originLocationId, $destinationLocationId]);

        foreach ($locationIds as $locationId) {
            // Find PosMitra users at this location - check both User table and PosMitraUser table
            // First try PosMitraUser table (where FCM token is actually stored)
            $posMitraUsers = [];
            
            try {
                // Try PosMitraUser model first
                $posMitraFromTable = \App\Models\PosMitraUser::where('location_id', $locationId)
                    ->whereNotNull('fcm_token')
                    ->where('fcm_token', '!=', '')
                    ->get();
                    
                if ($posMitraFromTable->count() > 0) {
                    foreach ($posMitraFromTable as $pm) {
                        $posMitraUsers[] = $pm;
                    }
                }
            } catch (\Exception $e) {
                Log::warning('Failed to query PosMitraUser: ' . $e->getMessage());
            }
            
            // Also try User table with role = posmitra
            try {
                $usersFromUserTable = \App\Models\User::where('role', 'posmitra')
                    ->where('location_id', $locationId)
                    ->where('id', '!=', $driverUserId)
                    ->whereNotNull('fcm_token')
                    ->where('fcm_token', '!=', '')
                    ->get();
                    
                if ($usersFromUserTable->count() > 0) {
                    foreach ($usersFromUserTable as $user) {
                        // Avoid duplicates
                        $exists = false;
                        foreach ($posMitraUsers as $existing) {
                            if (isset($existing->id) && $existing->id == $user->id) {
                                $exists = true;
                                break;
                            }
                        }
                        if (!$exists) {
                            $posMitraUsers[] = $user;
                        }
                    }
                }
            } catch (\Exception $e) {
                Log::warning('Failed to query User table: ' . $e->getMessage());
            }

            Log::info('Found PosMitra users at location', [
                'location_id' => $locationId,
                'count' => count($posMitraUsers)
            ]);

            foreach ($posMitraUsers as $posMitra) {
                $fcmToken = $posMitra->fcm_token ?? null;
                
                if (empty($fcmToken)) {
                    Log::info('Skipping PosMitra - no FCM token', ['id' => $posMitra->id ?? 'unknown']);
                    continue;
                }

                // Save to notifications table
                try {
                    \App\Models\Notification::create([
                        'user_id' => $posMitra->id,
                        'type' => 'new_ride_available',
                        'title' => $title,
                        'body' => $body,
                        'icon' => '🚗',
                        'data' => $data,
                        'is_read' => false,
                    ]);
                    Log::info('Notification saved to DB', ['user_id' => $posMitra->id]);
                } catch (\Exception $e) {
                    Log::warning('Failed to save notification: ' . $e->getMessage());
                }

                // Send FCM push notification
                try {
                    $sent = FcmService::sendToToken($fcmToken, $title, $body, $data);
                    if ($sent) {
                        Log::info('FCM notification sent to PosMitra', [
                            'posmitra_id' => $posMitra->id,
                            'ride_id' => $ride->id,
                            'location_id' => $locationId,
                        ]);
                    } else {
                        Log::warning('FCM send returned false', [
                            'posmitra_id' => $posMitra->id,
                        ]);
                    }
                } catch (\Exception $e) {
                    Log::warning('Failed to send FCM to PosMitra: ' . $e->getMessage());
                }
            }
        }
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

        // Normalize ride_type: accept both 'motor' and 'tebengan_motor' formats
        $normalizedType = $rideType;
        if ($rideType === 'tebengan_motor') {
            $normalizedType = 'motor';
        } elseif ($rideType === 'tebengan_mobil') {
            $normalizedType = 'mobil';
        } elseif ($rideType === 'tebengan_barang') {
            $normalizedType = 'barang';
        } elseif ($rideType === 'tebengan_titip_barang') {
            $normalizedType = 'titip';
        }

        $bookings = [];

        switch ($normalizedType) {
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
                    ->where('ride_id', $rideId)
                    ->get();
                break;
            case 'titip':
                $bookings = \App\Models\BookingTitipBarang::with(['user'])
                    ->where('ride_id', $rideId)
                    ->get();
                break;
        }

        return response()->json([
            'success' => true,
            'data' => $bookings,
        ]);
    }

    /**
     * Cancel a ride by mitra
     * This will cancel the ride and all associated bookings
     */
    public function cancelRide(Request $request, $rideId)
    {
        $validator = Validator::make($request->all(), [
            'ride_type' => 'required|in:motor,mobil,barang,titip',
            'cancellation_reason' => 'required|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $rideType = $request->ride_type;
        $cancellationReason = $request->cancellation_reason;

        try {
            DB::beginTransaction();

            // Get the ride based on type
            $ride = null;
            $bookings = [];

            switch ($rideType) {
                case 'motor':
                    $ride = Ride::find($rideId);
                    if ($ride) {
                        $bookings = \App\Models\Booking::where('ride_id', $rideId)->get();
                    }
                    break;
                case 'mobil':
                    $ride = \App\Models\CarRide::find($rideId);
                    if ($ride) {
                        $bookings = \App\Models\BookingMobil::where('ride_id', $rideId)->get();
                    }
                    break;
                case 'barang':
                    $ride = \App\Models\BarangRide::find($rideId);
                    if ($ride) {
                        $bookings = \App\Models\BookingBarang::where('ride_id', $rideId)->get();
                    }
                    break;
                case 'titip':
                    $ride = \App\Models\TebenganTitipBarang::find($rideId);
                    if ($ride) {
                        $bookings = \App\Models\BookingTitipBarang::where('ride_id', $rideId)->get();
                    }
                    break;
            }

            if (!$ride) {
                DB::rollBack();
                return response()->json([
                    'success' => false,
                    'message' => 'Ride not found',
                ], 404);
            }

            // Check if ride can be cancelled (must be paid or active status)
            $allowedStatuses = ['paid', 'active', 'menuju_penjemputan', 'sudah_di_penjemputan'];
            if (!in_array($ride->status, $allowedStatuses)) {
                DB::rollBack();
                return response()->json([
                    'success' => false,
                    'message' => 'Ride cannot be cancelled in current status',
                ], 400);
            }

            // Update ride status to cancelled
            $updateData = ['status' => 'cancelled'];
            
            // Add optional fields if they exist in the table
            if (Schema::hasColumn($ride->getTable(), 'cancellation_reason')) {
                $updateData['cancellation_reason'] = $cancellationReason;
            }
            if (Schema::hasColumn($ride->getTable(), 'cancelled_at')) {
                $updateData['cancelled_at'] = now();
            }
            
            $ride->update($updateData);

            // Cancel all bookings and refund payments
            foreach ($bookings as $booking) {
                if ($booking->status !== 'cancelled') {
                    $bookingUpdateData = ['status' => 'cancelled'];
                    
                    if (Schema::hasColumn($booking->getTable(), 'cancellation_reason')) {
                        $bookingUpdateData['cancellation_reason'] = 'Tebengan dibatalkan oleh mitra: ' . $cancellationReason;
                    }
                    if (Schema::hasColumn($booking->getTable(), 'cancelled_at')) {
                        $bookingUpdateData['cancelled_at'] = now();
                    }
                    
                    $booking->update($bookingUpdateData);

                    // Create refund if payment was made
                    if ($booking->payment_status === 'paid' && $booking->total_fare > 0) {
                        // No admin fee for mitra cancellation - full refund
                        $totalAmount = $booking->total_fare;
                        $adminFee = 0; // No admin fee when cancelled by mitra
                        $refundAmount = $totalAmount;
                        
                        \App\Models\Refund::create([
                            'user_id' => $booking->user_id,
                            'booking_id' => $booking->id,
                            'booking_type' => $rideType,
                            'refund_reason' => 'Tebengan dibatalkan oleh mitra: ' . $cancellationReason,
                            'total_amount' => $totalAmount,
                            'refund_amount' => $refundAmount,
                            'admin_fee' => $adminFee,
                            'bank_name' => null,
                            'account_number' => null,
                            'account_holder_name' => null,
                            'status' => 'approved', // Auto-approve mitra cancellations
                            'submitted_at' => now(),
                            'approved_at' => now(),
                        ]);

                        // Add refund amount back to user's balance
                        $user = \App\Models\User::find($booking->user_id);
                        if ($user) {
                            $user->balance = ($user->balance ?? 0) + $refundAmount;
                            $user->save();
                        }
                    }
                }
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Tebengan berhasil dibatalkan',
                'data' => [
                    'ride_id' => $rideId,
                    'ride_type' => $rideType,
                    'bookings_cancelled' => $bookings->count(),
                ],
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error cancelling ride: ' . $e->getMessage());
            Log::error('Stack trace: ' . $e->getTraceAsString());
            return response()->json([
                'success' => false,
                'message' => 'Failed to cancel ride: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get mitra's cancellation count for current month
     */
    public function getMitraCancellationCount(Request $request, $mitraId)
    {
        try {
            $startOfMonth = now()->startOfMonth();
            $endOfMonth = now()->endOfMonth();

            // Count cancelled rides by this mitra in current month
            // Use updated_at as fallback if cancelled_at doesn't exist
            $motorCount = Ride::where('user_id', $mitraId)
                ->where('status', 'cancelled');
            if (Schema::hasColumn('tebengan_motor', 'cancelled_at')) {
                $motorCount->whereBetween('cancelled_at', [$startOfMonth, $endOfMonth]);
            } else {
                $motorCount->whereBetween('updated_at', [$startOfMonth, $endOfMonth]);
            }
            $motorCount = $motorCount->count();

            $mobilCount = \App\Models\CarRide::where('user_id', $mitraId)
                ->where('status', 'cancelled');
            if (Schema::hasColumn('tebengan_mobil', 'cancelled_at')) {
                $mobilCount->whereBetween('cancelled_at', [$startOfMonth, $endOfMonth]);
            } else {
                $mobilCount->whereBetween('updated_at', [$startOfMonth, $endOfMonth]);
            }
            $mobilCount = $mobilCount->count();

            $barangCount = \App\Models\BarangRide::where('user_id', $mitraId)
                ->where('status', 'cancelled');
            if (Schema::hasColumn('tebengan_barang', 'cancelled_at')) {
                $barangCount->whereBetween('cancelled_at', [$startOfMonth, $endOfMonth]);
            } else {
                $barangCount->whereBetween('updated_at', [$startOfMonth, $endOfMonth]);
            }
            $barangCount = $barangCount->count();

            $titipCount = \App\Models\TebenganTitipBarang::where('user_id', $mitraId)
                ->where('status', 'cancelled');
            if (Schema::hasColumn('tebengan_titip_barang', 'cancelled_at')) {
                $titipCount->whereBetween('cancelled_at', [$startOfMonth, $endOfMonth]);
            } else {
                $titipCount->whereBetween('updated_at', [$startOfMonth, $endOfMonth]);
            }
            $titipCount = $titipCount->count();

            $totalCount = $motorCount + $mobilCount + $barangCount + $titipCount;

            return response()->json([
                'success' => true,
                'data' => [
                    'count' => $totalCount,
                    'month' => now()->format('Y-m'),
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Error getting mitra cancellation count: ' . $e->getMessage());
            return response()->json([
                'success' => true,
                'data' => ['count' => 0],
            ]);
        }
    }
}
