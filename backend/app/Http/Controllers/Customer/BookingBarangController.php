<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Services\PriceCalculationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use App\Http\Controllers\Api\Traits\CreatesConversation;

class BookingBarangController extends Controller
{
    use CreatesConversation;
    public function index(Request $request)
    {
        $rideId = $request->query('ride_id');
        
        if ($rideId) {
            $bookings = \App\Models\BookingBarang::where('ride_id', $rideId)
                ->with(['user', 'ride'])
                ->get();
            
            return response()->json(['success' => true, 'data' => $bookings], 200);
        }
        
        return response()->json(['success' => false, 'message' => 'ride_id parameter required'], 400);
    }
    
    public function store(Request $request, $ride = null)
    {
        // Expect $ride to be an instance of \App\Models\BarangRide
        if (!$ride) {
            $ride = \App\Models\BarangRide::find($request->ride_id);
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
            $serviceType = PriceCalculationService::determineServiceType('barang', $ride->service_type ?? 'tebengan');
            $bagasiCapacity = $ride->bagasi_capacity ?? null;

            $priceResult = PriceCalculationService::calculatePrice(
                $serviceType,
                'barang',
                floatval($weight),
                $bagasiCapacity
            );

            if ($priceResult['success']) {
                $calculatedPrice = $priceResult['price'];
                $priceBreakdown = $priceResult['breakdown'];
                Log::info('Price auto-calculated for barang booking', $priceBreakdown);
            } else {
                Log::warning('Price calculation failed for barang booking', [
                    'message' => $priceResult['message'],
                    'weight' => $weight,
                ]);
            }
        }

        // Handle photo upload for barang bookings
        $photoPath = null;
        if ($request->hasFile('photo')) {
            $photo = $request->file('photo');
            $filename = 'uploads/' . time() . '_' . uniqid() . '.' . $photo->getClientOriginalExtension();
            Storage::disk('public')->put($filename, file_get_contents($photo));
            $photoPath = '/storage/' . $filename;
        }

        $bookingNumber = 'FR-' . time() . '-' . rand(100, 999);

        $booking = \App\Models\BookingBarang::create([
            'ride_id' => $ride->id,
            'user_id' => $request->user_id,
            'booking_number' => $bookingNumber,
            'seats' => $seats,
            'status' => 'pending',
            'meta' => $priceBreakdown ? json_encode(['price_breakdown' => $priceBreakdown]) : null,
            'photo' => $photoPath,
            'weight' => $request->weight,
            'description' => $request->description,
        ]);

        // decrement bagasi for barang bookings
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
                Log::warning('Failed to decrement jumlah_bagasi for barang (controller)', ['error' => $e->getMessage(), 'ride_id' => $ride->id]);
            }
        }

        Log::info('BookingBarang created', ['booking_id' => $booking->id, 'booking_number' => $bookingNumber]);

        // Create conversation in Firebase
        $this->createConversationAfterBooking(
            rideId: $ride->id,
            bookingType: 'barang',
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
