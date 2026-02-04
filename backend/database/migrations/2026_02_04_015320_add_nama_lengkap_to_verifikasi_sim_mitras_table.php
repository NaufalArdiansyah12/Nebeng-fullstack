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
        Schema::table('verifikasi_sim_mitras', function (Blueprint $table) {
            $table->string('nama_lengkap')->nullable()->after('user_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('verifikasi_sim_mitras', function (Blueprint $table) {
            $table->dropColumn('nama_lengkap');
        });
    }
};
