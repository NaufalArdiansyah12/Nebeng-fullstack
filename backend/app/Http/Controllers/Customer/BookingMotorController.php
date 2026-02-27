<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Traits\CreatesConversation;
use App\Services\PriceCalculationService;
use App\Services\PriceCalculator;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class BookingMotorController extends Controller
{
    use CreatesConversation;

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

        // Auto-calculate price based on weight
        $calculatedPrice = null;
        $priceBreakdown = null;
        $weight = $request->weight ?? null;

        if ($weight) {
            // Map ride's service_type to pricing rule keys
            $rawService = $ride->service_type ?? null;
            $serviceTypeMap = [
                'tebengan' => 'hanya_tebengan',
                'barang' => 'hanya_barang',
                'both' => 'tebengan_dan_barang',
            ];
            $serviceType = $serviceTypeMap[$rawService] ?? $rawService;

            // Map weight label (Kecil/Sedang/Besar) to numeric kg using enum max weights
            $numericWeight = 0.0;
            try {
                $enum = \App\Enums\WeightCategory::from($weight);
                $numericWeight = (float) $enum->getMaxWeight();
            } catch (\Throwable $e) {
                $numericWeight = floatval($weight);
            }

            try {
                $calculator = app(PriceCalculator::class);
                $priceResult = $calculator->calculate('motor', $numericWeight, $serviceType, 0.0);

                if (is_array($priceResult) && array_key_exists('total', $priceResult)) {
                    $calculatedPrice = $priceResult['total'];
                    $priceBreakdown = $priceResult;
                    Log::info('Price auto-calculated for motor booking', $priceBreakdown);
                } else {
                    Log::warning('PriceCalculator returned unexpected format for motor booking', ['result' => $priceResult]);
                }
            } catch (\Throwable $e) {
                Log::warning('PriceCalculator failed for motor booking', ['error' => $e->getMessage(), 'weight' => $weight]);
            }
        }

        // If no weight-based calculation happened and ride has no explicit price,
        // attempt distance-based price calculation via PriceCalculator (profiles).
        if ($calculatedPrice === null && (floatval($ride->price ?? 0) <= 0)) {
            try {
                $rawService = $ride->service_type ?? null;
                $serviceTypeMap = [
                    'tebengan' => 'hanya_tebengan',
                    'barang' => 'hanya_barang',
                    'both' => 'tebengan_dan_barang',
                ];
                $serviceType = $serviceTypeMap[$rawService] ?? $rawService;

                $origin = $ride->originLocation;
                $destination = $ride->destinationLocation;
                $distance = 0.0;
                if ($origin && $destination && $origin->latitude && $origin->longitude && $destination->latitude && $destination->longitude) {
                    // Haversine formula
                    $lat1 = deg2rad(floatval($origin->latitude));
                    $lon1 = deg2rad(floatval($origin->longitude));
                    $lat2 = deg2rad(floatval($destination->latitude));
                    $lon2 = deg2rad(floatval($destination->longitude));
                    $dlat = $lat2 - $lat1;
                    $dlon = $lon2 - $lon1;
                    $a = pow(sin($dlat / 2), 2) + cos($lat1) * cos($lat2) * pow(sin($dlon / 2), 2);
                    $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
                    $earthRadiusKm = 6371.0;
                    $distance = $earthRadiusKm * $c; // in kilometers
                }

                $calculator = app(PriceCalculator::class);
                $calc = $calculator->calculate('motor', 0.0, $serviceType, $distance);
                if (isset($calc['total']) && $calc['total'] > 0) {
                    $calculatedPrice = $calc['total'];
                    $priceBreakdown = $calc;
                    Log::info('Distance-based price calculated for motor booking', ['distance' => $distance, 'breakdown' => $priceBreakdown]);
                }
            } catch (\Throwable $__e) {
                Log::warning('Distance-based price calculation failed', ['error' => $__e->getMessage()]);
            }
        }

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
            'meta' => $priceBreakdown ? json_encode(['price_breakdown' => $priceBreakdown]) : null,
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

        // Create Firebase conversation
        $this->createConversationAfterBooking(
            rideId: $ride->id,
            bookingType: 'motor',
            customerId: $request->user_id,
            mitraId: $ride->user_id,
            bookingNumber: $bookingNumber
        );

        // Load ride with user data for frontend
        $booking->load('ride.user');

        // Add calculated price to response
        $response = [
            'success' => true,
            'data' => $booking,
        ];

        if ($calculatedPrice !== null) {
            $response['calculated_price'] = $calculatedPrice;
            $response['price_breakdown'] = $priceBreakdown;
        }

        return response()->json($response, 201);
    }
}
