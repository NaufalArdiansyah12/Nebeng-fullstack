<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class RefundController extends Controller
{
    /**
     * Get all refund requests
     * GET /api/admin/refund
     */
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 10);
        $status = $request->input('status'); // pending, approved, rejected
        $search = $request->input('search');

        // Untuk sementara menggunakan dummy data
        // Nanti bisa diganti dengan query dari tabel refund
        $refunds = $this->getDummyRefunds($perPage, $status, $search);

        return response()->json([
            'success' => true,
            'data' => $refunds['data'],
            'pagination' => $refunds['pagination']
        ], 200);
    }

    /**
     * Get refund detail
     * GET /api/admin/refund/{id}
     */
    public function show($id)
    {
        // Dummy detail untuk sementara
        $refund = [
            'id' => $id,
            'refund_code' => 'REF-' . str_pad($id, 6, '0', STR_PAD_LEFT),
            'booking_id' => rand(1, 100),
            'booking_code' => 'BOOK-' . str_pad(rand(1, 100), 6, '0', STR_PAD_LEFT),
            'customer' => [
                'id' => 1,
                'name' => 'John Doe',
                'email' => 'john@example.com',
                'phone' => '081234567890',
            ],
            'mitra' => [
                'id' => 2,
                'name' => 'Jane Smith',
                'email' => 'jane@example.com',
            ],
            'amount' => 50000,
            'reason' => 'Mitra membatalkan pesanan',
            'description' => 'Pesanan dibatalkan oleh mitra tanpa alasan yang jelas.',
            'evidence' => [
                'photo' => 'https://via.placeholder.com/400',
            ],
            'status' => 'pending',
            'admin_notes' => null,
            'created_at' => now()->subDays(1)->format('d M Y H:i'),
            'processed_at' => null,
        ];

        return response()->json([
            'success' => true,
            'data' => $refund
        ], 200);
    }

    /**
     * Approve refund
     * POST /api/admin/refund/{id}/approve
     */
    public function approve(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'admin_notes' => 'nullable|string',
            'refund_amount' => 'nullable|numeric|min:0'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        // Implementasi approve refund
        // 1. Update status refund
        // 2. Kembalikan saldo ke customer
        // 3. Kirim notifikasi ke customer

        return response()->json([
            'success' => true,
            'message' => 'Refund berhasil disetujui dan saldo dikembalikan'
        ], 200);
    }

    /**
     * Reject refund
     * POST /api/admin/refund/{id}/reject
     */
    public function reject(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'reason' => 'required|string',
            'admin_notes' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        // Implementasi reject refund
        // 1. Update status refund
        // 2. Kirim notifikasi ke customer

        return response()->json([
            'success' => true,
            'message' => 'Refund ditolak'
        ], 200);
    }

    /**
     * Update refund status
     * PUT /api/admin/refund/{id}/status
     */
    public function updateStatus(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'status' => 'required|in:pending,approved,rejected',
            'admin_notes' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        // Update status refund
        // DB::table('refunds')->where('id', $id)->update([...])

        return response()->json([
            'success' => true,
            'message' => 'Status refund berhasil diupdate'
        ], 200);
    }

    /**
     * Statistics
     * GET /api/admin/refund/statistics
     */
    public function statistics()
    {
        return response()->json([
            'success' => true,
            'data' => [
                'total' => 89,
                'pending' => 12,
                'approved' => 65,
                'rejected' => 12,
                'total_amount' => 4500000,
                'approved_amount' => 3250000,
                'today' => 3,
                'this_month' => 23,
            ]
        ], 200);
    }

    /**
     * Helper: Get dummy refund data
     * Nanti bisa diganti dengan query database
     */
    private function getDummyRefunds($perPage = 10, $status = null, $search = null)
    {
        // Generate dummy data
        $data = [];
        for ($i = 1; $i <= $perPage; $i++) {
            $data[] = [
                'id' => $i,
                'refund_code' => 'REF-' . str_pad($i, 6, '0', STR_PAD_LEFT),
                'booking_code' => 'BOOK-' . str_pad(rand(1, 100), 6, '0', STR_PAD_LEFT),
                'customer_name' => 'Customer ' . $i,
                'amount' => rand(20000, 100000),
                'reason' => ['Pembatalan Mitra', 'Layanan Buruk', 'Lainnya'][rand(0, 2)],
                'status' => ['pending', 'approved', 'rejected'][rand(0, 2)],
                'created_at' => now()->subDays(rand(1, 30))->format('d M Y H:i'),
            ];
        }

        return [
            'data' => $data,
            'pagination' => [
                'current_page' => 1,
                'per_page' => $perPage,
                'total' => 89,
                'last_page' => ceil(89 / $perPage),
            ]
        ];
    }
}
