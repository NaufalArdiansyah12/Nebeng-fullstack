<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('pricing_profiles', function (Blueprint $table) {
            // Kolom untuk menyimpan weight category ID default untuk profile ini
            $table->foreignId('default_weight_category_id')->nullable()->after('transport_mode_id')->constrained('weight_categories')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('pricing_profiles', function (Blueprint $table) {
            $table->dropForeign(['default_weight_category_id']);
            $table->dropColumn('default_weight_category_id');
        });
    }
};
