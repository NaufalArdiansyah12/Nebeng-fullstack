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
            // Prefer updating by booking_id if available
            if (!empty($payment->booking_id)) {
                // Try by booking id across motor, mobil, barang, titip_barang tables
                $bookingModel = \App\Models\Booking::find($payment->booking_id);
                if ($bookingModel) {
                    $bookingModel->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by id, motor)', ['booking_id' => $bookingModel->id]);
                    return;
                }

                $bookingMobil = \App\Models\BookingMobil::find($payment->booking_id);
                if ($bookingMobil) {
                    $bookingMobil->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by id, mobil)', ['booking_id' => $bookingMobil->id]);
                    return;
                }

                $bookingBarang = \App\Models\BookingBarang::find($payment->booking_id);
                if ($bookingBarang) {
                    $bookingBarang->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by id, barang)', ['booking_id' => $bookingBarang->id]);
                    return;
                }

                $bookingTitip = \App\Models\BookingTitipBarang::find($payment->booking_id);
                if ($bookingTitip) {
                    $bookingTitip->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by id, titip)', ['booking_id' => $bookingTitip->id]);
                    return;
                }
            }

            // Fallback: Try by booking_number
            $bookingNumber = $payment->booking_number ?? null;
            if ($bookingNumber) {
                // Try booking_motor first
                $bookingModel = \App\Models\Booking::where('booking_number', $bookingNumber)->first();
                if ($bookingModel) {
                    $bookingModel->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by number, motor)', ['booking_number' => $bookingNumber, 'booking_id' => $bookingModel->id]);
                    return;
                }

                // Try booking_mobil
                $bookingMobil = \App\Models\BookingMobil::where('booking_number', $bookingNumber)->first();
                if ($bookingMobil) {
                    $bookingMobil->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by number, mobil)', ['booking_number' => $bookingNumber, 'booking_id' => $bookingMobil->id]);
                    return;
                }

                // Try booking_barang
                $bookingBarang = \App\Models\BookingBarang::where('booking_number', $bookingNumber)->first();
                if ($bookingBarang) {
                    $bookingBarang->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by number, barang)', ['booking_number' => $bookingNumber, 'booking_id' => $bookingBarang->id]);
                    return;
                }

                // Try booking_titip_barang
                $bookingTitip = \App\Models\BookingTitipBarang::where('booking_number', $bookingNumber)->first();
                if ($bookingTitip) {
                    $bookingTitip->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by number, titip)', ['booking_number' => $bookingNumber, 'booking_id' => $bookingTitip->id]);
                    return;
                }
            }

            // Last resort: Try by ride_id + user_id (for pending bookings)
            if ($payment->ride_id && $payment->user_id) {
                $bookingModel = \App\Models\Booking::where('ride_id', $payment->ride_id)
                    ->where('user_id', $payment->user_id)
                    ->where('status', 'pending')
                    ->orderBy('created_at', 'desc')
                    ->first();

                if ($bookingModel) {
                    $bookingModel->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by ride+user, motor)', ['booking_id' => $bookingModel->id]);
                    return;
                }

                $bookingMobil = \App\Models\BookingMobil::where('ride_id', $payment->ride_id)
                    ->where('user_id', $payment->user_id)
                    ->where('status', 'pending')
                    ->orderBy('created_at', 'desc')
                    ->first();

                if ($bookingMobil) {
                    $bookingMobil->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by ride+user, mobil)', ['booking_id' => $bookingMobil->id]);
                    return;
                }

                $bookingBarang = \App\Models\BookingBarang::where('ride_id', $payment->ride_id)
                    ->where('user_id', $payment->user_id)
                    ->where('status', 'pending')
                    ->orderBy('created_at', 'desc')
                    ->first();

                if ($bookingBarang) {
                    $bookingBarang->update(['status' => 'paid']);
                    Log::info('Booking status updated to paid (by ride+user, barang)', ['booking_id' => $bookingBarang->id]);
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
