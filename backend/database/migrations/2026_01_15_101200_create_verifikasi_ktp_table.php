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
        Schema::create('verifikasi_ktp', function (Blueprint $table) {
            $table->id();

            // polymorphic relation to support customers and mitra
            $table->morphs('verifiable');

            // captured identity fields (optional)
            $table->string('nama_lengkap')->nullable();
            $table->string('nik')->nullable();
            $table->date('tanggal_lahir')->nullable();
            $table->text('alamat')->nullable();

            // three photos: wajah, ktp, ktp+wajah
            $table->string('photo_wajah')->nullable();
            $table->string('photo_ktp')->nullable();
            $table->string('photo_ktp_wajah')->nullable();

            // verification status and reviewer
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->unsignedBigInteger('reviewer_id')->nullable();
            $table->timestamp('reviewed_at')->nullable();

            // additional data
            $table->json('meta')->nullable();

            $table->timestamps();

            $table->foreign('reviewer_id')
                  ->references('id')
                  ->on('users')
                  ->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('verifikasi_ktp');
    }
};
