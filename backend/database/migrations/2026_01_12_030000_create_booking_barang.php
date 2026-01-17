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
        if (!Schema::hasTable('booking_barang')) {
            Schema::create('booking_barang', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('ride_id');
                $table->unsignedBigInteger('user_id');
                $table->string('booking_number')->unique();
                $table->integer('seats')->default(1);
                $table->enum('status', ['pending', 'paid', 'cancelled'])->default('pending');
                $table->json('meta')->nullable();
                $table->timestamps();
            });

            // Add foreign keys only if referenced tables exist to avoid migration ordering issues
            if (Schema::hasTable('booking_barang')) {
                try {
                    Schema::table('booking_barang', function (Blueprint $table) {
                        if (Schema::hasTable('rides') && !Schema::hasColumn('booking_barang', 'ride_id')) {
                            // nothing
                        }
                        if (Schema::hasTable('rides')) {
                            $table->foreign('ride_id')->references('id')->on('rides')->onDelete('cascade');
                        }
                        if (Schema::hasTable('users')) {
                            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
                        }
                    });
                } catch (\Exception $e) {
                    // ignore foreign key creation errors (migration ordering may add them later)
                }
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('booking_barang')) {
            Schema::dropIfExists('booking_barang');
        }
    }
};
