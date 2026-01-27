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
        Schema::table('booking_motor', function (Blueprint $table) {
            // Drop pickup coordinates - now using ride->originLocation coordinates
            if (Schema::hasColumn('booking_motor', 'pickup_lat')) {
                $table->dropColumn('pickup_lat');
            }
            if (Schema::hasColumn('booking_motor', 'pickup_lng')) {
                $table->dropColumn('pickup_lng');
            }
            
            // Drop waiting_start_at and arrived_at - not used in current flow
            if (Schema::hasColumn('booking_motor', 'waiting_start_at')) {
                $table->dropColumn('waiting_start_at');
            }
            if (Schema::hasColumn('booking_motor', 'arrived_at')) {
                $table->dropColumn('arrived_at');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('booking_motor', function (Blueprint $table) {
            // Restore columns in reverse order
            $table->dateTime('arrived_at')->nullable()->after('driver_id');
            $table->dateTime('waiting_start_at')->nullable()->after('driver_id');
            $table->decimal('pickup_lng', 10, 7)->nullable()->after('meta');
            $table->decimal('pickup_lat', 10, 7)->nullable()->after('meta');
        });
    }
};
