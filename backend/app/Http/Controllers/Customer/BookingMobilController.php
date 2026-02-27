<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Services\PriceCalculationService;
use App\Services\PriceCalculator;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use App\Http\Controllers\Api\Traits\CreatesConversation;

class BookingMobilController extends Controller
{
    use CreatesConversation;
    public function index(Request $request)
    {
        $rideId = $request->query('ride_id');
        
        if ($rideId) {
            $bookings = \App\Models\BookingMobil::where('ride_id', $rideId)
                ->with(['user', 'ride'])
                ->get();
            
            return response()->json(['success' => true, 'data' => $bookings], 200);
        }
        
        return response()->json(['success' => false, 'message' => 'ride_id parameter required'], 400);
    }
    
    public function store(Request $request, $ride = null)
    {
        // Expect $ride to be an instance of \App\Models\CarRide
        if (!$ride) {
            $ride = \App\Models\CarRide::find($request->ride_id);
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
            $serviceType = PriceCalculationService::determineServiceType('mobil', $ride->service_type ?? 'tebengan');
            $bagasiCapacity = $ride->bagasi_capacity ?? null;

            $priceResult = PriceCalculationService::calculatePrice(
                $serviceType,
                'mobil',
                floatval($weight),
                $bagasiCapacity
            );

            if ($priceResult['success']) {
                $calculatedPrice = $priceResult['price'];
                $priceBreakdown = $priceResult['breakdown'];
                Log::info('Price auto-calculated for mobil booking', $priceBreakdown);
            } else {
                Log::warning('Price calculation failed for mobil booking', [
                    'message' => $priceResult['message'],
                    'weight' => $weight,
                ]);
            }
        }

            // If no weight-based calculation and ride has no explicit price, try distance-based calculation
            if ($calculatedPrice === null && (floatval($ride->price ?? 0) <= 0)) {
                try {
                    $serviceType = PriceCalculationService::determineServiceType('mobil', $ride->service_type ?? 'tebengan');

                    $origin = $ride->originLocation;
                    $destination = $ride->destinationLocation;
                    $distance = 0.0;
                    if ($origin && $destination && $origin->latitude && $origin->longitude && $destination->latitude && $destination->longitude) {
                        $lat1 = deg2rad(floatval($origin->latitude));
                        $lon1 = deg2rad(floatval($origin->longitude));
                        $lat2 = deg2rad(floatval($destination->latitude));
                        $lon2 = deg2rad(floatval($destination->longitude));
                        $dlat = $lat2 - $lat1;
                        $dlon = $lon2 - $lon1;
                        $a = pow(sin($dlat / 2), 2) + cos($lat1) * cos($lat2) * pow(sin($dlon / 2), 2);
                        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
                        $earthRadiusKm = 6371.0;
                        $distance = $earthRadiusKm * $c;
                    }

                    $calculator = app(PriceCalculator::class);
                    $calc = $calculator->calculate('mobil', 0.0, $serviceType, $distance);
                    if (isset($calc['total']) && $calc['total'] > 0) {
                        $calculatedPrice = $calc['total'];
                        $priceBreakdown = $calc;
                        Log::info('Distance-based price calculated for mobil booking', ['distance' => $distance, 'breakdown' => $priceBreakdown]);
                    }
                } catch (\Throwable $__e) {
                    Log::warning('Distance-based price calculation failed (mobil)', ['error' => $__e->getMessage()]);
                }
            }

        // Handle photo upload for barang
        $photoPath = null;
        if ($request->hasFile('photo')) {
            try {
                $photo = $request->file('photo');
                $filename = 'uploads/' . time() . '_' . uniqid() . '.' . $photo->getClientOriginalExtension();
                Storage::disk('public')->put($filename, file_get_contents($photo));
                $photoPath = '/storage/' . $filename;
            } catch (\Throwable $__e) {
                Log::warning('Failed to store booking photo (mobil)', ['error' => $__e->getMessage()]);
            }
        }

        // Create booking mobil
        $bookingNumber = 'FR-' . time() . '-' . rand(100, 999);

        $booking = \App\Models\BookingMobil::create([
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

        // decrement seats and bagasi atomically
        try {
            DB::transaction(function () use ($ride, $seats, $bagasiRequested) {
                $ride->refresh();
                
                $serviceType = $ride->service_type ?? null;
                $isBarangOnly = ($serviceType === 'barang');
                
                // Only decrement seats if not barang-only service
                if ($seats > 0 && !$isBarangOnly) {
                    $ride->decrement('available_seats', $seats);
                }
                
                if ($bagasiRequested > 0) {
                    $ride->decrement('jumlah_bagasi', $bagasiRequested);
                }
                
                $ride->refresh();
                
                // For barang-only: inactive when bagasi runs out
                // For regular/both: inactive when both seats AND bagasi run out
                if ($isBarangOnly) {
                    if (intval($ride->jumlah_bagasi ?? 0) <= 0) {
                        $ride->status = 'inactive';
                        $ride->save();
                    }
                } else {
                    if (intval($ride->available_seats ?? 0) <= 0 && intval($ride->jumlah_bagasi ?? 0) <= 0) {
                        $ride->status = 'inactive';
                        $ride->save();
                    }
                }
            });
        } catch (\Exception $e) {
            Log::warning('Failed to decrement seats/jumlah_bagasi for mobil (controller)', ['error' => $e->getMessage(), 'ride_id' => $ride->id]);
        }

        Log::info('BookingMobil created', ['booking_id' => $booking->id, 'booking_number' => $bookingNumber]);

        // Create conversation in Firebase
        $this->createConversationAfterBooking(
            rideId: $ride->id,
            bookingType: 'mobil',
            customerId: $request->user_id,
            mitraId: $ride->user_id,
            bookingNumber: $bookingNumber
        );

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
