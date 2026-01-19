<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Reward;
use App\Models\RewardRedemption;
use App\Models\ApiToken;
use Carbon\Carbon;

class RewardController extends Controller
{
    // Public list of available rewards
    public function index()
    {
        $rewards = Reward::orderBy('id', 'desc')->get();
        return response()->json(['success' => true, 'data' => $rewards]);
    }

    // Authenticated: user's redemption history
    public function myRedemptions(Request $request)
    {
        $user = $this->getUserFromBearer($request);
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $list = RewardRedemption::where('user_id', $user->id)->with('reward')->orderBy('created_at', 'desc')->get();
        return response()->json(['success' => true, 'data' => $list]);
    }

    // Redeem a reward
    public function redeem(Request $request, $id)
    {
        $user = $this->getUserFromBearer($request);
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $reward = Reward::find($id);
        if (!$reward) {
            return response()->json(['success' => false, 'message' => 'Reward not found'], 404);
        }

        if ($reward->stock <= 0) {
            return response()->json(['success' => false, 'message' => 'Reward out of stock'], 400);
        }

        if ($user->reward_points < $reward->points_cost) {
            return response()->json(['success' => false, 'message' => 'Insufficient points'], 400);
        }

        // perform redemption in transaction
        \DB::beginTransaction();
        try {
            // decrement user points and reward stock
            $user->reward_points = max(0, $user->reward_points - $reward->points_cost);
            $user->save();

            $reward->stock = max(0, $reward->stock - 1);
            $reward->save();

            $redemption = RewardRedemption::create([
                'user_id' => $user->id,
                'reward_id' => $reward->id,
                'points_spent' => $reward->points_cost,
                'status' => 'pending',
                'metadata' => $request->only(['note', 'shipping_address']),
            ]);

            \DB::commit();
            return response()->json(['success' => true, 'data' => $redemption]);
        } catch (\Exception $e) {
            \DB::rollBack();
            return response()->json(['success' => false, 'message' => 'Failed to redeem reward', 'error' => $e->getMessage()], 500);
        }
    }

    // Helper to resolve user from Bearer token using ApiToken
    protected function getUserFromBearer(Request $request)
    {
        $header = $request->header('Authorization');
        if (!$header) return null;
        if (!str_starts_with($header, 'Bearer ')) return null;
        $token = trim(substr($header, 7));
        if (!$token) return null;
        $hashed = hash('sha256', $token);
        $apiToken = ApiToken::where('token', $hashed)->where('expires_at', '>', Carbon::now())->first();
        if (!$apiToken) return null;
        return $apiToken->user;
    }
}
