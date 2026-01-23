<?php

namespace App\Services;

use App\Models\Payment;
use App\Models\Ride;
use App\Models\CarRide;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;
use Xendit\Configuration;
use Xendit\PaymentMethod\PaymentMethodApi;
use Xendit\PaymentMethod\PaymentMethodParameters;
use Xendit\PaymentMethod\VirtualAccountParameters;
use Xendit\PaymentMethod\VirtualAccountChannelProperties;
use App\Services\FcmService;

class PaymentService
{
    private $paymentMethodApi;

    public function __construct()
    {
        Configuration::setXenditKey(config('services.xendit.secret_key'));
        $this->paymentMethodApi = new PaymentMethodApi();
    }

    public function createVirtualAccount($rideId, $userId, $bookingNumber, $paymentMethod, $amount, $adminFee = 15000, $bookingId = null)
    {
        // support motor, mobil, barang rides, and tebengan titip barang
        $ride = Ride::find($rideId);
        if (!$ride) {
            $ride = CarRide::find($rideId);
        }
        if (!$ride) {
            // try barang rides
            $ride = \App\Models\BarangRide::find($rideId);
        }
        if (!$ride) {
            // try tebengan titip barang
            $ride = \App\Models\TebenganTitipBarang::find($rideId);
        }
        if (!$ride) {
            throw new \Exception('Ride not found');
        }
        $totalAmount = $amount + $adminFee;
        $externalId = 'PAYMENT-' . $bookingNumber . '-' . time();

        Log::info('Creating payment', [
            'ride_id' => $rideId,
            'user_id' => $userId,
            'booking_number' => $bookingNumber,
            'external_id' => $externalId,
            'payment_method' => $paymentMethod,
            'amount' => $amount,
        ]);

        // Map payment method to bank code
        $bankCode = $this->getBankCode($paymentMethod);

        if (!$bankCode) {
            throw new \Exception('Invalid payment method');
        }

        // Set expiration time (1 hour from now)
        $expiresAt = Carbon::now()->addHour();

        try {
            // For development/testing: generate dummy VA number if Xendit key is not configured
            $xenditKey = config('services.xendit.secret_key');

            // Check if we should use dummy mode
            // Use dummy mode if: no key, placeholder key, or explicitly enabled
            // Use real API if: valid key exists AND dummy mode is explicitly disabled
            $useDummyMode = empty($xenditKey) ||
                $xenditKey === 'your-xendit-secret-key-here' ||
                env('PAYMENT_DUMMY_MODE', false);  // Set to false to use real API

            if ($useDummyMode) {
                Log::info('Payment: Using dummy mode for VA generation');

                // Generate dummy VA number for testing
                $vaNumber = $this->generateDummyVANumber($bankCode);
                $response = [
                    'id' => 'dummy_' . uniqid(),
                    'reference_id' => $externalId,
                    'type' => 'VIRTUAL_ACCOUNT',
                    'status' => 'ACTIVE',
                    'virtual_account' => [
                        'channel_code' => $bankCode,
                        'virtual_account_number' => $vaNumber,
                    ],
                ];
            } else {
                Log::info('Payment: Using real Xendit API for VA generation');

                // Create payment method with virtual account via Xendit API
                $channelProperties = new VirtualAccountChannelProperties([
                    'customer_name' => 'Nebeng Motor Payment',
                    'expires_at' => $expiresAt->toIso8601String(),
                ]);

                $virtualAccount = new VirtualAccountParameters([
                    'channel_code' => $bankCode,
                    'channel_properties' => $channelProperties,
                ]);

                $params = new PaymentMethodParameters([
                    'type' => 'VIRTUAL_ACCOUNT',
                    'reusability' => 'ONE_TIME_USE',
                    'reference_id' => $externalId,
                    'virtual_account' => $virtualAccount,
                ]);

                // Call Xendit API
                $response = $this->paymentMethodApi->createPaymentMethod(
                    null,  // for_user_id
                    $params
                );

                // Get virtual account number from response
                $vaNumber = $response['virtual_account']['channel_properties']['virtual_account_number'] ??
                    $response['virtual_account']['virtual_account_number'] ??
                    'N/A';
            }

            // Decide whether to store ride_id to avoid foreign key constraint issues
            $rideIdToSave = $rideId;
            // If ride is a BarangRide or TebenganTitipBarang, some DB schemas use a different rides table and payments FK may reject it.
            // In that case, avoid setting ride_id to prevent FK constraint failures.
            if ($ride instanceof \App\Models\BarangRide || $ride instanceof \App\Models\TebenganTitipBarang) {
                $rideIdToSave = null;
            }

            // Save payment to database
            $payment = Payment::create([
                'booking_id' => $bookingId,
                'ride_id' => $rideIdToSave,
                'user_id' => $userId,
                'booking_number' => $bookingNumber,
                'payment_method' => $paymentMethod,
                'amount' => $amount,
                'admin_fee' => $adminFee,
                'total_amount' => $totalAmount,
                'external_id' => $externalId,
                'virtual_account_number' => $vaNumber,
                'bank_code' => $bankCode,
                'status' => 'pending',
                'expires_at' => $expiresAt,
                'xendit_response' => json_encode($response),
            ]);

            return [
                'success' => true,
                'payment' => $payment,
                'virtual_account_number' => $vaNumber,
                'bank_code' => $bankCode,
                'expires_at' => $expiresAt,
            ];
        } catch (\Exception $e) {
            Log::error('Xendit VA Creation Error: ' . $e->getMessage());
            Log::error('Xendit VA Creation Trace: ' . $e->getTraceAsString());
            throw new \Exception('Failed to create virtual account: ' . $e->getMessage());
        }
    }

    private function generateDummyVANumber($bankCode)
    {
        // Generate dummy VA number for testing (format: bank prefix + random numbers)
        $prefixes = [
            'BRI' => '9088',
            'BCA' => '7088',
            'MANDIRI' => '8808',
            'BNI' => '8808',
            'PERMATA' => '8808',
        ];

        $prefix = $prefixes[$bankCode] ?? '9088';
        $random = str_pad(mt_rand(1, 999999999999), 12, '0', STR_PAD_LEFT);

        return $prefix . $random;
    }

    public function checkPaymentStatus($paymentId)
    {
        $payment = Payment::findOrFail($paymentId);

        return [
            'payment_id' => $payment->id,
            'status' => $payment->status,
            'booking_number' => $payment->booking_number,
            'virtual_account_number' => $payment->virtual_account_number,
            'total_amount' => $payment->total_amount,
            'expires_at' => $payment->expires_at,
            'paid_at' => $payment->paid_at,
        ];
    }

    public function handleWebhook($payload)
    {
        try {
            // Log untuk debugging
            Log::info('Processing webhook payload', ['event' => $payload['event'] ?? 'unknown']);

            // 1. Cek event type
            $event = $payload['event'] ?? null;
            
            // 2. Ambil data dari objek 'data'
            $data = $payload['data'] ?? $payload;

            // 3. Ambil reference_id
            $externalId = null;
            
            // Untuk event payment.succeeded, reference_id ada di root data
            if ($event === 'payment.succeeded' || $event === 'payment.failed') {
                $externalId = $data['reference_id'] ?? null;
            } else {
                // Untuk payment_method events, reference_id ada di dalam data
                $externalId = $data['reference_id'] ?? $data['external_id'] ?? null;
            }

            if (!$externalId) {
                Log::warning('Webhook Warning: External ID tidak ditemukan', ['payload' => $payload]);
                return false;
            }

            Log::info("Processing webhook for external_id: $externalId, event: $event");

            // Cari data pembayaran di database berdasarkan external_id
            $payment = Payment::where('external_id', $externalId)->first();

            if (!$payment) {
                // Abaikan jika ini hanya testing dummy dari dashboard
                if (str_contains($externalId, 'fixed-va') || $externalId === 'TEST') {
                    Log::info('Ignoring test webhook');
                    return true;
                }
                Log::error("Payment not found for ID: $externalId");
                throw new \Exception('Payment not found for ID: ' . $externalId);
            }

            // 4. Handle berdasarkan event type
            if ($event === 'payment.succeeded') {
                // Event payment.succeeded berarti pembayaran berhasil
                $payment->update([
                    'status' => 'paid',
                    'paid_at' => \Carbon\Carbon::now(),
                    'xendit_response' => json_encode($payload),
                ]);

                // Update status pesanan/ride jika ada relasinya
                if ($payment->ride) {
                    $payment->ride->update(['payment_status' => 'paid']);
                }

                    // Update booking status if booking exists
                    // CRITICAL: Use booking_number first (unique), then fallback to booking_id (non-unique)
                    try {
                        $bookingNumber = $payment->booking_number ?? null;
                        $bookingFound = false;
                        
                        // Strategy 1: Try by booking_number first (HIGHEST PRIORITY - UNIQUE ACROSS ALL TABLES)
                        if (!empty($bookingNumber)) {
                            // Try booking_motor first
                            $bookingModel = \App\Models\Booking::where('booking_number', $bookingNumber)->first();
                            if ($bookingModel) {
                                $bookingModel->update(['status' => 'paid']);
                                
                                // Decrease available_seats on the ride
                                if ($bookingModel->ride_id) {
                                    $ride = \App\Models\Ride::find($bookingModel->ride_id);
                                    if ($ride && $ride->available_seats > 0) {
                                        $seatsBooked = $bookingModel->seats ?? 1;
                                        $ride->decrement('available_seats', $seatsBooked);
                                        Log::info('Decreased available_seats for motor ride', [
                                            'ride_id' => $ride->id,
                                            'seats_booked' => $seatsBooked,
                                            'remaining_seats' => $ride->fresh()->available_seats
                                        ]);
                                    }
                                }
                                
                                Log::info('Booking status updated to paid (by number, motor)', ['booking_number' => $bookingNumber, 'booking_id' => $bookingModel->id]);
                                $bookingFound = true;
                            } else {
                                // Fallback: check booking_mobil
                                $bookingMobil = \App\Models\BookingMobil::where('booking_number', $bookingNumber)->first();
                                if ($bookingMobil) {
                                    $bookingMobil->update(['status' => 'paid']);
                                    Log::info('Booking status updated to paid (by number, mobil)', ['booking_number' => $bookingNumber, 'booking_id' => $bookingMobil->id]);
                                    $bookingFound = true;
                                } else {
                                    // Fallback: check booking_barang
                                    $bookingBarang = \App\Models\BookingBarang::where('booking_number', $bookingNumber)->first();
                                    if ($bookingBarang) {
                                        $bookingBarang->update(['status' => 'paid']);
                                        Log::info('Booking status updated to paid (by number, barang)', ['booking_number' => $bookingNumber, 'booking_id' => $bookingBarang->id]);
                                        $bookingFound = true;
                                    } else {
                                        // Fallback: check booking_titip_barang
                                        $bookingTitip = \App\Models\BookingTitipBarang::where('booking_number', $bookingNumber)->first();
                                        if ($bookingTitip) {
                                            $bookingTitip->update(['status' => 'paid']);
                                            Log::info('Booking status updated to paid (by number, titip)', ['booking_number' => $bookingNumber, 'booking_id' => $bookingTitip->id]);
                                            $bookingFound = true;
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Strategy 2: If booking not found by number, try by booking_id (CAUTION: non-unique)
                        if (!$bookingFound && !empty($payment->booking_id)) {
                            Log::info('Booking not found by number, trying by booking_id', ['booking_id' => $payment->booking_id]);
                            
                            // Try by booking id across motor, mobil, barang, titip tables
                            $bookingModel = \App\Models\Booking::find($payment->booking_id);
                            if ($bookingModel) {
                                $bookingModel->update(['status' => 'paid']);
                                Log::info('Booking status updated to paid (by id, motor)', ['booking_id' => $bookingModel->id]);
                                $bookingFound = true;
                            } else {
                                $bookingMobil = \App\Models\BookingMobil::find($payment->booking_id);
                                if ($bookingMobil) {
                                    $bookingMobil->update(['status' => 'paid']);
                                    Log::info('Booking status updated to paid (by id, mobil)', ['booking_id' => $bookingMobil->id]);
                                    $bookingFound = true;
                                } else {
                                    $bookingBarang = \App\Models\BookingBarang::find($payment->booking_id);
                                    if ($bookingBarang) {
                                        $bookingBarang->update(['status' => 'paid']);
                                        Log::info('Booking status updated to paid (by id, barang)', ['booking_id' => $bookingBarang->id]);
                                        $bookingFound = true;
                                    } else {
                                        $bookingTitip = \App\Models\BookingTitipBarang::find($payment->booking_id);
                                        if ($bookingTitip) {
                                            $bookingTitip->update(['status' => 'paid']);
                                            Log::info('Booking status updated to paid (by id, titip)', ['booking_id' => $bookingTitip->id]);
                                            $bookingFound = true;
                                        }
                                    }
                                }
                            }
                        }
                            
                        // Strategy 3: If booking not found by number or id, try by ride_id + user_id (for latest pending booking)
                        if (!$bookingFound && !empty($payment->ride_id) && !empty($payment->user_id)) {
                            Log::info('Booking not found by number, trying by ride_id + user_id', [
                                'ride_id' => $payment->ride_id, 
                                'user_id' => $payment->user_id
                            ]);
                            
                            // Try booking_motor
                            $bookingModel = \App\Models\Booking::where('ride_id', $payment->ride_id)
                                ->where('user_id', $payment->user_id)
                                ->where('status', 'pending')
                                ->orderBy('created_at', 'desc')
                                ->first();
                                
                            if ($bookingModel) {
                                $bookingModel->update(['status' => 'paid']);
                                Log::info('Booking status updated to paid (by ride+user, motor)', ['booking_id' => $bookingModel->id]);
                                $bookingFound = true;
                            } else {
                                // Try booking_mobil
                                $bookingMobil = \App\Models\BookingMobil::where('ride_id', $payment->ride_id)
                                    ->where('user_id', $payment->user_id)
                                    ->where('status', 'pending')
                                    ->orderBy('created_at', 'desc')
                                    ->first();
                                    
                                if ($bookingMobil) {
                                    $bookingMobil->update(['status' => 'paid']);
                                    Log::info('Booking status updated to paid (by ride+user, mobil)', ['booking_id' => $bookingMobil->id]);
                                    $bookingFound = true;
                                } else {
                                    // Try booking_barang
                                    $bookingBarang = \App\Models\BookingBarang::where('ride_id', $payment->ride_id)
                                        ->where('user_id', $payment->user_id)
                                        ->where('status', 'pending')
                                        ->orderBy('created_at', 'desc')
                                        ->first();
                                        
                                    if ($bookingBarang) {
                                        $bookingBarang->update(['status' => 'paid']);
                                        Log::info('Booking status updated to paid (by ride+user, barang)', ['booking_id' => $bookingBarang->id]);
                                        $bookingFound = true;
                                    } else {
                                        // Try booking_titip_barang
                                        $bookingTitip = \App\Models\BookingTitipBarang::where('ride_id', $payment->ride_id)
                                            ->where('user_id', $payment->user_id)
                                            ->where('status', 'pending')
                                            ->orderBy('created_at', 'desc')
                                            ->first();
                                            
                                        if ($bookingTitip) {
                                            $bookingTitip->update(['status' => 'paid']);
                                            Log::info('Booking status updated to paid (by ride+user, titip)', ['booking_id' => $bookingTitip->id]);
                                            $bookingFound = true;
                                        }
                                    }
                                }
                            }
                        }
                            
                        if (!$bookingFound) {
                            Log::warning('Booking not found to update status', [
                                'booking_number' => $bookingNumber, 
                                'ride_id' => $payment->ride_id,
                                'user_id' => $payment->user_id,
                                'payment_id' => $payment->id
                            ]);
                        }
                    } catch (\Exception $e) {
                        Log::error('Failed to update booking status: ' . $e->getMessage());
                    }

                // Kirim notifikasi push via FCM jika user memiliki token
                try {
                    $user = $payment->user;
                    if ($user && !empty($user->fcm_token)) {
                        $title = 'Hi ' . ($user->name ?? '');
                        $body = 'Pembayaran Anda telah berhasil! Terima kasih telah menggunakan Nebeng. Perjalanan Anda siap dilanjutkan.';
                        FcmService::sendToToken($user->fcm_token, $title, $body, [
                            'payment_id' => $payment->id,
                            'booking_number' => $payment->booking_number,
                        ]);
                    }
                } catch (\Exception $e) {
                    Log::error('Failed to send FCM: ' . $e->getMessage());
                }

                Log::info("✅ Payment SUCCEEDED: Database updated for ID $externalId");
            } 
            elseif ($event === 'payment.failed') {
                // Event payment.failed berarti pembayaran gagal
                $payment->update([
                    'status' => 'failed',
                    'xendit_response' => json_encode($payload),
                ]);
                Log::info("❌ Payment FAILED: Database updated for ID $externalId");
            }
            elseif ($event === 'payment_method.activated') {
                // Event ini hanya informasi bahwa VA sudah aktif, tidak perlu update status
                Log::info("ℹ️ Payment method ACTIVATED for ID $externalId");
            }
            elseif ($event === 'payment_method.expired') {
                // Event ini hanya informasi bahwa VA sudah expired
                Log::info("⏰ Payment method EXPIRED for ID $externalId");
            }
            else {
                // Untuk backward compatibility dengan webhook lama
                $status = strtoupper($data['status'] ?? '');
                if ($status === 'PAID' || $status === 'COMPLETED' || $status === 'SUCCEEDED') {
                    $payment->update([
                        'status' => 'paid',
                        'paid_at' => \Carbon\Carbon::now(),
                        'xendit_response' => json_encode($payload),
                    ]);

                    if ($payment->ride) {
                        $payment->ride->update(['payment_status' => 'paid']);
                    }

                    Log::info("✅ Payment Successful (legacy): Database updated for ID $externalId");
                }
            }

            return $payment;
        } catch (\Exception $e) {
            Log::error('Webhook Error: ' . $e->getMessage());
            Log::error('Webhook Error Trace: ' . $e->getTraceAsString());
            throw $e;
        }
    }

    private function getBankCode($paymentMethod)
    {
        $bankCodes = [
            'bri' => 'BRI',
            'bca' => 'BCA',
            'mandiri' => 'MANDIRI',
            'bni' => 'BNI',
            'permata' => 'PERMATA',
        ];

        return $bankCodes[$paymentMethod] ?? null;
    }

    public function createCashPayment($rideId, $userId, $bookingNumber, $amount, $adminFee = 0, $bookingId = null)
    {
        $totalAmount = $amount + $adminFee;
        $externalId = 'CASH-' . $bookingNumber . '-' . time();

        // Avoid FK issues for BarangRide and TebenganTitipBarang: don't set ride_id if it's one of these
        $rideModel = \App\Models\Ride::find($rideId);
        if (!$rideModel) {
            $rideModel = \App\Models\CarRide::find($rideId);
        }
        if (!$rideModel) {
            $rideModel = \App\Models\BarangRide::find($rideId);
        }
        if (!$rideModel) {
            $rideModel = \App\Models\TebenganTitipBarang::find($rideId);
        }

        $rideIdToSave = $rideId;
        if ($rideModel instanceof \App\Models\BarangRide || $rideModel instanceof \App\Models\TebenganTitipBarang) {
            $rideIdToSave = null;
        }

        $payment = Payment::create([
            'booking_id' => $bookingId ?? null,
            'ride_id' => $rideIdToSave,
            'user_id' => $userId,
            'booking_number' => $bookingNumber,
            'payment_method' => 'cash',
            'amount' => $amount,
            'admin_fee' => $adminFee,
            'total_amount' => $totalAmount,
            'external_id' => $externalId,
            'status' => 'pending',
        ]);

        return [
            'success' => true,
            'payment' => $payment,
        ];
    }
}
