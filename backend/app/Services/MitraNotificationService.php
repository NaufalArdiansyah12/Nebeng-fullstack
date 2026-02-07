<?php

namespace App\Services;

use App\Models\User;
use App\Models\Notification;
use Illuminate\Support\Facades\Log;

class MitraNotificationService
{
    /**
     * Send notification when vehicle is approved
     */
    public static function sendVehicleApprovedNotification($vehicle): void
    {
        try {
            if (!$vehicle || !$vehicle->user) {
                Log::warning('Cannot send vehicle notification: vehicle or user missing');
                return;
            }

            $user = $vehicle->user;
            $vehicleName = $vehicle->vehicle_name ?? $vehicle->brand . ' ' . $vehicle->model;
            $plateNumber = $vehicle->license_plate ?? $vehicle->plate_number ?? '';

            $title = "Kendaraan Disetujui! 🎉";
            $body = "Selamat! Kendaraan {$vehicleName} - {$plateNumber} Anda telah disetujui. Anda sekarang dapat mulai menerima order.";
            $icon = "✅";

            $data = [
                'vehicle_id' => (string) $vehicle->id,
                'vehicle_name' => $vehicleName,
                'plate_number' => $plateNumber,
                'type' => 'vehicle_approved',
            ];

            self::saveAndSendNotification($user, 'vehicle_approved', $title, $body, $icon, $data);
            
            Log::info('Vehicle approved notification sent', [
                'user_id' => $user->id,
                'vehicle_id' => $vehicle->id,
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send vehicle approved notification', [
                'error' => $e->getMessage(),
                'vehicle_id' => $vehicle->id ?? null,
            ]);
        }
    }

    /**
     * Send notification when vehicle is rejected
     */
    public static function sendVehicleRejectedNotification($vehicle, string $reason = ''): void
    {
        try {
            if (!$vehicle || !$vehicle->user) {
                Log::warning('Cannot send vehicle rejection notification: vehicle or user missing');
                return;
            }

            $user = $vehicle->user;
            $vehicleName = $vehicle->vehicle_name ?? $vehicle->brand . ' ' . $vehicle->model;
            $plateNumber = $vehicle->license_plate ?? $vehicle->plate_number ?? '';
            
            $reasonText = $reason ? " Alasan: {$reason}." : '';

            $title = "Kendaraan Ditolak";
            $body = "Mohon maaf, kendaraan {$vehicleName} - {$plateNumber} Anda ditolak.{$reasonText} Silakan upload ulang dengan data yang benar.";
            $icon = "❌";

            $data = [
                'vehicle_id' => (string) $vehicle->id,
                'vehicle_name' => $vehicleName,
                'plate_number' => $plateNumber,
                'rejection_reason' => $reason,
                'type' => 'vehicle_rejected',
            ];

            self::saveAndSendNotification($user, 'vehicle_rejected', $title, $body, $icon, $data);
            
            Log::info('Vehicle rejected notification sent', [
                'user_id' => $user->id,
                'vehicle_id' => $vehicle->id,
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send vehicle rejected notification', [
                'error' => $e->getMessage(),
                'vehicle_id' => $vehicle->id ?? null,
            ]);
        }
    }

    /**
     * Send notification when withdrawal is successful
     */
    public static function sendWithdrawalSuccessNotification($withdrawal): void
    {
        try {
            if (!$withdrawal || !$withdrawal->user) {
                Log::warning('Cannot send withdrawal notification: withdrawal or user missing');
                return;
            }

            $user = $withdrawal->user;
            $amount = number_format($withdrawal->amount, 0, ',', '.');
            $bankName = $withdrawal->bank_name ?? 'Bank';
            $accountName = $withdrawal->account_name ?? '';

            $title = "Penarikan Berhasil! 💰";
            $body = "Penarikan saldo sebesar Rp {$amount} ke rekening {$bankName} a.n. {$accountName} telah berhasil diproses. Dana akan masuk dalam 1-2 hari kerja.";
            $icon = "💰";

            $data = [
                'withdrawal_id' => (string) $withdrawal->id,
                'amount' => (string) $withdrawal->amount,
                'bank_name' => $bankName,
                'type' => 'withdrawal_success',
            ];

            self::saveAndSendNotification($user, 'withdrawal_success', $title, $body, $icon, $data);
            
            Log::info('Withdrawal success notification sent', [
                'user_id' => $user->id,
                'withdrawal_id' => $withdrawal->id,
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send withdrawal success notification', [
                'error' => $e->getMessage(),
                'withdrawal_id' => $withdrawal->id ?? null,
            ]);
        }
    }

    /**
     * Send notification when withdrawal fails
     */
    public static function sendWithdrawalFailedNotification($withdrawal, string $reason = ''): void
    {
        try {
            if (!$withdrawal || !$withdrawal->user) {
                Log::warning('Cannot send withdrawal failed notification: withdrawal or user missing');
                return;
            }

            $user = $withdrawal->user;
            $amount = number_format($withdrawal->amount, 0, ',', '.');
            $reasonText = $reason ? " Alasan: {$reason}." : '';

            $title = "Penarikan Gagal";
            $body = "Penarikan saldo sebesar Rp {$amount} gagal diproses.{$reasonText} Silakan cek kembali data rekening Anda atau hubungi customer service.";
            $icon = "⚠️";

            $data = [
                'withdrawal_id' => (string) $withdrawal->id,
                'amount' => (string) $withdrawal->amount,
                'failure_reason' => $reason,
                'type' => 'withdrawal_failed',
            ];

            self::saveAndSendNotification($user, 'withdrawal_failed', $title, $body, $icon, $data);
            
            Log::info('Withdrawal failed notification sent', [
                'user_id' => $user->id,
                'withdrawal_id' => $withdrawal->id,
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send withdrawal failed notification', [
                'error' => $e->getMessage(),
                'withdrawal_id' => $withdrawal->id ?? null,
            ]);
        }
    }

    /**
     * Send notification when new booking is created
     */
    public static function sendNewBookingNotification($booking, $driver): void
    {
        try {
            if (!$booking || !$driver) {
                Log::warning('Cannot send new booking notification: booking or driver missing');
                return;
            }

            $customerName = $booking->user->name ?? 'Customer';
            $origin = $booking->origin_name ?? $booking->pickup_location ?? '';
            $destination = $booking->destination_name ?? $booking->dropoff_location ?? '';
            $dateTime = $booking->pickup_time ? date('d M Y, H:i', strtotime($booking->pickup_time)) : '';
            $price = number_format($booking->price, 0, ',', '.');

            $title = "Booking Baru! 🎉";
            $body = "Anda mendapat booking baru dari {$customerName} untuk rute {$origin} - {$destination} pada {$dateTime}. Harga: Rp {$price}";
            $icon = "🎫";

            $data = [
                'booking_id' => (string) $booking->id,
                'booking_number' => $booking->booking_number ?? '',
                'customer_name' => $customerName,
                'origin' => $origin,
                'destination' => $destination,
                'type' => 'new_booking',
            ];

            self::saveAndSendNotification($driver, 'new_booking', $title, $body, $icon, $data, $booking->id, $booking->booking_number ?? null);
            
            Log::info('New booking notification sent to driver', [
                'driver_id' => $driver->id,
                'booking_id' => $booking->id,
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send new booking notification', [
                'error' => $e->getMessage(),
                'booking_id' => $booking->id ?? null,
            ]);
        }
    }

    /**
     * Send notification when booking is cancelled by customer
     */
    public static function sendBookingCancelledNotification($booking, $driver): void
    {
        try {
            if (!$booking || !$driver) {
                Log::warning('Cannot send booking cancelled notification: booking or driver missing');
                return;
            }

            $bookingNumber = $booking->booking_number ?? 'Booking';

            $title = "Booking Dibatalkan";
            $body = "Booking #{$bookingNumber} telah dibatalkan oleh customer. Dana akan dikembalikan jika sudah dibayar.";
            $icon = "🚫";

            $data = [
                'booking_id' => (string) $booking->id,
                'booking_number' => $booking->booking_number ?? '',
                'type' => 'booking_cancelled',
            ];

            self::saveAndSendNotification($driver, 'booking_cancelled', $title, $body, $icon, $data, $booking->id, $booking->booking_number ?? null);
            
            Log::info('Booking cancelled notification sent to driver', [
                'driver_id' => $driver->id,
                'booking_id' => $booking->id,
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send booking cancelled notification', [
                'error' => $e->getMessage(),
                'booking_id' => $booking->id ?? null,
            ]);
        }
    }

    /**
     * Send notification when booking is completed
     */
    public static function sendBookingCompletedNotification($booking, $driver, float $earnings): void
    {
        try {
            if (!$booking || !$driver) {
                Log::warning('Cannot send booking completed notification: booking or driver missing');
                return;
            }

            $customerName = $booking->user->name ?? 'Customer';
            $earningsFormatted = number_format($earnings, 0, ',', '.');

            $title = "Perjalanan Selesai! 🎉";
            $body = "Selamat! Perjalanan dengan {$customerName} telah selesai. Pendapatan Rp {$earningsFormatted} akan ditambahkan ke saldo Anda.";
            $icon = "🎉";

            $data = [
                'booking_id' => (string) $booking->id,
                'booking_number' => $booking->booking_number ?? '',
                'earnings' => (string) $earnings,
                'customer_name' => $customerName,
                'type' => 'booking_completed',
            ];

            self::saveAndSendNotification($driver, 'booking_completed', $title, $body, $icon, $data, $booking->id, $booking->booking_number ?? null);
            
            Log::info('Booking completed notification sent to driver', [
                'driver_id' => $driver->id,
                'booking_id' => $booking->id,
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send booking completed notification', [
                'error' => $e->getMessage(),
                'booking_id' => $booking->id ?? null,
            ]);
        }
    }

    /**
     * Send notification when driver receives a rating
     */
    public static function sendRatingReceivedNotification($rating, $driver): void
    {
        try {
            if (!$rating || !$driver) {
                Log::warning('Cannot send rating notification: rating or driver missing');
                return;
            }

            $customerName = $rating->user->name ?? 'Customer';
            $ratingValue = $rating->rating ?? $rating->rate ?? 0;
            $review = $rating->review ?? $rating->comment ?? '';
            
            $stars = str_repeat('⭐', $ratingValue);
            $reviewText = $review ? " \"{$review}\"" : '';

            $title = $ratingValue >= 4 ? "Rating Baru ⭐" : "Rating Diterima";
            $body = "{$customerName} memberikan rating {$stars} untuk perjalanan Anda!{$reviewText}";
            $icon = "⭐";

            $data = [
                'rating_id' => (string) $rating->id,
                'rating_value' => (string) $ratingValue,
                'customer_name' => $customerName,
                'review' => $review,
                'booking_id' => $rating->booking_id ? (string) $rating->booking_id : null,
                'type' => 'rating_received',
            ];

            $bookingId = $rating->booking_id ?? null;
            $bookingNumber = null;
            if ($bookingId && $rating->booking) {
                $bookingNumber = $rating->booking->booking_number ?? null;
            }

            self::saveAndSendNotification($driver, 'rating_received', $title, $body, $icon, $data, $bookingId, $bookingNumber);
            
            Log::info('Rating received notification sent to driver', [
                'driver_id' => $driver->id,
                'rating_id' => $rating->id,
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send rating received notification', [
                'error' => $e->getMessage(),
                'rating_id' => $rating->id ?? null,
            ]);
        }
    }

    /**
     * Send notification when payment is received
     */
    public static function sendPaymentReceivedNotification($booking, $driver, float $amount): void
    {
        try {
            if (!$booking || !$driver) {
                Log::warning('Cannot send payment notification: booking or driver missing');
                return;
            }

            $amountFormatted = number_format($amount, 0, ',', '.');
            $bookingNumber = $booking->booking_number ?? 'Booking';
            
            // Get current balance if available
            $balanceText = '';
            if (isset($driver->balance)) {
                $balanceFormatted = number_format($driver->balance, 0, ',', '.');
                $balanceText = " Saldo Anda: Rp {$balanceFormatted}";
            }

            $title = "Pembayaran Diterima 💵";
            $body = "Pembayaran Rp {$amountFormatted} untuk booking #{$bookingNumber} telah diterima.{$balanceText}";
            $icon = "💵";

            $data = [
                'booking_id' => (string) $booking->id,
                'booking_number' => $booking->booking_number ?? '',
                'amount' => (string) $amount,
                'type' => 'payment_received',
            ];

            self::saveAndSendNotification($driver, 'payment_received', $title, $body, $icon, $data, $booking->id, $booking->booking_number ?? null);
            
            Log::info('Payment received notification sent to driver', [
                'driver_id' => $driver->id,
                'booking_id' => $booking->id,
                'amount' => $amount,
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send payment received notification', [
                'error' => $e->getMessage(),
                'booking_id' => $booking->id ?? null,
            ]);
        }
    }

    /**
     * Send general announcement to mitra
     */
    public static function sendAnnouncementToMitra($mitraUser, string $title, string $body, string $icon = '🔔', array $extraData = []): void
    {
        try {
            if (!$mitraUser) {
                Log::warning('Cannot send announcement: mitra user missing');
                return;
            }

            $data = array_merge([
                'type' => 'announcement',
            ], $extraData);

            self::saveAndSendNotification($mitraUser, 'announcement', $title, $body, $icon, $data);
            
            Log::info('Announcement sent to mitra', [
                'user_id' => $mitraUser->id,
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send announcement to mitra', [
                'error' => $e->getMessage(),
                'user_id' => $mitraUser->id ?? null,
            ]);
        }
    }

    /**
     * Send promo notification to mitra
     */
    public static function sendPromoToMitra($mitraUser, string $title, string $body, array $extraData = []): void
    {
        try {
            if (!$mitraUser) {
                Log::warning('Cannot send promo: mitra user missing');
                return;
            }

            $icon = "🎁";
            $data = array_merge([
                'type' => 'promo',
            ], $extraData);

            self::saveAndSendNotification($mitraUser, 'promo', $title, $body, $icon, $data);
            
            Log::info('Promo sent to mitra', [
                'user_id' => $mitraUser->id,
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send promo to mitra', [
                'error' => $e->getMessage(),
                'user_id' => $mitraUser->id ?? null,
            ]);
        }
    }

    /**
     * Helper method to save notification to database and send FCM
     */
    private static function saveAndSendNotification(
        User $user,
        string $type,
        string $title,
        string $body,
        string $icon,
        array $data = [],
        ?int $bookingId = null,
        ?string $bookingNumber = null
    ): void {
        // Save notification to database
        try {
            Notification::create([
                'user_id' => $user->id,
                'type' => $type,
                'title' => $title,
                'body' => $body,
                'icon' => $icon,
                'booking_id' => $bookingId,
                'booking_number' => $bookingNumber,
                'data' => $data,
                'is_read' => false,
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to save notification to database', [
                'error' => $e->getMessage(),
                'user_id' => $user->id,
            ]);
        }

        // Send FCM push notification if user has token
        if (!empty($user->fcm_token)) {
            FcmService::sendToToken($user->fcm_token, $title, $body, $data);
        } else {
            Log::info('User has no FCM token, notification saved to DB only', [
                'user_id' => $user->id,
                'type' => $type,
            ]);
        }
    }
}
