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
        if (Schema::hasTable('booking_motor')) {
            Schema::table('booking_motor', function (Blueprint $table) {
                if (!Schema::hasColumn('booking_motor', 'pickup_lat')) {
                    $table->decimal('pickup_lat', 10, 7)->nullable()->after('meta');
                }
                if (!Schema::hasColumn('booking_motor', 'pickup_lng')) {
                    $table->decimal('pickup_lng', 10, 7)->nullable()->after('pickup_lat');
                }
                if (!Schema::hasColumn('booking_motor', 'scheduled_at')) {
                    $table->dateTime('scheduled_at')->nullable()->after('pickup_lng');
                }
                if (!Schema::hasColumn('booking_motor', 'driver_id')) {
                    $table->unsignedBigInteger('driver_id')->nullable()->after('scheduled_at');
                }
                if (!Schema::hasColumn('booking_motor', 'waiting_start_at')) {
                    $table->dateTime('waiting_start_at')->nullable()->after('driver_id');
                }
                if (!Schema::hasColumn('booking_motor', 'arrived_at')) {
                    $table->dateTime('arrived_at')->nullable()->after('waiting_start_at');
                }
                if (!Schema::hasColumn('booking_motor', 'last_lat')) {
                    $table->decimal('last_lat', 10, 7)->nullable()->after('arrived_at');
                }
                if (!Schema::hasColumn('booking_motor', 'last_lng')) {
                    $table->decimal('last_lng', 10, 7)->nullable()->after('last_lat');
                }
                if (!Schema::hasColumn('booking_motor', 'last_location_at')) {
                    $table->dateTime('last_location_at')->nullable()->after('last_lng');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('booking_motor')) {
            Schema::table('booking_motor', function (Blueprint $table) {
                if (Schema::hasColumn('booking_motor', 'last_location_at')) {
                    $table->dropColumn('last_location_at');
                }
                if (Schema::hasColumn('booking_motor', 'last_lng')) {
                    $table->dropColumn('last_lng');
                }
                if (Schema::hasColumn('booking_motor', 'last_lat')) {
                    $table->dropColumn('last_lat');
                }
                if (Schema::hasColumn('booking_motor', 'arrived_at')) {
                    $table->dropColumn('arrived_at');
                }
                if (Schema::hasColumn('booking_motor', 'waiting_start_at')) {
                    $table->dropColumn('waiting_start_at');
                }
                if (Schema::hasColumn('booking_motor', 'driver_id')) {
                    $table->dropColumn('driver_id');
                }
                if (Schema::hasColumn('booking_motor', 'scheduled_at')) {
                    $table->dropColumn('scheduled_at');
                }
                if (Schema::hasColumn('booking_motor', 'pickup_lng')) {
                    $table->dropColumn('pickup_lng');
                }
                if (Schema::hasColumn('booking_motor', 'pickup_lat')) {
                    $table->dropColumn('pickup_lat');
                }
            });
        }
    }
};
