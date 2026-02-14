<?php

namespace App\Services;

use App\Models\User;
use App\Models\Notification;
use Illuminate\Support\Facades\Log;

class ChatNotificationService
{
    /**
     * Send notification when a new chat message is received
     *
     * @param int $senderId ID of the user who sent the message
     * @param int $recipientId ID of the user who should receive the notification
     * @param string $senderName Name of the sender
     * @param string $messageText Content of the message
     * @param string $conversationId Firebase conversation ID
     * @return bool
     */
    public static function sendNewMessageNotification(
        int $senderId,
        int $recipientId,
        string $senderName,
        string $messageText,
        string $conversationId
    ): bool {
        try {
            $recipient = User::find($recipientId);
            
            if (!$recipient) {
                Log::warning('Recipient user not found for chat notification', [
                    'recipient_id' => $recipientId
                ]);
                return false;
            }

            // Prepare notification content
            $title = "Pesan dari {$senderName}";
            $body = strlen($messageText) > 100 
                ? substr($messageText, 0, 100) . '...' 
                : $messageText;

            // Data payload for navigation
            $data = [
                'type' => 'chat_message',
                'conversation_id' => $conversationId,
                'sender_id' => (string) $senderId,
                'sender_name' => $senderName,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ];

            // Save notification to database
            Notification::create([
                'user_id' => $recipientId,
                'type' => 'chat_message',
                'title' => $title,
                'body' => $body,
                'data' => json_encode($data),
                'is_read' => false,
            ]);

            Log::info('Chat notification saved to database', [
                'recipient_id' => $recipientId,
                'sender_id' => $senderId,
            ]);

            // Send FCM push notification if user has token
            if (!empty($recipient->fcm_token)) {
                $sent = FcmService::sendToToken(
                    $recipient->fcm_token,
                    $title,
                    $body,
                    $data
                );

                if ($sent) {
                    Log::info('Chat FCM notification sent successfully', [
                        'recipient_id' => $recipientId,
                        'sender_id' => $senderId,
                    ]);
                    return true;
                } else {
                    Log::warning('Failed to send chat FCM notification', [
                        'recipient_id' => $recipientId,
                    ]);
                }
            } else {
                Log::info('Recipient has no FCM token, notification saved to DB only', [
                    'recipient_id' => $recipientId,
                ]);
            }

            return true;

        } catch (\Exception $e) {
            Log::error('Error sending chat notification: ' . $e->getMessage(), [
                'sender_id' => $senderId,
                'recipient_id' => $recipientId,
                'exception' => $e,
            ]);
            return false;
        }
    }
}

