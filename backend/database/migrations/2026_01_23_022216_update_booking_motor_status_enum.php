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
        // Update booking_motor status enum to include 'in_progress', 'completed', 'scheduled'
        \DB::statement("ALTER TABLE booking_motor MODIFY COLUMN status ENUM('pending', 'paid', 'confirmed', 'in_progress', 'completed', 'cancelled', 'scheduled') NOT NULL DEFAULT 'pending'");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Revert to original enum values
        \DB::statement("ALTER TABLE booking_motor MODIFY COLUMN status ENUM('pending', 'paid', 'cancelled') NOT NULL DEFAULT 'pending'");
    }
};
