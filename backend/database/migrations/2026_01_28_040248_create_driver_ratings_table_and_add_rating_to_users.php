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
        // Create driver_ratings table
        Schema::create('driver_ratings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('booking_id');
            $table->string('booking_type'); // 'motor', 'mobil', 'barang', 'titip_barang'
            $table->unsignedBigInteger('user_id'); // customer who gives rating
            $table->unsignedBigInteger('driver_id'); // driver being rated
            $table->tinyInteger('rating')->unsigned(); // 1-5 stars
            $table->text('review')->nullable(); // optional text review
            $table->timestamps();

            // Indexes
            $table->index(['booking_id', 'booking_type']);
            $table->index('driver_id');
            $table->index('user_id');
            
            // Foreign keys
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('driver_id')->references('id')->on('users')->onDelete('cascade');
        });

        // Add average_rating column to users table
        Schema::table('users', function (Blueprint $table) {
            $table->decimal('average_rating', 3, 2)->nullable()->after('role');
            $table->unsignedInteger('total_ratings')->default(0)->after('average_rating');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['average_rating', 'total_ratings']);
        });
        
        Schema::dropIfExists('driver_ratings');
    }
};
