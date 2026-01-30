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
        Schema::table('kendaraan_mitra', function (Blueprint $table) {
            if (!Schema::hasColumn('kendaraan_mitra', 'deletion_status')) {
                $table->enum('deletion_status', ['none', 'pending', 'approved', 'rejected'])
                    ->default('none')
                    ->after('approved_by')
                    ->comment('Status permintaan hapus kendaraan');
            }
            
            if (!Schema::hasColumn('kendaraan_mitra', 'deletion_reason')) {
                $table->string('deletion_reason')
                    ->nullable()
                    ->after('deletion_status')
                    ->comment('Alasan permintaan hapus kendaraan');
            }
            
            if (!Schema::hasColumn('kendaraan_mitra', 'deletion_requested_at')) {
                $table->timestamp('deletion_requested_at')
                    ->nullable()
                    ->after('deletion_reason')
                    ->comment('Waktu request hapus');
            }
            
            if (!Schema::hasColumn('kendaraan_mitra', 'deletion_approved_at')) {
                $table->timestamp('deletion_approved_at')
                    ->nullable()
                    ->after('deletion_requested_at')
                    ->comment('Waktu approval hapus');
            }
            
            if (!Schema::hasColumn('kendaraan_mitra', 'deletion_approved_by')) {
                $table->foreignId('deletion_approved_by')
                    ->nullable()
                    ->after('deletion_approved_at')
                    ->constrained('users')
                    ->onDelete('set null')
                    ->comment('Admin yang approve/reject hapus');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('kendaraan_mitra', function (Blueprint $table) {
            if (Schema::hasColumn('kendaraan_mitra', 'deletion_approved_by')) {
                $table->dropForeign(['deletion_approved_by']);
                $table->dropColumn('deletion_approved_by');
            }
            if (Schema::hasColumn('kendaraan_mitra', 'deletion_approved_at')) {
                $table->dropColumn('deletion_approved_at');
            }
            if (Schema::hasColumn('kendaraan_mitra', 'deletion_requested_at')) {
                $table->dropColumn('deletion_requested_at');
            }
            if (Schema::hasColumn('kendaraan_mitra', 'deletion_reason')) {
                $table->dropColumn('deletion_reason');
            }
            if (Schema::hasColumn('kendaraan_mitra', 'deletion_status')) {
                $table->dropColumn('deletion_status');
            }
        });
    }
};
