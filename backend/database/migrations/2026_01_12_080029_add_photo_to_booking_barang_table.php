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
        Schema::table('booking_barang', function (Blueprint $table) {
            $table->string('photo')->nullable()->after('meta');
            $table->string('weight')->nullable()->after('photo');
            $table->text('description')->nullable()->after('weight');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('booking_barang', function (Blueprint $table) {
            $table->dropColumn(['photo', 'weight', 'description']);
        });
    }
};
