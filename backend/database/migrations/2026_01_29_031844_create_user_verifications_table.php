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
        Schema::create('mitra_verifikasi', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('ktp_verification_id')->nullable();
            $table->unsignedBigInteger('sim_verification_id')->nullable();
            $table->unsignedBigInteger('skck_verification_id')->nullable();
            $table->unsignedBigInteger('bank_verification_id')->nullable();
            $table->timestamp('verified_at')->nullable();
            $table->timestamps();
            
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('ktp_verification_id')->references('id')->on('verifikasi_ktp_mitras')->onDelete('set null');
            $table->foreign('sim_verification_id')->references('id')->on('verifikasi_sim_mitras')->onDelete('set null');
            $table->foreign('skck_verification_id')->references('id')->on('verifikasi_skck_mitras')->onDelete('set null');
            $table->foreign('bank_verification_id')->references('id')->on('verifikasi_bank_mitras')->onDelete('set null');
            $table->unique('user_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('mitra_verifikasi');
    }
};
