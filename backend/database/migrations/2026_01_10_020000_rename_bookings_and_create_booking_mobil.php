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
        // Rename existing bookings table to booking_motor
        if (Schema::hasTable('bookings')) {
            Schema::rename('bookings', 'booking_motor');
        }

        // If payments table has foreign key to bookings, adjust to booking_motor
        if (Schema::hasTable('payments')) {
            Schema::table('payments', function (Blueprint $table) {
                // Drop foreign if exists
                try {
                    $table->dropForeign(['booking_id']);
                } catch (\Exception $e) {
                    // ignore
                }
            });

            Schema::table('payments', function (Blueprint $table) {
                if (!Schema::hasColumn('payments', 'booking_id')) return;
                $table->foreign('booking_id')->references('id')->on('booking_motor')->onDelete('set null');
            });
        }

        // Create booking_mobil table for mobil bookings
        if (!Schema::hasTable('booking_mobil')) {
            Schema::create('booking_mobil', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('ride_id');
                $table->unsignedBigInteger('user_id');
                $table->string('booking_number')->unique();
                $table->integer('seats')->default(1);
                $table->enum('status', ['pending', 'paid', 'cancelled'])->default('pending');
                $table->json('meta')->nullable();
                $table->timestamps();

                $table->foreign('ride_id')->references('id')->on('rides')->onDelete('cascade');
                $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('booking_mobil')) {
            Schema::dropIfExists('booking_mobil');
        }

        if (Schema::hasTable('booking_motor') && !Schema::hasTable('bookings')) {
            Schema::rename('booking_motor', 'bookings');
        }

        if (Schema::hasTable('payments')) {
            Schema::table('payments', function (Blueprint $table) {
                try {
                    $table->dropForeign(['booking_id']);
                } catch (\Exception $e) {
                }
            });
        }
    }
};
