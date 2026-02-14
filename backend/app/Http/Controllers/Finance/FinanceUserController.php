<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class FinanceUserController extends Controller
{
    /**
     * Get user count by role
     */
    public function countByRole()
    {
        $mitra = User::where('role', 'mitra')->count();
        $posmitra = User::where('role', 'pos_mitra')->count();
        $customer = User::where('role', 'customer')->count();

        return response()->json([
            'mitra' => $mitra,
            'posmitra' => $posmitra,
            'customer' => $customer,
            'total' => $mitra + $posmitra + $customer,
        ]);
    }

    /**
     * Get mitra users
     */
    public function getMitraUsers(Request $request)
    {
        $query = User::where('role', 'mitra');

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $users = $query->paginate($request->get('per_page', 10));

        return response()->json($users);
    }

    /**
     * Get mitra detail
     */
    public function getMitraDetail($id)
    {
        $user = User::where('role', 'mitra')->findOrFail($id);
        
        return response()->json($user);
    }

    /**
     * Get pos mitra users
     */
    public function getPosMitraUsers(Request $request)
    {
        $query = User::where('role', 'pos_mitra');

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $users = $query->paginate($request->get('per_page', 10));

        return response()->json($users);
    }

    /**
     * Get pos mitra detail
     */
    public function getPosMitraDetail($id)
    {
        $user = User::where('role', 'pos_mitra')->findOrFail($id);
        
        return response()->json($user);
    }

    /**
     * Login finance admin
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid credentials'
            ], 401);
        }

        // Check if user is finance admin
        if (!in_array($user->role, ['finance_admin', 'super_admin', 'admin'])) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized access'
            ], 403);
        }

        $token = $user->createToken('finance-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'user' => $user,
            'token' => $token
        ]);
    }

    /**
     * Get user by ID
     */
    public function getById($id)
    {
        $user = User::findOrFail($id);
        
        return response()->json($user);
    }

    /**
     * Get user profile
     */
    public function profile($id)
    {
        $user = User::findOrFail($id);
        
        return response()->json([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
            'phone' => $user->phone,
            'address' => $user->address,
            'profile_photo' => $user->profile_photo,
            'created_at' => $user->created_at,
            'updated_at' => $user->updated_at,
        ]);
    }

    /**
     * Update user profile
     */
    public function updateProfile(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,' . $id,
            'phone' => 'sometimes|string|max:20',
            'address' => 'sometimes|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $user->update($request->only([
            'name',
            'email',
            'phone',
            'address',
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully',
            'user' => $user
        ]);
    }

    /**
     * Update user account (password)
     */
    public function updateAccount(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'password' => 'required|string|min:6',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $user->update([
            'password' => Hash::make($request->password)
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Password updated successfully'
        ]);
    }

    /**
     * Upload profile image
     */
    public function uploadProfileImage(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'profile_image' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            // Delete old image if exists
            if ($user->profile_photo) {
                Storage::disk('public')->delete($user->profile_photo);
            }

            // Store new image
            $path = $request->file('profile_image')->store('profile-images', 'public');

            $user->update([
                'profile_photo' => $path
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Profile image uploaded successfully',
                'image_url' => Storage::url($path)
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to upload image: ' . $e->getMessage()
            ], 500);
        }
    }
}
