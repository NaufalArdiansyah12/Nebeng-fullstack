<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\User;

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

        return response()->json(['success' => true, 'message' => 'FCM token updated']);
    }
}
