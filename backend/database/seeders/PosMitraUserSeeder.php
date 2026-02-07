<?php

namespace Database\Seeders;

use App\Models\PosMitraUser;
use App\Models\Location;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class PosMitraUserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Get some locations
        $locations = Location::take(3)->get();

        if ($locations->isEmpty()) {
            $this->command->warn('No locations found. Please run LocationSeeder first.');
            return;
        }

        // Create PosMitra users for each location
        foreach ($locations as $index => $location) {
            PosMitraUser::create([
                'name' => 'PosMitra ' . $location->name,
                'email' => 'posmitra' . ($index + 1) . '@example.com',
                'phone' => '0812' . str_pad($index + 1, 8, '0', STR_PAD_LEFT),
                'phone_verified' => true,
                'phone_verified_at' => now(),
                'password' => Hash::make('password'),
                'balance' => 0,
                'pin' => '123456',
                'location_id' => $location->id,
            ]);

            $this->command->info("Created PosMitra user for location: {$location->name}");
        }
    }
}
