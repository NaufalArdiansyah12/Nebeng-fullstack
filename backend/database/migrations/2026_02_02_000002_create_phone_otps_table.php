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
        Schema::create('phone_otps', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('phone', 20);
            $table->string('otp_code');
            $table->integer('attempts')->default(0);
            $table->timestamp('expires_at');
            $table->boolean('is_used')->default(false);
            $table->timestamps();
            
            // Index untuk performa
            $table->index(['user_id', 'phone']);
            $table->index('expires_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('phone_otps');
    }
};
