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
        // Update status enum to match booking_motor
        DB::statement("ALTER TABLE booking_mobil MODIFY COLUMN status ENUM('pending', 'confirmed', 'paid', 'menuju_penjemputan', 'sudah_di_penjemputan', 'menuju_tujuan', 'sudah_sampai_tujuan', 'selesai', 'cancelled') DEFAULT 'pending'");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Revert to original enum
        DB::statement("ALTER TABLE booking_mobil MODIFY COLUMN status ENUM('pending', 'paid', 'cancelled') DEFAULT 'pending'");
    }
};
