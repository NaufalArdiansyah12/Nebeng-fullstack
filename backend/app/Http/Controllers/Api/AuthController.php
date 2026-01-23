<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ApiToken;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();
        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Email atau password salah',
            ], 401);
        }

        // create simple token entry
        $token = Str::random(60);
        $apiToken = ApiToken::create([
            'user_id' => $user->id,
            'token' => hash('sha256', $token),
            'expires_at' => now()->addDays(30),
        ]);

        return response()->json([
            'success' => true,
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'reward_points' => $user->reward_points ?? 0,
                    'role' => $user->role,
                ],
                'token' => $token,
            ],
        ]);
    }

    public function logout(Request $request)
    {
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json(['success' => false, 'message' => 'No token provided'], 400);
        }
        $hashed = hash('sha256', $bearer);
        ApiToken::where('token', $hashed)->delete();
        return response()->json(['success' => true]);
    }

    public function changePassword(Request $request)
    {
        $request->validate([
            'old_password' => 'required|string',
            'new_password' => 'required|string|min:6',
            'new_password_confirmation' => 'required|string|same:new_password',
        ]);

        // Get authenticated user from bearer token
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak ditemukan',
            ], 401);
        }

        $hashed = hash('sha256', $bearer);
        $apiToken = ApiToken::where('token', $hashed)
            ->where('expires_at', '>', now())
            ->first();

        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak valid atau sudah kadaluarsa',
            ], 401);
        }

        $user = User::find($apiToken->user_id);
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        // Verify old password
        if (!Hash::check($request->old_password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Kata sandi lama tidak sesuai',
            ], 400);
        }

        // Update password
        $user->password = Hash::make($request->new_password);
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Kata sandi berhasil diubah',
        ]);
    }

    /**
     * Update user profile (name, email, address, phone, gender, profile photo)
     */
    public function updateProfile(Request $request)
    {
        // Get authenticated user from bearer token
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak ditemukan',
            ], 401);
        }

        $hashed = hash('sha256', $bearer);
        $apiToken = ApiToken::where('token', $hashed)
            ->where('expires_at', '>', now())
            ->first();

        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak valid atau sudah kadaluarsa',
            ], 401);
        }

        $user = User::find($apiToken->user_id);
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        $rules = [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email',
            'address' => 'sometimes|string|nullable',
            'phone' => 'sometimes|string|nullable',
            'gender' => 'sometimes|string|nullable',
            'profile_photo' => 'sometimes|file|mimes:jpg,jpeg,png|max:5120',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Update fields
        $input = $request->only(['name', 'email', 'address', 'phone', 'gender']);
        foreach ($input as $key => $val) {
            if ($val !== null) {
                $user->{$key} = $val;
            }
        }

        // Handle photo upload if provided
        if ($request->hasFile('profile_photo')) {
            $file = $request->file('profile_photo');
            $filename = 'profile_photos/' . $user->id . '_' . time() . '.' . $file->getClientOriginalExtension();
            Storage::disk('public')->put($filename, file_get_contents($file));
            $user->profile_photo = Storage::url($filename);
        }

        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Profil berhasil diperbarui',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'address' => $user->address,
                    'phone' => $user->phone,
                    'gender' => $user->gender,
                    'profile_photo' => $user->profile_photo,
                    'reward_points' => $user->reward_points ?? 0,
                ],
            ],
        ]);
    }

    /**
     * Return authenticated user profile (via bearer token)
     */
    public function me(Request $request)
    {
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak ditemukan',
            ], 401);
        }

        $hashed = hash('sha256', $bearer);
        $apiToken = ApiToken::where('token', $hashed)
            ->where('expires_at', '>', now())
            ->first();

        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak valid atau sudah kadaluarsa',
            ], 401);
        }

        $user = User::find($apiToken->user_id);
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'address' => $user->address,
                    'phone' => $user->phone,
                    'gender' => $user->gender,
                    'profile_photo' => $user->profile_photo,
                    'role' => $user->role,
                    'reward_points' => $user->reward_points ?? 0,
                ],
            ],
        ]);
    }
}
