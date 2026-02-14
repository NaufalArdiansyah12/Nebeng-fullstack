<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ChatNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class ChatController extends Controller
{
    /**
     * Send notification when a new chat message is sent
     * Called from Flutter after message is added to Firestore
     *
     * POST /api/v1/chat/notify
     */
    public function notifyNewMessage(Request $request)
    {
        Log::info('📨 Chat notification request received', [
            'data' => $request->all()
        ]);

        $validator = Validator::make($request->all(), [
            'sender_id' => 'required|integer',
            'recipient_id' => 'required|integer',
            'sender_name' => 'required|string',
            'message_text' => 'required|string',
            'conversation_id' => 'required|string',
        ]);

        if ($validator->fails()) {
            Log::warning('Chat notification validation failed', [
                'errors' => $validator->errors()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $sent = ChatNotificationService::sendNewMessageNotification(
                senderId: $request->sender_id,
                recipientId: $request->recipient_id,
                senderName: $request->sender_name,
                messageText: $request->message_text,
                conversationId: $request->conversation_id
            );

            if ($sent) {
                Log::info('✅ Chat notification sent successfully');
                
                return response()->json([
                    'success' => true,
                    'message' => 'Notification sent successfully',
                ]);
            } else {
                Log::warning('⚠️ Chat notification service returned false');
                
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to send notification',
                ], 500);
            }

        } catch (\Exception $e) {
            Log::error('❌ Chat notify endpoint error: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Server error',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Test endpoint to manually trigger a chat notification
     * GET /api/v1/chat/notify/test
     */
    public function testNotification(Request $request)
    {
        try {
            $recipientId = $request->query('recipient_id', 1);
            
            $sent = ChatNotificationService::sendNewMessageNotification(
                senderId: 999,
                recipientId: (int) $recipientId,
                senderName: 'Test User',
                messageText: 'This is a test notification from the backend API',
                conversationId: 'test_conversation_' . time()
            );

            return response()->json([
                'success' => $sent,
                'message' => $sent ? 'Test notification sent' : 'Failed to send test notification',
                'recipient_id' => $recipientId,
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error: ' . $e->getMessage(),
            ], 500);
        }
    }
}

