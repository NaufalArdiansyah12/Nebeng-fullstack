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
        Schema::create('verifikasi_ktp_posmitra', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('posmitra_id');

            $table->string('nama_lengkap')->nullable();
            $table->string('nik')->nullable();
            $table->date('tanggal_lahir')->nullable();
            $table->enum('jenis_kelamin', ['laki-laki', 'perempuan'])->nullable();
            $table->text('alamat')->nullable();

            $table->string('photo_ktp')->nullable();

            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->unsignedBigInteger('reviewer_id')->nullable();
            $table->timestamp('reviewed_at')->nullable();

            $table->json('meta')->nullable();
            $table->timestamps();

            $table->index('posmitra_id');
            
            $table->foreign('posmitra_id')
                  ->references('id')
                  ->on('posmitra_users')
                  ->onDelete('cascade');

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
        Schema::dropIfExists('verifikasi_ktp_posmitra');
    }
};
