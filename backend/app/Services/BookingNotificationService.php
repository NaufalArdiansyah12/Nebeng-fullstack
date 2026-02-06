<?php

namespace App\Services;

use App\Models\User;
use App\Models\Notification;
use Illuminate\Support\Facades\Log;

class BookingNotificationService
{
    /**
     * Send notification when booking status changes
     */
    public static function sendStatusNotification($booking, string $newStatus, array $extraData = []): void
    {
        try {
            if (!$booking || !$booking->user) {
                Log::warning('Cannot send booking notification: booking or user missing', ['booking_id' => $booking->id ?? null]);
                return;
            }

            $user = $booking->user;
            [$title, $body, $icon] = self::getNotificationContent($user, $newStatus, $booking, $extraData);

            $data = [
                'booking_id' => (string) $booking->id,
                'booking_number' => $booking->booking_number ?? '',
                'status' => $newStatus,
                'type' => 'booking_status_update',
            ];

            // Merge extra data
            $data = array_merge($data, $extraData);

            // Save notification to database
            try {
                Notification::create([
                    'user_id' => $user->id,
                    'type' => 'booking_status_update',
                    'title' => $title,
                    'body' => $body,
                    'icon' => $icon,
                    'booking_id' => $booking->id,
                    'booking_number' => $booking->booking_number ?? null,
                    'status' => $newStatus,
                    'data' => $data,
                    'is_read' => false,
                ]);
            } catch (\Exception $e) {
                Log::error('Failed to save notification to database', ['error' => $e->getMessage()]);
            }

            // Send FCM push notification if user has token
            if (!empty($user->fcm_token)) {
                FcmService::sendToToken($user->fcm_token, $title, $body, $data);
            } else {
                Log::info('User has no FCM token, notification saved to DB only', ['user_id' => $user->id, 'booking_id' => $booking->id]);
            }
            
            Log::info('Booking status notification sent', [
                'user_id' => $user->id,
                'booking_id' => $booking->id,
                'status' => $newStatus
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send booking status notification', [
                'error' => $e->getMessage(),
                'booking_id' => $booking->id ?? null,
                'status' => $newStatus
            ]);
        }
    }

    /**
     * Get notification title and body based on status
     */
    private static function getNotificationContent(User $user, string $status, $booking, array $extraData): array
    {
        $userName = $user->name ?? 'Penumpang';
        $bookingNumber = $booking->booking_number ?? '';

        switch (strtolower($status)) {
            case 'paid':
                return [
                    "Pembayaran Berhasil! 🎉",
                    "Halo {$userName}, pembayaran untuk booking {$bookingNumber} telah berhasil. Perjalanan Anda siap dilanjutkan!",
                    "🎉"
                ];

            case 'confirmed':
            case 'dijemput':
                return [
                    "Booking Dikonfirmasi ✅",
                    "Halo {$userName}, booking {$bookingNumber} telah dikonfirmasi. Driver akan segera menjemput Anda.",
                    "✅"
                ];

            case 'menuju_penjemputan':
                return [
                    "Driver Menuju Lokasi Penjemputan 🚗",
                    "Halo {$userName}, driver sedang dalam perjalanan menuju lokasi penjemputan Anda. Mohon bersiap-siap!",
                    "🚗"
                ];

            case 'sudah_di_penjemputan':
            case 'arrived':
                return [
                    "Driver Sudah Tiba! 📍",
                    "Halo {$userName}, driver sudah tiba di lokasi penjemputan. Silakan segera naik kendaraan.",
                    "📍"
                ];

            case 'sedang_dalam_perjalanan':
            case 'in_progress':
            case 'menuju_tujuan':
                return [
                    "Perjalanan Dimulai 🛣️",
                    "Halo {$userName}, perjalanan Anda telah dimulai. Selamat menikmati perjalanan yang aman dan nyaman!",
                    "🛣️"
                ];

            case 'sudah_sampai_tujuan':
            case 'near_destination':
                return [
                    "Hampir Sampai Tujuan! 🎯",
                    "Halo {$userName}, Anda akan segera tiba di tujuan. Terima kasih telah menggunakan Nebeng!",
                    "🎯"
                ];

            case 'completed':
            case 'done':
            case 'selesai':
                return [
                    "Perjalanan Selesai ✨",
                    "Halo {$userName}, perjalanan Anda telah selesai dengan selamat. Terima kasih telah menggunakan Nebeng! Jangan lupa berikan rating untuk driver.",
                    "✨"
                ];

            case 'cancelled':
            case 'dibatalkan':
                $reason = $extraData['cancellation_reason'] ?? '';
                $reasonText = $reason ? " Alasan: {$reason}" : '';
                return [
                    "Booking Dibatalkan ❌",
                    "Halo {$userName}, booking {$bookingNumber} telah dibatalkan.{$reasonText}",
                    "❌"
                ];

            case 'expired':
            case 'kadaluarsa':
                return [
                    "Booking Kadaluarsa ⏰",
                    "Halo {$userName}, booking {$bookingNumber} telah kadaluarsa karena pembayaran tidak dilakukan tepat waktu.",
                    "⏰"
                ];

            case 'pending':
                return [
                    "Menunggu Pembayaran 💳",
                    "Halo {$userName}, booking {$bookingNumber} menunggu pembayaran. Segera selesaikan pembayaran Anda.",
                    "💳"
                ];

            case 'refunded':
            case 'dikembalikan':
                return [
                    "Pembayaran Dikembalikan 💰",
                    "Halo {$userName}, pembayaran untuk booking {$bookingNumber} telah dikembalikan ke akun Anda.",
                    "💰"
                ];

            default:
                return [
                    "Update Booking 🔔",
                    "Halo {$userName}, status booking {$bookingNumber} telah diperbarui menjadi: {$status}",
                    "🔔"
                ];
        }
    }

    /**
     * Send notification to driver when customer booking arrives
     */
    public static function sendDriverNotification($ride, string $message, array $extraData = []): void
    {
        try {
            if (!$ride || !$ride->user) {
                Log::warning('Cannot send driver notification: ride or user missing');
                return;
            }

            $driver = $ride->user;
            if (empty($driver->fcm_token)) {
                Log::info('Driver has no FCM token, skipping notification', ['driver_id' => $driver->id]);
                return;
            }

            $title = "Booking Baru! 🚗";
            $body = $message;

            $data = array_merge([
                'ride_id' => (string) $ride->id,
                'type' => 'new_booking',
            ], $extraData);

            FcmService::sendToToken($driver->fcm_token, $title, $body, $data);
            
            Log::info('Driver notification sent', ['driver_id' => $driver->id, 'ride_id' => $ride->id]);
        } catch (\Exception $e) {
            Log::error('Failed to send driver notification', ['error' => $e->getMessage()]);
        }
    }
}
