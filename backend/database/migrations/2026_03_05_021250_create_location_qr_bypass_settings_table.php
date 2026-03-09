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
        Schema::create('location_qr_bypass_settings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('location_id')->constrained('locations')->onDelete('cascade');
            $table->boolean('qr_bypass_enabled')->default(false);
            $table->text('notes')->nullable();
            $table->timestamps();

            // Ensure one setting per location
            $table->unique('location_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('location_qr_bypass_settings');
    }
};
