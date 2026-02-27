<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\FinanceSetting;
use Illuminate\Support\Facades\Log;

class SettingsController extends Controller
{
    // GET /api/v1/finance/settings/fees
    public function getFees(Request $request)
    {
        try {
            $row = FinanceSetting::first();
            if (!$row) {
                // return defaults
                return response()->json([
                    'admin_fee' => 0,
                    'reschedule_fee' => 0,
                ]);
            }

            return response()->json([
                'admin_fee' => (float) $row->admin_fee,
                'reschedule_fee' => (float) $row->reschedule_fee,
            ]);
        } catch (\Exception $e) {
            Log::error('Get fees error: ' . $e->getMessage());
            return response()->json(['message' => 'gagal mengambil data'], 500);
        }
    }

    // PUT /api/v1/finance/settings/fees
    public function updateFees(Request $request)
    {
        $validated = $request->validate([
            'admin_fee' => 'required|numeric|min:0',
            'reschedule_fee' => 'required|numeric|min:0',
        ]);

        try {
            $row = FinanceSetting::first();
            if (!$row) {
                $row = FinanceSetting::create([
                    'admin_fee' => $validated['admin_fee'],
                    'reschedule_fee' => $validated['reschedule_fee'],
                ]);
            } else {
                $row->update([
                    'admin_fee' => $validated['admin_fee'],
                    'reschedule_fee' => $validated['reschedule_fee'],
                ]);
            }

            return response()->json(['success' => true, 'data' => [
                'admin_fee' => (float) $row->admin_fee,
                'reschedule_fee' => (float) $row->reschedule_fee,
            ]]);
        } catch (\Exception $e) {
            Log::error('Update fees error: ' . $e->getMessage());
            return response()->json(['message' => 'gagal menyimpan data'], 500);
        }
    }
}
