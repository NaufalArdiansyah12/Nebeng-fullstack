<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('price_per_kg', function (Blueprint $table) {
            $table->integer('bagasi_capacity')->nullable()->after('ride_type')
                ->comment('Kapasitas bagasi: 5, 10, atau 20 kg (hanya untuk service_type=antar_barang)');
        });

        Schema::table('price_per_kg_history', function (Blueprint $table) {
            $table->integer('bagasi_capacity')->nullable()->after('ride_type')
                ->comment('Kapasitas bagasi: 5, 10, atau 20 kg (hanya untuk service_type=antar_barang)');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('price_per_kg', function (Blueprint $table) {
            $table->dropColumn('bagasi_capacity');
        });

        Schema::table('price_per_kg_history', function (Blueprint $table) {
            $table->dropColumn('bagasi_capacity');
        });
    }
};
