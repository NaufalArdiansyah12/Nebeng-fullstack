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
        Schema::create('withdrawal_posmitra', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('posmitra_id');
            $table->string('transaction_id')->unique();
            $table->decimal('amount', 15, 2);
            $table->decimal('admin_fee', 15, 2)->default(0);
            $table->decimal('total_amount', 15, 2);
            
            // Bank Information
            $table->string('bank_name');
            $table->string('bank_account_number');
            $table->string('bank_account_name');
            
            // Status tracking
            $table->enum('status', [
                'pending',           // Pengajuan telah diajukan
                'verifying',        // Memeriksa pengajuan anda
                'approved',         // Pengajuan disetujui
                'processing',       // Pencairan sedang diproses
                'transferring',     // Pencairan sedang dikirim
                'completed',        // Penarikan telah ditransfer
                'rejected',         // Pengajuan ditolak
                'refunded'          // Dana telah direfund
            ])->default('pending');
            
            // Timeline
            $table->timestamp('submitted_at')->nullable();
            $table->timestamp('verified_at')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->timestamp('processing_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('rejected_at')->nullable();
            
            // Additional info
            $table->text('rejection_reason')->nullable();
            $table->text('notes')->nullable();
            $table->unsignedBigInteger('processed_by')->nullable();
            
            $table->timestamps();
            
            $table->foreign('posmitra_id')
                  ->references('id')
                  ->on('posmitra_users')
                  ->onDelete('cascade');
            
            $table->foreign('processed_by')
                  ->references('id')
                  ->on('users')
                  ->onDelete('set null');
            
            $table->index('posmitra_id');
            $table->index('status');
            $table->index('transaction_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('withdrawal_posmitra');
    }
};
