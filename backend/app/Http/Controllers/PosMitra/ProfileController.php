<?php

namespace App\Http\Controllers\PosMitra;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\PosMitraUser;
use App\Models\ApiToken;
use App\Enums\UserRole;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ProfileController extends Controller
{
    /**
     * Return authenticated posmitra profile
     */
    public function show(Request $request)
    {
        $user = $this->getAuthenticatedUser($request);
        if ($user instanceof \Illuminate\Http\JsonResponse) {
            return $user;
        }

        return response()->json([
            'success' => true,
            'data' => [
                'user' => $this->formatUser($user),
            ],
        ]);
    }

    /**
     * Update authenticated posmitra profile
     */
    public function update(Request $request)
    {
        $user = $this->getAuthenticatedUser($request);
        if ($user instanceof \Illuminate\Http\JsonResponse) {
            return $user;
        }

        $validator = Validator::make($request->all(), [
            'email' => 'sometimes|email|unique:users,email,' . $user->id,
            'profile_photo' => 'sometimes|image|mimes:jpg,jpeg,png|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        if ($request->filled('email')) {
            $user->email = $request->email;
        }

        if ($request->hasFile('profile_photo')) {
            $path = $request->file('profile_photo')->storeAs(
                'profile_photos',
                $user->id . '_' . time() . '.' . $request->file('profile_photo')->getClientOriginalExtension(),
                'public'
            );

            // ✅ SIMPAN PATH SAJA (TANPA /storage)
            $user->profile_photo = $path;
        }

        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Profil posmitra berhasil diperbarui',
            'data' => [
                'user' => $this->formatUser($user),
            ],
        ]);
    }

    /**
     * ================= HELPER =================
     */

    private function getAuthenticatedUser(Request $request)
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

        // Check first in PosMitraUser table based on user_type
        if ($apiToken->user_type === 'posmitra') {
            if (!$apiToken->posmitra_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Token posmitra tidak valid',
                ], 401);
            }
            
            $posMitraUser = PosMitraUser::find($apiToken->posmitra_id);
            if ($posMitraUser) {
                return $posMitraUser;
            }
        }

        // Fallback to User table for backward compatibility (using user_id)
        if ($apiToken->user_id) {
            $user = User::find($apiToken->user_id);
            if ($user && $user->role === UserRole::POSMITRA) {
                return $user;
            }
        }

        return response()->json([
            'success' => false,
            'message' => 'User tidak ditemukan atau bukan posmitra',
        ], 404);
    }

    /**
     * Format user response (AMAN untuk data lama & baru)
     */
    private function formatUser(User|PosMitraUser $user): array
    {
        $photo = null;

        if ($user->profile_photo) {
            // 🔒 Jika data lama sudah mengandung /storage
            if (str_starts_with($user->profile_photo, '/storage/')) {
                $photo = asset(ltrim($user->profile_photo, '/'));
            }
            // 🔒 Data baru (path saja)
            else {
                $photo = asset('storage/' . $user->profile_photo);
            }
        }

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'address' => $user->address ?? null,
            'gender' => $user->gender ?? null,
            'profile_photo' => $photo,
            'role' => $user instanceof PosMitraUser ? 'posmitra' : $user->role,
        ];
    }
}
