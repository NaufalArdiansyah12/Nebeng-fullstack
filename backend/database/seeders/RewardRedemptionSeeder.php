<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Reward;
use App\Models\RewardRedemption;
use App\Models\User;

class RewardRedemptionSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $user = User::first();
        if (!$user) return;

        // top-up user points for testing
        $user->reward_points = max($user->reward_points ?? 0, 1000);
        $user->save();

        $reward = Reward::first();
        if (!$reward) return;

        // create a sample redemption
        RewardRedemption::create([
            'user_id' => $user->id,
            'reward_id' => $reward->id,
            'points_spent' => $reward->points_cost,
            'status' => 'completed',
            'metadata' => ['note' => 'Sample redemption from seeder'],
        ]);
    }
}
