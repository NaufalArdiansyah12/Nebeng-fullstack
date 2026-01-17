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
        Schema::table('reschedule_requests', function (Blueprint $table) {
            // remove existing foreign keys to allow polymorphic use
            try {
                $table->dropForeign(['booking_id']);
            } catch (\Exception $e) {
                // ignore if does not exist
            }

            try {
                $table->dropForeign(['requested_ride_id']);
            } catch (\Exception $e) {
                // ignore if does not exist
            }

            // add polymorphic columns
            if (!Schema::hasColumn('reschedule_requests', 'booking_type')) {
                $table->string('booking_type')->default('mobil')->after('booking_id');
            }

            if (!Schema::hasColumn('reschedule_requests', 'requested_target_type')) {
                $table->string('requested_target_type')->nullable()->after('requested_ride_id');
            }

            if (!Schema::hasColumn('reschedule_requests', 'requested_target_id')) {
                $table->unsignedBigInteger('requested_target_id')->nullable()->after('requested_target_type');
            }

            // add useful indexes for polymorphic lookup
            $table->index(['booking_type', 'booking_id'], 'reschedule_booking_type_booking_id_idx');
            $table->index(['requested_target_type', 'requested_target_id'], 'reschedule_target_type_id_idx');

            // optionally drop the old requested_ride_id column if present
            if (Schema::hasColumn('reschedule_requests', 'requested_ride_id')) {
                try {
                    $table->dropColumn('requested_ride_id');
                } catch (\Exception $e) {
                    // ignore drop errors
                }
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('reschedule_requests', function (Blueprint $table) {
            if (Schema::hasColumn('reschedule_requests', 'requested_target_id')) {
                $table->dropIndex('reschedule_target_type_id_idx');
                $table->dropColumn('requested_target_id');
            }
            if (Schema::hasColumn('reschedule_requests', 'requested_target_type')) {
                $table->dropColumn('requested_target_type');
            }
            if (Schema::hasColumn('reschedule_requests', 'booking_type')) {
                $table->dropIndex('reschedule_booking_type_booking_id_idx');
                $table->dropColumn('booking_type');
            }

            // We won't restore dropped foreign keys automatically
        });
    }
};
