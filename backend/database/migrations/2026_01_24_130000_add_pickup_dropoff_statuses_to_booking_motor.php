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
        // Add pickup/dropoff lifecycle statuses to booking_motor.status enum (removed in_progress)
        \DB::statement("ALTER TABLE booking_motor MODIFY COLUMN status ENUM('pending', 'paid', 'confirmed', 'menuju_penjemputan', 'sudah_di_penjemputan', 'menuju_tujuan', 'sudah_sampai_tujuan', 'completed', 'cancelled', 'scheduled') NOT NULL DEFAULT 'pending'");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Revert to previous enum values (without the pickup/dropoff statuses)
        \DB::statement("ALTER TABLE booking_motor MODIFY COLUMN status ENUM('pending', 'paid', 'confirmed', 'completed', 'cancelled', 'scheduled') NOT NULL DEFAULT 'pending'");
    }
};
