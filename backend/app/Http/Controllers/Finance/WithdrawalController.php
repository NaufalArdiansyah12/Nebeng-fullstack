<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class WithdrawalController extends Controller
{
    /**
     * Get all withdrawal requests with filters
     */
    public function index(Request $request)
    {
        try {
            $type = $request->get('type', 'all'); // all, mitra, posmitra
            $status = $request->get('status');
            $search = $request->get('search');
            $perPage = $request->get('per_page', 10);

            // Get Mitra withdrawals
            $mitraQuery = DB::table('withdrawals as w')
                ->join('users as u', 'w.user_id', '=', 'u.id')
                ->select(
                    'w.id',
                    'w.transaction_id',
                    'w.amount',
                    'w.admin_fee',
                    'w.total_amount',
                    'w.bank_name',
                    'w.bank_account_number',
                    'w.bank_account_name',
                    'w.status',
                    'w.submitted_at',
                    'w.verified_at',
                    'w.approved_at',
                    'w.processing_at',
                    'w.completed_at',
                    'w.rejected_at',
                    'w.rejection_reason',
                    'w.notes',
                    'w.created_at',
                    'u.name as user_name',
                    'u.email as user_email',
                    'u.phone as user_phone',
                    DB::raw("'mitra' as type")
                );

            // Get PosMitra withdrawals
            $posmitraQuery = DB::table('withdrawal_posmitra as wp')
                ->join('posmitra_users as pm', 'wp.posmitra_id', '=', 'pm.id')
                ->select(
                    'wp.id',
                    'wp.transaction_id',
                    'wp.amount',
                    'wp.admin_fee',
                    'wp.total_amount',
                    'wp.bank_name',
                    'wp.bank_account_number',
                    'wp.bank_account_name',
                    'wp.status',
                    'wp.submitted_at',
                    'wp.verified_at',
                    'wp.approved_at',
                    'wp.processing_at',
                    'wp.completed_at',
                    'wp.rejected_at',
                    'wp.rejection_reason',
                    'wp.notes',
                    'wp.created_at',
                    'pm.name as user_name',
                    'pm.email as user_email',
                    'pm.phone as user_phone',
                    DB::raw("'posmitra' as type")
                );

            // Combine queries based on type filter
            if ($type === 'mitra') {
                $query = $mitraQuery;
            } elseif ($type === 'posmitra') {
                $query = $posmitraQuery;
            } else {
                $query = $mitraQuery->unionAll($posmitraQuery);
            }

            // Apply filters on the union result
            $withdrawals = DB::table(DB::raw("({$query->toSql()}) as combined"))
                ->mergeBindings($query);

            if ($status) {
                $withdrawals->where('status', $status);
            }

            if ($search) {
                $withdrawals->where(function($q) use ($search) {
                    $q->where('user_name', 'like', "%{$search}%")
                      ->orWhere('transaction_id', 'like', "%{$search}%")
                      ->orWhere('user_email', 'like', "%{$search}%");
                });
            }

            $result = $withdrawals->orderBy('created_at', 'desc')
                                  ->paginate($perPage);

            // Get statistics
            $stats = [
                'total' => DB::table('withdrawals')->count() + DB::table('withdrawal_posmitra')->count(),
                'pending' => DB::table('withdrawals')->where('status', 'pending')->count() + 
                            DB::table('withdrawal_posmitra')->where('status', 'pending')->count(),
                'processing' => DB::table('withdrawals')->whereIn('status', ['verifying', 'approved', 'processing', 'transferring'])->count() + 
                               DB::table('withdrawal_posmitra')->whereIn('status', ['verifying', 'approved', 'processing', 'transferring'])->count(),
                'completed' => DB::table('withdrawals')->where('status', 'completed')->count() + 
                              DB::table('withdrawal_posmitra')->where('status', 'completed')->count(),
                'rejected' => DB::table('withdrawals')->where('status', 'rejected')->count() + 
                             DB::table('withdrawal_posmitra')->where('status', 'rejected')->count(),
            ];

            return response()->json([
                'success' => true,
                'data' => $result->items(),
                'meta' => [
                    'current_page' => $result->currentPage(),
                    'last_page' => $result->lastPage(),
                    'per_page' => $result->perPage(),
                    'total' => $result->total(),
                ],
                'statistics' => $stats
            ]);

        } catch (\Exception $e) {
            Log::error('Error fetching withdrawals: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch withdrawals',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get withdrawal detail by ID and type
     */
    public function show(Request $request, $id)
    {
        try {
            $type = $request->get('type', 'mitra');

            if ($type === 'posmitra') {
                $withdrawal = DB::table('withdrawal_posmitra as wp')
                    ->join('posmitra_users as pm', 'wp.posmitra_id', '=', 'pm.id')
                    ->where('wp.id', $id)
                    ->select(
                        'wp.*',
                        'pm.name as user_name',
                        'pm.email as user_email',
                        'pm.phone as user_phone',
                        DB::raw('CONCAT("POS", LPAD(pm.id, 4, "0")) as kode_referral'),
                        DB::raw("'posmitra' as type")
                    )
                    ->first();
            } else {
                $withdrawal = DB::table('withdrawals as w')
                    ->join('users as u', 'w.user_id', '=', 'u.id')
                    ->where('w.id', $id)
                    ->select(
                        'w.*',
                        'u.name as user_name',
                        'u.email as user_email',
                        'u.phone as user_phone',
                        DB::raw('CONCAT("MTR", LPAD(u.id, 4, "0")) as kode_referral'),
                        DB::raw("'mitra' as type")
                    )
                    ->first();
            }

            if (!$withdrawal) {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal not found'
                ], 404);
            }

            // Generate progress timeline
            $progress = $this->generateProgressTimeline($withdrawal);
            $withdrawal->progress = $progress;

            // Auto-update verified_at on first view if status is pending
            if ($withdrawal->status === 'pending' && !$withdrawal->verified_at) {
                $table = $type === 'posmitra' ? 'withdrawal_posmitra' : 'withdrawals';
                DB::table($table)
                    ->where('id', $id)
                    ->update(['verified_at' => now()]);
                
                $withdrawal->verified_at = now();
            }

            return response()->json($withdrawal);

        } catch (\Exception $e) {
            Log::error('Error fetching withdrawal detail: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch withdrawal detail'
            ], 500);
        }
    }

    /**
     * Approve withdrawal
     */
    public function approve(Request $request, $id)
    {
        try {
            $request->validate([
                'type' => 'required|in:mitra,posmitra',
                'admin_fee' => 'nullable|numeric|min:0'
            ]);

            $type = $request->type;
            $table = $type === 'posmitra' ? 'withdrawal_posmitra' : 'withdrawals';

            $withdrawal = DB::table($table)->where('id', $id)->first();

            if (!$withdrawal) {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal not found'
                ], 404);
            }

            if (!in_array($withdrawal->status, ['pending', 'verifying'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal cannot be approved in current status'
                ], 400);
            }

            $adminFee = $request->admin_fee ?? 0;
            $totalAmount = $withdrawal->amount - $adminFee;

            DB::table($table)->where('id', $id)->update([
                'status' => 'approved',
                'admin_fee' => $adminFee,
                'total_amount' => $totalAmount,
                'approved_at' => now(),
                'updated_at' => now()
            ]);

            // Create notification for withdrawal approval
            $updatedWithdrawal = DB::table($table)->where('id', $id)->first();
            NotificationService::createWithdrawalNotification($updatedWithdrawal);

            return response()->json([
                'success' => true,
                'message' => 'Withdrawal approved successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Error approving withdrawal: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to approve withdrawal'
            ], 500);
        }
    }

    /**
     * Reject withdrawal
     */
    public function reject(Request $request, $id)
    {
        try {
            $request->validate([
                'type' => 'required|in:mitra,posmitra',
                'rejection_reason' => 'required|string'
            ]);

            $type = $request->type;
            $table = $type === 'posmitra' ? 'withdrawal_posmitra' : 'withdrawals';

            $withdrawal = DB::table($table)->where('id', $id)->first();

            if (!$withdrawal) {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal not found'
                ], 404);
            }

            if (!in_array($withdrawal->status, ['pending', 'verifying', 'approved'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal cannot be rejected in current status'
                ], 400);
            }

            DB::table($table)->where('id', $id)->update([
                'status' => 'rejected',
                'rejection_reason' => $request->rejection_reason,
                'rejected_at' => now(),
                'updated_at' => now()
            ]);

            // Create notification for withdrawal rejection
            $updatedWithdrawal = DB::table($table)->where('id', $id)->first();
            NotificationService::createWithdrawalNotification($updatedWithdrawal);

            return response()->json([
                'success' => true,
                'message' => 'Withdrawal rejected successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Error rejecting withdrawal: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to reject withdrawal'
            ], 500);
        }
    }

    /**
     * Process withdrawal (start transfer)
     */
    public function process(Request $request, $id)
    {
        try {
            $request->validate([
                'type' => 'required|in:mitra,posmitra'
            ]);

            $type = $request->type;
            $table = $type === 'posmitra' ? 'withdrawal_posmitra' : 'withdrawals';

            $withdrawal = DB::table($table)->where('id', $id)->first();

            if (!$withdrawal) {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal not found'
                ], 404);
            }

            if ($withdrawal->status !== 'approved') {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal must be approved before processing'
                ], 400);
            }

            DB::table($table)->where('id', $id)->update([
                'status' => 'processing',
                'processing_at' => now(),
                'updated_at' => now()
            ]);

            // Create notification for withdrawal processing
            $updatedWithdrawal = DB::table($table)->where('id', $id)->first();
            NotificationService::createWithdrawalNotification($updatedWithdrawal);

            return response()->json([
                'success' => true,
                'message' => 'Withdrawal is now being processed'
            ]);

        } catch (\Exception $e) {
            Log::error('Error processing withdrawal: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to process withdrawal'
            ], 500);
        }
    }

    /**
     * Complete withdrawal (mark as transferred)
     */
    public function complete(Request $request, $id)
    {
        try {
            $request->validate([
                'type' => 'required|in:mitra,posmitra'
            ]);

            $type = $request->type;
            $table = $type === 'posmitra' ? 'withdrawal_posmitra' : 'withdrawals';

            $withdrawal = DB::table($table)->where('id', $id)->first();

            if (!$withdrawal) {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal not found'
                ], 404);
            }

            if (!in_array($withdrawal->status, ['processing', 'transferring'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal must be in processing or transferring status'
                ], 400);
            }

            DB::table($table)->where('id', $id)->update([
                'status' => 'completed',
                'completed_at' => now(),
                'updated_at' => now()
            ]);

            // Create notification for withdrawal completion
            $updatedWithdrawal = DB::table($table)->where('id', $id)->first();
            NotificationService::createWithdrawalNotification($updatedWithdrawal);

            return response()->json([
                'success' => true,
                'message' => 'Withdrawal completed successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Error completing withdrawal: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to complete withdrawal'
            ], 500);
        }
    }

    /**
     * Generate progress timeline based on withdrawal status
     */
    private function generateProgressTimeline($withdrawal)
    {
        $steps = [
            [
                'title' => 'Pengajuan Diajukan',
                'description' => 'Pengajuan penarikan dana telah diterima',
                'date' => $withdrawal->submitted_at,
                'status' => $withdrawal->submitted_at ? 'completed' : 'pending'
            ],
            [
                'title' => 'Memeriksa Pengajuan',
                'description' => 'Admin sedang memeriksa pengajuan Anda',
                'date' => $withdrawal->verified_at,
                'status' => $withdrawal->verified_at ? 'completed' : ($withdrawal->status === 'rejected' ? 'rejected' : 'pending')
            ],
            [
                'title' => 'Pengajuan Disetujui',
                'description' => 'Pengajuan penarikan dana telah disetujui',
                'date' => $withdrawal->approved_at,
                'status' => $withdrawal->approved_at ? 'completed' : ($withdrawal->status === 'rejected' ? 'rejected' : 'pending')
            ],
            [
                'title' => 'Pencairan Diproses',
                'description' => 'Dana sedang diproses untuk ditransfer',
                'date' => $withdrawal->processing_at,
                'status' => $withdrawal->processing_at ? 'completed' : ($withdrawal->status === 'rejected' ? 'rejected' : 'pending')
            ],
            [
                'title' => 'Penarikan Selesai',
                'description' => 'Dana telah berhasil ditransfer ke rekening Anda',
                'date' => $withdrawal->completed_at,
                'status' => $withdrawal->completed_at ? 'completed' : ($withdrawal->status === 'rejected' ? 'rejected' : 'pending')
            ]
        ];

        return $steps;
    }
}
