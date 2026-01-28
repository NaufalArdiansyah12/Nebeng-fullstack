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
        // Add cancellation_reason to booking_motor
        Schema::table('booking_motor', function (Blueprint $table) {
            $table->string('cancellation_reason')->nullable()->after('status');
        });

        // Add cancellation_reason to booking_mobil
        Schema::table('booking_mobil', function (Blueprint $table) {
            $table->string('cancellation_reason')->nullable()->after('status');
        });

        // Add cancellation_reason to booking_barang
        Schema::table('booking_barang', function (Blueprint $table) {
            $table->string('cancellation_reason')->nullable()->after('status');
        });

        // Add cancellation_reason to booking_titip_barang
        Schema::table('booking_titip_barang', function (Blueprint $table) {
            $table->string('cancellation_reason')->nullable()->after('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Remove cancellation_reason from booking_motor
        Schema::table('booking_motor', function (Blueprint $table) {
            $table->dropColumn('cancellation_reason');
        });

        // Remove cancellation_reason from booking_mobil
        Schema::table('booking_mobil', function (Blueprint $table) {
            $table->dropColumn('cancellation_reason');
        });

        // Remove cancellation_reason from booking_barang
        Schema::table('booking_barang', function (Blueprint $table) {
            $table->dropColumn('cancellation_reason');
        });

        // Remove cancellation_reason from booking_titip_barang
        Schema::table('booking_titip_barang', function (Blueprint $table) {
            $table->dropColumn('cancellation_reason');
        });
    }
};
