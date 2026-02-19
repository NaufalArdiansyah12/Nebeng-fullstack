<?php

namespace App\Http\Controllers\PosMitra;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\PosMitraUser;
use App\Models\ApiToken;
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
        if ($user instanceof \Illuminate\Http\JsonResponse) return $user;

        $user->load('location');

        return response()->json([
            'success' => true,
            'data' => [
                'user' => $this->mapUser($user),
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
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:pos_mitra_users,email,' . $user->id,
            'phone' => 'sometimes|string|max:20',
            'profile_photo' => 'sometimes|image|mimes:jpg,jpeg,png|max:5120',
            'bank_name' => 'sometimes|string|max:255',
            'bank_account_number' => 'sometimes|string|max:255',
            'bank_account_name' => 'sometimes|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        if ($request->filled('name')) {
            $user->name = $request->name;
        }

        if ($request->filled('email')) {
            $user->email = $request->email;
        }

        if ($request->filled('phone')) {
            $user->phone = $request->phone;
        }

        if ($request->filled('bank_name')) {
            $user->bank_name = $request->bank_name;
        }

        if ($request->filled('bank_account_number')) {
            $user->bank_account_number = $request->bank_account_number;
        }

        if ($request->filled('bank_account_name')) {
            $user->bank_account_name = $request->bank_account_name;
        }

        if ($request->hasFile('profile_photo')) {
            $file = $request->file('profile_photo');
            $path = $file->storeAs(
                'profile_photos',
                'posmitra_' . $user->id . '_' . time() . '.' . $file->getClientOriginalExtension(),
                'public'
            );
            $user->profile_photo = $path; // simpan path saja
        }

        $user->save();
        $user->load('location');

        return response()->json([
            'success' => true,
            'message' => 'Profil posmitra berhasil diperbarui',
            'data' => [
                'user' => $this->mapUser($user),
            ],
        ]);
    }

    /**
     * ================= HELPER =================
     */

    /**
     * Get authenticated user from bearer token
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

        if (!$apiToken || $apiToken->user_type !== 'posmitra') {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak valid atau bukan posmitra',
            ], 401);
        }

        $user = PosMitraUser::find($apiToken->posmitra_id);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User posmitra tidak ditemukan',
            ], 404);
        }

        return $user;
    }


    /**
     * Mapping user data agar konsisten
     */
    private function mapUser($user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email ?? null,
            'phone' => $user->phone ?? null,
            'profile_photo' => $user->profile_photo
                ? asset('storage/' . ltrim(str_replace('/storage/', '', $user->profile_photo), '/'))
                : null,
            'balance' => (float) ($user->balance ?? 0),
            'bank_name' => $user->bank_name ?? null,
            'bank_account_number' => $user->bank_account_number ?? null,
            'bank_account_name' => $user->bank_account_name ?? null,
            'location_id' => $user->location_id ?? null,
            'location' => $user->location ? [
                'id' => $user->location->id,
                'name' => $user->location->name,
                'city' => $user->location->city ?? null,
                'address' => $user->location->address ?? null,
                'latitude' => $user->location->latitude ?? null,
                'longitude' => $user->location->longitude ?? null,
            ] : null,
            'role' => 'posmitra',
        ];
    }
}