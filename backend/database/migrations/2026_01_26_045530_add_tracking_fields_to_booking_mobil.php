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
        Schema::table('booking_mobil', function (Blueprint $table) {
            // Add tracking fields similar to booking_motor
            if (!Schema::hasColumn('booking_mobil', 'scheduled_at')) {
                $table->dateTime('scheduled_at')->nullable()->after('meta');
            }
            if (!Schema::hasColumn('booking_mobil', 'driver_id')) {
                $table->unsignedBigInteger('driver_id')->nullable()->after('scheduled_at');
            }
            if (!Schema::hasColumn('booking_mobil', 'last_lat')) {
                $table->decimal('last_lat', 10, 7)->nullable()->after('driver_id');
            }
            if (!Schema::hasColumn('booking_mobil', 'last_lng')) {
                $table->decimal('last_lng', 10, 7)->nullable()->after('last_lat');
            }
            if (!Schema::hasColumn('booking_mobil', 'last_location_at')) {
                $table->dateTime('last_location_at')->nullable()->after('last_lng');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('booking_mobil', function (Blueprint $table) {
            if (Schema::hasColumn('booking_mobil', 'last_location_at')) {
                $table->dropColumn('last_location_at');
            }
            if (Schema::hasColumn('booking_mobil', 'last_lng')) {
                $table->dropColumn('last_lng');
            }
            if (Schema::hasColumn('booking_mobil', 'last_lat')) {
                $table->dropColumn('last_lat');
            }
            if (Schema::hasColumn('booking_mobil', 'driver_id')) {
                $table->dropColumn('driver_id');
            }
            if (Schema::hasColumn('booking_mobil', 'scheduled_at')) {
                $table->dropColumn('scheduled_at');
            }
        });
    }
};
