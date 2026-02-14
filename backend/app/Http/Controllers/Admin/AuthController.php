<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\ApiToken;
use App\Enums\UserRole;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;

class AuthController extends Controller
{
    /**
     * Login admin
     * POST /api/admin/auth/login
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }

        // Cari user dengan role admin
        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Email tidak ditemukan'
            ], 401);
        }

        // Cek apakah role adalah admin atau superadmin
        if ($user->role !== UserRole::ADMIN && $user->role !== UserRole::SUPERADMIN) {
            return response()->json([
                'success' => false,
                'message' => 'Anda bukan admin'
            ], 401);
        }

        // Verifikasi password
        if (!Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Password salah'
            ], 401);
        }

        // Generate token dan simpan di api_tokens table
        $token = Str::random(60);
        
        // Hapus token lama jika ada
        ApiToken::where('user_id', $user->id)->delete();
        
        // Buat token baru
        ApiToken::create([
            'user_id' => $user->id,
            'token' => $token,
            'expires_at' => now()->addDays(30), // Token valid 30 hari
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
            ]
        ], 200);
    }

    /**
     * Logout admin
     * POST /api/admin/auth/logout
     */
    public function logout(Request $request)
    {
        $user = $request->user;
        
        // Hapus token dari api_tokens table
        if ($user) {
            ApiToken::where('user_id', $user->id)->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil'
        ], 200);
    }

    /**
     * Verify token
     * GET /api/admin/auth/verify
     */
    public function verify(Request $request)
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak valid'
            ], 401);
        }

        // Cek apakah role adalah admin atau superadmin
        if ($user->role !== UserRole::ADMIN && $user->role !== UserRole::SUPERADMIN) {
            return response()->json([
                'success' => false,
                'message' => 'User bukan admin'
            ], 401);
        }

        return response()->json([
            'success' => true,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role->value,
            ]
        ], 200);
    }

    /**
     * Get admin profile
     * GET /api/admin/auth/profile
     */
    public function profile(Request $request)
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 401);
        }

        // Cek apakah role adalah admin atau superadmin
        if ($user->role !== UserRole::ADMIN && $user->role !== UserRole::SUPERADMIN) {
            return response()->json([
                'success' => false,
                'message' => 'User bukan admin'
            ], 401);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $user->id,
                'namaLengkap' => $user->name,
                'nama_lengkap' => $user->name,
                'email' => $user->email,
                'role' => $user->role->value,
                'foto' => $user->profile_photo ? url('storage/' . $user->profile_photo) : null,
                'noTlp' => $user->phone ?? '',
                'no_tlp' => $user->phone ?? '',
                'layanan' => 'Nebeng',
                'tempatLahir' => '',
                'tempat_lahir' => '',
                'tanggalLahir' => '',
                'tanggal_lahir' => '',
                'jenisKelamin' => '',
                'jenis_kelamin' => '',
            ]
        ], 200);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 401);
        }

        // Cek apakah role adalah admin atau superadmin
        if ($user->role !== UserRole::ADMIN && $user->role !== UserRole::SUPERADMIN) {
            return response()->json([
                'success' => false,
                'message' => 'User bukan admin'
            ], 401);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'namaLengkap' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,' . $user->id,
            'phone' => 'sometimes|string|max:20',
            'noTlp' => 'sometimes|string|max:20',
            'foto' => 'sometimes|string', // base64 image
            'password' => 'sometimes|string|min:6',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }

        // Update data
        if ($request->has('name') || $request->has('namaLengkap')) {
            $user->name = $request->input('name') ?? $request->input('namaLengkap');
        }

        if ($request->has('email')) {
            $user->email = $request->email;
        }

        if ($request->has('phone') || $request->has('noTlp')) {
            $user->phone = $request->input('phone') ?? $request->input('noTlp');
        }

        if ($request->has('foto')) {
            // Handle base64 image upload
            $foto = $request->foto;
            if (strpos($foto, 'data:image') === 0) {
                // Save base64 image
                $image = str_replace('data:image/png;base64,', '', $foto);
                $image = str_replace('data:image/jpg;base64,', '', $image);
                $image = str_replace('data:image/jpeg;base64,', '', $image);
                $image = str_replace(' ', '+', $image);
                
                $imageName = 'admin_' . time() . '.png';
                Storage::disk('public')->put('profiles/' . $imageName, base64_decode($image));
                
                $user->profile_photo = 'profiles/' . $imageName;
            }
        }

        if ($request->has('password')) {
            $user->password = Hash::make($request->password);
        }

        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Profile berhasil diupdate',
            'data' => [
                'id' => $user->id,
                'namaLengkap' => $user->name,
                'email' => $user->email,
                'role' => $user->role->value,
                'foto' => $user->profile_photo ? url('storage/' . $user->profile_photo) : null,
                'noTlp' => $user->phone ?? '',
            ]
        ], 200);
    }
}
