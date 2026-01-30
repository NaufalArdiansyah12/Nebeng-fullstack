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
            if (!Schema::hasColumn('kendaraan_mitra', 'status')) {
                $table->enum('status', ['pending', 'approved', 'rejected'])
                    ->default('pending')
                    ->after('is_active')
                    ->comment('Status approval kendaraan oleh admin');
            }
            
            if (!Schema::hasColumn('kendaraan_mitra', 'rejection_reason')) {
                $table->text('rejection_reason')
                    ->nullable()
                    ->after('status')
                    ->comment('Alasan penolakan jika status rejected');
            }
            
            if (!Schema::hasColumn('kendaraan_mitra', 'approved_at')) {
                $table->timestamp('approved_at')
                    ->nullable()
                    ->after('rejection_reason')
                    ->comment('Waktu approval');
            }
            
            if (!Schema::hasColumn('kendaraan_mitra', 'approved_by')) {
                $table->foreignId('approved_by')
                    ->nullable()
                    ->after('approved_at')
                    ->constrained('users')
                    ->onDelete('set null')
                    ->comment('Admin yang melakukan approval/rejection');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('kendaraan_mitra', function (Blueprint $table) {
            if (Schema::hasColumn('kendaraan_mitra', 'approved_by')) {
                $table->dropForeign(['approved_by']);
                $table->dropColumn('approved_by');
            }
            if (Schema::hasColumn('kendaraan_mitra', 'approved_at')) {
                $table->dropColumn('approved_at');
            }
            if (Schema::hasColumn('kendaraan_mitra', 'rejection_reason')) {
                $table->dropColumn('rejection_reason');
            }
            if (Schema::hasColumn('kendaraan_mitra', 'status')) {
                $table->dropColumn('status');
            }
        });
    }
};
