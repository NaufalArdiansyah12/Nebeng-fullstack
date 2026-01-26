<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    // =========================
    // TOTAL PENDAPATAN
    // =========================
    public function getPendapatan()
    {
        try {
            $pendapatan = DB::table('payments')
                ->where('status', 'paid')
                ->sum('total_amount');

            return response()->json([
                'pendapatan' => $pendapatan ?? 0
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'gagal mengambil data',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // =========================
    // CHART PENDAPATAN PER BULAN
    // =========================
    public function getPendapatanChart()
    {
        try {
            $data = DB::table('payments')
                ->selectRaw("
                    MONTH(paid_at) as month,
                    DATE_FORMAT(paid_at, '%b') as month_name,
                    SUM(total_amount) as total
                ")
                ->where('status', 'paid')
                ->groupByRaw('MONTH(paid_at), DATE_FORMAT(paid_at, "%b")')
                ->orderByRaw('MONTH(paid_at)')
                ->get();

            return response()->json($data);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'gagal mengambil data chart',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
