<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class LaporanController extends Controller
{
    /**
     * Get all laporan
     * GET /api/admin/laporan
     */
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 10);
        $status = $request->input('status'); // pending, resolved, rejected
        $type = $request->input('type'); // customer, mitra
        $search = $request->input('search');

        // Untuk sementara, jika belum ada tabel laporan, kita create dummy data
        // Nanti bisa diganti dengan query dari tabel laporan
        $laporan = $this->getDummyLaporan($perPage, $status, $type, $search);

        return response()->json([
            'success' => true,
            'data' => $laporan['data'],
            'pagination' => $laporan['pagination']
        ], 200);
    }

    /**
     * Get laporan detail
     * GET /api/admin/laporan/{id}
     */
    public function show($id)
    {
        // Dummy detail untuk sementara
        $laporan = [
            'id' => $id,
            'laporan_code' => 'LAP-' . str_pad($id, 6, '0', STR_PAD_LEFT),
            'reporter' => [
                'id' => 1,
                'name' => 'John Doe',
                'email' => 'john@example.com',
                'phone' => '081234567890',
                'type' => 'customer'
            ],
            'reported' => [
                'id' => 2,
                'name' => 'Jane Smith',
                'email' => 'jane@example.com',
                'phone' => '081234567891',
                'type' => 'mitra'
            ],
            'category' => 'Pelayanan Buruk',
            'subject' => 'Mitra tidak sopan',
            'description' => 'Mitra berbicara kasar dan tidak profesional selama perjalanan.',
            'evidence' => [
                'photo' => 'https://via.placeholder.com/400',
            ],
            'status' => 'pending',
            'admin_notes' => null,
            'created_at' => now()->subDays(2)->format('d M Y H:i'),
            'resolved_at' => null,
        ];

        return response()->json([
            'success' => true,
            'data' => $laporan
        ], 200);
    }

    /**
     * Create laporan (dari admin)
     * POST /api/admin/laporan
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'reporter_id' => 'required|integer',
            'reported_id' => 'required|integer',
            'category' => 'required|string|max:100',
            'subject' => 'required|string|max:255',
            'description' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        // Implementasi create laporan
        // DB::table('laporan')->insert([...])

        return response()->json([
            'success' => true,
            'message' => 'Laporan berhasil dibuat'
        ], 201);
    }

    /**
     * Update laporan status
     * PUT /api/admin/laporan/{id}/status
     */
    public function updateStatus(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'status' => 'required|in:pending,resolved,rejected',
            'admin_notes' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        // Update status laporan
        // DB::table('laporan')->where('id', $id)->update([...])

        return response()->json([
            'success' => true,
            'message' => 'Status laporan berhasil diupdate'
        ], 200);
    }

    /**
     * Resolve laporan
     * POST /api/admin/laporan/{id}/resolve
     */
    public function resolve(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'resolution' => 'required|string',
            'action_taken' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        // Resolve laporan
        // DB::table('laporan')->where('id', $id)->update([...])

        return response()->json([
            'success' => true,
            'message' => 'Laporan berhasil diselesaikan'
        ], 200);
    }

    /**
     * Statistics
     * GET /api/admin/laporan/statistics
     */
    public function statistics()
    {
        return response()->json([
            'success' => true,
            'data' => [
                'total' => 156,
                'pending' => 23,
                'resolved' => 120,
                'rejected' => 13,
                'today' => 5,
                'this_month' => 45,
            ]
        ], 200);
    }

    /**
     * Helper: Get dummy laporan data
     * Nanti bisa diganti dengan query database
     */
    private function getDummyLaporan($perPage = 10, $status = null, $type = null, $search = null)
    {
        // Generate dummy data
        $data = [];
        for ($i = 1; $i <= $perPage; $i++) {
            $data[] = [
                'id' => $i,
                'laporan_code' => 'LAP-' . str_pad($i, 6, '0', STR_PAD_LEFT),
                'reporter_name' => 'Reporter ' . $i,
                'reporter_type' => $i % 2 == 0 ? 'customer' : 'mitra',
                'reported_name' => 'Reported User ' . $i,
                'category' => ['Pelayanan Buruk', 'Keamanan', 'Penipuan', 'Lainnya'][rand(0, 3)],
                'subject' => 'Laporan masalah #' . $i,
                'status' => ['pending', 'resolved', 'rejected'][rand(0, 2)],
                'created_at' => now()->subDays(rand(1, 30))->format('d M Y H:i'),
            ];
        }

        return [
            'data' => $data,
            'pagination' => [
                'current_page' => 1,
                'per_page' => $perPage,
                'total' => 156,
                'last_page' => ceil(156 / $perPage),
            ]
        ];
    }
}
