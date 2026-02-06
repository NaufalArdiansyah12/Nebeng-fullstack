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
        Schema::table('verifikasi_ktp_mitras', function (Blueprint $table) {
            // Drop kolom photo_ktp_wajah dan photo_wajah
            if (Schema::hasColumn('verifikasi_ktp_mitras', 'photo_ktp_wajah')) {
                $table->dropColumn('photo_ktp_wajah');
            }
            if (Schema::hasColumn('verifikasi_ktp_mitras', 'photo_wajah')) {
                $table->dropColumn('photo_wajah');
            }
            
            // Tambah kolom jenis_kelamin
            if (!Schema::hasColumn('verifikasi_ktp_mitras', 'jenis_kelamin')) {
                $table->enum('jenis_kelamin', ['laki-laki', 'perempuan'])->nullable()->after('tanggal_lahir');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('verifikasi_ktp_mitras', function (Blueprint $table) {
            // Hapus kolom jenis_kelamin
            if (Schema::hasColumn('verifikasi_ktp_mitras', 'jenis_kelamin')) {
                $table->dropColumn('jenis_kelamin');
            }
            
            // Restore kolom photo_wajah dan photo_ktp_wajah
            if (!Schema::hasColumn('verifikasi_ktp_mitras', 'photo_wajah')) {
                $table->string('photo_wajah')->nullable()->after('alamat');
            }
            if (!Schema::hasColumn('verifikasi_ktp_mitras', 'photo_ktp_wajah')) {
                $table->string('photo_ktp_wajah')->nullable()->after('photo_ktp');
            }
        });
    }
};
