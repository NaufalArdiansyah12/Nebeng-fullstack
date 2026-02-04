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
        Schema::table('kendaraan_mitra', function (Blueprint $table) {
            if (!Schema::hasColumn('kendaraan_mitra', 'foto_stnk')) {
                $table->string('foto_stnk')->nullable()->after('year');
            }
            if (!Schema::hasColumn('kendaraan_mitra', 'foto_kendaraan')) {
                $table->string('foto_kendaraan')->nullable()->after('foto_stnk');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('kendaraan_mitra', function (Blueprint $table) {
            if (Schema::hasColumn('kendaraan_mitra', 'foto_kendaraan')) {
                $table->dropColumn('foto_kendaraan');
            }
            if (Schema::hasColumn('kendaraan_mitra', 'foto_stnk')) {
                $table->dropColumn('foto_stnk');
            }
        });
    }
};
