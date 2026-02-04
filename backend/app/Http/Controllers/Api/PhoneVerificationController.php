<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PhoneOtp;
use App\Models\User;
use App\Models\ApiToken;
use App\Mail\PhoneVerificationOtp;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class PhoneVerificationController extends Controller
{
    /**
     * Get user dari Bearer token (custom ApiToken)
     */
    private function getUserFromToken(Request $request)
    {
        $authHeader = $request->header('Authorization');
        if (!$authHeader || !str_starts_with($authHeader, 'Bearer ')) {
            return null;
        }

        $rawToken = substr($authHeader, 7);
        $hashedToken = hash('sha256', $rawToken);

        $apiToken = ApiToken::where('token', $hashedToken)
            ->where('expires_at', '>', now())
            ->first();

        if (!$apiToken) {
            return null;
        }

        return User::find($apiToken->user_id);
    }

    /**
     * Kirim OTP ke email user untuk verifikasi nomor HP
     */
    public function sendOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone' => 'required|string|min:10|max:15|regex:/^[0-9+\-\s]+$/',
        ], [
            'phone.required' => 'Nomor HP wajib diisi',
            'phone.min' => 'Nomor HP minimal 10 digit',
            'phone.max' => 'Nomor HP maksimal 15 digit',
            'phone.regex' => 'Format nomor HP tidak valid',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
            ], 422);
        }

        try {
            $user = $this->getUserFromToken($request);
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized. Token tidak valid atau sudah kadaluarsa.',
                ], 401);
            }

            $phone = $request->phone;

            // Cek apakah nomor HP sudah digunakan user lain yang sudah terverifikasi
            $existingUser = User::where('phone', $phone)
                ->where('phone_verified', true)
                ->where('id', '!=', $user->id)
                ->first();

            if ($existingUser) {
                return response()->json([
                    'success' => false,
                    'message' => 'Nomor HP ini sudah terdaftar dan terverifikasi oleh pengguna lain',
                ], 422);
            }

            // Rate limiting: Cek apakah user sudah request OTP dalam 1 menit terakhir
            $recentOtp = PhoneOtp::where('user_id', $user->id)
                ->where('created_at', '>', Carbon::now()->subMinute())
                ->first();

            if ($recentOtp) {
                $secondsRemaining = 60 - Carbon::now()->diffInSeconds($recentOtp->created_at);
                return response()->json([
                    'success' => false,
                    'message' => "Mohon tunggu {$secondsRemaining} detik sebelum meminta kode baru",
                ], 429);
            }

            // Generate 6 digit OTP
            $otpCode = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

            // Invalidate semua OTP lama yang belum digunakan untuk user ini
            PhoneOtp::where('user_id', $user->id)
                ->where('is_used', false)
                ->update(['is_used' => true]);

            // Create OTP baru
            $phoneOtp = PhoneOtp::create([
                'user_id' => $user->id,
                'phone' => $phone,
                'otp_code' => bcrypt($otpCode), // Hash OTP untuk keamanan
                'expires_at' => Carbon::now()->addMinutes(10),
                'attempts' => 0,
                'is_used' => false,
            ]);

            // Kirim email dengan OTP
            Mail::to($user->email)->send(new PhoneVerificationOtp(
                $otpCode,
                $user->name,
                $phone
            ));

            return response()->json([
                'success' => true,
                'message' => 'Kode OTP telah dikirim ke email Anda',
                'data' => [
                    'email' => $this->maskEmail($user->email),
                    'phone' => $phone,
                    'expires_in_minutes' => 10,
                ],
            ], 200);

        } catch (\Exception $e) {
            Log::error('Error sending OTP: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengirim kode OTP. Silakan coba lagi',
            ], 500);
        }
    }

    /**
     * Verify OTP yang diinput user
     */
    public function verifyOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone' => 'required|string',
            'otp_code' => 'required|string|size:6',
        ], [
            'phone.required' => 'Nomor HP wajib diisi',
            'otp_code.required' => 'Kode OTP wajib diisi',
            'otp_code.size' => 'Kode OTP harus 6 digit',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
            ], 422);
        }

        try {
            $user = $this->getUserFromToken($request);
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User tidak ditemukan atau token tidak valid',
                ], 401);
            }
            
            $phone = $request->phone;
            $otpCode = $request->otp_code;

            // Cari OTP yang masih valid
            $phoneOtp = PhoneOtp::where('user_id', $user->id)
                ->where('phone', $phone)
                ->where('is_used', false)
                ->where('expires_at', '>', Carbon::now())
                ->orderBy('created_at', 'desc')
                ->first();

            if (!$phoneOtp) {
                return response()->json([
                    'success' => false,
                    'message' => 'Kode OTP tidak valid atau sudah kadaluarsa',
                ], 422);
            }

            // Cek apakah sudah mencapai max attempts
            if ($phoneOtp->hasReachedMaxAttempts()) {
                $phoneOtp->markAsUsed();
                return response()->json([
                    'success' => false,
                    'message' => 'Anda telah mencapai batas maksimal percobaan. Silakan minta kode baru',
                ], 422);
            }

            // Verify OTP
            if (!password_verify($otpCode, $phoneOtp->otp_code)) {
                $phoneOtp->incrementAttempts();
                $remainingAttempts = 3 - $phoneOtp->attempts;
                
                return response()->json([
                    'success' => false,
                    'message' => "Kode OTP salah. Sisa percobaan: {$remainingAttempts}",
                    'data' => [
                        'remaining_attempts' => $remainingAttempts,
                    ],
                ], 422);
            }

            // OTP benar, update user
            $user->update([
                'phone' => $phone,
                'phone_verified' => true,
                'phone_verified_at' => Carbon::now(),
            ]);

            // Mark OTP as used
            $phoneOtp->markAsUsed();

            return response()->json([
                'success' => true,
                'message' => 'Nomor HP berhasil diverifikasi',
                'data' => [
                    'phone' => $phone,
                    'phone_verified' => true,
                    'verified_at' => $user->phone_verified_at,
                ],
            ], 200);

        } catch (\Exception $e) {
            Log::error('Error verifying OTP: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memverifikasi kode OTP. Silakan coba lagi',
            ], 500);
        }
    }

    /**
     * Get status verifikasi nomor HP user
     */
    public function getPhoneStatus(Request $request)
    {
        try {
            $user = $this->getUserFromToken($request);
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User tidak ditemukan atau token tidak valid',
                ], 401);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'phone' => $user->phone,
                    'phone_verified' => $user->phone_verified ?? false,
                    'phone_verified_at' => $user->phone_verified_at,
                ],
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil status verifikasi',
            ], 500);
        }
    }

    /**
     * Resend OTP (sama dengan sendOtp tapi dengan pesan berbeda)
     */
    public function resendOtp(Request $request)
    {
        return $this->sendOtp($request);
    }

    /**
     * Helper function untuk mask email
     */
    private function maskEmail(string $email): string
    {
        $parts = explode('@', $email);
        $name = $parts[0];
        $domain = $parts[1];

        $nameLength = strlen($name);
        $maskLength = max(1, $nameLength - 2);
        
        $maskedName = substr($name, 0, 1) . str_repeat('*', $maskLength) . substr($name, -1);
        
        return $maskedName . '@' . $domain;
    }
}
