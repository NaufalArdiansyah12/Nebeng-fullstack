<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\FcmService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class FcmTestController extends Controller
{
    /**
     * Test endpoint to send FCM notification directly.
     * POST /api/v1/test/fcm
     * Body: { "token": "device_token", "title": "Test", "body": "Test message" }
     */
    public function sendTest(Request $request)
    {
        $validated = $request->validate([
            'token' => 'required|string',
            'title' => 'nullable|string',
            'body' => 'nullable|string',
        ]);

        $token = $validated['token'];
        $title = $validated['title'] ?? 'Test Notification';
        $body = $validated['body'] ?? 'This is a test message from Nebeng backend';

        Log::info('FCM test send requested', ['token' => $token, 'title' => $title]);

        $result = FcmService::sendToToken($token, $title, $body, [
            'test' => 'true',
            'timestamp' => (string) time(),
        ]);

        if ($result) {
            return response()->json([
                'success' => true,
                'message' => 'FCM notification sent successfully',
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Failed to send FCM notification. Check logs.',
        ], 500);
    }
}
