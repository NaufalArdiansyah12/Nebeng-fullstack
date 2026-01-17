<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;

class DebugFcmController extends Controller
{
    // Temporary debug endpoint: register fcm token for a user without auth
    // POST /api/v1/debug/register-fcm
    // body: { "user_id": 1, "fcm_token": "..." }
    public function register(Request $request)
    {
        $data = $request->validate([
            'user_id' => 'required|integer|exists:users,id',
            'fcm_token' => 'required|string',
        ]);

        $user = User::find($data['user_id']);
        $user->fcm_token = $data['fcm_token'];
        $user->save();

        return response()->json(['success' => true, 'message' => 'FCM token registered for user', 'user_id' => $user->id]);
    }
}
