<?php

namespace App\Http\Controllers\Api;

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
                    ->where('departure_date', $date);
                    // Removed: ->where('id', '!=', $ride->id) to allow same trip selection
                break;
            case 'mobil':
                $candidateQuery = CarRide::where('origin_location_id', $ride->origin_location_id)
                    ->where('destination_location_id', $ride->destination_location_id)
                    ->where('departure_date', $date);
                    // Removed: ->where('id', '!=', $ride->id) to allow same trip selection
                break;
            case 'barang':
                $candidateQuery = BarangRide::where('origin_location_id', $ride->origin_location_id)
                    ->where('destination_location_id', $ride->destination_location_id)
                    ->where('departure_date', $date);
                    // Removed: ->where('id', '!=', $ride->id) to allow same trip selection
                break;
            case 'titip':
                $candidateQuery = TebenganTitipBarang::where('origin_location_id', $ride->origin_location_id)
                    ->where('destination_location_id', $ride->destination_location_id)
                    ->where('departure_date', $date);
                    // Removed: ->where('id', '!=', $ride->id) to allow same trip selection
                break;
            default:
                $candidateQuery = CarRide::where('origin_location_id', $ride->origin_location_id)
                    ->where('destination_location_id', $ride->destination_location_id)
                    ->where('departure_date', $date);
                    // Removed: ->where('id', '!=', $ride->id) to allow same trip selection
        }

        $candidates = $candidateQuery->with(['originLocation', 'destinationLocation'])->get();

        $data = $candidates->map(function ($r) use ($booking) {
            return [
                'id' => $r->id,
                'ride_id' => $r->id,
                'departure_date' => (string) $r->departure_date,
                'departure_time' => $r->departure_time ?? null,
                'arrival_time' => $r->arrival_time ?? null,
                'available_seats' => $r->available_seats ?? 0,
                'price' => (int) ($r->price ?? 0),
                'price_per_seat' => (int) ($r->price ?? 0),
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

                $priceBefore = 0;
                if ($booking->ride && isset($booking->ride->price)) {
                    $priceBefore = intval(round($booking->ride->price * $seats));
                }
                $priceAfter = intval(round((isset($requestedTarget->price) ? $requestedTarget->price : 0) * $seats));
                $priceDiff = $priceAfter - $priceBefore;

                $requestRow = RescheduleRequest::create([
                    'booking_id' => $booking->id,
                    'booking_type' => $bookingType,
                    'requested_target_type' => $targetType,
                    'requested_target_id' => $requestedTarget->id,
                    'requested_by' => $user->id,
                    'status' => $priceDiff > 0 ? 'awaiting_payment' : 'pending',
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
                    'payment_required' => $priceDiff > 0,
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
                        // ensure status reflects availability
                        $requestedTarget->status = intval($requestedTarget->available_seats) > 0 ? 'active' : 'inactive';
                        $requestedTarget->save();
                    } else if ($diff < 0) {
                        // release seats back to same ride
                        $requestedTarget->available_seats = intval($requestedTarget->available_seats ?? 0) + abs($diff);
                        $requestedTarget->status = intval($requestedTarget->available_seats) > 0 ? 'active' : 'inactive';
                        $requestedTarget->save();
                    }
                } else {
                    // Different rides: release old seats (if we have oldRide) then decrement new ride
                    if ($oldRide) {
                        $oldRide->available_seats = intval($oldRide->available_seats ?? 0) + $oldSeats;
                        $oldRide->status = intval($oldRide->available_seats) > 0 ? 'active' : 'inactive';
                        $oldRide->save();
                    }

                    // Check capacity now using the updated seats count
                    if (intval($requestedTarget->available_seats ?? 0) < $seatsToOccupy) {
                        throw new \Exception('No seats/capacity available on requested target');
                    }

                    // Decrement available seats on requested target by the updated seats count
                    if (isset($requestedTarget->available_seats)) {
                        $requestedTarget->available_seats = max(0, intval($requestedTarget->available_seats) - $seatsToOccupy);
                        $requestedTarget->status = intval($requestedTarget->available_seats) > 0 ? 'active' : 'inactive';
                        $requestedTarget->save();
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
            $code = method_exists($e, 'getCode') && intval($e->getCode()) >= 400 ? intval($e->getCode()) : 500;
            return response()->json(['success' => false, 'message' => $e->getMessage()], $code);
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
