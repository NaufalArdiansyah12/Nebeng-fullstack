<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Add gender column to verifikasi_ktp_customers
        Schema::table('verifikasi_ktp_customers', function (Blueprint $table) {
            if (!Schema::hasColumn('verifikasi_ktp_customers', 'jenis_kelamin')) {
                $table->enum('jenis_kelamin', ['Laki-laki', 'Perempuan'])->nullable()->after('tanggal_lahir');
            }
        });

        // Copy data from users.gender to verifikasi_ktp_customers.jenis_kelamin
        DB::statement("
            UPDATE verifikasi_ktp_customers v
            INNER JOIN users u ON v.user_id = u.id
            SET v.jenis_kelamin = CASE 
                WHEN LOWER(u.gender) IN ('male', 'laki-laki', 'l', 'm') THEN 'Laki-laki'
                WHEN LOWER(u.gender) IN ('female', 'perempuan', 'p', 'f') THEN 'Perempuan'
                ELSE NULL
            END
            WHERE u.gender IS NOT NULL
        ");

        // Remove gender column from users
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'gender')) {
                $table->dropColumn('gender');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Add gender column back to users
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'gender')) {
                $table->string('gender', 50)->nullable();
            }
        });

        // Copy data back from verifikasi_ktp_customers.jenis_kelamin to users.gender
        DB::statement("
            UPDATE users u
            INNER JOIN verifikasi_ktp_customers v ON u.id = v.user_id
            SET u.gender = CASE 
                WHEN v.jenis_kelamin = 'Laki-laki' THEN 'male'
                WHEN v.jenis_kelamin = 'Perempuan' THEN 'female'
                ELSE NULL
            END
            WHERE v.jenis_kelamin IS NOT NULL
        ");

        // Remove jenis_kelamin column from verifikasi_ktp_customers
        Schema::table('verifikasi_ktp_customers', function (Blueprint $table) {
            if (Schema::hasColumn('verifikasi_ktp_customers', 'jenis_kelamin')) {
                $table->dropColumn('jenis_kelamin');
            }
        });
    }
};
