<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Models\User;
use App\Models\PosMitraUser;

class FcmController extends Controller
{
    public function updateToken(Request $request)
    {
        $token = $request->bearerToken();
        if (!$token) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $hashedToken = hash('sha256', $token);
        $apiToken = DB::table('api_tokens')->where('token', $hashedToken)->first();

        if (!$apiToken) {
            return response()->json(['success' => false, 'message' => 'Invalid token'], 401);
        }

        $user = User::find($apiToken->user_id);
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'User not found'], 404);
        }

        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $user->fcm_token = $request->fcm_token;
        $user->save();

        Log::info('[FCM] User FCM token updated', ['user_id' => $user->id]);
        return response()->json(['success' => true, 'message' => 'FCM token updated']);
    }

    /**
     * Update FCM token for PosMitra user
     * POST /api/v1/posmitra/fcm-token
     */
    public function updatePosMitraToken(Request $request)
    {
        Log::info('[FCM PosMitra] updatePosMitraToken called');

        $token = $request->bearerToken();
        if (!$token) {
            Log::warning('[FCM PosMitra] No bearer token');
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $hashedToken = hash('sha256', $token);
        $apiToken = DB::table('api_tokens')
            ->where('token', $hashedToken)
            ->where('user_type', 'posmitra')
            ->first();

        if (!$apiToken) {
            Log::warning('[FCM PosMitra] Invalid or non-posmitra token');
            return response()->json(['success' => false, 'message' => 'Invalid token or not a posmitra token'], 401);
        }

        Log::info('[FCM PosMitra] ApiToken found', ['posmitra_id' => $apiToken->posmitra_id]);

        $posMitra = PosMitraUser::find($apiToken->posmitra_id);
        if (!$posMitra) {
            Log::warning('[FCM PosMitra] PosMitra user not found', ['posmitra_id' => $apiToken->posmitra_id]);
            return response()->json(['success' => false, 'message' => 'PosMitra user not found'], 404);
        }

        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $fcmToken = $request->fcm_token;
        $posMitra->fcm_token = $fcmToken;
        $posMitra->save();

        Log::info('[FCM PosMitra] FCM token saved', [
            'posmitra_id' => $posMitra->id,
            'fcm_token_preview' => substr($fcmToken, 0, 20) . '...',
        ]);

        return response()->json(['success' => true, 'message' => 'PosMitra FCM token updated']);
    }
}
