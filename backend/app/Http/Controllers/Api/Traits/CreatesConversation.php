<?php

namespace App\Http\Controllers\Api\Traits;

use App\Services\FirebaseChatService;
use Illuminate\Support\Facades\Log;

trait CreatesConversation
{
    /**
     * Create Firebase conversation after successful booking
     */
    protected function createConversationAfterBooking(
        int $rideId,
        string $bookingType,
        int $customerId,
        int $mitraId,
        string $bookingNumber
    ): ?string {
        try {
            // TODO: Fix Firebase OAuth2 JWT signature issue
            // For now, skip server-side conversation creation
            // Conversation will be created from Flutter client-side
            Log::info('⏭️ Skipping server-side conversation creation (will be handled by client)', [
                'ride_id' => $rideId,
                'booking_type' => $bookingType,
                'customer_id' => $customerId,
                'mitra_id' => $mitraId,
            ]);
            
            return null;
            
            /* Original code - commented until Firebase auth issue fixed
            $customer = \App\Models\User::find($customerId);
            $mitra = \App\Models\User::find($mitraId);
            
            if (!$customer || !$mitra) {
                Log::warning('Cannot create conversation: user not found', [
                    'customer_id' => $customerId,
                    'mitra_id' => $mitraId
                ]);
                return null;
            }

            $chatService = app(FirebaseChatService::class);
            
            $conversationId = $chatService->createConversation(
                rideId: $rideId,
                bookingType: $bookingType,
                customerId: $customer->id,
                customerName: $customer->name,
                customerPhoto: $customer->profile_photo ?? null,
                mitraId: $mitra->id,
                mitraName: $mitra->name,
                mitraPhoto: $mitra->profile_photo ?? null
            );

            // Send initial system message
            $chatService->sendSystemMessage(
                $conversationId,
                "Booking {$bookingNumber} berhasil dibuat. Silakan chat untuk koordinasi lebih lanjut."
            );

            return $conversationId;
            */
        } catch (\Exception $e) {
            Log::warning('Failed to create chat conversation', [
                'error' => $e->getMessage(),
                'ride_id' => $rideId,
                'booking_type' => $bookingType
            ]);
            return null;
        }
    }
}
