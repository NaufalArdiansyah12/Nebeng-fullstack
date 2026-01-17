<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreLocationRequest;
use App\Http\Requests\UpdateLocationRequest;
use App\Models\Location;
use Illuminate\Http\Request;

class LocationController extends Controller
{
    // Public: list all locations
    public function index()
    {
        $locations = Location::orderBy('name')->get();
        return response()->json(['success' => true, 'data' => $locations]);
    }

    // Public: show single location
    public function show($id)
    {
        $location = Location::find($id);
        if (!$location) {
            return response()->json(['success' => false, 'message' => 'Location not found'], 404);
        }
        return response()->json(['success' => true, 'data' => $location]);
    }

    // Protected: create location (admin)
    public function store(StoreLocationRequest $request)
    {
        $validated = $request->validated();
        $location = Location::create(array_merge($validated, [
            'created_by_role' => $request->user() ? ($request->user()->role ?? 'admin') : 'admin',
        ]));
        return response()->json(['success' => true, 'data' => $location], 201);
    }

    // Protected: update location (admin)
    public function update(UpdateLocationRequest $request, $id)
    {
        $location = Location::find($id);
        if (!$location) {
            return response()->json(['success' => false, 'message' => 'Location not found'], 404);
        }
        $location->update($request->validated());
        return response()->json(['success' => true, 'data' => $location]);
    }

    // Protected: delete location (admin)
    public function destroy(Request $request, $id)
    {
        $location = Location::find($id);
        if (!$location) {
            return response()->json(['success' => false, 'message' => 'Location not found'], 404);
        }
        $location->delete();
        return response()->json(['success' => true, 'message' => 'Location deleted']);
    }
}
