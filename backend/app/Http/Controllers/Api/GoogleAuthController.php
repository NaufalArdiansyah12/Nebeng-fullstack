<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ApiToken;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Google\Client as GoogleClient;

class GoogleAuthController extends Controller
{
    /**
     * Handle Google Sign-In / Register.
     *
     * The Flutter app sends the Google ID token obtained from google_sign_in.
     * We verify it with Google, then find-or-create the user and return an API token.
     *
     * POST /api/v1/auth/google
     * Body: { "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6..." }
     */
    public function handleGoogleAuth(Request $request)
    {
        $request->validate([
            'id_token' => 'required|string',
        ]);

        try {
            // Verify the Google ID token
            $googleClientId = config('services.google.client_id');

            $client = new GoogleClient(['client_id' => $googleClientId]);
            $payload = $client->verifyIdToken($request->id_token);

            if (!$payload) {
                return response()->json([
                    'success' => false,
                    'message' => 'Token Google tidak valid. Silakan coba lagi.',
                ], 401);
            }

            $googleId    = $payload['sub'];
            $email       = $payload['email'] ?? null;
            $name        = $payload['name'] ?? ($payload['given_name'] ?? 'User');
            $avatar      = $payload['picture'] ?? null;

            if (!$email) {
                return response()->json([
                    'success' => false,
                    'message' => 'Email tidak ditemukan pada akun Google Anda.',
                ], 422);
            }

            // Find user by google_id first, then by email
            $user = User::where('google_id', $googleId)->first()
                ?? User::where('email', $email)->first();

            if ($user) {
                // Update google_id & avatar if not set yet (first time Google login on existing account)
                $updates = [];
                if (!$user->google_id) {
                    $updates['google_id'] = $googleId;
                }
                if ($avatar && !$user->google_avatar) {
                    $updates['google_avatar'] = $avatar;
                }
                if (!empty($updates)) {
                    $user->update($updates);
                }
            } else {
                // Register new user via Google
                $user = User::create([
                    'name'          => $name,
                    'email'         => $email,
                    'google_id'     => $googleId,
                    'google_avatar' => $avatar,
                    'password'      => bcrypt(Str::random(32)), // random password, user won't use it
                    'role'          => 'customer',
                    'balance'       => 0,
                    'reward_points' => 0,
                    'phone_verified' => false,
                ]);
            }

            // Check if user is blocked
            if (isset($user->status) && $user->status === 'blocked') {
                return response()->json([
                    'success' => false,
                    'message' => 'Akun Anda telah diblokir',
                    'blocked' => true,
                    'data' => [
                        'status'     => 'blocked',
                        'reason'     => $user->blocked_reason ?? 'Tidak ada alasan yang diberikan',
                        'blocked_at' => $user->blocked_at,
                    ],
                ], 403);
            }

            // Create API token
            $token = Str::random(60);
            ApiToken::create([
                'user_type'   => 'user',
                'user_id'     => $user->id,
                'posmitra_id' => null,
                'token'       => hash('sha256', $token),
                'expires_at'  => now()->addDays(30),
            ]);

            return response()->json([
                'success' => true,
                'data' => [
                    'user' => [
                        'id'            => $user->id,
                        'name'          => $user->name,
                        'email'         => $user->email,
                        'role'          => $user->role,
                        'user_type'     => 'user',
                        'google_avatar' => $user->google_avatar,
                        'reward_points' => $user->reward_points ?? 0,
                        'average_rating'=> $user->average_rating ?? null,
                        'total_ratings' => $user->total_ratings ?? 0,
                    ],
                    'token' => $token,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan saat login dengan Google.',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }
}
