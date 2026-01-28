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
        Schema::create('refunds', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('booking_id');
            $table->string('booking_type'); // motor, mobil, barang, titip
            $table->string('refund_reason'); // Alasan refund
            $table->decimal('total_amount', 15, 2); // Total dana asli
            $table->decimal('refund_amount', 15, 2); // Estimasi refund
            $table->decimal('admin_fee', 15, 2)->default(0); // Biaya admin
            
            // Bank account info
            $table->string('bank_name');
            $table->string('account_number');
            $table->string('account_holder_name');
            
            // Status: pending, approved, processing, completed, rejected
            $table->enum('status', ['pending', 'approved', 'processing', 'completed', 'rejected'])->default('pending');
            $table->text('rejection_reason')->nullable();
            
            // Tracking dates
            $table->timestamp('submitted_at')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->timestamp('processed_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            
            $table->timestamps();
            
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('refunds');
    }
};
