<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Foundation\Validation\ValidatesRequests;
use App\Models\ApiToken;
use App\Models\BookingMobil;
use App\Models\CarRide;
use App\Models\RescheduleRequest;
use App\Models\Booking;
use App\Models\BookingBarang;
use App\Models\BookingTitipBarang;
use App\Models\PenumpangBookingMobil;
use App\Models\Ride;
use App\Models\BarangRide;
use App\Models\TebenganTitipBarang;
use App\Models\FinanceSetting;
use App\Services\PriceCalculator;

class RescheduleController extends Controller
{
    use ValidatesRequests;
    /**
     * GET available replacement rides for a booking
     */
    public function availableRides(Request $request, $bookingId)
    {
        $bookingType = $request->query('booking_type', 'mobil');
        $booking = $this->resolveBooking($bookingType, $bookingId);
        if (!$booking) {
            return response()->json(['success' => false, 'message' => 'Booking not found'], 404);
        }

        $ride = $booking->ride;
        if (!$ride) {
            return response()->json(['success' => true, 'data' => []]);
        }

        $date = $request->query('date', $ride->departure_date);

        // determine candidate model based on booking type
        $candidateQuery = null;
        switch ($bookingType) {
            case 'motor':
                $candidateQuery = Ride::where('origin_location_id', $ride->origin_location_id)
                    ->where('destination_location_id', $ride->destination_location_id)
                    ->whereDate('departure_date', $date)
                    ->where('id', '!=', $ride->id);
                break;
            case 'mobil':
                $candidateQuery = CarRide::where('origin_location_id', $ride->origin_location_id)
                    ->where('destination_location_id', $ride->destination_location_id)
                    ->whereDate('departure_date', $date)
                    ->where('id', '!=', $ride->id);
                break;
            case 'barang':
                $candidateQuery = BarangRide::where('origin_location_id', $ride->origin_location_id)
                    ->where('destination_location_id', $ride->destination_location_id)
                    ->whereDate('departure_date', $date)
                    ->where('id', '!=', $ride->id);
                break;
            case 'titip':
                $candidateQuery = TebenganTitipBarang::where('origin_location_id', $ride->origin_location_id)
                    ->where('destination_location_id', $ride->destination_location_id)
                    ->whereDate('departure_date', $date)
                    ->where('id', '!=', $ride->id);
                break;
            default:
                $candidateQuery = CarRide::where('origin_location_id', $ride->origin_location_id)
                    ->where('destination_location_id', $ride->destination_location_id)
                    ->whereDate('departure_date', $date)
                    ->where('id', '!=', $ride->id);
        }

        // eager load ride relation where available so we can fallback to ride->price
        // Only eager-load the 'ride' relation for models that define it
        $with = ['originLocation', 'destinationLocation'];
        if (!in_array(strtolower($bookingType), ['motor'])) {
            $with[] = 'ride';
        }
        $candidates = $candidateQuery->with($with)->get();

        // Debug log to help diagnose empty results from frontend
        try {
            Log::info('availableRides request', [
                'booking_id' => $booking->id ?? null,
                'booking_type' => $bookingType ?? null,
                'date' => $date,
                'candidates_count' => count($candidates),
            ]);
        } catch (\Throwable $e) {
            // ignore logging errors
        }

        $data = $candidates->map(function ($r) use ($booking, $bookingType) {
            // Determine price: prefer direct model price, fallback to related ride price
            $rawPrice = null;
            if (isset($r->price) && $r->price !== null && floatval($r->price) > 0) {
                $rawPrice = $r->price;
            } elseif (strtolower($bookingType) === 'motor') {
                // For motor rides, attempt to calculate price if not present using PriceCalculator
                try {
                    $serviceRaw = $r->service_type ?? ($r->ride->service_type ?? null);
                    $serviceTypeMap = [
                        'tebengan' => 'hanya_tebengan',
                        'barang' => 'hanya_barang',
                        'both' => 'tebengan_dan_barang',
                    ];
                    $serviceType = $serviceTypeMap[$serviceRaw] ?? $serviceRaw;

                    $origin = $r->originLocation ?? ($r->ride->originLocation ?? null);
                    $destination = $r->destinationLocation ?? ($r->ride->destinationLocation ?? null);
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
                    $calc = $calculator->calculate('motor', 0.0, $serviceType, $distance);
                    if (is_array($calc) && isset($calc['total'])) {
                        $rawPrice = $calc['total'];
                    }
                } catch (\Throwable $e) {
                    // fallback to related ride price below
                }
            }

            if ($rawPrice === null) {
                if (isset($r->ride) && isset($r->ride->price) && floatval($r->ride->price) > 0) {
                    $rawPrice = $r->ride->price;
                } else {
                    $rawPrice = 0;
                }
            }
            // Round per-seat price to nearest 5,000 (kelipatan 5)
            $intPrice = intval(round(floatval($rawPrice) / 5000.0) * 5000);

            return [
                'id' => $r->id,
                'ride_id' => $r->id,
                'departure_date' => (string) $r->departure_date,
                'departure_time' => $r->departure_time ?? null,
                'arrival_time' => $r->arrival_time ?? null,
                'available_seats' => $r->available_seats ?? 0,
                'price' => $intPrice,
                'price_per_seat' => $intPrice,
                'origin_location' => $r->originLocation ? [
                    'id' => $r->originLocation->id,
                    'name' => $r->originLocation->name,
                    'address' => $r->originLocation->address,
                ] : null,
                'destination_location' => $r->destinationLocation ? [
                    'id' => $r->destinationLocation->id,
                    'name' => $r->destinationLocation->name,
                    'address' => $r->destinationLocation->address,
                ] : null,
                'vehicle' => [
                    'name' => $r->vehicle_name ?? null,
                    'plate_number' => $r->vehicle_plate ?? null,
                ],
                'meta' => [],
            ];
        })->toArray();

        // If caller requested debug info, include query and raw candidates
        if ($request->query('debug') == '1') {
            $raw = $candidates->map(function ($r) use ($booking) {
                // Log candidate-level values for diagnostics (safe variables only)
                try {
                    Log::info('RescheduleController: candidate debug', [
                        'booking_id' => $booking->id ?? null,
                        'candidate_id' => $r->id ?? null,
                        'candidate_price' => $r->price ?? null,
                        'candidate_available_seats' => $r->available_seats ?? null,
                    ]);
                } catch (\Throwable $__logEx) {
                    // ignore logging errors
                }

                return [
                    'id' => $r->id,
                    'departure_date' => (string) ($r->departure_date ?? null),
                    'available_seats' => $r->available_seats ?? null,
                    'price' => isset($r->price) ? (string) $r->price : null,
                ];
            })->toArray();

            return response()->json([
                'success' => true,
                'data' => $data,
                'debug' => [
                    'query_date' => $date,
                    'booking_type' => $bookingType,
                    'booking_ride_id' => $booking->ride_id ?? null,
                    'candidates_count' => count($candidates),
                    'candidates_raw' => $raw,
                ],
            ]);
        }

        return response()->json(['success' => true, 'data' => $data]);
    }

    /**
     * Create a reschedule request. Does not apply change until payment/approval.
     */
    public function store(Request $request, $bookingId)
    {
        $validator = Validator::make($request->all(), [
            'requested_target_id' => 'required|integer',
            'booking_type' => 'required|string',
            'requested_target_type' => 'required|string',
            'reason' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Get user from bearer token
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }
        $hashed = hash('sha256', $bearer);
        $apiToken = ApiToken::where('token', $hashed)->first();
        if (!$apiToken) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }
        $user = $apiToken->user;
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        try {
            $res = DB::transaction(function () use ($request, $bookingId, $user) {
                $bookingType = $request->input('booking_type');
                // lock booking row and eager load ride
                $booking = $this->resolveBooking($bookingType, $bookingId, true);
                if (!$booking) {
                    return response()->json(['success' => false, 'message' => 'Booking not found'], 404);
                }

                if ($booking->user_id !== $user->id) {
                    return response()->json(['success' => false, 'message' => 'Forbidden'], 403);
                }

                $targetType = $request->input('requested_target_type');
                $targetId = intval($request->input('requested_target_id'));
                
                // Prevent selecting the exact same trip
                $currentRideId = $booking->ride_id ?? $booking->barang_ride_id ?? $booking->titip_barang_id ?? null;
                if ($currentRideId && $currentRideId == $targetId) {
                    return response()->json(['success' => false, 'message' => 'Cannot reschedule to the same trip'], 400);
                }
                
                $requestedTarget = $this->resolveTarget($targetType, $targetId, true);
                if (!$requestedTarget) {
                    return response()->json(['success' => false, 'message' => 'Requested target not found'], 404);
                }

                $seats = intval($booking->seats ?? 1);
                $available = intval($requestedTarget->available_seats ?? 0);
                if ($available < $seats) {
                    return response()->json(['success' => false, 'message' => 'Not enough seats/capacity on requested target'], 409);
                }

                // Compute price_before and price_after with same fallback logic as booking controllers
                $priceBefore = 0;
                $priceAfter = 0;
                try {
                    // Helper to compute per-seat price for a target/model
                    $computePerSeat = function ($model, $type) {
                        // Prefer explicit price on model
                        if (isset($model->price) && floatval($model->price) > 0) {
                            return floatval($model->price);
                        }

                        // For motor, attempt PriceCalculator distance-based fallback
                        if (strtolower($type) === 'motor') {
                            try {
                                $serviceRaw = $model->service_type ?? ($model->ride->service_type ?? null);
                                $serviceTypeMap = [
                                    'tebengan' => 'hanya_tebengan',
                                    'barang' => 'hanya_barang',
                                    'both' => 'tebengan_dan_barang',
                                ];
                                $serviceType = $serviceTypeMap[$serviceRaw] ?? $serviceRaw;

                                $origin = $model->originLocation ?? ($model->ride->originLocation ?? null);
                                $destination = $model->destinationLocation ?? ($model->ride->destinationLocation ?? null);
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
                                $calc = $calculator->calculate('motor', 0.0, $serviceType, $distance);
                                if (is_array($calc) && isset($calc['total'])) {
                                    return floatval($calc['total']);
                                }
                            } catch (\Throwable $__e) {
                                // ignore and fallthrough to zero
                            }
                        }

                        // fallback zero
                        return 0.0;
                    };

                    // price before: booking's current ride
                    if (!empty($booking->ride)) {
                        $perSeatBefore = $computePerSeat($booking->ride, $bookingType);
                        $priceBefore = intval(round(($perSeatBefore * $seats) / 5000.0) * 5000);
                    }

                    // price after: requested target
                    $perSeatAfter = $computePerSeat($requestedTarget, $bookingType);
                    $priceAfter = intval(round(($perSeatAfter * $seats) / 5000.0) * 5000);
                } catch (\Throwable $__e) {
                    Log::warning('Failed to compute reschedule prices: ' . $__e->getMessage());
                    // default to zero values
                    $priceBefore = intval(round(((isset($booking->ride->price) ? $booking->ride->price * $seats : 0)) / 5000.0) * 5000);
                    $priceAfter = intval(round(((isset($requestedTarget->price) ? $requestedTarget->price * $seats : 0)) / 5000.0) * 5000);
                }

                $priceDiff = $priceAfter - $priceBefore;

                // Read finance settings to determine admin/reschedule fees
                $finance = FinanceSetting::first();
                $adminFee = 0;
                $rescheduleFee = 0;
                if ($finance) {
                    $adminFee = floatval($finance->admin_fee ?? 0);
                    $rescheduleFee = floatval($finance->reschedule_fee ?? 0);
                }

                // Payment required when customer owes more OR when system-level fees exist
                $paymentRequired = ($priceDiff > 0) || ( ($adminFee + $rescheduleFee) > 0 );

                $requestRow = RescheduleRequest::create([
                    'booking_id' => $booking->id,
                    'booking_type' => $bookingType,
                    'requested_target_type' => $targetType,
                    'requested_target_id' => $requestedTarget->id,
                    'requested_by' => $user->id,
                    'status' => $paymentRequired ? 'awaiting_payment' : 'pending',
                    'price_before' => $priceBefore,
                    'price_after' => $priceAfter,
                    'price_diff' => $priceDiff,
                    'reason' => $request->input('reason'),
                ]);

                return [
                    'request_id' => $requestRow->id,
                    'booking_id' => $booking->id,
                    'status' => $requestRow->status,
                    'price_before' => $priceBefore,
                    'price_after' => $priceAfter,
                    'price_diff' => $priceDiff,
                    'payment_required' => $paymentRequired,
                    'admin_fee' => $adminFee,
                    'reschedule_fee' => $rescheduleFee,
                ];
            });

            // if DB transaction returned a Response (error) pass it through
            if (is_array($res) && array_key_exists('request_id', $res)) {
                return response()->json(['success' => true, 'data' => $res], 201);
            }
            return $res;
        } catch (\Exception $e) {
            Log::error('Reschedule store error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Internal server error'], 500);
        }
    }

    /**
     * Show reschedule request
     */
    public function show($id)
    {
        $req = RescheduleRequest::with(['booking', 'requestedRide', 'requestedBy'])->find($id);
        if (!$req) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }
        return response()->json(['success' => true, 'data' => $req]);
    }

    /**
     * Confirm payment and apply reschedule atomically
     */
    public function confirmPayment(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'payment_txn_id' => 'required|string',
            'passengers' => 'sometimes|array',
            'passengers.*.name' => 'required|string',
            'passengers.*.phone' => 'required|string',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $oldRideData = null;
            $newRideData = null;

            DB::transaction(function () use ($request, $id, &$oldRideData, &$newRideData) {
                $req = RescheduleRequest::lockForUpdate()->find($id);
                if (!$req) {
                    throw new \Exception('Reschedule request not found', 404);
                }

                if ($req->status === 'approved') {
                    return; // already applied
                }

                // resolve booking and requested target polymorphically
                $booking = $this->resolveBooking($req->booking_type ?? 'mobil', $req->booking_id, true);
                $requestedTarget = $this->resolveTarget($req->requested_target_type ?? 'car', $req->requested_target_id, true);

                if (!$booking || !$requestedTarget) {
                    throw new \Exception('Booking or requested target not found');
                }

                // Capture old ride and seats before we change booking so we can
                // release seats on the old ride (if different) or adjust
                // availability correctly when staying on the same ride.
                $oldSeats = intval($booking->seats ?? 1);
                $oldRide = null;
                // map booking type to target type for resolving the current ride
                $bt = strtolower($req->booking_type ?? 'mobil');
                $oldTargetType = 'car';
                if (in_array($bt, ['motor'])) {
                    $oldTargetType = 'motor';
                } elseif (in_array($bt, ['barang'])) {
                    $oldTargetType = 'barang';
                } elseif (in_array($bt, ['titip'])) {
                    $oldTargetType = 'titip';
                }
                if (!empty($booking->ride_id)) {
                    $oldRide = $this->resolveTarget($oldTargetType, $booking->ride_id, true);
                }

                // Mark request as approved and attach txn
                $req->payment_txn_id = $request->input('payment_txn_id');
                $req->status = 'approved';
                $req->processed_at = now();
                $req->save();

                // Update booking pointer depending on booking type
                switch ($req->booking_type ?? 'mobil') {
                    case 'motor':
                        $booking->ride_id = $requestedTarget->id;
                        break;
                    case 'mobil':
                        $booking->ride_id = $requestedTarget->id;
                        // Update passengers if provided
                        if ($request->has('passengers')) {
                            // Delete existing passengers
                            PenumpangBookingMobil::where('booking_mobil_id', $booking->id)->delete();
                            
                            // Insert new passengers
                            $passengers = $request->input('passengers', []);
                            foreach ($passengers as $passenger) {
                                PenumpangBookingMobil::create([
                                    'booking_mobil_id' => $booking->id,
                                    'nama' => $passenger['name'] ?? '',
                                    'no_telepon' => $passenger['phone'] ?? '',
                                ]);
                            }
                            
                            // Update total seats
                            $booking->seats = count($passengers);
                        }
                        break;
                    case 'barang':
                        $booking->ride_id = $requestedTarget->id;
                        break;
                    case 'titip':
                        $booking->ride_id = $requestedTarget->id;
                        break;
                }
                // Save booking updates first
                $booking->save();

                // Determine seats to occupy (after any passenger updates)
                $seatsToOccupy = intval($booking->seats ?? 1);

                // If old ride is the same as requested target, adjust by diff
                if ($oldRide && $oldRide->id === $requestedTarget->id) {
                    $diff = $seatsToOccupy - $oldSeats; // positive => need more seats
                    if ($diff > 0) {
                        if (intval($requestedTarget->available_seats ?? 0) < $diff) {
                            throw new \Exception('No seats/capacity available on requested target');
                        }
                        $requestedTarget->available_seats = max(0, intval($requestedTarget->available_seats) - $diff);
                        // ensure status reflects availability (store as string)
                        $requestedTarget->status = (intval($requestedTarget->available_seats) > 0) ? 'active' : 'full';
                        try {
                            $requestedTarget->save();
                        } catch (\Throwable $__saveEx) {
                            Log::error('Failed to save requestedTarget (same-ride adjust): ' . $__saveEx->getMessage());
                            throw new \Exception('Failed to apply reschedule (save error)');
                        }
                    } else if ($diff < 0) {
                        // release seats back to same ride
                        $requestedTarget->available_seats = intval($requestedTarget->available_seats ?? 0) + abs($diff);
                        $requestedTarget->status = (intval($requestedTarget->available_seats) > 0) ? 'active' : 'full';
                        try {
                            $requestedTarget->save();
                        } catch (\Throwable $__saveEx) {
                            Log::error('Failed to save requestedTarget (same-ride release): ' . $__saveEx->getMessage());
                            throw new \Exception('Failed to apply reschedule (save error)');
                        }
                    }
                } else {
                    // Different rides: release old seats (if we have oldRide) then decrement new ride
                    if ($oldRide) {
                        $oldRide->available_seats = intval($oldRide->available_seats ?? 0) + $oldSeats;
                        $oldRide->status = (intval($oldRide->available_seats) > 0) ? 'active' : 'full';
                        try {
                            $oldRide->save();
                        } catch (\Throwable $__saveEx) {
                            Log::error('Failed to save oldRide (release seats): ' . $__saveEx->getMessage());
                            throw new \Exception('Failed to apply reschedule (save error)');
                        }
                    }

                    // Check capacity now using the updated seats count
                    if (intval($requestedTarget->available_seats ?? 0) < $seatsToOccupy) {
                        throw new \Exception('No seats/capacity available on requested target');
                    }

                    // Decrement available seats on requested target by the updated seats count
                    if (isset($requestedTarget->available_seats)) {
                        $requestedTarget->available_seats = max(0, intval($requestedTarget->available_seats) - $seatsToOccupy);
                        $requestedTarget->status = (intval($requestedTarget->available_seats) > 0) ? 'active' : 'full';
                        try {
                            $requestedTarget->save();
                        } catch (\Throwable $__saveEx) {
                            Log::error('Failed to save requestedTarget (decrement new ride): ' . $__saveEx->getMessage());
                            throw new \Exception('Failed to apply reschedule (save error)');
                        }
                    }
                }

                // Prepare response payload for updated rides
                try {
                    if ($oldRide) {
                        $oldRide->refresh();
                        $oldRideData = $oldRide->toArray();
                    }
                } catch (\Throwable $e) {
                    Log::warning('Failed to refresh oldRide: ' . $e->getMessage());
                }

                try {
                    $requestedTarget->refresh();
                    $newRideData = $requestedTarget->toArray();
                    // Ensure returned new_ride includes a usable price (per-seat) for frontend
                    try {
                        $perSeat = null;
                        if (isset($requestedTarget->price) && floatval($requestedTarget->price) > 0) {
                            $perSeat = floatval($requestedTarget->price);
                        } else {
                            // attempt PriceCalculator fallback for motor-type reschedules
                            $bt = strtolower($req->booking_type ?? 'mobil');
                            if ($bt === 'motor') {
                                try {
                                    $serviceRaw = $requestedTarget->service_type ?? ($requestedTarget->ride->service_type ?? null);
                                    $serviceTypeMap = [
                                        'tebengan' => 'hanya_tebengan',
                                        'barang' => 'hanya_barang',
                                        'both' => 'tebengan_dan_barang',
                                    ];
                                    $serviceType = $serviceTypeMap[$serviceRaw] ?? $serviceRaw;
                                    $origin = $requestedTarget->originLocation ?? ($requestedTarget->ride->originLocation ?? null);
                                    $destination = $requestedTarget->destinationLocation ?? ($requestedTarget->ride->destinationLocation ?? null);
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
                                    $calc = $calculator->calculate('motor', 0.0, $serviceType, $distance);
                                    if (is_array($calc) && isset($calc['total'])) {
                                        $perSeat = floatval($calc['total']);
                                    }
                                } catch (\Throwable $__e) {
                                    // ignore
                                }
                            }
                        }

                        if ($perSeat !== null) {
                            $newRideData['price'] = intval(round($perSeat));
                            $newRideData['price_per_seat'] = intval(round($perSeat));
                        }
                    } catch (\Throwable $e) {
                        // ignore price population errors
                    }
                } catch (\Throwable $e) {
                    Log::warning('Failed to refresh requestedTarget: ' . $e->getMessage());
                }
                
                // Log seat operations for debugging
                try {
                    Log::info('Reschedule applied', [
                        'reschedule_request_id' => $req->id,
                        'booking_id' => $booking->id,
                        'old_seats' => $oldSeats,
                        'new_seats' => intval($booking->seats ?? 1),
                        'old_ride_after' => $oldRideData,
                        'new_ride_after' => $newRideData,
                    ]);
                } catch (\Throwable $e) {
                    // ignore logging errors
                }
            });

            // Return updated rides so frontend can refresh lists
            return response()->json([
                'success' => true,
                'message' => 'Reschedule applied',
                'data' => [
                    'old_ride' => $oldRideData,
                    'new_ride' => $newRideData,
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('confirmPayment error: ' . $e->getMessage());
            $rawCode = method_exists($e, 'getCode') ? intval($e->getCode()) : 0;
            // Ensure HTTP status is a valid code (100-599); otherwise fallback to 500
            if ($rawCode < 100 || $rawCode > 599) {
                $httpCode = 500;
            } else {
                $httpCode = $rawCode;
            }
            return response()->json(['success' => false, 'message' => $e->getMessage()], $httpCode);
        }
    }

    /**
     * Admin approve (apply without payment)
     */
    public function approve(Request $request, $id)
    {
        $req = RescheduleRequest::find($id);
        if (!$req) return response()->json(['success' => false, 'message' => 'Not found'], 404);

        try {
            DB::transaction(function () use ($req) {
                $booking = $this->resolveBooking($req->booking_type ?? 'mobil', $req->booking_id, true);
                $requestedTarget = $this->resolveTarget($req->requested_target_type ?? 'car', $req->requested_target_id, true);
                if ($booking && $requestedTarget) {
                    $seats = intval($booking->seats ?? 1);
                    if (intval($requestedTarget->available_seats ?? 0) < $seats) {
                        throw new \Exception('Not enough seats to approve');
                    }

                    $booking->ride_id = $requestedTarget->id;
                    $booking->save();

                    if (isset($requestedTarget->available_seats)) {
                        $requestedTarget->available_seats = max(0, intval($requestedTarget->available_seats) - $seats);
                        $requestedTarget->status = intval($requestedTarget->available_seats) > 0 ? 'active' : 'inactive';
                        $requestedTarget->save();
                    }
                }

                $req->status = 'approved';
                $req->processed_at = now();
                $req->save();
            });
        } catch (\Exception $e) {
            Log::error('approve error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json(['success' => true]);
    }

    public function reject(Request $request, $id)
    {
        $req = RescheduleRequest::find($id);
        if (!$req) return response()->json(['success' => false, 'message' => 'Not found'], 404);
        $req->status = 'rejected';
        $req->processed_at = now();
        $req->save();
        return response()->json(['success' => true]);
    }

    /**
     * Resolve booking record by type
     *
     * @param string $bookingType
     * @param int $bookingId
     * @param bool $forUpdate
     * @return mixed
     */
    protected function resolveBooking(string $bookingType, int $bookingId, bool $forUpdate = false)
    {
        switch ($bookingType) {
            case 'motor':
                $q = $forUpdate ? Booking::lockForUpdate()->with('ride') : Booking::with('ride');
                return $q->find($bookingId);
            case 'mobil':
                $q = $forUpdate ? BookingMobil::lockForUpdate()->with('ride') : BookingMobil::with('ride');
                return $q->find($bookingId);
            case 'barang':
                $q = $forUpdate ? BookingBarang::lockForUpdate()->with('ride') : BookingBarang::with('ride');
                return $q->find($bookingId);
            case 'titip':
                $q = $forUpdate ? BookingTitipBarang::lockForUpdate()->with('ride') : BookingTitipBarang::with('ride');
                return $q->find($bookingId);
            default:
                $q = $forUpdate ? BookingMobil::lockForUpdate()->with('ride') : BookingMobil::with('ride');
                return $q->find($bookingId);
        }
    }

    /**
     * Resolve requested target by type
     *
     * @param string $targetType
     * @param int $targetId
     * @param bool $forUpdate
     * @return mixed
     */
    protected function resolveTarget(string $targetType, int $targetId, bool $forUpdate = false)
    {
        $t = strtolower($targetType);
        if (in_array($t, ['ride', 'motor', 'ride_motor'])) {
            return $forUpdate ? Ride::lockForUpdate()->find($targetId) : Ride::find($targetId);
        }
        if (in_array($t, ['car', 'mobil', 'car_ride', 'tebengan_mobil'])) {
            return $forUpdate ? CarRide::lockForUpdate()->find($targetId) : CarRide::find($targetId);
        }
        if (in_array($t, ['barang', 'barang_ride', 'tebengan_barang'])) {
            return $forUpdate ? BarangRide::lockForUpdate()->find($targetId) : BarangRide::find($targetId);
        }
        if (in_array($t, ['titip', 'titip_barang', 'tebengan_titip'])) {
            return $forUpdate ? TebenganTitipBarang::lockForUpdate()->find($targetId) : TebenganTitipBarang::find($targetId);
        }

        // fallback to CarRide
        return $forUpdate ? CarRide::lockForUpdate()->find($targetId) : CarRide::find($targetId);
    }
}
