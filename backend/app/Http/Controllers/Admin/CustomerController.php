<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CustomerController extends Controller
{
    /**
     * Get all customers
     * GET /api/admin/customers
     * 
     * Query params:
     * - per_page: jumlah data per halaman (default: 10)
     * - status_filter: AKTIF (tidak blocked), SEMUA (semua customer), DIBLOCK (hanya blocked)
     * - search: pencarian nama, email, atau phone
     */
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 10);
        $statusFilter = $request->input('status_filter', 'AKTIF'); // AKTIF, SEMUA, DIBLOCK
        $search = $request->input('search');

        $query = User::where('role', 'customer');

        // ✅ Filter berdasarkan statusFilter yang sesuai dengan frontend
        if ($statusFilter === 'AKTIF') {
            // Tampilkan customer yang tidak di-block
            $query->where(function($q) {
                $q->where('status', '!=', 'blocked')
                  ->orWhereNull('status')
                  ->orWhere('status', '=', 'active');
            });
        } elseif ($statusFilter === 'DIBLOCK') {
            // Tampilkan hanya customer yang di-block
            $query->where('status', 'blocked');
        }
        // Jika SEMUA, tidak perlu filter tambahan (tampilkan semua)

        // Search filter
        if ($search) {
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%")
                  ->orWhere('id', 'like', "%{$search}%");
            });
        }

        $customers = $query->orderBy('created_at', 'desc')
                          ->paginate($perPage);

        // ✅ Transform data untuk frontend
        // Transform data to be consistent with Mitra API response
        $transformedData = collect($customers->items())->map(function($customer) {
            return [
                // keep id as string for consistency with Mitra responses
                'id' => (string) $customer->id,
                'nama' => $customer->name,
                'email' => $customer->email,
                // provide both snake_case and camelCase phone fields
                'no_tlp' => $customer->phone,
                'noTlp' => $customer->phone,
                // gender intentionally omitted: we take all fields from users except jenis_kelamin
                // keep status mapping consistent with frontend expectations
                'status' => $this->mapStatusToDisplay($customer->status),
                // provide date fields similar to MitraController
                'tanggal_daftar' => $customer->created_at,
                'tanggal' => $customer->created_at,
                'created_at' => $customer->created_at,
                'updated_at' => $customer->updated_at,
                // default layanan/kode for compatibility with Mitra frontend
                'layanan' => 'Customer',
                'kode' => '#' . $customer->id,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $transformedData,
            'pagination' => [
                'current_page' => $customers->currentPage(),
                'per_page' => $customers->perPage(),
                'total' => $customers->total(),
                'last_page' => $customers->lastPage(),
            ]
        ], 200);
    }

    /**
     * Map database status ke display format
     */
    private function mapStatusToDisplay($status)
    {
        if (!$status) return 'PENGAJUAN';
        
        $statusMap = [
            'pending' => 'PENGAJUAN',
            'active' => 'TERVERIFIKASI',
            'approved' => 'TERVERIFIKASI',
            'rejected' => 'DITOLAK',
            'suspended' => 'DIBLOCK',
            'blocked' => 'DIBLOCK',
        ];
        
        return $statusMap[strtolower($status)] ?? strtoupper($status);
    }

    /**
     * Get customer detail
     * GET /api/admin/customers/{id}
     */
    public function show($id)
    {
        $customer = User::where('role', 'customer')->find($id);

        if (!$customer) {
            return response()->json([
                'success' => false,
                'message' => 'Customer tidak ditemukan'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $customer->id,
                'name' => $customer->name,
                'email' => $customer->email,
                'phone' => $customer->phone,
                'phone_verified' => $customer->phone_verified,
                'address' => $customer->address,
                'status' => $customer->status,
                'blocked_reason' => $customer->blocked_reason,
                'blocked_at' => $customer->blocked_at,
                'profile_photo' => $customer->profile_photo ? url('storage/' . $customer->profile_photo) : null,
                'balance' => $customer->balance,
                'reward_points' => $customer->reward_points,
                'created_at' => $customer->created_at->format('d M Y H:i'),
            ]
        ], 200);
    }

    /**
     * Verify customer
     * POST /api/admin/customers/{id}/verify
     */
    public function verify($id)
    {
        $customer = User::where('role', 'customer')->find($id);

        if (!$customer) {
            return response()->json([
                'success' => false,
                'message' => 'Customer tidak ditemukan'
            ], 404);
        }

        $customer->phone_verified = true;
        $customer->phone_verified_at = now();
        $customer->status = 'active';
        $customer->save();

        return response()->json([
            'success' => true,
            'message' => 'Customer berhasil diverifikasi',
            'data' => $customer
        ], 200);
    }

    /**
     * Block customer
     * POST /api/admin/customers/{id}/block
     */
    public function block(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'reason' => 'nullable|string|max:500'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $customer = User::where('role', 'customer')->find($id);

        if (!$customer) {
            return response()->json([
                'success' => false,
                'message' => 'Customer tidak ditemukan'
            ], 404);
        }

        $customer->status = 'blocked';
        $customer->blocked_reason = $request->input('reason', 'Diblokir oleh admin');
        $customer->blocked_at = now();
        $customer->save();

        return response()->json([
            'success' => true,
            'message' => 'Customer berhasil diblokir',
            'data' => $customer
        ], 200);
    }

    /**
     * Unblock customer
     * POST /api/admin/customers/{id}/unblock
     */
    public function unblock($id)
    {
        $customer = User::where('role', 'customer')->find($id);

        if (!$customer) {
            return response()->json([
                'success' => false,
                'message' => 'Customer tidak ditemukan'
            ], 404);
        }

        $customer->status = 'active';
        $customer->blocked_reason = null;
        $customer->blocked_at = null;
        $customer->save();

        return response()->json([
            'success' => true,
            'message' => 'Customer berhasil diunblock',
            'data' => $customer
        ], 200);
    }

    /**
     * Get pending verification customers
     * GET /api/admin/customers/pending-verification
     */
    public function pendingVerification(Request $request)
    {
        $perPage = $request->input('per_page', 10);

        $customers = User::where('role', 'customer')
                        ->where('phone_verified', false)
                        ->orderBy('created_at', 'desc')
                        ->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $customers->items(),
            'pagination' => [
                'current_page' => $customers->currentPage(),
                'per_page' => $customers->perPage(),
                'total' => $customers->total(),
                'last_page' => $customers->lastPage(),
            ]
        ], 200);
    }

    /**
     * Get blocked customers
     * GET /api/admin/customers/blocked
     */
    public function blocked(Request $request)
    {
        $perPage = $request->input('per_page', 10);

        $customers = User::where('role', 'customer')
                        ->where('status', 'blocked')
                        ->orderBy('blocked_at', 'desc')
                        ->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $customers->items(),
            'pagination' => [
                'current_page' => $customers->currentPage(),
                'per_page' => $customers->perPage(),
                'total' => $customers->total(),
                'last_page' => $customers->lastPage(),
            ]
        ], 200);
    }
}
