<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class UserController extends Controller
{
    /* =========================
       USER COUNT BY ROLE
    ========================= */
    public function countByRole()
    {
        $rows = DB::table('users')
            ->select('role', DB::raw('COUNT(*) as total'))
            ->groupBy('role')
            ->get();

        $data = [
            'mitra' => 0,
            'customer' => 0,
        ];

        foreach ($rows as $row) {
            if ($row->role === 'mitra') $data['mitra'] = $row->total;
            if ($row->role === 'customer') $data['customer'] = $row->total;
        }

        return response()->json($data);
    }

    /* =========================
       GET MITRA USERS
    ========================= */
    public function getMitraUsers()
    {
        $mitra = DB::table('users')
            ->select(
                'id',
                'name as nama',
                'email',
                'phone as telp'
            )
            ->where('role', 'mitra')
            ->orderBy('name')
            ->get();

        return response()->json($mitra);
    }

    /* =========================
       LOGIN ADMIN
    ========================= */
    public function login(Request $request)
    {
        try {
            // Validasi input
            $request->validate([
                'email' => 'required|email',
                'password' => 'required',
            ]);

            // Cek koneksi database
            try {
                $user = DB::table('users')
                    ->where('email', $request->email)
                    ->first();
            } catch (\Exception $dbError) {
                Log::error('Database error: ' . $dbError->getMessage());
                return response()->json([
                    'message' => 'Gagal terhubung ke database',
                    'error' => config('app.debug') ? $dbError->getMessage() : 'Database connection error'
                ], 500);
            }

            if (!$user) {
                return response()->json([
                    'message' => 'email tidak ditemukan'
                ], 401);
            }

            if ($user->role !== 'admin') {
                return response()->json([
                    'message' => 'akses ditolak, hanya admin'
                ], 403);
            }

            // Verifikasi password menggunakan password_verify (kompatibel dengan bcryptjs)
            $passwordHash = $user->password ?? '';
            
            // Pastikan password hash tidak kosong
            if (empty($passwordHash)) {
                return response()->json([
                    'message' => 'password tidak valid'
                ], 401);
            }
            
            // Hanya gunakan password_verify (tidak gunakan Hash::check karena error dengan format bcryptjs)
            try {
                $passwordValid = password_verify($request->password, $passwordHash);
            } catch (\Exception $pwdError) {
                Log::error('Password verify error: ' . $pwdError->getMessage());
                return response()->json([
                    'message' => 'Gagal verifikasi password',
                    'error' => config('app.debug') ? $pwdError->getMessage() : 'Password verification error'
                ], 500);
            }
            
            if (!$passwordValid) {
                return response()->json([
                    'message' => 'password salah'
                ], 401);
            }

            return response()->json([
                'message' => 'login finance berhasil',
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                ]
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validasi gagal',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            Log::error('Login error: ' . $e->getMessage(), [
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return response()->json([
                'message' => 'Terjadi kesalahan pada server',
                'error' => config('app.debug') ? $e->getMessage() . ' (Line: ' . $e->getLine() . ')' : 'Internal server error'
            ], 500);
        }
    }

    /* =========================
       GET USER BY ID
    ========================= */
    public function getById($id)
    {
        $user = DB::table('users')
            ->select('id', 'name', 'email', 'role')
            ->where('id', $id)
            ->first();

        if (!$user) {
            return response()->json([
                'message' => 'user tidak ditemukan'
            ], 404);
        }

        return response()->json($user);
    }

    /* =========================
       GET USER PROFILE
    ========================= */
    public function profile($id)
    {
        $user = DB::table('users')
            ->select(
                'id',
                'name',
                'email',
                'role',
                'address',
                'phone',
                'gender',
                'profile_photo',
                'created_at'
            )
            ->where('id', $id)
            ->first();

        if (!$user) {
            return response()->json([
                'message' => 'user tidak ditemukan'
            ], 404);
        }

        return response()->json($user);
    }

    /* =========================
       UPDATE PROFILE
    ========================= */
    public function updateProfile(Request $request, $id)
    {
        $exists = DB::table('users')->where('id', $id)->exists();

        if (!$exists) {
            return response()->json([
                'message' => 'user tidak ditemukan'
            ], 404);
        }

        DB::table('users')
            ->where('id', $id)
            ->update([
                'name' => $request->name,
                'phone' => $request->phone,
                'gender' => $request->gender,
                'address' => $request->address,
                'updated_at' => now(),
            ]);

        return response()->json([
            'message' => 'profile berhasil diperbarui'
        ]);
    }

    /* =========================
       UPDATE ACCOUNT
    ========================= */
    public function updateAccount(Request $request, $id)
    {
        if (!$request->email && !$request->password) {
            return response()->json([
                'message' => 'tidak ada data yang diubah'
            ], 400);
        }

        $data = [];

        if ($request->email) {
            $exists = DB::table('users')
                ->where('email', $request->email)
                ->where('id', '!=', $id)
                ->exists();

            if ($exists) {
                return response()->json([
                    'message' => 'email sudah digunakan'
                ], 409);
            }

            $data['email'] = $request->email;
        }

        if ($request->password) {
            $data['password'] = Hash::make($request->password);
        }

        $data['updated_at'] = now();

        DB::table('users')
            ->where('id', $id)
            ->update($data);

        return response()->json([
            'message' => 'akun berhasil diperbarui'
        ]);
    }
}
