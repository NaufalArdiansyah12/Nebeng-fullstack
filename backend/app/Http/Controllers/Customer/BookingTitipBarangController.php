<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Services\PriceCalculationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use App\Http\Controllers\Api\Traits\CreatesConversation;

class BookingTitipBarangController extends Controller
{
    use CreatesConversation;
    public function store(Request $request, $ride = null)
    {
        $validator = Validator::make($request->all(), [
            'ride_id' => 'required|integer',
            'user_id' => 'required|integer',
            'seats' => 'nullable|integer|min:1',
            'jumlah_bagasi' => 'nullable|integer|min:0',
            'photo' => 'nullable|image|mimes:jpeg,jpg,png|max:5120',
            'weight' => 'nullable|string|in:Kecil,Sedang,Besar',
            'description' => 'nullable|string|max:1000',
            'penerima' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        // If ride not passed from parent controller, locate ride (supports polymorphic ride types)
        if (!$ride) {
            $ride = \App\Models\TebenganTitipBarang::find($request->ride_id);
            $isBarang = false;
            
            if (!$ride) {
                $ride = \App\Models\Ride::find($request->ride_id);
            }
            
            if (!$ride) {
                $ride = \App\Models\BarangRide::find($request->ride_id);
                if ($ride) $isBarang = true;
            }
        }

        if (!$ride) {
            return response()->json(['success' => false, 'message' => 'Ride not found'], 404);
        }

        // Auto-calculate price based on weight
        $calculatedPrice = null;
        $priceBreakdown = null;
        $weight = $request->weight ?? null;

        if ($weight) {
            // Determine service type the same way as before
            $serviceType = PriceCalculationService::determineServiceType('titip_barang', $ride->service_type ?? 'tebengan');

            // Map weight label (Kecil/Sedang/Besar) to numeric kg using enum max weights
            $numericWeight = 0.0;
            try {
                $enum = \App\Enums\WeightCategory::from($weight);
                $numericWeight = (float) $enum->getMaxWeight();
            } catch (\Throwable $e) {
                // Fallback: try to parse as numeric value
                $numericWeight = floatval($weight);
            }

            // Determine transport slug for titip barang profiles
            $transportation = $ride->transportation_type ?? null;
            $transportMap = [
                'bus' => 'titip-barang-bus',
                'kereta' => 'titip-barang-kereta',
                'pesawat' => 'titip-barang-pesawat',
            ];
            $transportSlug = $transportMap[$transportation] ?? 'titip-barang-bus';

            // Use PriceCalculator (modern pricing) instead of legacy PricePerKg flow
            try {
                $calculator = app(\App\Services\PriceCalculator::class);
                $priceResult = $calculator->calculate($transportSlug, $numericWeight, $serviceType, 0.0);

                if (is_array($priceResult) && array_key_exists('total', $priceResult)) {
                    $calculatedPrice = $priceResult['total'];
                    $priceBreakdown = $priceResult;
                    Log::info('Price auto-calculated for titip_barang booking', $priceBreakdown);
                } else {
                    Log::warning('PriceCalculator returned unexpected format for titip_barang booking', ['result' => $priceResult]);
                }
            } catch (\Throwable $e) {
                Log::warning('PriceCalculator failed for titip_barang booking', ['error' => $e->getMessage(), 'weight' => $weight]);
            }
        }

        // Handle photo upload
        $photoPath = null;
        if ($request->hasFile('photo')) {
            $photo = $request->file('photo');
            $filename = 'uploads/' . time() . '_' . uniqid() . '.' . $photo->getClientOriginalExtension();
            Storage::disk('public')->put($filename, file_get_contents($photo));
            $photoPath = '/storage/' . $filename;
        }

        $bookingNumber = 'FT-' . time() . '-' . rand(100, 999);

        $bagasiRequested = intval($request->jumlah_bagasi ?? 0);

        // Check bagasi availability before creating booking
        if ($bagasiRequested > 0) {
            $availableBagasi = intval($ride->jumlah_bagasi ?? 0);
            if ($availableBagasi < $bagasiRequested) {
                return response()->json([
                    'success' => false,
                    'message' => 'Not enough bagasi available',
                    'available_bagasi' => $availableBagasi,
                ], 409);
            }
        }

        $booking = \App\Models\BookingTitipBarang::create([
            'ride_id' => $ride->id,
            'user_id' => $request->user_id,
            'booking_number' => $bookingNumber,
            'seats' => $request->seats ?? 1,
            'status' => 'pending',
            'meta' => $priceBreakdown ? json_encode(['price_breakdown' => $priceBreakdown]) : null,
            'photo' => $photoPath,
            'weight' => $request->weight,
            'description' => $request->description,
            'penerima' => $request->penerima,
        ]);

        // decrement bagasi for titip booking
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
                Log::warning('Failed to decrement jumlah_bagasi for titip (separate controller)', ['error' => $e->getMessage(), 'ride_id' => $ride->id]);
            }
        }

        Log::info('BookingTitipBarang created', ['id' => $booking->id, 'booking_number' => $bookingNumber]);

        // Create conversation in Firebase
        $this->createConversationAfterBooking(
            rideId: $ride->id,
            bookingType: 'titip',
            customerId: $request->user_id,
            mitraId: $ride->user_id,
            bookingNumber: $bookingNumber
        );

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

    public function index(Request $request)
    {
        $rideId = $request->query('ride_id');
        if (!$rideId) {
            return response()->json(['success' => false, 'message' => 'ride_id parameter required'], 400);
        }

        $bookings = \App\Models\BookingTitipBarang::where('ride_id', $rideId)->get();
        return response()->json(['success' => true, 'data' => $bookings], 200);
    }

    public function show($id)
    {
        $b = \App\Models\BookingTitipBarang::with(['ride', 'user'])->find($id);
        if (!$b) {
            return response()->json(['success' => false, 'message' => 'Booking not found'], 404);
        }
        return response()->json(['success' => true, 'data' => $b]);
    }
}
