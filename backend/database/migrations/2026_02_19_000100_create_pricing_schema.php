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
        // Transport modes (motor, mobil, barang, titip_barang, etc.)
        Schema::create('transport_modes', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->timestamps();
        });

        // Weight categories (e.g., 0-1kg, 1-5kg, etc.)
        Schema::create('weight_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->decimal('min_weight', 8, 2)->default(0);
            $table->decimal('max_weight', 8, 2)->nullable();
            $table->timestamps();
        });

        // Pricing profiles (grouping of pricing rules)
        Schema::create('pricing_profiles', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('description')->nullable();
            $table->foreignId('transport_mode_id')->nullable()->constrained('transport_modes')->nullOnDelete();
            $table->boolean('active')->default(true);
            $table->decimal('base_price', 12, 2)->default(0);
            $table->decimal('price_per_km', 12, 2)->default(0);
            $table->decimal('price_per_kg', 12, 2)->default(0);
            $table->decimal('min_price', 12, 2)->nullable();
            $table->timestamps();
        });

        // Pricing rules per profile + weight category + service
        Schema::create('pricing_rules', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pricing_profile_id')->constrained('pricing_profiles')->onDelete('cascade');
            $table->foreignId('weight_category_id')->nullable()->constrained('weight_categories')->onDelete('cascade');
            $table->string('service_type')->nullable();
            // price stored as nominal per-kg (you can change semantics in PriceCalculator)
            $table->decimal('price', 12, 2)->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pricing_rules');
        Schema::dropIfExists('pricing_profiles');
        Schema::dropIfExists('weight_categories');
        Schema::dropIfExists('transport_modes');
    }
};
