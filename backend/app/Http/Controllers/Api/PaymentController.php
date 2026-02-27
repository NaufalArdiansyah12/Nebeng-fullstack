<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\PaymentService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    private $paymentService;

    public function __construct(PaymentService $paymentService)
    {
        $this->paymentService = $paymentService;
    }

    public function createPayment(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'ride_id' => 'required|integer',
            // Relax exists:users,id to avoid 422 when frontend supplies user_id
            'user_id' => 'required|integer',
            'booking_number' => 'nullable|string',
            'booking_id' => 'nullable|integer',
            'payment_method' => 'required|in:bri,bca,mandiri,bni,permata,qris,dana',
            'amount' => 'required|numeric|min:0',
            'admin_fee' => 'nullable|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            // Prefer admin_fee provided by request, otherwise read from finance_settings table, fallback to 15000
            $adminFee = $request->admin_fee ?? null;
            if ($adminFee === null) {
                try {
                    $setting = \App\Models\FinanceSetting::first();
                    $adminFee = $setting?->admin_fee ?? 15000;
                } catch (\Exception $e) {
                    // If anything goes wrong reading settings, fallback to sensible default
                    $adminFee = 15000;
                }
            }

            // Normalize incoming amount:
            // - If caller provided `total_amount`, interpret that as total and compute nominal `amount = total_amount - adminFee`.
            // - Otherwise, apply a conservative heuristic: if the provided `amount` is significantly larger than the admin fee
            //   (likely the frontend sent total including admin), subtract adminFee once to recover nominal amount.
            $incomingAmount = isset($request->amount) ? floatval($request->amount) : 0.0;
            if ($request->has('total_amount')) {
                $incomingTotal = floatval($request->input('total_amount'));
                $incomingAmount = max(0.0, $incomingTotal - floatval($adminFee));
                Log::info('PaymentController: normalizing amount from total_amount', ['total_amount' => $incomingTotal, 'admin_fee' => $adminFee, 'amount' => $incomingAmount]);
            } else {
                // Heuristic threshold: if incomingAmount > 1.5 * adminFee, assume it included adminFee and subtract it once.
                if ($incomingAmount > (1.5 * floatval($adminFee))) {
                    Log::warning('PaymentController: incoming amount appears to include admin_fee; normalizing by subtracting admin_fee', ['incoming' => $incomingAmount, 'admin_fee' => $adminFee]);
                    $incomingAmount = max(0.0, $incomingAmount - floatval($adminFee));
                }
            }

            // Determine booking_number: prefer booking_id if provided
            $bookingNumber = $request->booking_number;
            $bookingId = $request->booking_id ?? null;
            $bookingFromMotor = false;
            if ($bookingId) {
                // Try to find booking in motor, mobil, barang, then titip_barang bookings
                $b = \App\Models\Booking::find($bookingId);
                if ($b) {
                    $bookingNumber = $b->booking_number;
                    $bookingFromMotor = true;
                } else {
                    $bm = \App\Models\BookingMobil::find($bookingId);
                    if ($bm) {
                        $bookingNumber = $bm->booking_number;
                    } else {
                        $bb = \App\Models\BookingBarang::find($bookingId);
                        if ($bb) {
                            $bookingNumber = $bb->booking_number;
                        } else {
                            $bt = \App\Models\BookingTitipBarang::find($bookingId);
                            if ($bt) {
                                $bookingNumber = $bt->booking_number;
                            }
                        }
                    }
                }
            }

            // Ensure ride exists in motor, mobil, barang, or tebengan_titip_barang tables
            $rideModel = \App\Models\Ride::find($request->ride_id);
            if (!$rideModel) {
                $rideModel = \App\Models\CarRide::find($request->ride_id);
            }
            if (!$rideModel) {
                $rideModel = \App\Models\BarangRide::find($request->ride_id);
            }
            if (!$rideModel) {
                $rideModel = \App\Models\TebenganTitipBarang::find($request->ride_id);
            }

            if (!$rideModel) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation error',
                    'errors' => ['ride_id' => ['Ride not found']],
                ], 422);
            }

            // If ride is mobil or barang/titip_barang, we won't attach booking_id to payments (keep booking_id null to avoid FK errors)
            $isCarRide = $rideModel instanceof \App\Models\CarRide || (isset($rideModel->ride_type) && $rideModel->ride_type === 'mobil');
            $isBarangRide = $rideModel instanceof \App\Models\BarangRide;
            $isTitipBarang = $rideModel instanceof \App\Models\TebenganTitipBarang;
            // Only pass booking_id to payments if the booking is stored in booking_motor (legacy payments FK)
            $bookingIdToPass = (!$isCarRide && !$isBarangRide && !$isTitipBarang && $bookingFromMotor) ? $bookingId : null;

            // Determine charge amount (what customer will pay) and optional booking_price (new ride nominal)
            $chargeAmount = $incomingAmount;
            $bookingPrice = $request->has('booking_price') ? floatval($request->input('booking_price')) : null;
            $rescheduleRequestId = $request->has('reschedule_request_id') ? intval($request->input('reschedule_request_id')) : null;

            // Apply same rounding rules as booking: round to nearest 1,000 rupiah
            $roundToNearest = function ($v) {
                // round to nearest 5,000 (kelipatan 5)
                return intval(round(floatval($v) / 5000.0) * 5000);
            };

            $chargeAmount = $roundToNearest($chargeAmount);
            if ($bookingPrice !== null) {
                $bookingPrice = $roundToNearest($bookingPrice);
            }

            // Diagnostic log: record incoming vs normalized amounts for debugging reschedule/booking flows
            try {
                Log::info('PaymentController:createPayment debug', [
                    'raw_amount' => $request->input('amount'),
                    'normalized_amount' => $incomingAmount,
                    'booking_price' => $bookingPrice,
                    'admin_fee' => $adminFee,
                    'total_amount_field' => $request->input('total_amount') ?? null,
                    'ride_id' => $request->input('ride_id') ?? null,
                    'booking_id' => $bookingId ?? null,
                    'payload_keys' => array_keys($request->all()),
                ]);
            } catch (\Throwable $__logEx) {
                // ignore logging errors
            }

            // Handle QRIS payment separately
            if ($request->payment_method === 'qris') {
                $result = $this->paymentService->createQRISPayment(
                    $request->ride_id,
                    $request->user_id,
                    $bookingNumber,
                    $chargeAmount,
                    $adminFee,
                    $bookingIdToPass,
                    $bookingPrice,
                    $rescheduleRequestId
                );
            } else {
                // Create virtual account for bank transfer payments
                $result = $this->paymentService->createVirtualAccount(
                    $request->ride_id,
                    $request->user_id,
                    $bookingNumber,
                    $request->payment_method,
                    $chargeAmount,
                    $adminFee,
                    $bookingIdToPass,
                    $bookingPrice,
                    $rescheduleRequestId
                );
            }

            return response()->json([
                'success' => true,
                'message' => 'Payment created successfully',
                'data' => $result,
            ], 201);
        } catch (\Exception $e) {
            Log::error('CreatePayment Exception: ' . $e->getMessage(), ['trace' => $e->getTraceAsString(), 'payload' => $request->all()]);
            return response()->json([
                'success' => false,
                // Return exception message for easier debugging in frontend during development
                'message' => $e->getMessage() ?: 'Failed to create payment',
                'error' => $e->getTraceAsString(),
            ], 500);
        }
    }

    public function checkPaymentStatus($paymentId)
    {
        try {
            $result = $this->paymentService->checkPaymentStatus($paymentId);

            return response()->json([
                'success' => true,
                'data' => $result,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Payment not found',
                'error' => $e->getMessage(),
            ], 404);
        }
    }

    public function webhookCallback(Request $request)
    {
        try {
            // Log webhook request for debugging
            Log::info('Webhook received', [
                'headers' => $request->headers->all(),
                'payload' => $request->all()
            ]);

            // Verify webhook token
            $callbackToken = $request->header('x-callback-token');
            
            if ($callbackToken !== config('services.xendit.webhook_token')) {
                Log::warning('Invalid webhook token', ['token' => $callbackToken]);
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid webhook token',
                ], 401);
            }

            $payload = $request->all();
            
            // Handle test webhook from Xendit (benar-benar empty)
            if (empty($payload)) {
                Log::info('Test webhook from Xendit (empty payload)');
                return response()->json([
                    'success' => true,
                    'message' => 'Test webhook received successfully',
                ], 200);
            }

            // Process real webhook (including payment.succeeded event)
            $payment = $this->paymentService->handleWebhook($payload);

            return response()->json([
                'success' => true,
                'message' => 'Webhook processed successfully',
                'payment_id' => $payment->id ?? null,
            ], 200);
        } catch (\Exception $e) {
            Log::error('Webhook Callback Error: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString(),
                'payload' => $request->all()
            ]);
            
            // Return 200 even on error to prevent Xendit retry
            return response()->json([
                'success' => false,
                'message' => 'Webhook processing failed',
                'error' => $e->getMessage(),
            ], 200);
        }
    }
}
