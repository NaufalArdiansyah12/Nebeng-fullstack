<?php

namespace App\Http\Controllers\PosMitra;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Services\PointRewardService;
use App\Models\Ride;
use App\Models\CarRide;
use App\Models\BarangRide;
use App\Models\TebenganTitipBarang;
use App\Models\Booking;
use App\Models\BookingMobil;
use App\Models\BookingBarang;
use App\Models\BookingTitipBarang;

class QrController extends Controller
{
    /**
     * Verify QR code and return booking details
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function verifyQRCode(Request $request)
    {
        try {
            $request->validate([
                'qr_data' => 'required|string',
            ]);

            $qrData = $request->qr_data;
            Log::info('PosMitra QR Verification', ['qr_data' => $qrData]);

            // Parse QR code format: RIDE-{TYPE}-{ID}-{RANDOM}
            // Example: RIDE-MOTOR-123-ABC123XY
            if (!preg_match('/^RIDE-([A-Z]+)-(\d+)-/', $qrData, $matches)) {
                return response()->json([
                    'success' => false,
                    'message' => 'QR Code tidak valid',
                ], 400);
            }

            $rideType = strtolower($matches[1]);
            $rideId = (int) $matches[2];

            // Find the ride and booking based on type
            $result = $this->findBookingByQrCode($qrData, $rideType, $rideId);

            if (!$result) {
                return response()->json([
                    'success' => false,
                    'message' => 'Data booking tidak ditemukan',
                ], 404);
            }

            return response()->json([
                'success' => true,
                'message' => 'QR Code berhasil diverifikasi',
                'data' => $result,
            ]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Data tidak valid',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            Log::error('QR Verification Error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan saat memverifikasi QR Code',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Find booking by QR code
     * 
     * @param string $qrData
     * @param string $rideType
     * @param int $rideId
     * @return array|null
     */
    private function findBookingByQrCode($qrData, $rideType, $rideId)
    {
        switch ($rideType) {
            case 'motor':
                return $this->findMotorBooking($qrData, $rideId);
            
            case 'mobil':
                return $this->findMobilBooking($qrData, $rideId);
            
            case 'barang':
                return $this->findBarangBooking($qrData, $rideId);
            
            case 'titip':
                return $this->findTitipBarangBooking($qrData, $rideId);
            
            default:
                return null;
        }
    }

    /**
     * Find motor booking
     */
    private function findMotorBooking($qrData, $rideId)
    {
        // First, try to find the ride with matching ID (from QR code pattern)
        $ride = Ride::with([
            'user',
            'originLocation',
            'destinationLocation',
            'kendaraanMitra'
        ])->where('qr_code_data', $qrData)
          ->where('id', $rideId)
          ->first();

        // Check if this ride has bookings
        if ($ride) {
            $hasBookings = Booking::where('ride_id', $ride->id)
                ->where('status', '!=', 'cancelled')
                ->exists();
            
            if (!$hasBookings) {
                // This ride doesn't have bookings, try fallback
                $ride = null;
            }
        }

        // If not found with ID match OR has no bookings, try to find any ride with this QR code that has bookings
        if (!$ride) {
            $rides = Ride::with([
                'user',
                'originLocation',
                'destinationLocation',
                'kendaraanMitra'
            ])->where('qr_code_data', $qrData)->get();

            // Find the first ride that has bookings
            foreach ($rides as $r) {
                $hasBookings = Booking::where('ride_id', $r->id)
                    ->where('status', '!=', 'cancelled')
                    ->exists();
                if ($hasBookings) {
                    $ride = $r;
                    break;
                }
            }
        }

        if (!$ride) {
            return null;
        }

        // Get all bookings for this ride (accept any status that's not cancelled)
        $bookings = Booking::with(['user'])
            ->where('ride_id', $ride->id)
            ->where('status', '!=', 'cancelled')
            ->get();

        if ($bookings->isEmpty()) {
            return null;
        }

        // Calculate total earnings from all passengers
        $totalEarnings = 0;
        $passengerItems = [];

        foreach ($bookings as $booking) {
            $passengerItems[] = [
                'id' => $booking->id,
                'name' => $booking->user->name ?? 'Unknown',
                'phone' => $booking->user->phone ?? '-',
                'seats' => $booking->seats ?? 1,
                'status' => $booking->status,
            ];

            // Calculate earnings based on price per seat
            if ($ride->price && $booking->seats) {
                $totalEarnings += $ride->price * $booking->seats;
            }
        }

        return [
            'booking' => [
                'id' => $bookings->first()->id,
                'booking_number' => $bookings->first()->booking_number ?? '-',
                'status' => $bookings->first()->status,
                'total_passengers' => $bookings->count(),
                'total_seats' => $bookings->sum('seats'),
            ],
            'trip' => [
                'id' => $ride->id,
                'ride_type' => 'motor',
                'origin_city' => $ride->originLocation->city ?? '-',
                'origin_address' => $ride->originLocation->address ?? '-',
                'destination_city' => $ride->destinationLocation->city ?? '-',
                'destination_address' => $ride->destinationLocation->address ?? '-',
                'departure_time' => $ride->departure_date . ' ' . $ride->departure_time,
                'price_per_seat' => $ride->price ?? 0,
                'available_seats' => $ride->available_seats ?? 0,
            ],
            'driver' => [
                'id' => $ride->user->id ?? null,
                'name' => $ride->user->name ?? '-',
                'phone' => $ride->user->phone ?? '-',
                'photo' => $ride->user->profile_photo ?? null,
            ],
            'vehicle' => [
                'id' => $ride->kendaraanMitra->id ?? null,
                'type' => $ride->kendaraanMitra->vehicle_type ?? '-',
                'brand' => $ride->kendaraanMitra->brand ?? '-',
                'model' => $ride->kendaraanMitra->model ?? '-',
                'plate' => $ride->kendaraanMitra->license_plate ?? '-',
                'color' => $ride->kendaraanMitra->color ?? '-',
            ],
            'passenger' => $bookings->first()->user ? [
                'id' => $bookings->first()->user->id,
                'name' => $bookings->first()->user->name ?? '-',
                'phone' => $bookings->first()->user->phone ?? '-',
            ] : null,
            'items' => $passengerItems,
            'estimated_earnings' => $totalEarnings,
        ];
    }

    /**
     * Find mobil booking
     */
    private function findMobilBooking($qrData, $rideId)
    {
        $ride = CarRide::with([
            'user',
            'originLocation',
            'destinationLocation',
            'kendaraanMitra'
        ])->where('qr_code_data', $qrData)
          ->where('id', $rideId)
          ->first();

        if (!$ride) {
            return null;
        }

        $bookings = BookingMobil::with(['user'])
            ->where('tebengan_mobil_id', $rideId)
            ->whereIn('status', ['confirmed', 'paid', 'on_trip', 'arrived'])
            ->get();

        if ($bookings->isEmpty()) {
            return null;
        }

        $totalEarnings = 0;
        $passengerItems = [];

        foreach ($bookings as $booking) {
            $passengerItems[] = [
                'id' => $booking->id,
                'name' => $booking->user->name ?? 'Unknown',
                'phone' => $booking->user->phone ?? '-',
                'seats' => $booking->seats ?? 1,
                'status' => $booking->status,
            ];

            if ($ride->price && $booking->seats) {
                $totalEarnings += $ride->price * $booking->seats;
            }
        }

        return [
            'booking' => [
                'id' => $bookings->first()->id,
                'booking_number' => $bookings->first()->booking_number ?? '-',
                'status' => $bookings->first()->status,
                'total_passengers' => $bookings->count(),
                'total_seats' => $bookings->sum('seats'),
            ],
            'trip' => [
                'id' => $ride->id,
                'ride_type' => 'mobil',
                'origin_city' => $ride->originLocation->city ?? '-',
                'origin_address' => $ride->originLocation->address ?? '-',
                'destination_city' => $ride->destinationLocation->city ?? '-',
                'destination_address' => $ride->destinationLocation->address ?? '-',
                'departure_time' => $ride->departure_date . ' ' . $ride->departure_time,
                'price_per_seat' => $ride->price ?? 0,
                'available_seats' => $ride->available_seats ?? 0,
            ],
            'driver' => [
                'id' => $ride->user->id ?? null,
                'name' => $ride->user->name ?? '-',
                'phone' => $ride->user->phone ?? '-',
                'photo' => $ride->user->profile_photo ?? null,
            ],
            'vehicle' => [
                'id' => $ride->kendaraanMitra->id ?? null,
                'type' => $ride->kendaraanMitra->vehicle_type ?? '-',
                'brand' => $ride->kendaraanMitra->brand ?? '-',
                'model' => $ride->kendaraanMitra->model ?? '-',
                'plate' => $ride->kendaraanMitra->license_plate ?? '-',
                'color' => $ride->kendaraanMitra->color ?? '-',
            ],
            'passenger' => $bookings->first()->user ? [
                'id' => $bookings->first()->user->id,
                'name' => $bookings->first()->user->name ?? '-',
                'phone' => $bookings->first()->user->phone ?? '-',
            ] : null,
            'items' => $passengerItems,
            'estimated_earnings' => $totalEarnings,
        ];
    }

    /**
     * Find barang booking
     */
    private function findBarangBooking($qrData, $rideId)
    {
        $ride = BarangRide::with([
            'user',
            'originLocation',
            'destinationLocation',
            'kendaraanMitra'
        ])->where('qr_code_data', $qrData)
          ->where('id', $rideId)
          ->first();

        if (!$ride) {
            return null;
        }

        $bookings = BookingBarang::with(['user'])
            ->where('tebengan_barang_id', $rideId)
            ->whereIn('status', ['confirmed', 'paid', 'on_trip', 'arrived'])
            ->get();

        if ($bookings->isEmpty()) {
            return null;
        }

        $totalEarnings = 0;
        $itemsList = [];

        foreach ($bookings as $booking) {
            $itemsList[] = [
                'id' => $booking->id,
                'sender_name' => $booking->user->name ?? 'Unknown',
                'phone' => $booking->user->phone ?? '-',
                'weight' => $booking->weight ?? 0,
                'description' => $booking->description ?? '-',
                'status' => $booking->status,
            ];

            // Calculate based on weight and price
            if ($ride->price_per_kg && $booking->weight) {
                $totalEarnings += $ride->price_per_kg * $booking->weight;
            }
        }

        return [
            'booking' => [
                'id' => $bookings->first()->id,
                'booking_number' => $bookings->first()->booking_number ?? '-',
                'status' => $bookings->first()->status,
                'total_items' => $bookings->count(),
                'total_weight' => $bookings->sum('weight'),
            ],
            'trip' => [
                'id' => $ride->id,
                'ride_type' => 'barang',
                'origin_city' => $ride->originLocation->city ?? '-',
                'origin_address' => $ride->originLocation->address ?? '-',
                'destination_city' => $ride->destinationLocation->city ?? '-',
                'destination_address' => $ride->destinationLocation->address ?? '-',
                'departure_time' => $ride->departure_date . ' ' . $ride->departure_time,
                'price_per_kg' => $ride->price_per_kg ?? 0,
                'available_weight' => $ride->available_weight ?? 0,
            ],
            'driver' => [
                'id' => $ride->user->id ?? null,
                'name' => $ride->user->name ?? '-',
                'phone' => $ride->user->phone ?? '-',
                'photo' => $ride->user->profile_photo ?? null,
            ],
            'vehicle' => [
                'id' => $ride->kendaraanMitra->id ?? null,
                'type' => $ride->kendaraanMitra->vehicle_type ?? '-',
                'brand' => $ride->kendaraanMitra->brand ?? '-',
                'model' => $ride->kendaraanMitra->model ?? '-',
                'plate' => $ride->kendaraanMitra->license_plate ?? '-',
                'color' => $ride->kendaraanMitra->color ?? '-',
            ],
            'passenger' => null,
            'items' => $itemsList,
            'estimated_earnings' => $totalEarnings,
        ];
    }

    /**
     * Find titip barang booking
     */
    private function findTitipBarangBooking($qrData, $rideId)
    {
        $ride = TebenganTitipBarang::with([
            'user',
            'originLocation',
            'destinationLocation',
            'kendaraanMitra'
        ])->where('qr_code_data', $qrData)
          ->where('id', $rideId)
          ->first();

        if (!$ride) {
            return null;
        }

        $bookings = BookingTitipBarang::with(['user'])
            ->where('tebengan_titip_barang_id', $rideId)
            ->whereIn('status', ['confirmed', 'paid', 'on_trip', 'arrived'])
            ->get();

        if ($bookings->isEmpty()) {
            return null;
        }

        $totalEarnings = 0;
        $itemsList = [];

        foreach ($bookings as $booking) {
            $itemsList[] = [
                'id' => $booking->id,
                'sender_name' => $booking->user->name ?? 'Unknown',
                'phone' => $booking->user->phone ?? '-',
                'weight' => $booking->weight ?? 0,
                'description' => $booking->description ?? '-',
                'status' => $booking->status,
            ];

            if ($ride->price_per_kg && $booking->weight) {
                $totalEarnings += $ride->price_per_kg * $booking->weight;
            }
        }

        return [
            'booking' => [
                'id' => $bookings->first()->id,
                'booking_number' => $bookings->first()->booking_number ?? '-',
                'status' => $bookings->first()->status,
                'total_items' => $bookings->count(),
                'total_weight' => $bookings->sum('weight'),
            ],
            'trip' => [
                'id' => $ride->id,
                'ride_type' => 'titip_barang',
                'origin_city' => $ride->originLocation->city ?? '-',
                'origin_address' => $ride->originLocation->address ?? '-',
                'destination_city' => $ride->destinationLocation->city ?? '-',
                'destination_address' => $ride->destinationLocation->address ?? '-',
                'departure_time' => $ride->departure_date . ' ' . $ride->departure_time,
                'price_per_kg' => $ride->price_per_kg ?? 0,
                'available_weight' => $ride->available_weight ?? 0,
            ],
            'driver' => [
                'id' => $ride->user->id ?? null,
                'name' => $ride->user->name ?? '-',
                'phone' => $ride->user->phone ?? '-',
                'photo' => $ride->user->profile_photo ?? null,
            ],
            'vehicle' => [
                'id' => $ride->kendaraanMitra->id ?? null,
                'type' => $ride->kendaraanMitra->vehicle_type ?? '-',
                'brand' => $ride->kendaraanMitra->brand ?? '-',
                'model' => $ride->kendaraanMitra->model ?? '-',
                'plate' => $ride->kendaraanMitra->license_plate ?? '-',
                'color' => $ride->kendaraanMitra->color ?? '-',
            ],
            'passenger' => null,
            'items' => $itemsList,
            'estimated_earnings' => $totalEarnings,
        ];
    }

    /**
     * Complete ride after QR scan
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function completeRide(Request $request)
    {
        try {
            $request->validate([
                'booking_id' => 'required|integer',
                'qr_data' => 'required|string',
            ]);

            $bookingId = $request->booking_id;
            $qrData = $request->qr_data;

            Log::info('PosMitra Complete Ride', [
                'booking_id' => $bookingId,
                'qr_data' => $qrData,
            ]);

            // Parse QR code to get ride type
            if (!preg_match('/^RIDE-([A-Z]+)-(\d+)-/', $qrData, $matches)) {
                return response()->json([
                    'success' => false,
                    'message' => 'QR Code tidak valid',
                ], 400);
            }

            $rideType = strtolower($matches[1]);

            // Update booking status based on ride type
            $updated = false;
            $booking = null;

            switch ($rideType) {
                case 'motor':
                    $booking = Booking::find($bookingId);
                    if ($booking) {
                        $booking->status = 'completed';
                        $booking->save();
                        // Award points to customer
                        if ($booking->user_id) {
                            PointRewardService::awardPointsForBooking($booking->user_id, 'motor', $booking->id);
                        }
                        $updated = true;
                    }
                    break;

                case 'mobil':
                    $booking = BookingMobil::find($bookingId);
                    if ($booking) {
                        $booking->status = 'completed';
                        $booking->save();
                        // Award points to customer
                        if ($booking->user_id) {
                            PointRewardService::awardPointsForBooking($booking->user_id, 'mobil', $booking->id);
                        }
                        $updated = true;
                    }
                    break;

                case 'barang':
                    $booking = BookingBarang::find($bookingId);
                    if ($booking) {
                        $booking->status = 'completed';
                        $booking->save();
                        // Award points to customer
                        if ($booking->user_id) {
                            PointRewardService::awardPointsForBooking($booking->user_id, 'barang', $booking->id);
                        }
                        $updated = true;
                    }
                    break;

                case 'titip':
                    $booking = BookingTitipBarang::find($bookingId);
                    if ($booking) {
                        $booking->status = 'completed';
                        $booking->save();
                        // Award points to customer
                        if ($booking->user_id) {
                            PointRewardService::awardPointsForBooking($booking->user_id, 'titip', $booking->id);
                        }
                        $updated = true;
                    }
                    break;

                default:
                    return response()->json([
                        'success' => false,
                        'message' => 'Tipe tebengan tidak valid',
                    ], 400);
            }

            if (!$updated || !$booking) {
                return response()->json([
                    'success' => false,
                    'message' => 'Booking tidak ditemukan',
                ], 404);
            }

            // TODO: Additional logic
            // - Update ride status if all bookings are completed
            // - Calculate and transfer earnings to driver
            // - Send notification to customer
            // - Send notification to mitra

            Log::info('Booking completed successfully', [
                'booking_id' => $bookingId,
                'ride_type' => $rideType,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Tebengan berhasil diselesaikan',
                'data' => [
                    'booking_id' => $bookingId,
                    'status' => 'completed',
                    'booking_number' => $booking->booking_number ?? null,
                ],
            ]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Data tidak valid',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            Log::error('Complete Ride Error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal menyelesaikan tebengan',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
