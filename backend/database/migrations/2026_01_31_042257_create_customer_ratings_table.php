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
        // Create customer_ratings table (mitra rates customer)
        Schema::create('customer_ratings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('booking_id');
            $table->string('booking_type'); // 'motor', 'mobil', 'barang', 'titip_barang'
            $table->unsignedBigInteger('mitra_id'); // mitra who gives rating
            $table->unsignedBigInteger('customer_id'); // customer being rated
            $table->tinyInteger('rating')->unsigned(); // 1-5 stars
            $table->text('feedback')->nullable(); // optional text feedback
            $table->string('proof_image')->nullable(); // optional proof image
            $table->timestamps();

            // Indexes
            $table->index(['booking_id', 'booking_type']);
            $table->index('customer_id');
            $table->index('mitra_id');
            
            // Foreign keys
            $table->foreign('mitra_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('customer_id')->references('id')->on('users')->onDelete('cascade');
        });

        // Add customer rating columns to users table if not exists
        if (!Schema::hasColumn('users', 'customer_average_rating')) {
            Schema::table('users', function (Blueprint $table) {
                $table->decimal('customer_average_rating', 3, 2)->nullable()->after('total_ratings');
                $table->unsignedInteger('customer_total_ratings')->default(0)->after('customer_average_rating');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'customer_average_rating')) {
                $table->dropColumn(['customer_average_rating', 'customer_total_ratings']);
            }
        });
        
        Schema::dropIfExists('customer_ratings');
    }
};
