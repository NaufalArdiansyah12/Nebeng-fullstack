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
        // 1. Add assigned_location_id to users table for pos mitra
        Schema::table('users', function (Blueprint $table) {
            $table->unsignedBigInteger('assigned_location_id')->nullable()->after('role');
            $table->foreign('assigned_location_id')->references('id')->on('locations')->onDelete('set null');
        });

        // 2. Add conversation fields to tebengan_motor
        if (Schema::hasTable('tebengan_motor')) {
            Schema::table('tebengan_motor', function (Blueprint $table) {
                $table->string('origin_pos_conversation_id')->nullable()->after('status');
                $table->string('destination_pos_conversation_id')->nullable()->after('origin_pos_conversation_id');
            });
        }

        // 3. Add conversation fields to tebengan_mobil
        if (Schema::hasTable('tebengan_mobil')) {
            Schema::table('tebengan_mobil', function (Blueprint $table) {
                $table->string('origin_pos_conversation_id')->nullable()->after('status');
                $table->string('destination_pos_conversation_id')->nullable()->after('origin_pos_conversation_id');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Remove conversation fields from tebengan_mobil
        if (Schema::hasTable('tebengan_mobil')) {
            Schema::table('tebengan_mobil', function (Blueprint $table) {
                $table->dropColumn(['origin_pos_conversation_id', 'destination_pos_conversation_id']);
            });
        }

        // Remove conversation fields from tebengan_motor
        if (Schema::hasTable('tebengan_motor')) {
            Schema::table('tebengan_motor', function (Blueprint $table) {
                $table->dropColumn(['origin_pos_conversation_id', 'destination_pos_conversation_id']);
            });
        }

        // Remove assigned_location_id from users
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['assigned_location_id']);
            $table->dropColumn('assigned_location_id');
        });
    }
};
