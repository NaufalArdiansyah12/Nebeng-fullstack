<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\TransportMode;
use App\Models\WeightCategory;
use App\Models\PricingProfile;
use App\Models\PricingRule;

class PricingConfigSeeder extends Seeder
{
    public function run(): void
    {
        $motor = TransportMode::where('slug', 'motor')->first();
        $mobil = TransportMode::where('slug', 'mobil')->first();
        $barang = TransportMode::where('slug', 'barang')->first();
        $titipBus = TransportMode::where('slug', 'titip-barang-bus')->first();
        $titipKereta = TransportMode::where('slug', 'titip-barang-kereta')->first();
        $titipPesawat = TransportMode::where('slug', 'titip-barang-pesawat')->first();

        $kecil = WeightCategory::where('slug', 'kecil')->first();
        $sedang = WeightCategory::where('slug', 'sedang')->first();
        $besar = WeightCategory::where('slug', 'besar')->first();

        // ========== MOTOR ==========
        if ($motor) {
            // Profile: Motor - Hanya Tebengan
            $motorTebengan = PricingProfile::updateOrCreate(
                ['transport_mode_id' => $motor->id, 'name' => 'Motor - Hanya Tebengan'],
                [
                    'description' => 'Konfigurasi harga untuk motor hanya tebengan',
                    'active' => true,
                    'base_price' => 5000,
                    'price_per_km' => 2000,
                    'price_per_kg' => 0,
                    'min_price' => 10000,
                ]
            );
            PricingRule::updateOrCreate(
                ['pricing_profile_id' => $motorTebengan->id, 'service_type' => 'hanya_tebengan'],
                ['weight_category_id' => null]
            );

            // Profile: Motor - Hanya Barang
            $motorBarang = PricingProfile::updateOrCreate(
                ['transport_mode_id' => $motor->id, 'name' => 'Motor - Hanya Barang'],
                [
                    'description' => 'Konfigurasi harga untuk motor hanya barang',
                    'active' => true,
                    'base_price' => 0,
                    'price_per_km' => 0,
                    'price_per_kg' => 0,
                ]
            );
            PricingRule::updateOrCreate(
                ['pricing_profile_id' => $motorBarang->id, 'weight_category_id' => $kecil->id, 'service_type' => 'hanya_barang'],
                ['price' => 2000]
            );
            PricingRule::updateOrCreate(
                ['pricing_profile_id' => $motorBarang->id, 'weight_category_id' => $sedang->id, 'service_type' => 'hanya_barang'],
                ['price' => 3000]
            );
            PricingRule::updateOrCreate(
                ['pricing_profile_id' => $motorBarang->id, 'weight_category_id' => $besar->id, 'service_type' => 'hanya_barang'],
                ['price' => 4000]
            );

            // Profile: Motor - Tebengan + Barang
            $motorKeduanya = PricingProfile::updateOrCreate(
                ['transport_mode_id' => $motor->id, 'name' => 'Motor - Tebengan dan Barang'],
                [
                    'description' => 'Konfigurasi harga untuk motor tebengan dan barang',
                    'active' => true,
                    'base_price' => 5000,
                    'price_per_km' => 2000,
                    'price_per_kg' => 0,
                ]
            );
            PricingRule::updateOrCreate(
                ['pricing_profile_id' => $motorKeduanya->id, 'weight_category_id' => $kecil->id, 'service_type' => 'tebengan_dan_barang'],
                ['price' => 1500]
            );
            PricingRule::updateOrCreate(
                ['pricing_profile_id' => $motorKeduanya->id, 'weight_category_id' => $sedang->id, 'service_type' => 'tebengan_dan_barang'],
                ['price' => 2500]
            );
            PricingRule::updateOrCreate(
                ['pricing_profile_id' => $motorKeduanya->id, 'weight_category_id' => $besar->id, 'service_type' => 'tebengan_dan_barang'],
                ['price' => 3500]
            );
        }

        // ========== MOBIL ==========
        if ($mobil) {
            // Profile: Mobil - Hanya Tebengan
            $mobilTebengan = PricingProfile::updateOrCreate(
                ['transport_mode_id' => $mobil->id, 'name' => 'Mobil - Hanya Tebengan'],
                [
                    'description' => 'Konfigurasi harga untuk mobil hanya tebengan',
                    'active' => true,
                    'base_price' => 10000,
                    'price_per_km' => 3000,
                    'price_per_kg' => 0,
                    'min_price' => 20000,
                ]
            );
            PricingRule::updateOrCreate(
                ['pricing_profile_id' => $mobilTebengan->id, 'service_type' => 'hanya_tebengan'],
                ['weight_category_id' => null]
            );

            // Profile: Mobil - Hanya Barang
            $mobilBarang = PricingProfile::updateOrCreate(
                ['transport_mode_id' => $mobil->id, 'name' => 'Mobil - Hanya Barang'],
                [
                    'description' => 'Konfigurasi harga untuk mobil hanya barang',
                    'active' => true,
                    'base_price' => 0,
                    'price_per_km' => 0,
                    'price_per_kg' => 0,
                ]
            );
            PricingRule::updateOrCreate(
                ['pricing_profile_id' => $mobilBarang->id, 'weight_category_id' => $kecil->id, 'service_type' => 'hanya_barang'],
                ['price' => 3000]
            );
            PricingRule::updateOrCreate(
                ['pricing_profile_id' => $mobilBarang->id, 'weight_category_id' => $sedang->id, 'service_type' => 'hanya_barang'],
                ['price' => 4500]
            );
            PricingRule::updateOrCreate(
                ['pricing_profile_id' => $mobilBarang->id, 'weight_category_id' => $besar->id, 'service_type' => 'hanya_barang'],
                ['price' => 6000]
            );

            // Profile: Mobil - Tebengan + Barang
            $mobilKeduanya = PricingProfile::updateOrCreate(
                ['transport_mode_id' => $mobil->id, 'name' => 'Mobil - Tebengan dan Barang'],
                [
                    'description' => 'Konfigurasi harga untuk mobil tebengan dan barang',
                    'active' => true,
                    'base_price' => 10000,
                    'price_per_km' => 3000,
                    'price_per_kg' => 0,
                ]
            );
            PricingRule::updateOrCreate(
                ['pricing_profile_id' => $mobilKeduanya->id, 'weight_category_id' => $kecil->id, 'service_type' => 'tebengan_dan_barang'],
                ['price' => 2000]
            );
            PricingRule::updateOrCreate(
                ['pricing_profile_id' => $mobilKeduanya->id, 'weight_category_id' => $sedang->id, 'service_type' => 'tebengan_dan_barang'],
                ['price' => 3500]
            );
            PricingRule::updateOrCreate(
                ['pricing_profile_id' => $mobilKeduanya->id, 'weight_category_id' => $besar->id, 'service_type' => 'tebengan_dan_barang'],
                ['price' => 5000]
            );
        }

        // ========== BARANG ==========
        if ($barang) {
            $barangProfile = PricingProfile::updateOrCreate(
                ['transport_mode_id' => $barang->id, 'name' => 'Tebengan Barang'],
                [
                    'description' => 'Konfigurasi harga untuk tebengan barang',
                    'active' => true,
                    'base_price' => 8000,
                    'price_per_km' => 0,
                    'price_per_kg' => 0,
                    'price_category_kecil' => 2500,
                    'price_category_sedang' => 3500,
                    'price_category_besar' => 5000,
                ]
            );
        }

        // ========== TITIP BARANG ==========
        foreach ([$titipBus, $titipKereta, $titipPesawat] as $transport) {
            if (!$transport) continue;

            $basePrice = match($transport->slug) {
                'titip-barang-bus' => 15000,
                'titip-barang-kereta' => 20000,
                'titip-barang-pesawat' => 50000,
                default => 10000,
            };

            $titipProfile = PricingProfile::updateOrCreate(
                ['transport_mode_id' => $transport->id, 'name' => $transport->name],
                [
                    'description' => 'Konfigurasi harga untuk ' . $transport->name,
                    'active' => true,
                    'base_price' => $basePrice,
                    'price_per_km' => 0,
                    'price_per_kg' => 0,
                    'price_category_kecil' => 3000,
                    'price_category_sedang' => 5000,
                    'price_category_besar' => 7000,
                ]
            );
        }

        $this->command->info('Pricing configuration seeded successfully!');
    }
}
