<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('pricing_profiles', function (Blueprint $table) {
            // 3 kolom baru untuk menyimpan nominal harga per kategori berat
            $table->decimal('price_category_kecil', 12, 2)->default(0)->after('price_per_kg')->comment('Harga untuk kategori Kecil (0-5kg)');
            $table->decimal('price_category_sedang', 12, 2)->default(0)->after('price_category_kecil')->comment('Harga untuk kategori Sedang (5-10kg)');
            $table->decimal('price_category_besar', 12, 2)->default(0)->after('price_category_sedang')->comment('Harga untuk kategori Besar (10-20kg)');
        });
    }

    public function down(): void
    {
        Schema::table('pricing_profiles', function (Blueprint $table) {
            $table->dropColumn(['price_category_kecil', 'price_category_sedang', 'price_category_besar']);
        });
    }
};
