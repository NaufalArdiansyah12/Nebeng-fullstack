<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    // =========================
    // TOTAL PENDAPATAN
    // =========================
    public function getPendapatan(Request $request)
    {
        try {
            $query = DB::table('payments')
                ->where('status', 'paid');

            // Filter by month if provided (format: YYYY-MM)
            if ($request->has('month')) {
                $month = $request->month;
                $query->whereRaw("DATE_FORMAT(paid_at, '%Y-%m') = ?", [$month]);
            }

            $pendapatan = $query->sum('total_amount');

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
    public function getPendapatanChart(Request $request)
    {
        try {
            $query = DB::table('payments')
                ->selectRaw("
                    DATE_FORMAT(paid_at, '%b') as month_name,
                    DATE_FORMAT(paid_at, '%Y-%m') as month_key,
                    SUM(total_amount) as total
                ")
                ->where('status', 'paid');

            // If month filter provided, show data from 12 months before up to selected month
            if ($request->has('month')) {
                $selectedMonth = $request->month; // format: YYYY-MM
                list($year, $month) = explode('-', $selectedMonth);
                
                // Calculate 11 months before selected month
                $startDate = date('Y-m-01', strtotime("-11 months", strtotime("$selectedMonth-01")));
                $endDate = date('Y-m-t', strtotime("$selectedMonth-01"));
                
                $query->whereBetween('paid_at', [$startDate, $endDate]);
            }

            $data = $query
                ->groupByRaw('DATE_FORMAT(paid_at, "%Y-%m"), DATE_FORMAT(paid_at, "%b")')
                ->orderByRaw('DATE_FORMAT(paid_at, "%Y-%m")')
                ->get();

            // Format response to match frontend expectation
            $formattedData = $data->map(function($item) {
                return [
                    'month' => $item->month_name,
                    'value' => (float) $item->total
                ];
            });

            return response()->json($formattedData);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'gagal mengambil data chart',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
