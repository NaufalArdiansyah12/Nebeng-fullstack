<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Pindahkan semua user dengan role 'posmitra' ke table posmitra_users
        $posMitraUsers = DB::table('users')
            ->where('role', 'posmitra')
            ->get();

        foreach ($posMitraUsers as $user) {
            // Skip jika phone null (karena kolom phone di posmitra_users tidak nullable)
            if (empty($user->phone)) {
                continue;
            }
            
            DB::table('posmitra_users')->insert([
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'phone_verified' => $user->phone_verified ?? false,
                'phone_verified_at' => $user->phone_verified_at,
                'password' => $user->password,
                'profile_photo' => $user->profile_photo,
                'balance' => $user->balance ?? 0,
                'pin' => $user->pin,
                'fcm_token' => $user->fcm_token,
                'location_id' => $user->assigned_location_id,
                'remember_token' => $user->remember_token,
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ]);
        }

        // Hapus user dengan role posmitra dari table users
        DB::table('users')->where('role', 'posmitra')->delete();
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Kembalikan data dari posmitra_users ke users
        $posMitraUsers = DB::table('posmitra_users')->get();

        foreach ($posMitraUsers as $user) {
            DB::table('users')->insert([
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'phone_verified' => $user->phone_verified ?? false,
                'phone_verified_at' => $user->phone_verified_at,
                'password' => $user->password,
                'role' => 'posmitra',
                'address' => $user->address,
                'profile_photo' => $user->profile_photo,
                'balance' => $user->balance ?? 0,
                'pin' => $user->pin,
                'reward_points' => $user->reward_points ?? 0,
                'fcm_token' => $user->fcm_token,
                'assigned_location_id' => $user->location_id,
                'remember_token' => $user->remember_token,
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ]);
        }

        // Hapus data dari posmitra_users
        DB::table('posmitra_users')->truncate();
    }
};
