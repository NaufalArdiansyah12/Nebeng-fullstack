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
        Schema::table('booking_titip_barang', function (Blueprint $table) {
            DB::statement("ALTER TABLE booking_titip_barang MODIFY COLUMN status ENUM('pending', 'confirmed', 'paid', 'menuju_penjemputan', 'sudah_di_penjemputan', 'menuju_tujuan', 'sudah_sampai_tujuan', 'selesai', 'cancelled') DEFAULT 'pending'");
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('booking_titip_barang', function (Blueprint $table) {
            DB::statement("ALTER TABLE booking_titip_barang MODIFY COLUMN status ENUM('pending', 'confirmed', 'paid', 'in_progress', 'completed', 'cancelled') DEFAULT 'pending'");
        });
    }
};
