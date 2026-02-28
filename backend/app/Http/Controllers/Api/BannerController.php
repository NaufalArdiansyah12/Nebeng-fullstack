<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\BannerModel;

class BannerController extends Controller
{
    // GET /api/v1/banners?position=home
    public function index(Request $request)
    {
        $position = $request->query('position', 'home');
        $banners = BannerModel::where('position', $position)
            ->where('is_active', true)
            ->orderBy('order', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $banners,
        ]);
    }

    // Admin: create banner (simple, no auth enforcement here)
    public function store(Request $request)
    {
        $data = $request->only(['title', 'image_url', 'is_active', 'position', 'order']);
        $banner = BannerModel::create($data);
        return response()->json(['success' => true, 'data' => $banner]);
    }

    // Admin: update
    public function update(Request $request, $id)
    {
        $banner = BannerModel::findOrFail($id);
        $data = $request->only(['title', 'image_url', 'is_active', 'position', 'order']);
        $banner->update($data);
        return response()->json(['success' => true, 'data' => $banner]);
    }

    // Admin: delete
    public function destroy($id)
    {
        $banner = BannerModel::findOrFail($id);
        $banner->delete();
        return response()->json(['success' => true]);
    }
}
