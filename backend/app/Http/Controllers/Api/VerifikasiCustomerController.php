<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\VerifikasiKtpCustomer;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class VerifikasiCustomerController extends Controller
{
    /**
     * Get user from bearer token
     */
    private function getUserFromToken(Request $request)
    {
        $token = $request->bearerToken();
        if (!$token) {
            return null;
        }

        $hashed = hash('sha256', $token);
        $apiToken = DB::table('api_tokens')->where('token', $hashed)->first();
        
        if (!$apiToken) {
            return null;
        }
        
        return User::find($apiToken->user_id);
    }

    /**
     * Get verification status for current user
     */
    public function getStatus(Request $request)
    {
        try {
            $user = $this->getUserFromToken($request);
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }
            
            $verifikasi = VerifikasiKtpCustomer::where('user_id', $user->id)->first();
            
            if (!$verifikasi) {
                return response()->json([
                    'success' => true,
                    'data' => [
                        'has_verification' => false,
                        'status' => null,
                        'verifikasi_wajah' => false,
                        'verifikasi_ktp' => false,
                        'verifikasi_wajah_ktp' => false,
                    ]
                ]);
            }
            
            return response()->json([
                'success' => true,
                'data' => [
                    'has_verification' => true,
                    'status' => $verifikasi->status,
                    'verifikasi_wajah' => !empty($verifikasi->photo_wajah),
                    'verifikasi_ktp' => !empty($verifikasi->photo_ktp),
                    'verifikasi_wajah_ktp' => !empty($verifikasi->photo_ktp_wajah),
                    'nama_lengkap' => $verifikasi->nama_lengkap,
                    'nik' => $verifikasi->nik,
                    'tanggal_lahir' => $verifikasi->tanggal_lahir,
                    'alamat' => $verifikasi->alamat,
                    'reviewed_at' => $verifikasi->reviewed_at,
                    'created_at' => $verifikasi->created_at,
                    'updated_at' => $verifikasi->updated_at,
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil status verifikasi: ' . $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Upload face photo verification
     */
    public function uploadFacePhoto(Request $request)
    {
        try {
            $user = $this->getUserFromToken($request);
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }
            
            $validator = Validator::make($request->all(), [
                'photo' => 'required|image|mimes:jpeg,png,jpg|max:5120', // max 5MB
            ]);
            
            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validasi gagal',
                    'errors' => $validator->errors()
                ], 422);
            }
            
            DB::beginTransaction();
            
            // Upload photo
            $photo = $request->file('photo');
            $filename = 'verifikasi/wajah/' . $user->id . '_' . time() . '.' . $photo->getClientOriginalExtension();
            Storage::disk('public')->put($filename, file_get_contents($photo));
            
            // Get or create verification record
            $verifikasi = VerifikasiKtpCustomer::firstOrNew(['user_id' => $user->id]);
            
            // Delete old photo if exists
            if ($verifikasi->photo_wajah) {
                Storage::disk('public')->delete($verifikasi->photo_wajah);
            }
            
            $verifikasi->photo_wajah = $filename;
            $verifikasi->status = 'pending';
            $verifikasi->save();
            
            DB::commit();
            
            return response()->json([
                'success' => true,
                'message' => 'Foto wajah berhasil diupload',
                'data' => [
                    'photo_url' => Storage::url($filename),
                    'status' => $verifikasi->status
                ]
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengupload foto wajah: ' . $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Upload KTP photo verification
     */
    public function uploadKtpPhoto(Request $request)
    {
        try {
            $user = $this->getUserFromToken($request);
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }
            
            $validator = Validator::make($request->all(), [
                'photo' => 'required|image|mimes:jpeg,png,jpg|max:5120', // max 5MB
                'nama_lengkap' => 'required|string|max:255',
                'nik' => 'required|string|size:16',
                'tanggal_lahir' => 'required|date',
                'alamat' => 'required|string',
            ]);
            
            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validasi gagal',
                    'errors' => $validator->errors()
                ], 422);
            }
            
            DB::beginTransaction();
            
            // Upload photo
            $photo = $request->file('photo');
            $filename = 'verifikasi/ktp/' . $user->id . '_' . time() . '.' . $photo->getClientOriginalExtension();
            Storage::disk('public')->put($filename, file_get_contents($photo));
            
            // Get or create verification record
            $verifikasi = VerifikasiKtpCustomer::firstOrNew(['user_id' => $user->id]);
            
            // Delete old photo if exists
            if ($verifikasi->photo_ktp) {
                Storage::disk('public')->delete($verifikasi->photo_ktp);
            }
            
            $verifikasi->photo_ktp = $filename;
            $verifikasi->nama_lengkap = $request->nama_lengkap;
            $verifikasi->nik = $request->nik;
            $verifikasi->tanggal_lahir = $request->tanggal_lahir;
            $verifikasi->alamat = $request->alamat;
            $verifikasi->status = 'pending';
            $verifikasi->save();
            
            DB::commit();
            
            return response()->json([
                'success' => true,
                'message' => 'Foto KTP berhasil diupload',
                'data' => [
                    'photo_url' => Storage::url($filename),
                    'status' => $verifikasi->status
                ]
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengupload foto KTP: ' . $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Upload face and KTP photo verification (selfie with KTP)
     */
    public function uploadFaceKtpPhoto(Request $request)
    {
        try {
            $user = $this->getUserFromToken($request);
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }
            
            $validator = Validator::make($request->all(), [
                'photo' => 'required|image|mimes:jpeg,png,jpg|max:5120', // max 5MB
                'nama_lengkap' => 'required|string|max:255',
                'nik' => 'required|string|size:16',
                'tanggal_lahir' => 'required|date',
                'alamat' => 'required|string',
            ]);
            
            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validasi gagal',
                    'errors' => $validator->errors()
                ], 422);
            }
            
            DB::beginTransaction();
            
            // Upload photo
            $photo = $request->file('photo');
            $filename = 'verifikasi/wajah_ktp/' . $user->id . '_' . time() . '.' . $photo->getClientOriginalExtension();
            Storage::disk('public')->put($filename, file_get_contents($photo));
            
            // Get or create verification record
            $verifikasi = VerifikasiKtpCustomer::firstOrNew(['user_id' => $user->id]);
            
            // Delete old photo if exists
            if ($verifikasi->photo_ktp_wajah) {
                Storage::disk('public')->delete($verifikasi->photo_ktp_wajah);
            }
            
            $verifikasi->photo_ktp_wajah = $filename;
            $verifikasi->nama_lengkap = $request->nama_lengkap;
            $verifikasi->nik = $request->nik;
            $verifikasi->tanggal_lahir = $request->tanggal_lahir;
            $verifikasi->alamat = $request->alamat;
            $verifikasi->status = 'pending';
            $verifikasi->save();
            
            DB::commit();
            
            return response()->json([
                'success' => true,
                'message' => 'Foto wajah dan KTP berhasil diupload',
                'data' => [
                    'photo_url' => Storage::url($filename),
                    'status' => $verifikasi->status
                ]
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengupload foto wajah dan KTP: ' . $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Submit verification for review
     */
    public function submitVerification(Request $request)
    {
        try {
            $user = $this->getUserFromToken($request);
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }
            
            $verifikasi = VerifikasiKtpCustomer::where('user_id', $user->id)->first();
            
            if (!$verifikasi) {
                return response()->json([
                    'success' => false,
                    'message' => 'Data verifikasi tidak ditemukan. Silakan upload dokumen terlebih dahulu.'
                ], 404);
            }
            
            // Check if at least one verification type is completed
            if (empty($verifikasi->photo_wajah) && empty($verifikasi->photo_ktp) && empty($verifikasi->photo_ktp_wajah)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Silakan upload minimal satu dokumen verifikasi.'
                ], 400);
            }
            
            $verifikasi->status = 'pending';
            $verifikasi->save();
            
            return response()->json([
                'success' => true,
                'message' => 'Verifikasi berhasil disubmit. Tunggu proses review dari admin.',
                'data' => [
                    'status' => $verifikasi->status
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal submit verifikasi: ' . $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Get verification details
     */
    public function getVerification(Request $request)
    {
        try {
            $user = $this->getUserFromToken($request);
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }
            
            $verifikasi = VerifikasiKtpCustomer::where('user_id', $user->id)->first();
            
            if (!$verifikasi) {
                return response()->json([
                    'success' => false,
                    'message' => 'Data verifikasi tidak ditemukan.'
                ], 404);
            }
            
            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $verifikasi->id,
                    'nama_lengkap' => $verifikasi->nama_lengkap,
                    'nik' => $verifikasi->nik,
                    'tanggal_lahir' => $verifikasi->tanggal_lahir,
                    'alamat' => $verifikasi->alamat,
                    'photo_wajah' => $verifikasi->photo_wajah ? Storage::url($verifikasi->photo_wajah) : null,
                    'photo_ktp' => $verifikasi->photo_ktp ? Storage::url($verifikasi->photo_ktp) : null,
                    'photo_ktp_wajah' => $verifikasi->photo_ktp_wajah ? Storage::url($verifikasi->photo_ktp_wajah) : null,
                    'status' => $verifikasi->status,
                    'reviewed_at' => $verifikasi->reviewed_at,
                    'created_at' => $verifikasi->created_at,
                    'updated_at' => $verifikasi->updated_at,
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil data verifikasi: ' . $e->getMessage()
            ], 500);
        }
    }
}
