<?php

namespace App\Services;

use App\Models\User;
use App\Models\PointHistory;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PointRewardService
{
    /**
     * Point rewards based on booking type
     */
    const POINTS = [
        'motor' => 15,
        'mobil' => 25,
        'barang' => 20,
        'titip' => 18,
    ];

    /**
     * Award points to user for completed booking
     * 
     * @param int $userId
     * @param string $bookingType (motor, mobil, barang, titip)
     * @param int $bookingId
     * @return bool
     */
    public static function awardPointsForBooking($userId, $bookingType, $bookingId)
    {
        try {
            DB::beginTransaction();

            $points = self::POINTS[$bookingType] ?? 0;
            
            if ($points <= 0) {
                Log::warning("Invalid booking type for points: {$bookingType}");
                return false;
            }

            // Get user
            $user = User::find($userId);
            if (!$user) {
                Log::error("User not found: {$userId}");
                DB::rollBack();
                return false;
            }

            // Check if points already awarded for this booking
            $existingHistory = PointHistory::where('user_id', $userId)
                ->where('source', "booking_{$bookingType}")
                ->where('source_id', $bookingId)
                ->first();

            if ($existingHistory) {
                Log::info("Points already awarded for booking {$bookingId}");
                DB::rollBack();
                return false;
            }

            // Add points to user
            $user->reward_points = ($user->reward_points ?? 0) + $points;
            $user->save();

            // Create point history
            PointHistory::create([
                'user_id' => $userId,
                'points' => $points,
                'type' => 'earned',
                'source' => "booking_{$bookingType}",
                'source_id' => $bookingId,
                'description' => "Reward point dari penyelesaian nebeng {$bookingType}",
            ]);

            DB::commit();

            Log::info("Points awarded", [
                'user_id' => $userId,
                'booking_type' => $bookingType,
                'booking_id' => $bookingId,
                'points' => $points,
                'new_total' => $user->reward_points,
            ]);

            return true;

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("Error awarding points: " . $e->getMessage(), [
                'user_id' => $userId,
                'booking_type' => $bookingType,
                'booking_id' => $bookingId,
            ]);
            return false;
        }
    }

    /**
     * Get point value for booking type
     * 
     * @param string $bookingType
     * @return int
     */
    public static function getPointsForType($bookingType)
    {
        return self::POINTS[$bookingType] ?? 0;
    }

    /**
     * Get user's point history
     * 
     * @param int $userId
     * @return \Illuminate\Database\Eloquent\Collection
     */
    public static function getUserPointHistory($userId)
    {
        return PointHistory::where('user_id', $userId)
            ->orderBy('created_at', 'desc')
            ->get();
    }
}
