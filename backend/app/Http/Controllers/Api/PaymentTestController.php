<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Services\PaymentService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class PaymentTestController extends Controller
{
    /**
     * Simulate payment success (for development only)
     */
    public function simulatePayment($paymentId)
    {
        if (!app()->environment('local', 'development')) {
            return response()->json([
                'success' => false,
                'message' => 'This endpoint is only available in development mode',
            ], 403);
        }

        try {
            $payment = Payment::findOrFail($paymentId);

            if ($payment->status === 'paid') {
                return response()->json([
                    'success' => false,
                    'message' => 'Payment already paid',
                ], 400);
            }

            // Update payment status to paid
            $payment->update([
                'status' => 'paid',
                'paid_at' => Carbon::now(),
            ]);

            // Update ride payment status if needed
            if ($payment->ride) {
                $payment->ride->update(['payment_status' => 'paid']);
            }

            // Use same processing as webhook handler so booking updates work for all booking tables
            try {
                $paymentService = new PaymentService();
                $payload = [
                    'event' => 'payment.succeeded',
                    'data' => [
                        'reference_id' => $payment->external_id,
                    ],
                ];
                $paymentService->handleWebhook($payload);
            } catch (\Exception $e) {
                Log::error('PaymentTestController simulate: PaymentService handleWebhook failed: ' . $e->getMessage(), ['payment_id' => $payment->id]);
                // Fallback to original controller logic
                $this->updateBookingStatus($payment);
            }

            return response()->json([
                'success' => true,
                'message' => 'Payment simulated successfully',
                'data' => $payment,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Payment not found',
            ], 404);
        }
    }

    /**
     * Update booking status when payment is successful
     */
    private function updateBookingStatus($payment)
    {
        try {
            // IMPORTANT: booking_id can overlap across tables (motor id=1, titip id=1 are different records)
            // So we ALWAYS try by booking_number first (most reliable unique identifier)
            
            $bookingNumber = $payment->booking_number ?? null;
            
            // Strategy 1: Try by booking_number (HIGHEST PRIORITY - unique across all tables)
            if ($bookingNumber) {
                // Try all booking tables by booking_number
                $bookingMotor = \App\Models\Booking::where('booking_number', $bookingNumber)->first();
                if ($bookingMotor) {
                    $bookingMotor->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by number, motor)', ['booking_number' => $bookingNumber, 'booking_id' => $bookingMotor->id]);
                    return;
                }

                $bookingMobil = \App\Models\BookingMobil::where('booking_number', $bookingNumber)->first();
                if ($bookingMobil) {
                    $bookingMobil->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by number, mobil)', ['booking_number' => $bookingNumber, 'booking_id' => $bookingMobil->id]);
                    return;
                }

                $bookingBarang = \App\Models\BookingBarang::where('booking_number', $bookingNumber)->first();
                if ($bookingBarang) {
                    $bookingBarang->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by number, barang)', ['booking_number' => $bookingNumber, 'booking_id' => $bookingBarang->id]);
                    return;
                }

                $bookingTitip = \App\Models\BookingTitipBarang::where('booking_number', $bookingNumber)->first();
                if ($bookingTitip) {
                    $bookingTitip->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by number, titip)', ['booking_number' => $bookingNumber, 'booking_id' => $bookingTitip->id]);
                    return;
                }
            }
            
            // Strategy 2: Try by booking_id + ride_id combination (safer than ID alone)
            if (!empty($payment->booking_id) && !empty($payment->ride_id)) {
                $bookingModel = \App\Models\Booking::where('id', $payment->booking_id)
                    ->where('ride_id', $payment->ride_id)
                    ->first();
                if ($bookingModel) {
                    $bookingModel->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by id+ride, motor)', ['booking_id' => $bookingModel->id]);
                    return;
                }

                $bookingMobil = \App\Models\BookingMobil::where('id', $payment->booking_id)
                    ->where('ride_id', $payment->ride_id)
                    ->first();
                if ($bookingMobil) {
                    $bookingMobil->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by id+ride, mobil)', ['booking_id' => $bookingMobil->id]);
                    return;
                }

                $bookingBarang = \App\Models\BookingBarang::where('id', $payment->booking_id)
                    ->where('ride_id', $payment->ride_id)
                    ->first();
                if ($bookingBarang) {
                    $bookingBarang->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by id+ride, barang)', ['booking_id' => $bookingBarang->id]);
                    return;
                }

                $bookingTitip = \App\Models\BookingTitipBarang::where('id', $payment->booking_id)
                    ->where('ride_id', $payment->ride_id)
                    ->first();
                if ($bookingTitip) {
                    $bookingTitip->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by id+ride, titip)', ['booking_id' => $bookingTitip->id]);
                    return;
                }
            }
            
            // Strategy 3: Try by booking_id if available (but risky due to ID overlap)
            // Only use this as last resort because booking IDs can overlap across tables
            if (!empty($payment->booking_id)) {
                Log::warning('Using booking_id fallback (risky due to ID overlap)', ['booking_id' => $payment->booking_id]);
                
                $bookingMotor = \App\Models\Booking::find($payment->booking_id);
                if ($bookingMotor && $bookingMotor->status === 'pending') {
                    $bookingMotor->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by id only, motor)', ['booking_id' => $bookingMotor->id]);
                    return;
                }

                $bookingMobil = \App\Models\BookingMobil::find($payment->booking_id);
                if ($bookingMobil && $bookingMobil->status === 'pending') {
                    $bookingMobil->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by id only, mobil)', ['booking_id' => $bookingMobil->id]);
                    return;
                }

                $bookingBarang = \App\Models\BookingBarang::find($payment->booking_id);
                if ($bookingBarang && $bookingBarang->status === 'pending') {
                    $bookingBarang->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by id only, barang)', ['booking_id' => $bookingBarang->id]);
                    return;
                }

                $bookingTitip = \App\Models\BookingTitipBarang::find($payment->booking_id);
                if ($bookingTitip && $bookingTitip->status === 'pending') {
                    $bookingTitip->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by id only, titip)', ['booking_id' => $bookingTitip->id]);
                    return;
                }
            }

            Log::warning('Booking not found to update status', [
                'booking_number' => $bookingNumber,
                'booking_id' => $payment->booking_id,
                'ride_id' => $payment->ride_id,
                'user_id' => $payment->user_id,
                'payment_id' => $payment->id
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to update booking status', [
                'payment_id' => $payment->id,
                'error' => $e->getMessage()
            ]);
        }
    }

    /**
     * Get all pending payments (for development testing)
     */
    public function getPendingPayments()
    {
        if (!app()->environment('local', 'development')) {
            return response()->json([
                'success' => false,
                'message' => 'This endpoint is only available in development mode',
            ], 403);
        }

        $payments = Payment::where('status', 'pending')
            ->with(['ride', 'user'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $payments,
        ]);
    }
}
