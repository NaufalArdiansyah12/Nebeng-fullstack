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
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ride_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('booking_number');
            $table->string('payment_method'); // qris, bri, bca, dana, cash
            $table->decimal('amount', 10, 2);
            $table->decimal('admin_fee', 10, 2)->default(0);
            $table->decimal('total_amount', 10, 2);
            $table->string('external_id')->unique(); // Xendit external ID
            $table->string('virtual_account_number')->nullable();
            $table->string('bank_code')->nullable(); // BRI, BCA, etc.
            $table->string('status')->default('pending'); // pending, paid, expired, failed
            $table->timestamp('expires_at')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->text('xendit_response')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
