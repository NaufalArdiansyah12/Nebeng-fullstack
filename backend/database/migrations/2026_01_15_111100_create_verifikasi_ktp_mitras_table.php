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
        Schema::create('verifikasi_ktp_mitras', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('mitra_id');

            $table->string('nama_lengkap')->nullable();
            $table->string('nik')->nullable();
            $table->date('tanggal_lahir')->nullable();
            $table->text('alamat')->nullable();

            $table->string('photo_wajah')->nullable();
            $table->string('photo_ktp')->nullable();
            $table->string('photo_ktp_wajah')->nullable();

            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->unsignedBigInteger('reviewer_id')->nullable();
            $table->timestamp('reviewed_at')->nullable();

            $table->json('meta')->nullable();
            $table->timestamps();

            // mitra table name may vary; skip FK to avoid migration errors if table differs
            $table->index('mitra_id');

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
        Schema::dropIfExists('verifikasi_ktp_mitras');
    }
};
