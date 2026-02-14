<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

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

            if ($user->role !== 'finance') {
                return response()->json([
                    'message' => 'akses ditolak, hanya untuk akun finance'
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
       FORGOT PASSWORD - SEND OTP
    ========================= */
    public function forgotPassword(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'email' => 'required|email',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation error',
                    'errors' => $validator->errors()
                ], 422);
            }

            $user = DB::table('users')
                ->where('email', $request->email)
                ->where('role', 'finance')
                ->first();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Email tidak ditemukan atau bukan akun finance'
                ], 404);
            }

            // Generate 6 digit OTP
            $otp = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

            // Delete old OTP if exists
            DB::table('password_reset_tokens')
                ->where('email', $request->email)
                ->delete();

            // Save OTP to database
            DB::table('password_reset_tokens')->insert([
                'email' => $request->email,
                'token' => $otp,
                'created_at' => now()
            ]);

            // Send email (for now just log it, you can implement actual email later)
            Log::info("OTP for {$request->email}: {$otp}");

            // In production, send actual email:
            // Mail::to($request->email)->send(new ResetPasswordOTP($otp));

            return response()->json([
                'success' => true,
                'message' => 'OTP telah dikirim ke email Anda',
                'otp' => config('app.debug') ? $otp : null // Only show OTP in debug mode
            ]);

        } catch (\Exception $e) {
            Log::error('Forgot password error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengirim OTP',
                'error' => config('app.debug') ? $e->getMessage() : null
            ], 500);
        }
    }

    /* =========================
       VERIFY OTP
    ========================= */
    public function verifyOtp(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'email' => 'required|email',
                'otp' => 'required|string|size:6',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation error',
                    'errors' => $validator->errors()
                ], 422);
            }

            $resetToken = DB::table('password_reset_tokens')
                ->where('email', $request->email)
                ->where('token', $request->otp)
                ->first();

            if (!$resetToken) {
                return response()->json([
                    'success' => false,
                    'message' => 'OTP tidak valid'
                ], 400);
            }

            // Check if OTP is expired (15 minutes)
            $createdAt = \Carbon\Carbon::parse($resetToken->created_at);
            $expiresAt = $createdAt->addMinutes(15);

            if (now()->greaterThan($expiresAt)) {
                DB::table('password_reset_tokens')
                    ->where('email', $request->email)
                    ->delete();

                return response()->json([
                    'success' => false,
                    'message' => 'OTP sudah kadaluarsa, silakan request OTP baru'
                ], 400);
            }

            return response()->json([
                'success' => true,
                'message' => 'OTP valid'
            ]);

        } catch (\Exception $e) {
            Log::error('Verify OTP error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal verifikasi OTP',
                'error' => config('app.debug') ? $e->getMessage() : null
            ], 500);
        }
    }

    /* =========================
       RESET PASSWORD
    ========================= */
    public function resetPassword(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'email' => 'required|email',
                'otp' => 'required|string|size:6',
                'password' => 'required|string|min:6|confirmed',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation error',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Verify OTP again
            $resetToken = DB::table('password_reset_tokens')
                ->where('email', $request->email)
                ->where('token', $request->otp)
                ->first();

            if (!$resetToken) {
                return response()->json([
                    'success' => false,
                    'message' => 'OTP tidak valid'
                ], 400);
            }

            // Check if OTP is expired
            $createdAt = \Carbon\Carbon::parse($resetToken->created_at);
            $expiresAt = $createdAt->addMinutes(15);

            if (now()->greaterThan($expiresAt)) {
                DB::table('password_reset_tokens')
                    ->where('email', $request->email)
                    ->delete();

                return response()->json([
                    'success' => false,
                    'message' => 'OTP sudah kadaluarsa'
                ], 400);
            }

            // Update password
            DB::table('users')
                ->where('email', $request->email)
                ->update([
                    'password' => Hash::make($request->password),
                    'updated_at' => now()
                ]);

            // Delete OTP
            DB::table('password_reset_tokens')
                ->where('email', $request->email)
                ->delete();

            return response()->json([
                'success' => true,
                'message' => 'Password berhasil direset'
            ]);

        } catch (\Exception $e) {
            Log::error('Reset password error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal reset password',
                'error' => config('app.debug') ? $e->getMessage() : null
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

    /* =========================
       GET MITRA DETAIL
    ========================= */
    public function getMitraDetail($id)
    {
        // Get user basic info
        $user = DB::table('users')
            ->select('id', 'name', 'email', 'phone', 'profile_photo', 'address')
            ->where('id', $id)
            ->where('role', 'mitra')
            ->first();

        if (!$user) {
            return response()->json([
                'message' => 'mitra tidak ditemukan'
            ], 404);
        }

        // Get KTP data
        $ktp = DB::table('verifikasi_ktp_mitras')
            ->select(
                'nama_lengkap',
                'nik',
                'tanggal_lahir',
                'jenis_kelamin',
                'alamat',
                'photo_ktp'
            )
            ->where('mitra_id', $id)
            ->first();

        // Get SIM data
        $sim = DB::table('verifikasi_sim_mitras')
            ->select(
                'nama_lengkap',
                'sim_number as nomor_sim',
                'sim_type',
                'sim_expiry_date',
                'sim_photo'
            )
            ->where('user_id', $id)
            ->first();

        // Get vehicle data to determine service type
        $vehicle = DB::table('kendaraan_mitra')
            ->select('vehicle_type')
            ->where('user_id', $id)
            ->where('is_active', 1)
            ->first();

        $serviceType = $vehicle ? ($vehicle->vehicle_type === 'motor' ? 'Nebeng Motor' : 'Nebeng Mobil') : 'Nebeng Motor';

        return response()->json([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'profile_photo' => $user->profile_photo,
            'service_type' => $serviceType,
            'pribadi' => [
                'nama_lengkap' => $user->name,
                'email' => $user->email,
                'tempat_lahir' => $ktp ? ($ktp->alamat ?: $user->address) : $user->address,
                'tanggal_lahir' => $ktp ? $ktp->tanggal_lahir : null,
                'jenis_kelamin' => $ktp ? $ktp->jenis_kelamin : null,
                'no_telepon' => $user->phone,
            ],
            'ktp' => $ktp ? [
                'nama_lengkap' => $ktp->nama_lengkap,
                'nik' => $ktp->nik,
                'tanggal_lahir' => $ktp->tanggal_lahir,
                'jenis_kelamin' => $ktp->jenis_kelamin,
                'photo_ktp' => $ktp->photo_ktp ? '/storage/' . $ktp->photo_ktp : null,
            ] : null,
            'sim' => $sim ? [
                'nama_lengkap' => $sim->nama_lengkap,
                'nomor_sim' => $sim->nomor_sim,
                'sim_type' => $sim->sim_type,
                'sim_expiry_date' => $sim->sim_expiry_date,
                'sim_photo' => $sim->sim_photo ? '/storage/' . $sim->sim_photo : null,
            ] : null,
        ]);
    }

    /* =========================
       GET POS MITRA USERS
    ========================= */
    public function getPosMitraUsers()
    {
        $posMitra = DB::table('posmitra_users as pm')
            ->leftJoin('locations as loc', 'pm.location_id', '=', 'loc.id')
            ->select(
                'pm.id',
                'pm.name as nama',
                'pm.email',
                'pm.phone',
                'loc.name as terminal',
                'loc.address as alamat_terminal',
                DB::raw('CONCAT("POS", LPAD(pm.id, 4, "0")) as kode_referral')
            )
            ->orderBy('pm.name')
            ->get();

        return response()->json($posMitra);
    }

    /* =========================
       GET POS MITRA DETAIL
    ========================= */
    public function getPosMitraDetail($id)
    {
        $posMitra = DB::table('posmitra_users as pm')
            ->leftJoin('locations as loc', 'pm.location_id', '=', 'loc.id')
            ->select(
                'pm.id',
                'pm.name',
                'pm.email',
                'pm.phone',
                'pm.profile_photo',
                'pm.balance',
                'loc.id as location_id',
                'loc.name as terminal',
                'loc.address as alamat_terminal',
                DB::raw('CONCAT("POS", LPAD(pm.id, 4, "0")) as kode_referral')
            )
            ->where('pm.id', $id)
            ->first();

        if (!$posMitra) {
            return response()->json(['message' => 'Pos Mitra tidak ditemukan'], 404);
        }

        // Get KTP verification data
        $ktp = DB::table('verifikasi_ktp_posmitra')
            ->select(
                'nama_lengkap',
                'nik',
                'tanggal_lahir',
                'jenis_kelamin',
                'photo_ktp'
            )
            ->where('posmitra_id', $id)
            ->first();

        return response()->json([
            'id' => $posMitra->id,
            'name' => $posMitra->name,
            'email' => $posMitra->email,
            'phone' => $posMitra->phone,
            'profile_photo' => $posMitra->profile_photo,
            'balance' => $posMitra->balance,
            'location' => [
                'id' => $posMitra->location_id,
                'terminal' => $posMitra->terminal,
                'address' => $posMitra->alamat_terminal,
                'code' => $posMitra->kode_referral,
            ],
            'ktp' => $ktp ? [
                'nama_lengkap' => $ktp->nama_lengkap,
                'nik' => $ktp->nik,
                'tanggal_lahir' => $ktp->tanggal_lahir,
                'jenis_kelamin' => $ktp->jenis_kelamin,
                'photo_ktp' => $ktp->photo_ktp ? '/storage/' . $ktp->photo_ktp : null,
            ] : null,
        ]);
    }

    /**
     * Upload profile image
     */
    public function uploadProfileImage(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'profile_image' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $user = DB::table('users')->where('id', $id)->first();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not found'
                ], 404);
            }

            // Delete old image if exists
            if ($user->profile_photo) {
                Storage::disk('public')->delete($user->profile_photo);
            }

            // Store new image
            $path = $request->file('profile_image')->store('profile-images', 'public');

            DB::table('users')->where('id', $id)->update([
                'profile_photo' => $path,
                'updated_at' => now()
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Profile image uploaded successfully',
                'image_url' => Storage::url($path),
                'profile_photo' => $path
            ]);
        } catch (\Exception $e) {
            Log::error('Error uploading profile image: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to upload image: ' . $e->getMessage()
            ], 500);
        }
    }
}
