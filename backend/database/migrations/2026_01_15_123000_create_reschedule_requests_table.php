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
        Schema::create('reschedule_requests', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('booking_id');
            $table->unsignedBigInteger('requested_ride_id');
            $table->unsignedBigInteger('requested_by')->nullable();
            $table->enum('status', ['pending','awaiting_payment','paid','approved','rejected','cancelled'])->default('pending');
            $table->bigInteger('price_before')->nullable();
            $table->bigInteger('price_after')->nullable();
            $table->bigInteger('price_diff')->nullable();
            $table->string('payment_txn_id')->nullable();
            $table->text('reason')->nullable();
            $table->json('meta')->nullable();
            $table->timestamp('processed_at')->nullable();
            $table->timestamps();

            $table->foreign('booking_id')->references('id')->on('booking_mobil')->onDelete('cascade');
            $table->foreign('requested_ride_id')->references('id')->on('tebengan_mobil')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('reschedule_requests');
    }
};
