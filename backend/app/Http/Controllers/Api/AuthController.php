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
    // =================== REGISTER ===================
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:8',
            'password_confirmation' => 'required|string|same:password',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => 'customer',
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
    }

    // =================== LOGIN ===================
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
            'user_type' => 'sometimes|string|in:user,posmitra',
        ]);

        $userType = $request->input('user_type', 'user');

        // ambil user berdasarkan user_type
        $user = $this->getUserByType($request->email, $userType);

        // fallback: cek posmitra jika default user gagal
        if (!$user && $userType === 'user') {
            $user = $this->getUserByType($request->email, 'posmitra');
            $userType = 'posmitra';
        }

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Email atau password salah',
            ], 401);
        }

        $token = Str::random(60);
ApiToken::create([
    'user_id'     => $userType === 'user' ? $user->id : null,
    'posmitra_id' => $userType === 'posmitra' ? $user->id : null,
    'user_type'   => $userType,
    'token'       => hash('sha256', $token),
    'expires_at'  => now()->addDays(30),
]);


        $userData = $this->formatUserData($user, $userType);

        return response()->json([
            'success' => true,
            'data' => [
                'user' => $userData,
                'token' => $token,
            ],
        ]);
    }

    // =================== LOGOUT ===================
    public function logout(Request $request)
    {
        $bearer = $request->bearerToken();
        if (!$bearer) return response()->json(['success' => false, 'message' => 'No token provided'], 400);

        ApiToken::where('token', hash('sha256', $bearer))->delete();

        return response()->json(['success' => true]);
    }

    // =================== LOGIN POSMITRA ===================
public function loginPosMitra(Request $request)
{
    $request->validate([
        'email' => 'required|email',
        'password' => 'required|string',
    ]);

    $userType = 'posmitra'; // ✅ WAJIB ADA

    $user = $this->getUserByType($request->email, $userType);

    if (!$user || !Hash::check($request->password, $user->password)) {
        return response()->json([
            'success' => false,
            'message' => 'Email atau password salah untuk Pos Mitra',
        ], 401);
    }

    $token = Str::random(60);

    ApiToken::create([
        'user_id'     => null,
        'posmitra_id' => $user->id, // ✅ FIX
        'user_type'   => 'posmitra',
        'token'       => hash('sha256', $token),
        'expires_at'  => now()->addDays(30),
    ]);

    return response()->json([
        'success' => true,
        'data' => [
            'user' => $this->formatUserData($user, 'posmitra'),
            'token' => $token,
        ],
    ]);
}


    // =================== CHANGE PASSWORD ===================
    public function changePassword(Request $request)
    {
        $request->validate([
            'old_password' => 'required|string',
            'new_password' => 'required|string|min:6',
            'new_password_confirmation' => 'required|string|same:new_password',
        ]);

        $user = $this->getUserFromToken($request->bearerToken());
        if (!$user) return response()->json(['success' => false, 'message' => 'Token tidak valid atau user tidak ditemukan'], 401);

        if (!Hash::check($request->old_password, $user->password)) {
            return response()->json(['success' => false, 'message' => 'Kata sandi lama tidak sesuai'], 400);
        }

        $user->password = Hash::make($request->new_password);
        $user->save();

        return response()->json(['success' => true, 'message' => 'Kata sandi berhasil diubah']);
    }

    // =================== UPDATE PROFILE ===================
    public function updateProfile(Request $request)
    {
        $user = $this->getUserFromToken($request->bearerToken());
        if (!$user) return response()->json(['success' => false, 'message' => 'Token tidak valid atau user tidak ditemukan'], 401);

        $rules = [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email',
            'address' => 'sometimes|string|nullable',
            'phone' => 'sometimes|string|nullable',
            'profile_photo' => 'sometimes|file|mimes:jpg,jpeg,png|max:5120',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) return response()->json(['success' => false, 'message' => 'Validasi gagal', 'errors' => $validator->errors()], 422);

        $input = $request->only(['name', 'email', 'address', 'phone']);
        foreach ($input as $key => $val) if ($val !== null) $user->{$key} = $val;

        if ($request->hasFile('profile_photo')) {
            $file = $request->file('profile_photo');
            $filename = 'profile_photos/' . $user->id . '_' . time() . '.' . $file->getClientOriginalExtension();
            Storage::disk('public')->put($filename, file_get_contents($file));
            $user->profile_photo = Storage::url($filename);
        }

        $user->save();

        return response()->json(['success' => true, 'message' => 'Profil berhasil diperbarui', 'data' => ['user' => $this->formatUserData($user, $this->getUserType($user))]]);
    }

    // =================== GET PROFILE ===================
    public function me(Request $request)
    {
        $user = $this->getUserFromToken($request->bearerToken());
        if (!$user) return response()->json(['success' => false, 'message' => 'Token tidak valid atau user tidak ditemukan'], 401);

        $userType = $this->getUserType($user);

        return response()->json(['success' => true, 'data' => ['user' => $this->formatUserData($user, $userType)]]);
    }

    // =================== HELPER FUNCTIONS ===================

    private function getUserByType($email, $type)
    {
        if ($type === 'posmitra') {
            return PosMitraUser::where('email', $email)->first();
        }
        return User::where('email', $email)->first();
    }

private function getUserFromToken($bearer)
{
    if (!$bearer) return null;

    $hashed = hash('sha256', $bearer);

    $apiToken = ApiToken::where('token', $hashed)
        ->where('expires_at', '>', now())
        ->first();

    if (!$apiToken) return null;

    if ($apiToken->user_type === 'posmitra') {
        return PosMitraUser::find($apiToken->posmitra_id);
    }

    return User::find($apiToken->user_id);
}


    private function getUserType($user)
    {
        if ($user instanceof PosMitraUser) return 'posmitra';
        return 'user';
    }

    private function formatUserData($user, $userType)
    {
        $data = [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'user_type' => $userType,
            'role' => $userType === 'posmitra' ? 'posmitra' : $user->role,
        ];

        if ($userType === 'user') {
            $data['address'] = $user->address ?? null;
            $data['reward_points'] = $user->reward_points ?? 0;
            $data['average_rating'] = $user->average_rating ?? null;
            $data['total_ratings'] = $user->total_ratings ?? 0;
            $data['balance'] = $user->balance ?? 0;
        } else {
            $data['location_id'] = $user->location_id ?? null;
            $data['balance'] = $user->balance ?? 0;
        }

        return $data;
    }
}
