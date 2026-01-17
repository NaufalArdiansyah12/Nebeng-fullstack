<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Customer user
        User::create([
            'name' => 'John Customer',
            'email' => 'customer@example.com',
            'role' => 'customer',
            'password' => Hash::make('password'),
        ]);

        // Mitra user
        User::create([
            'name' => 'Kamado Tanjiro',
            'email' => 'mitra@example.com',
            'role' => 'mitra',
            'password' => Hash::make('password'),
        ]);

        // Admin user
        User::create([
            'name' => 'Admin User',
            'email' => 'admin@example.com',
            'role' => 'admin',
            'password' => Hash::make('password'),
        ]);
    }
}
