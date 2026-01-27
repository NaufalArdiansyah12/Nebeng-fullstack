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
        Schema::table('booking_barang', function (Blueprint $table) {
            $table->timestamp('scheduled_at')->nullable()->after('status');
            $table->unsignedBigInteger('driver_id')->nullable()->after('scheduled_at');
            $table->decimal('last_lat', 10, 7)->nullable()->after('driver_id');
            $table->decimal('last_lng', 10, 7)->nullable()->after('last_lat');
            $table->timestamp('last_location_at')->nullable()->after('last_lng');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('booking_barang', function (Blueprint $table) {
            $table->dropColumn(['scheduled_at', 'driver_id', 'last_lat', 'last_lng', 'last_location_at']);
        });
    }
};
