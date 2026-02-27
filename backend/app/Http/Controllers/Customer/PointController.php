<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Services\PointRewardService;
use Illuminate\Http\Request;

class PointController extends Controller
{
    /**
     * Get user's current points and history
     */
    public function index(Request $request)
    {
        $userId = $request->query('user_id');
        
        if (!$userId) {
            return response()->json([
                'success' => false,
                'message' => 'User ID required'
            ], 400);
        }

        $user = \App\Models\User::find($userId);
        
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found'
            ], 404);
        }

        $history = PointRewardService::getUserPointHistory($userId);

        return response()->json([
            'success' => true,
            'data' => [
                'current_points' => $user->reward_points ?? 0,
                'history' => $history,
                'point_values' => [
                    'motor' => PointRewardService::getPointsForType('motor'),
                    'mobil' => PointRewardService::getPointsForType('mobil'),
                    'barang' => PointRewardService::getPointsForType('barang'),
                    'titip' => PointRewardService::getPointsForType('titip'),
                ],
            ]
        ]);
    }

    /**
     * Get point values for each booking type
     */
    public function getPointValues()
    {
        return response()->json([
            'success' => true,
            'data' => [
                'motor' => [
                    'points' => PointRewardService::getPointsForType('motor'),
                    'name' => 'Nebeng Motor',
                    'description' => 'Setiap penggunaan fitur nebeng motor, point akan bertambah sebanyak 15 point',
                ],
                'mobil' => [
                    'points' => PointRewardService::getPointsForType('mobil'),
                    'name' => 'Nebeng Mobil',
                    'description' => 'Setiap penggunaan fitur nebeng mobil, point akan bertambah sebanyak 25 point',
                ],
                'barang' => [
                    'points' => PointRewardService::getPointsForType('barang'),
                    'name' => 'Nebeng Barang',
                    'description' => 'Setiap penggunaan fitur nebeng barang, point akan bertambah sebanyak 20 point',
                ],
                'titip' => [
                    'points' => PointRewardService::getPointsForType('titip'),
                    'name' => 'Titip Barang Transportasi Umum',
                    'description' => 'Setiap penggunaan fitur nebeng barang, point akan bertambah sebanyak 18 point',
                ],
            ]
        ]);
    }
}
