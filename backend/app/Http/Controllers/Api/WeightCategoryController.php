<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Enums\WeightCategory;
use Illuminate\Http\Request;

class WeightCategoryController extends Controller
{
    /**
     * Get all available weight categories
     * 
     * @return \Illuminate\Http\JsonResponse
     */
    public function index()
    {
        return response()->json([
            'success' => true,
            'data' => WeightCategory::options(),
        ]);
    }
}
