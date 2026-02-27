<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use App\Models\PricePerKg;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class PricePerKgController extends Controller
{
    /**
     * Get all prices with filtering
     */
    public function index(Request $request)
    {
        $query = PricePerKg::query();

        // Filter by service type
        if ($request->has('service_type') && $request->service_type !== 'all') {
            $query->where('service_type', $request->service_type);
        }

        // Filter by ride type
        if ($request->has('ride_type') && $request->ride_type !== 'all') {
            $query->where('ride_type', $request->ride_type);
        }

        // Filter by status
        if ($request->has('is_active')) {
            $query->where('is_active', $request->is_active);
        }

        // Search
        if ($request->has('search') && $request->search) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('service_type', 'like', "%{$search}%")
                    ->orWhere('ride_type', 'like', "%{$search}%");
            });
        }

        $prices = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $prices,
        ]);
    }

    /**
     * Store new price
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'service_type' => 'required|in:antar_barang,antar_penumpang',
            'ride_type' => 'required|in:motor,mobil,barang,titip_barang',
            'bagasi_capacity' => 'nullable|integer|in:5,10,20',
            'rate_per_kg' => 'required|numeric|min:0',
            'min_charge' => 'required|numeric|min:0',
            'effective_from' => 'required|date',
            'is_active' => 'boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Validate bagasi_capacity only for antar_barang
        if ($request->service_type === 'antar_barang' && !$request->has('bagasi_capacity')) {
            return response()->json([
                'success' => false,
                'message' => 'Kapasitas bagasi wajib diisi untuk layanan antar barang',
            ], 422);
        }

        // Check for duplicate active price
        $duplicateQuery = PricePerKg::where('service_type', $request->service_type)
            ->where('ride_type', $request->ride_type)
            ->where('is_active', true);
        
        // For antar_barang, also check bagasi_capacity
        if ($request->service_type === 'antar_barang') {
            $duplicateQuery->where('bagasi_capacity', $request->bagasi_capacity);
        }
        
        $existingActive = $duplicateQuery->exists();

        if ($existingActive && ($request->is_active ?? true)) {
            return response()->json([
                'success' => false,
                'message' => 'Tarif aktif untuk kombinasi layanan, jenis tebengan, dan kapasitas bagasi ini sudah ada. Nonaktifkan tarif lama terlebih dahulu.',
            ], 422);
        }

        DB::beginTransaction();
        try {
            $price = PricePerKg::create([
                'service_type' => $request->service_type,
                'ride_type' => $request->ride_type,
                'bagasi_capacity' => $request->bagasi_capacity,
                'rate_per_kg' => $request->rate_per_kg,
                'min_charge' => $request->min_charge,
                'is_active' => $request->is_active ?? true,
                'effective_from' => $request->effective_from,
            ]);

            // Log to history
            $price->logChange('created', auth()->id(), 'Tarif baru dibuat');

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Tarif berhasil ditambahkan',
                'data' => $price,
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Gagal menambahkan tarif',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Update price
     */
    public function update(Request $request, $id)
    {
        $price = PricePerKg::find($id);

        if (!$price) {
            return response()->json([
                'success' => false,
                'message' => 'Tarif tidak ditemukan',
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'service_type' => 'sometimes|in:antar_barang,antar_penumpang',
            'ride_type' => 'sometimes|in:motor,mobil,barang,titip_barang',
            'bagasi_capacity' => 'nullable|integer|in:5,10,20',
            'rate_per_kg' => 'sometimes|numeric|min:0',
            'min_charge' => 'sometimes|numeric|min:0',
            'effective_from' => 'sometimes|date',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        DB::beginTransaction();
        try {
            $price->update($request->all());

            // Log to history
            $price->logChange('updated', auth()->id(), 'Tarif diperbarui');

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Tarif berhasil diperbarui',
                'data' => $price,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Gagal memperbarui tarif',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Toggle active status
     */
    public function toggleStatus($id)
    {
        $price = PricePerKg::find($id);

        if (!$price) {
            return response()->json([
                'success' => false,
                'message' => 'Tarif tidak ditemukan',
            ], 404);
        }

        DB::beginTransaction();
        try {
            $newStatus = !$price->is_active;
            $price->is_active = $newStatus;
            $price->save();

            // Log to history
            $action = $newStatus ? 'activated' : 'deactivated';
            $price->logChange($action, auth()->id(), 'Status tarif diubah');

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => $newStatus ? 'Tarif berhasil diaktifkan' : 'Tarif berhasil dinonaktifkan',
                'data' => $price,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengubah status tarif',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Delete price
     */
    public function destroy($id)
    {
        $price = PricePerKg::find($id);

        if (!$price) {
            return response()->json([
                'success' => false,
                'message' => 'Tarif tidak ditemukan',
            ], 404);
        }

        DB::beginTransaction();
        try {
            // Log to history before delete
            $price->logChange('deleted', auth()->id(), 'Tarif dihapus');

            $price->delete();

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Tarif berhasil dihapus',
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Gagal menghapus tarif',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get price history
     */
    public function history($id)
    {
        $price = PricePerKg::with('history.changedByUser')->find($id);

        if (!$price) {
            return response()->json([
                'success' => false,
                'message' => 'Tarif tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $price->history()->orderBy('changed_at', 'desc')->get(),
        ]);
    }

    /**
     * Calculate price based on weight
     */
    public function calculatePrice(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'service_type' => 'required|in:antar_barang,antar_penumpang',
            'ride_type' => 'required|in:motor,mobil,barang,titip_barang',
            'bagasi_capacity' => 'nullable|integer|in:5,10,20',
            'weight' => 'required|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $bagasiCapacity = $request->service_type === 'antar_barang' ? $request->bagasi_capacity : null;
        $price = PricePerKg::getActivePrice($request->service_type, $request->ride_type, $bagasiCapacity);

        if (!$price) {
            return response()->json([
                'success' => false,
                'message' => 'Tarif tidak ditemukan untuk kombinasi layanan, jenis tebengan, dan kapasitas bagasi ini',
            ], 404);
        }

        $totalPrice = $price->calculatePrice($request->weight);

        return response()->json([
            'success' => true,
            'data' => [
                'weight' => $request->weight,
                'rate_per_kg' => $price->rate_per_kg,
                'min_charge' => $price->min_charge,
                'calculated_price' => $request->weight * $price->rate_per_kg,
                'final_price' => $totalPrice,
            ],
        ]);
    }
}
