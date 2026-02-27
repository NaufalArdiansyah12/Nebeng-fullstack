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
        Schema::table('pricing_profiles', function (Blueprint $table) {
            $table->decimal('base_price', 12, 2)->default(0)->after('description');
            $table->decimal('price_per_km', 12, 2)->default(0)->after('base_price');
            $table->decimal('price_per_kg', 12, 2)->default(0)->after('price_per_km');
            $table->decimal('min_price', 12, 2)->nullable()->after('price_per_kg');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('pricing_profiles', function (Blueprint $table) {
            $table->dropColumn(['base_price', 'price_per_km', 'price_per_kg', 'min_price']);
        });
    }
};
