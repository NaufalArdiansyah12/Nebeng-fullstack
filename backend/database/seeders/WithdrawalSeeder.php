<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\VerifikasiBankMitra;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class WithdrawalSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Update mitra user with balance and PIN
        $mitra = User::where('email', 'mitra@example.com')->first();
        
        if ($mitra) {
            $mitra->update([
                'balance' => 200000,
                'pin' => Hash::make('123456'), // Default PIN for testing
            ]);

            $this->command->info('✅ Mitra balance and PIN updated');

            // Create bank verification if not exists
            $bankVerification = VerifikasiBankMitra::where('user_id', $mitra->id)->first();
            
            if (!$bankVerification) {
                VerifikasiBankMitra::create([
                    'user_id' => $mitra->id,
                    'bank_name' => 'BRI',
                    'bank_account_number' => '129519285192518417',
                    'bank_account_name' => 'Kamado Tanjiro',
                    'status' => 'approved',
                    'verified_at' => now(),
                ]);

                $this->command->info('✅ Bank verification created for mitra');
            } else {
                $this->command->info('ℹ️  Bank verification already exists');
            }
        } else {
            $this->command->warn('⚠️  Mitra user not found. Please run UserSeeder first.');
        }
    }
}
