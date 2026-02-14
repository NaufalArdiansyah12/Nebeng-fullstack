<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ApiToken;
use App\Models\User;
use App\Models\PosMitraUser;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:8',
            'password_confirmation' => 'required|string|same:password',
        ], [
            'name.required' => 'Nama harus diisi',
            'email.required' => 'Email harus diisi',
            'email.email' => 'Format email tidak valid',
            'email.unique' => 'Email sudah terdaftar',
            'password.required' => 'Password harus diisi',
            'password.min' => 'Password minimal 8 karakter',
            'password_confirmation.required' => 'Konfirmasi password harus diisi',
            'password_confirmation.same' => 'Konfirmasi password tidak sama dengan password',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            // Create new user with default role 'customer'
            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'role' => 'customer', // default role
                'balance' => 0,
                'reward_points' => 0,
                'phone_verified' => false,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Registrasi berhasil',
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'name' => $user->name,
                        'email' => $user->email,
                        'role' => $user->role,
                    ],
                ],
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan saat registrasi',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
            'user_type' => 'sometimes|string|in:user,posmitra', // optional parameter
        ]);

        // Default ke 'user' jika tidak ada user_type
        $userType = $request->input('user_type', 'user');

        // Cari user berdasarkan tipe
        if ($userType === 'posmitra') {
            $user = PosMitraUser::where('email', $request->email)->first();
            $tableName = 'pos mitra';
        } else {
            $user = User::where('email', $request->email)->first();
            $tableName = 'user';
        }

        // Jika tidak ditemukan dan user_type default (user), coba cek di tabel posmitra_users
        if (!$user && $userType === 'user') {
            $userFromPosMitra = PosMitraUser::where('email', $request->email)->first();
            if ($userFromPosMitra) {
                $user = $userFromPosMitra;
                $userType = 'posmitra';
                $tableName = 'pos mitra';
            }
        }

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Email atau password salah',
            ], 401);
        }

        // Check if user is blocked (only for regular users, not posmitra)
        if ($userType === 'user' && isset($user->status) && $user->status === 'blocked') {
            return response()->json([
                'success' => false,
                'message' => 'Akun Anda telah diblokir',
                'blocked' => true,
                'data' => [
                    'status' => 'blocked',
                    'reason' => $user->blocked_reason ?? 'Tidak ada alasan yang diberikan',
                    'blocked_at' => $user->blocked_at,
                ]
            ], 403);
        }

        // create simple token entry with user_type
        $token = Str::random(60);
        $tokenData = [
            'user_type' => $userType,
            'token' => hash('sha256', $token),
            'expires_at' => now()->addDays(30),
        ];
        
        // Set user_id or posmitra_id based on user_type
        if ($userType === 'posmitra') {
            $tokenData['posmitra_id'] = $user->id;
            $tokenData['user_id'] = null;
        } else {
            $tokenData['user_id'] = $user->id;
            $tokenData['posmitra_id'] = null;
        }
        
        $apiToken = ApiToken::create($tokenData);

        // Format response berdasarkan user type
        $userData = [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'user_type' => $userType,
        ];

        // Add additional fields untuk regular user
        if ($userType === 'user') {
            $userData['reward_points'] = $user->reward_points ?? 0;
            $userData['average_rating'] = $user->average_rating ?? null;
            $userData['total_ratings'] = $user->total_ratings ?? 0;
            $userData['role'] = $user->role;
        } else {
            // PosMitra specific fields
            $userData['location_id'] = $user->location_id ?? null;
            $userData['role'] = 'posmitra'; // Set role untuk routing di frontend
        }

        return response()->json([
            'success' => true,
            'data' => [
                'user' => $userData,
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

    /**
     * Login specifically for PosMitra users
     * This is a convenience endpoint that automatically sets user_type to 'posmitra'
     */
    public function loginPosMitra(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = PosMitraUser::where('email', $request->email)->first();
        
        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Email atau password salah untuk Pos Mitra',
            ], 401);
        }

        // create token entry for posmitra
        $token = Str::random(60);
        $apiToken = ApiToken::create([
            'posmitra_id' => $user->id,
            'user_id' => null,
            'user_type' => 'posmitra',
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
                    'user_type' => 'posmitra',
                    'role' => 'posmitra', // Untuk routing di frontend
                    'location_id' => $user->location_id ?? null,
                    'balance' => $user->balance ?? 0,
                ],
                'token' => $token,
            ],
        ]);
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
     * Update user profile (name, email, address, phone, profile photo)
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
        $input = $request->only(['name', 'email', 'address', 'phone']);
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

        // Get user berdasarkan user_type
        if ($apiToken->user_type === 'posmitra') {
            $user = PosMitraUser::find($apiToken->user_id);
            $userType = 'posmitra';
        } else {
            $user = User::find($apiToken->user_id);
            $userType = 'user';
        }

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        // Build user data berdasarkan tipe
        $userData = [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'profile_photo' => $user->profile_photo,
            'user_type' => $userType,
        ];

        // Add fields spesifik untuk regular user
        if ($userType === 'user') {
            $userData['address'] = $user->address;
            $userData['average_rating'] = $user->average_rating ?? null;
            $userData['total_ratings'] = $user->total_ratings ?? 0;
            $userData['role'] = $user->role;
            $userData['reward_points'] = $user->reward_points ?? 0;
            $userData['balance'] = $user->balance ?? 0;
        } else {
            // Add fields spesifik untuk posmitra
            $userData['location_id'] = $user->location_id ?? null;
            $userData['balance'] = $user->balance ?? 0;
            $userData['role'] = 'posmitra'; // Set role untuk frontend
        }

        return response()->json([
            'success' => true,
            'data' => [
                'user' => $userData,
            ],
        ]);
    }
}
