<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class RefundController extends Controller
{
    /* =========================
       GET ALL REFUNDS
    ========================= */
    public function index(Request $request)
    {
        try {
            $query = DB::table('refunds as r')
                ->leftJoin('users as u', 'r.user_id', '=', 'u.id')
                ->select(
                    'r.id',
                    'r.booking_id',
                    'r.booking_type',
                    'r.refund_reason',
                    'r.total_amount',
                    'r.refund_amount',
                    'r.admin_fee',
                    'r.bank_name',
                    'r.account_number',
                    'r.account_holder_name',
                    'r.status',
                    'r.rejection_reason',
                    'r.submitted_at',
                    'r.approved_at',
                    'r.processed_at',
                    'r.completed_at',
                    'r.created_at',
                    'u.name as customer_name',
                    'u.email as customer_email',
                    'u.phone as customer_phone'
                )
                ->orderBy('r.created_at', 'desc');

            // Filter by status if provided
            if ($request->has('status') && $request->status != '') {
                $query->where('r.status', $request->status);
            }

            $refunds = $query->get();

            return response()->json($refunds);
        } catch (\Exception $e) {
            Log::error('Error fetching refunds: ' . $e->getMessage());
            return response()->json([
                'message' => 'Gagal mengambil data refund',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /* =========================
       GET REFUND DETAIL
    ========================= */
    public function show($id)
    {
        try {
            $refund = DB::table('refunds as r')
                ->leftJoin('users as u', 'r.user_id', '=', 'u.id')
                ->select(
                    'r.*',
                    'u.name as customer_name',
                    'u.email as customer_email',
                    'u.phone as customer_phone',
                    'u.profile_photo as customer_photo'
                )
                ->where('r.id', $id)
                ->first();

            if (!$refund) {
                return response()->json(['message' => 'Refund tidak ditemukan'], 404);
            }

            // Auto-update reviewed_at when admin views for the first time
            if ($refund->status === 'pending' && !$refund->reviewed_at) {
                DB::table('refunds')
                    ->where('id', $id)
                    ->update([
                        'reviewed_at' => now(),
                        'updated_at' => now(),
                    ]);
                
                // Refresh the refund data
                $refund = DB::table('refunds as r')
                    ->leftJoin('users as u', 'r.user_id', '=', 'u.id')
                    ->select(
                        'r.*',
                        'u.name as customer_name',
                        'u.email as customer_email',
                        'u.phone as customer_phone',
                        'u.profile_photo as customer_photo'
                    )
                    ->where('r.id', $id)
                    ->first();
            }

            // Build progress timeline
            $progress = [];
            
            // 1. Refund Diajukan
            $progress[] = [
                'title' => 'Refund Telah Diajukan',
                'description' => 'Proses pengembalian dana sedang berlangsung dan akan diproses dalam 3-5 hari kerja',
                'date' => $refund->created_at,
                'status' => 'completed'
            ];

            // 2. Memeriksa Pengajuan (completed when reviewed_at is set)
            if ($refund->status !== 'rejected') {
                $progress[] = [
                    'title' => 'Memeriksa Pengajuan Anda',
                    'description' => 'Saat ini, Admin kami sedang memeriksa informasi yang telah Anda kirimkan',
                    'date' => $refund->reviewed_at ?? $refund->updated_at,
                    'status' => $refund->reviewed_at ? 'completed' : 'pending'
                ];
            }

            // 3. Refund Disetujui
            if ($refund->status !== 'rejected') {
                $progress[] = [
                    'title' => 'Refund Disetujui',
                    'description' => 'Pemeriksaan pengajuan Anda sudah disetujui! Dana Anda akan segera ditransfer ke rekening Anda yang terdaftar',
                    'date' => $refund->approved_at,
                    'status' => in_array($refund->status, ['approved', 'processing', 'completed']) ? 'completed' : 'pending'
                ];
            }

            // 4. Refund Sedang Dikirim
            if ($refund->status !== 'rejected') {
                $progress[] = [
                    'title' => 'Refund Sedang Dikirim',
                    'description' => 'Refund Anda sedang diproses. Harap bersabarlah dan akan segera masuk ke rekening Anda',
                    'date' => $refund->processed_at,
                    'status' => in_array($refund->status, ['processing', 'completed']) ? 'completed' : 'pending'
                ];
            }

            // 5. Refund Telah Ditransfer
            if ($refund->status !== 'rejected') {
                $progress[] = [
                    'title' => 'Refund Telah Ditransfer',
                    'description' => 'Refund Anda sebesar Rp' . number_format($refund->refund_amount, 0, ',', '.') . ' telah berhasil kami proses dan akan segera masuk ke rekening Anda. Terima kasih!',
                    'date' => $refund->completed_at,
                    'status' => $refund->status === 'completed' ? 'completed' : 'pending'
                ];
            }

            // If rejected, add rejection step
            if ($refund->status === 'rejected') {
                $progress[] = [
                    'title' => 'Refund Ditolak',
                    'description' => $refund->rejection_reason ?? 'Pengajuan refund Anda tidak dapat diproses',
                    'date' => $refund->updated_at,
                    'status' => 'rejected'
                ];
            }

            $refund->progress = $progress;

            return response()->json($refund);
        } catch (\Exception $e) {
            Log::error('Error fetching refund detail: ' . $e->getMessage());
            return response()->json([
                'message' => 'Gagal mengambil detail refund',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /* =========================
       APPROVE REFUND
    ========================= */
    public function approve(Request $request, $id)
    {
        try {
            $request->validate([
                'admin_fee' => 'nullable|numeric|min:0',
            ]);

            $refund = DB::table('refunds')->where('id', $id)->first();

            if (!$refund) {
                return response()->json(['message' => 'Refund tidak ditemukan'], 404);
            }

            if ($refund->status !== 'pending') {
                return response()->json([
                    'message' => 'Refund hanya bisa disetujui jika statusnya pending'
                ], 400);
            }

            // Calculate final refund amount
            $adminFee = $request->admin_fee ?? 0;
            $finalRefundAmount = $refund->total_amount - $adminFee;

            DB::table('refunds')
                ->where('id', $id)
                ->update([
                    'status' => 'approved',
                    'admin_fee' => $adminFee,
                    'refund_amount' => $finalRefundAmount,
                    'approved_at' => now(),
                    'updated_at' => now(),
                ]);

            // Create notification for refund approval
            $updatedRefund = DB::table('refunds')->where('id', $id)->first();
            NotificationService::createRefundNotification($updatedRefund);

            return response()->json([
                'message' => 'Refund berhasil disetujui',
                'refund_amount' => $finalRefundAmount
            ]);
        } catch (\Exception $e) {
            Log::error('Error approving refund: ' . $e->getMessage());
            return response()->json([
                'message' => 'Gagal menyetujui refund',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /* =========================
       REJECT REFUND
    ========================= */
    public function reject(Request $request, $id)
    {
        try {
            $request->validate([
                'rejection_reason' => 'required|string|max:500',
            ]);

            $refund = DB::table('refunds')->where('id', $id)->first();

            if (!$refund) {
                return response()->json(['message' => 'Refund tidak ditemukan'], 404);
            }

            if ($refund->status !== 'pending') {
                return response()->json([
                    'message' => 'Refund hanya bisa ditolak jika statusnya pending'
                ], 400);
            }

            DB::table('refunds')
                ->where('id', $id)
                ->update([
                    'status' => 'rejected',
                    'rejection_reason' => $request->rejection_reason,
                    'updated_at' => now(),
                ]);

            // Create notification for refund rejection
            $updatedRefund = DB::table('refunds')->where('id', $id)->first();
            NotificationService::createRefundNotification($updatedRefund);

            return response()->json([
                'message' => 'Refund berhasil ditolak'
            ]);
        } catch (\Exception $e) {
            Log::error('Error rejecting refund: ' . $e->getMessage());
            return response()->json([
                'message' => 'Gagal menolak refund',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /* =========================
       PROCESS REFUND (Mark as Processing)
    ========================= */
    public function process($id)
    {
        try {
            $refund = DB::table('refunds')->where('id', $id)->first();

            if (!$refund) {
                return response()->json(['message' => 'Refund tidak ditemukan'], 404);
            }

            if ($refund->status !== 'approved') {
                return response()->json([
                    'message' => 'Refund hanya bisa diproses jika sudah disetujui'
                ], 400);
            }

            DB::table('refunds')
                ->where('id', $id)
                ->update([
                    'status' => 'processing',
                    'processed_at' => now(),
                    'updated_at' => now(),
                ]);

            // Create notification for refund processing
            $updatedRefund = DB::table('refunds')->where('id', $id)->first();
            NotificationService::createRefundNotification($updatedRefund);

            return response()->json([
                'message' => 'Refund berhasil diproses'
            ]);
        } catch (\Exception $e) {
            Log::error('Error processing refund: ' . $e->getMessage());
            return response()->json([
                'message' => 'Gagal memproses refund',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /* =========================
       COMPLETE REFUND
    ========================= */
    public function complete($id)
    {
        try {
            $refund = DB::table('refunds')->where('id', $id)->first();

            if (!$refund) {
                return response()->json(['message' => 'Refund tidak ditemukan'], 404);
            }

            if ($refund->status !== 'processing') {
                return response()->json([
                    'message' => 'Refund hanya bisa diselesaikan jika statusnya processing'
                ], 400);
            }

            DB::table('refunds')
                ->where('id', $id)
                ->update([
                    'status' => 'completed',
                    'completed_at' => now(),
                    'updated_at' => now(),
                ]);

            // Create notification for refund completion
            $updatedRefund = DB::table('refunds')->where('id', $id)->first();
            NotificationService::createRefundNotification($updatedRefund);

            return response()->json([
                'message' => 'Refund berhasil diselesaikan'
            ]);
        } catch (\Exception $e) {
            Log::error('Error completing refund: ' . $e->getMessage());
            return response()->json([
                'message' => 'Gagal menyelesaikan refund',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /* =========================
       GET REFUND STATISTICS
    ========================= */
    public function statistics()
    {
        try {
            $stats = [
                'total' => DB::table('refunds')->count(),
                'pending' => DB::table('refunds')->where('status', 'pending')->count(),
                'approved' => DB::table('refunds')->where('status', 'approved')->count(),
                'processing' => DB::table('refunds')->where('status', 'processing')->count(),
                'completed' => DB::table('refunds')->where('status', 'completed')->count(),
                'rejected' => DB::table('refunds')->where('status', 'rejected')->count(),
                'total_amount' => DB::table('refunds')->sum('refund_amount'),
            ];

            return response()->json($stats);
        } catch (\Exception $e) {
            Log::error('Error fetching refund statistics: ' . $e->getMessage());
            return response()->json([
                'message' => 'Gagal mengambil statistik refund',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
